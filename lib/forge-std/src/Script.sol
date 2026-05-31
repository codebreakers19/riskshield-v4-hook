// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface Vm {
    function envUint(string calldata name) external view returns (uint256);
    function envAddress(string calldata name) external view returns (address);
    function addr(uint256 privateKey) external returns (address);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

abstract contract Script {
    Vm public constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
}
