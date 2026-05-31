// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "v4-core/src/types/PoolOperation.sol";

import {RiskShieldHook} from "../src/RiskShieldHook.sol";
import {RiskShieldVault} from "../src/RiskShieldVault.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {MockRiskAsset} from "../src/mocks/MockRiskAsset.sol";

contract UnauthorizedHookCaller {
    function callBeforeSwap(RiskShieldHook hook, PoolKey calldata key, SwapParams calldata params) external {
        hook.beforeSwap(address(this), key, params, "");
    }
}

contract RiskShieldHookTest {
    MockUSDC internal usdc;
    MockRiskAsset internal risk;
    RiskShieldVault internal vault;
    RiskShieldHook internal hook;
    PoolKey internal key;

    uint256 internal constant USDC = 1e6;

    constructor() {
        usdc = new MockUSDC();
        risk = new MockRiskAsset();
        vault = new RiskShieldVault(usdc, address(this));
        hook = new RiskShieldHook(address(this), vault);
        vault.setHook(address(hook));

        key = PoolKey({
            currency0: Currency.wrap(address(risk)),
            currency1: Currency.wrap(address(usdc)),
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });
    }

    function testBeforeSwapReturnsDynamicPremiumFee() external {
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -100_000 * int256(USDC),
            sqrtPriceLimitX96: 0
        });

        (, , uint24 feeOverride) = hook.beforeSwap(address(this), key, params, abi.encode(int24(120)));

        require(feeOverride & LPFeeLibrary.OVERRIDE_FEE_FLAG != 0, "override flag missing");
        require((feeOverride & LPFeeLibrary.REMOVE_OVERRIDE_MASK) > 0, "fee missing");
    }

    function testAfterSwapAccountsPremium() external {
        usdc.mint(address(this), 10_000 * USDC);
        usdc.approve(address(vault), 10_000 * USDC);
        vault.depositJunior(bytes32(0), 10_000 * USDC);

        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -100_000 * int256(USDC),
            sqrtPriceLimitX96: 0
        });

        hook.beforeSwap(address(this), key, params, abi.encode(int24(120)));
        hook.afterSwap(address(this), key, params, BalanceDeltaLibrary.ZERO_DELTA, "");

        require(vault.reserveAvailable(bytes32(0)) >= 10_000 * USDC, "reserve underflow");
    }

    function testOnlyPoolManagerCanCallHookCallbacks() external {
        UnauthorizedHookCaller caller = new UnauthorizedHookCaller();
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -100_000 * int256(USDC),
            sqrtPriceLimitX96: 0
        });

        try caller.callBeforeSwap(hook, key, params) {
            revert("unauthorized call succeeded");
        } catch {}
    }

    function testAfterAddLiquidityOpensSeniorPosition() external {
        ModifyLiquidityParams memory params =
            ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 100, salt: bytes32(0)});

        hook.afterAddLiquidity(
            address(0xA11CE),
            key,
            params,
            BalanceDeltaLibrary.ZERO_DELTA,
            BalanceDeltaLibrary.ZERO_DELTA,
            abi.encode(uint8(1), 1 ether, 2_000 * USDC, 2_000e18)
        );

        (, address owner,,,,,) = vault.seniorPositions(1);
        require(owner == address(0xA11CE), "senior owner mismatch");
    }
}

