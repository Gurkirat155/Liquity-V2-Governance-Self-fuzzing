// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {TargetFunctionsGovernanace} from "./TargetFiles/TargetFunctionsGovernanace.sol";
// import {SelfSetup} from "./SelfSetup.sol";
// import {CryticAsserts} from "@chimera/CryticAsserts.sol";

contract SelfCryticTester is TargetFunctionsGovernanace {

    constructor() payable{
        setup();
    }
}