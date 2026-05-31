// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {MockRiskAsset} from "../src/mocks/MockRiskAsset.sol";
import {RiskShieldVault} from "../src/RiskShieldVault.sol";
import {RiskShieldHook} from "../src/RiskShieldHook.sol";

contract DeployRiskShield {
    address public constant UNICHAIN_SEPOLIA_POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;

    function deploy() external returns (MockUSDC usdc, MockRiskAsset risk, RiskShieldVault vault, RiskShieldHook hook) {
        usdc = new MockUSDC();
        risk = new MockRiskAsset();
        vault = new RiskShieldVault(usdc, address(this));
        hook = new RiskShieldHook(UNICHAIN_SEPOLIA_POOL_MANAGER, vault);
        vault.setHook(address(hook));
        vault.transferAdmin(msg.sender);
    }
}
