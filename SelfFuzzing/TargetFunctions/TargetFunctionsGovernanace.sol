// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Setup} from "../Setup.sol";


contract TargetFunctionsGovernanace is Setup{
    

    // 1. first make view functions 
    // 2. then make the main functions withdraw deposit, allcate claim etc

    // Jot down view functions
    // epoch()
    // epochStart()
    // secondsWithinEpoch()
    // getLatestVotingThreshold()
    // calculateVotingThreshold(uint256 _votes)
    // getTotalVotesAndState()
    // getInitiativeSnapshotAndState(address _initiative)
    // getInitiativeState( address _initiative, VoteSnapshot memory _votesSnapshot, InitiativeVoteSnapshot memory       _votesForInitiativeSnapshot, InitiativeState memory _initiativeState)


    // function handler_epoch()
    // Some users must have lqty and some might not so that we could also get a revert from the function
    // 1. Push some users address and give them some lqty
    function handler_clampedDepositLqty() external {
        // governance.
    } 
}