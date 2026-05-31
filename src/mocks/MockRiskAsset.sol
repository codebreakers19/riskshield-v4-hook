// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {MockERC20} from "./MockERC20.sol";

contract MockRiskAsset is MockERC20 {
    constructor() MockERC20("Mock Risk Asset", "mRISK", 18) {}
}

