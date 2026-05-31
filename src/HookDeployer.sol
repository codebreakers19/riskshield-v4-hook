// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract HookDeployer {
    event Deployed(address indexed deployed, bytes32 indexed salt);

    error DeploymentFailed();

    function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed) {
        assembly ("memory-safe") {
            deployed := create2(callvalue(), add(creationCode, 0x20), mload(creationCode), salt)
        }

        if (deployed == address(0)) revert DeploymentFailed();
        emit Deployed(deployed, salt);
    }

    function computeAddress(bytes32 salt, bytes32 initCodeHash) external view returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCodeHash)))));
    }
}

