// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "./IERC20.sol";
import {InsuranceMath} from "./InsuranceMath.sol";

contract RiskShieldVault {
    using InsuranceMath for uint256;

    uint256 internal constant BPS = 10_000;

    struct PoolReserve {
        uint256 juniorCapital;
        uint256 accruedPremiums;
        uint256 paidCoverage;
    }

    struct SeniorPosition {
        bytes32 poolId;
        address owner;
        uint256 entryAmount0;
        uint256 entryAmount1;
        uint256 entryPriceWad;
        uint256 liquidity;
        bool closed;
    }

    IERC20 public immutable reserveToken;
    address public admin;
    address public hook;
    uint256 public nextPositionId = 1;
    uint256 public maxCoverageBps = 3_000;

    mapping(bytes32 poolId => PoolReserve) public poolReserves;
    mapping(bytes32 poolId => mapping(address account => uint256 amount)) public juniorBalanceOf;
    mapping(uint256 positionId => SeniorPosition position) public seniorPositions;

    event HookUpdated(address indexed hook);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    event JuniorDeposited(bytes32 indexed poolId, address indexed insurer, uint256 amount);
    event PremiumFunded(bytes32 indexed poolId, address indexed funder, uint256 amount);
    event PremiumAccrued(bytes32 indexed poolId, uint256 amount);
    event SeniorPositionOpened(
        uint256 indexed positionId,
        bytes32 indexed poolId,
        address indexed owner,
        uint256 amount0,
        uint256 amount1,
        uint256 entryPriceWad,
        uint256 liquidity
    );
    event SeniorPositionClosed(
        uint256 indexed positionId,
        bytes32 indexed poolId,
        address indexed owner,
        uint256 holdValue,
        uint256 exitValue,
        uint256 loss,
        uint256 coveragePaid
    );

    error NotAuthorized();
    error InvalidAmount();
    error PositionClosed();
    error NotPositionOwner();
    error TransferFailed();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAuthorized();
        _;
    }

    modifier onlyHookOrAdmin() {
        if (msg.sender != hook && msg.sender != admin) revert NotAuthorized();
        _;
    }

    constructor(IERC20 reserveToken_, address admin_) {
        reserveToken = reserveToken_;
        admin = admin_;
    }

    function setHook(address hook_) external onlyAdmin {
        hook = hook_;
        emit HookUpdated(hook_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAmount();
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    function setMaxCoverageBps(uint256 maxCoverageBps_) external onlyAdmin {
        if (maxCoverageBps_ > BPS) revert InvalidAmount();
        maxCoverageBps = maxCoverageBps_;
    }

    function depositJunior(bytes32 poolId, uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        _pullReserve(msg.sender, amount);
        juniorBalanceOf[poolId][msg.sender] += amount;
        poolReserves[poolId].juniorCapital += amount;
        emit JuniorDeposited(poolId, msg.sender, amount);
    }

    function fundPremium(bytes32 poolId, uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        _pullReserve(msg.sender, amount);
        poolReserves[poolId].accruedPremiums += amount;
        emit PremiumFunded(poolId, msg.sender, amount);
    }

    function accruePremium(bytes32 poolId, uint256 amount) external onlyHookOrAdmin {
        if (amount == 0) return;
        poolReserves[poolId].accruedPremiums += amount;
        emit PremiumAccrued(poolId, amount);
    }

    function openSeniorPosition(
        bytes32 poolId,
        address owner,
        uint256 amount0,
        uint256 amount1,
        uint256 entryPriceWad,
        uint256 liquidity
    ) external onlyHookOrAdmin returns (uint256 positionId) {
        if (owner == address(0) || entryPriceWad == 0 || liquidity == 0) revert InvalidAmount();

        positionId = nextPositionId++;
        seniorPositions[positionId] = SeniorPosition({
            poolId: poolId,
            owner: owner,
            entryAmount0: amount0,
            entryAmount1: amount1,
            entryPriceWad: entryPriceWad,
            liquidity: liquidity,
            closed: false
        });

        emit SeniorPositionOpened(positionId, poolId, owner, amount0, amount1, entryPriceWad, liquidity);
    }

    function closeSeniorPosition(uint256 positionId, uint256 exitAmount0, uint256 exitAmount1, uint256 exitPriceWad)
        external
        onlyHookOrAdmin
        returns (uint256 loss, uint256 coveragePaid)
    {
        return _closeSeniorPosition(positionId, exitAmount0, exitAmount1, exitPriceWad);
    }

    function closeMySeniorPosition(uint256 positionId, uint256 exitAmount0, uint256 exitAmount1, uint256 exitPriceWad)
        external
        returns (uint256 loss, uint256 coveragePaid)
    {
        SeniorPosition storage position = seniorPositions[positionId];
        if (msg.sender != position.owner) revert NotPositionOwner();
        return _closeSeniorPosition(positionId, exitAmount0, exitAmount1, exitPriceWad);
    }

    function _closeSeniorPosition(uint256 positionId, uint256 exitAmount0, uint256 exitAmount1, uint256 exitPriceWad)
        internal
        returns (uint256 loss, uint256 coveragePaid)
    {
        SeniorPosition storage position = seniorPositions[positionId];
        if (position.closed) revert PositionClosed();
        position.closed = true;

        uint256 holdValue =
            InsuranceMath.valueInToken1(position.entryAmount0, position.entryAmount1, exitPriceWad);
        uint256 exitValue = InsuranceMath.valueInToken1(exitAmount0, exitAmount1, exitPriceWad);
        uint256 availableReserve = reserveAvailable(position.poolId);

        (loss, coveragePaid) = InsuranceMath.coveredLoss(holdValue, exitValue, availableReserve, maxCoverageBps);
        if (coveragePaid != 0) {
            poolReserves[position.poolId].paidCoverage += coveragePaid;
            _pushReserve(position.owner, coveragePaid);
        }

        emit SeniorPositionClosed(
            positionId, position.poolId, position.owner, holdValue, exitValue, loss, coveragePaid
        );
    }

    function reserveAvailable(bytes32 poolId) public view returns (uint256) {
        PoolReserve memory reserve = poolReserves[poolId];
        uint256 accountedReserve = reserve.juniorCapital + reserve.accruedPremiums;
        if (accountedReserve <= reserve.paidCoverage) return 0;
        accountedReserve -= reserve.paidCoverage;

        uint256 balance = reserveToken.balanceOf(address(this));
        return balance < accountedReserve ? balance : accountedReserve;
    }

    function positionValues(uint256 positionId, uint256 exitAmount0, uint256 exitAmount1, uint256 exitPriceWad)
        external
        view
        returns (uint256 holdValue, uint256 exitValue, uint256 loss, uint256 coverable)
    {
        SeniorPosition memory position = seniorPositions[positionId];
        holdValue = InsuranceMath.valueInToken1(position.entryAmount0, position.entryAmount1, exitPriceWad);
        exitValue = InsuranceMath.valueInToken1(exitAmount0, exitAmount1, exitPriceWad);
        (loss, coverable) = InsuranceMath.coveredLoss(
            holdValue, exitValue, reserveAvailable(position.poolId), maxCoverageBps
        );
    }

    function _pullReserve(address from, uint256 amount) internal {
        bool ok = reserveToken.transferFrom(from, address(this), amount);
        if (!ok) revert TransferFailed();
    }

    function _pushReserve(address to, uint256 amount) internal {
        bool ok = reserveToken.transfer(to, amount);
        if (!ok) revert TransferFailed();
    }
}
