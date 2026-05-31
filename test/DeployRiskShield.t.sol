// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DeployRiskShield} from "../script/DeployRiskShield.s.sol";
import {RiskShieldVault} from "../src/RiskShieldVault.sol";
import {RiskShieldHook} from "../src/RiskShieldHook.sol";

contract DeployRiskShieldTest {
    function testDeployScriptWiresVaultAndHook() external {
        DeployRiskShield deployer = new DeployRiskShield();
        (, , RiskShieldVault vault, RiskShieldHook hook) = deployer.deployForTest(address(0xA11CE));

        require(vault.admin() == address(0xA11CE), "admin mismatch");
        require(vault.hook() == address(hook), "hook mismatch");
        require(hook.poolManager() == deployer.UNICHAIN_SEPOLIA_POOL_MANAGER(), "pool manager mismatch");
    }
}
