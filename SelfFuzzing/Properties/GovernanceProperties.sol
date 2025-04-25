// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import "../TargetFiles/TargetFunctionsGovernanace.sol";
import "../Setup.sol";

contract GovernanceProperties is Setup{

    // constructor() payable{
    //     setup();
    // }

    function echidna_checkUserBalance() public view returns(bool){
        return (lqty.balanceOf(users[1]) == initialLqtyAllocatedPerUser);
    }

}
// View functions should never revert 
