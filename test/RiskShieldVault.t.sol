// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {InsuranceMath} from "../src/InsuranceMath.sol";
import {RiskShieldVault} from "../src/RiskShieldVault.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

contract RiskShieldVaultTest {
    MockUSDC internal usdc;
    RiskShieldVault internal vault;
    bytes32 internal constant POOL_ID = keccak256("RISK/USDC");

    uint256 internal constant USDC = 1e6;
    uint256 internal constant WAD = 1e18;

    constructor() {
        usdc = new MockUSDC();
        vault = new RiskShieldVault(usdc, address(this));
        vault.setHook(address(this));
    }

    function testSeniorDepositTracksEntryAmounts() external {
        uint256 id = vault.openSeniorPosition(POOL_ID, address(0xA11CE), 10 ether, 20_000 * USDC, 2_000 * WAD, 100);
        (
            bytes32 poolId,
            address owner,
            uint256 entryAmount0,
            uint256 entryAmount1,
            uint256 entryPriceWad,
            uint256 liquidity,
            bool closed
        ) = vault.seniorPositions(id);

        _assertEqBytes32(poolId, POOL_ID);
        _assertEq(owner, address(0xA11CE));
        _assertEq(entryAmount0, 10 ether);
        _assertEq(entryAmount1, 20_000 * USDC);
        _assertEq(entryPriceWad, 2_000 * WAD);
        _assertEq(liquidity, 100);
        _assertFalse(closed);
    }

    function testJuniorDepositIncreasesInsuranceReserve() external {
        usdc.mint(address(this), 5_000 * USDC);
        usdc.approve(address(vault), 5_000 * USDC);
        vault.depositJunior(POOL_ID, 5_000 * USDC);

        _assertEq(vault.juniorBalanceOf(POOL_ID, address(this)), 5_000 * USDC);
        _assertEq(vault.reserveAvailable(POOL_ID), 5_000 * USDC);
    }

    function testSwapCollectsPremium() external {
        usdc.mint(address(this), 100 * USDC);
        usdc.approve(address(vault), 100 * USDC);
        vault.fundPremium(POOL_ID, 100 * USDC);
        _assertEq(vault.reserveAvailable(POOL_ID), 100 * USDC);
    }

    function testLargerSwapPaysHigherPremium() external pure {
        uint256 small = InsuranceMath.premiumBps(5, 1_000 * USDC, 1_000_000 * USDC, 0, 100);
        uint256 large = InsuranceMath.premiumBps(5, 100_000 * USDC, 1_000_000 * USDC, 0, 100);
        _assertGt(large, small);
    }

    function testSeniorWithdrawalReceivesCoverageWhenILExists() external {
        uint256 reserve = 2_000 * USDC;
        usdc.mint(address(this), reserve);
        usdc.approve(address(vault), reserve);
        vault.depositJunior(POOL_ID, reserve);

        uint256 id = vault.openSeniorPosition(POOL_ID, address(0xA11CE), 1 ether, 2_000 * USDC, 2_000 * WAD, 100);
        uint256 aliceBefore = usdc.balanceOf(address(0xA11CE));

        (, uint256 coverage) = vault.closeSeniorPosition(id, 0.5 ether, 1_000 * USDC, 2_000 * WAD);

        _assertGt(coverage, 0);
        _assertEq(usdc.balanceOf(address(0xA11CE)), aliceBefore + coverage);
    }

    function testSeniorCoverageIsCappedByReserve() external {
        uint256 reserve = 100 * USDC;
        usdc.mint(address(this), reserve);
        usdc.approve(address(vault), reserve);
        vault.depositJunior(POOL_ID, reserve);

        uint256 id = vault.openSeniorPosition(POOL_ID, address(0xA11CE), 10 ether, 20_000 * USDC, 2_000 * WAD, 100);
        (, uint256 coverage) = vault.closeSeniorPosition(id, 1 ether, 2_000 * USDC, 2_000 * WAD);

        _assertEq(coverage, reserve);
        _assertEq(vault.reserveAvailable(POOL_ID), 0);
    }

    function testJuniorCapitalAbsorbsFirstLossOnlyAfterReserve() external {
        uint256 reserve = 1_000 * USDC;
        uint256 premium = 500 * USDC;
        usdc.mint(address(this), reserve + premium);
        usdc.approve(address(vault), reserve + premium);
        vault.depositJunior(POOL_ID, reserve);
        vault.fundPremium(POOL_ID, premium);

        uint256 id = vault.openSeniorPosition(POOL_ID, address(0xA11CE), 1 ether, 2_000 * USDC, 2_000 * WAD, 100);
        (, uint256 coverage) = vault.closeSeniorPosition(id, 0.5 ether, 1_000 * USDC, 2_000 * WAD);

        _assertGt(coverage, premium);
        _assertEq(vault.reserveAvailable(POOL_ID), reserve + premium - coverage);
    }

    function testNoCompensationWhenNoIL() external {
        usdc.mint(address(this), 1_000 * USDC);
        usdc.approve(address(vault), 1_000 * USDC);
        vault.depositJunior(POOL_ID, 1_000 * USDC);

        uint256 id = vault.openSeniorPosition(POOL_ID, address(0xA11CE), 1 ether, 2_000 * USDC, 2_000 * WAD, 100);
        (uint256 loss, uint256 coverage) = vault.closeSeniorPosition(id, 1 ether, 2_000 * USDC, 2_000 * WAD);

        _assertEq(loss, 0);
        _assertEq(coverage, 0);
    }

    function testPremiumAccountingCannotOverdrawReserve() external {
        usdc.mint(address(this), 100 * USDC);
        usdc.approve(address(vault), 100 * USDC);
        vault.depositJunior(POOL_ID, 100 * USDC);
        vault.accruePremium(POOL_ID, 1_000 * USDC);

        _assertEq(vault.reserveAvailable(POOL_ID), 100 * USDC);
    }

    function _assertEq(uint256 a, uint256 b) internal pure {
        require(a == b, "uint neq");
    }

    function _assertEq(address a, address b) internal pure {
        require(a == b, "address neq");
    }

    function _assertEqBytes32(bytes32 a, bytes32 b) internal pure {
        require(a == b, "bytes32 neq");
    }

    function _assertGt(uint256 a, uint256 b) internal pure {
        require(a > b, "uint !gt");
    }

    function _assertFalse(bool value) internal pure {
        require(!value, "not false");
    }
}

