// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library InsuranceMath {
    uint256 internal constant BPS = 10_000;
    uint256 internal constant WAD = 1e18;

    error InvalidPrice();

    function abs(int256 value) internal pure returns (uint256) {
        return uint256(value >= 0 ? value : -value);
    }

    function premiumBps(
        uint256 basePremiumBps,
        uint256 tradeAmount,
        uint256 referenceLiquidity,
        uint256 tickMove,
        uint256 maxPremiumBps
    ) internal pure returns (uint256 premium) {
        uint256 sizePremium = referenceLiquidity == 0 ? 0 : (tradeAmount * 100) / referenceLiquidity;
        uint256 volatilityPremium = tickMove / 10;
        premium = basePremiumBps + sizePremium + volatilityPremium;
        if (premium > maxPremiumBps) premium = maxPremiumBps;
    }

    function valueInToken1(uint256 amount0, uint256 amount1, uint256 priceToken1PerToken0Wad)
        internal
        pure
        returns (uint256)
    {
        if (priceToken1PerToken0Wad == 0) revert InvalidPrice();
        return ((amount0 * priceToken1PerToken0Wad) / WAD) + amount1;
    }

    function coveredLoss(
        uint256 holdValue,
        uint256 exitValue,
        uint256 availableReserve,
        uint256 maxCoverageBps
    ) internal pure returns (uint256 loss, uint256 coverage) {
        if (exitValue >= holdValue) return (0, 0);

        loss = holdValue - exitValue;
        uint256 coverageCap = (holdValue * maxCoverageBps) / BPS;
        coverage = loss;
        if (coverage > coverageCap) coverage = coverageCap;
        if (coverage > availableReserve) coverage = availableReserve;
    }
}

