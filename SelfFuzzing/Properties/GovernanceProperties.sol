// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "../SelfSetup.sol";
import {BeforeAfter}from "../BeforeAfter.sol";
import {Test,console} from "forge-std/Test.sol";

contract GovernanceProperties is SelfSetup, BeforeAfter,Test {
// abstract contract GovernanceProperties is SelfSetup {


    event InitialBeforeAfterStatus(uint8 beforeStatus, uint8 afterStatus);
    event BeforeAfterStatus(uint8 beforeStatus, uint8 afterStatus);
    event BoldBalanceError(uint256, uint256);
    event DebugNumbers(string,uint256);
    event DebugPath(string);
    event ErrorBytes(string,bytes);
    event VotesAndEpcoh(uint256, uint256);
    event TotalAllocatedOffsetBeforeAndAfter(uint256, uint256);
    event LqtyAmt(uint256);

    
    // returns(bool)
    function invariant_initiativeShouldReturnSameStatus() public {
        if(_before.epoch == _after.epoch) {
            for(uint256 i;i <deployedInitiatives.length; i++){
                address initiative = deployedInitiatives[i];

                emit InitialBeforeAfterStatus(uint8(_before.initiativeStatus[initiative]) , uint8(_after.initiativeStatus[initiative]));

                if(_before.initiativeStatus[initiative] == IGovernance.InitiativeStatus.NONEXISTENT && _after.initiativeStatus[initiative] == IGovernance.InitiativeStatus.WARM_UP){
                    continue;
                }

                if(_before.initiativeStatus[initiative] == IGovernance.InitiativeStatus.CLAIMABLE && _after.initiativeStatus[initiative] == IGovernance.InitiativeStatus.CLAIMED){
                    continue;

                }

                if(_before.initiativeStatus[initiative] == IGovernance.InitiativeStatus.UNREGISTERABLE && _after.initiativeStatus[initiative] == IGovernance.InitiativeStatus.DISABLED){
                    continue;
                }

                assert(_before.initiativeStatus[initiative] == _after.initiativeStatus[initiative]);
                // if(_before.initiativeStatus[initiative] != _after.initiativeStatus[initiative]){
                //     emit BeforeAfterStatus(uint8(_before.initiativeStatus[initiative]) , uint8(_after.initiativeStatus[initiative]));
                //     emit AssertionFailed("_before.initiativeStatus[initiative] != _after.initiativeStatus[initiative] is false");
                //     assert(false);
                // }
                // return(_before.initiativeStatus[initiative] == _after.initiativeStatus[initiative]);

            }
        }
        // assert(true);
        // return true;
    }

    /* ------------------------commenting out revert properties for the fuzzer to function better
    ---------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------- */

    // function invariant_epochShouldNotRevert() public {
    //     try governance.epoch(){
    //         // return true;
    //         assert(true);
    //     } catch  {
    //         emit Error("Epoch should not revert");
    //         // return false;
    //         assert(false);
    //     }
    // }

    // function invariant_secondsWithinEpochShouldNotRevert() public {
        
    //     try governance.secondsWithinEpoch() {
    //         // return true;
    //         assert(true);
    //     }catch {
    //         emit Error("Epoch should not revert");
    //         // return false;
    //         assert(false);
    //     }
    // }

    // function invariant_getTotalVotesAndStateShouldNotRevert() public {
    //     try governance.getTotalVotesAndState() {
    //         // return true;
    //         assert(true);
    //     }
    //     catch {
    //         emit Error("Get total Votes and state should not revert");
    //         // return false;
    //         assert(false);
    //     }
    // }

    // function invariant_calculateVotingThresholdWithVotesShouldNotRevert() public   {
    //     (uint256 totalVotes,) = governance.votesSnapshot();
    //     try governance.calculateVotingThreshold(totalVotes) {
    //         // return true;
    //         assert(true);
    //     }catch{
    //         emit Error("Calculate Voting threshold should not revert");
    //         // return false;
    //         assert(false);
    //     }
    // }

    // function invariant_calculateVotingThresholdShouldNotRevert() public   {
        
    //     try governance.calculateVotingThreshold() {
    //         // return true;
    //         assert(true);
    //     }catch{
    //         emit Error("Calculate Voting threshold should not revert");
    //         // return false;
    //         assert(false);
    //     }
    // }


    // function invariant_getLatestVotingThresholdShouldNotRevert() public   {
        
    //     try governance.getLatestVotingThreshold() {
    //         // return true;
    //         assert(true);
    //     }catch{
    //         emit Error("Get latest voting threshold should not revert");
    //         // return false;
    //         assert(false);
    //     }
    // }

    /* ------------------------commenting out revert properties for the fuzzer to function better
    ---------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------- */


    function invariant_offSetOfUserShouldIncreaseWithDepositForSingleUser(uint8 userIndex, uint256 lqtyAmt) public {
        if (lqtyAmt == 0) return;
        (address user,) = _getRandomUser(userIndex);
        (, uint256 unallocatedLQTYOffsetInital,,) = governance.userStates(user);

        uint256 userBalance = lqty.balanceOf(user);
        // if (userBalance == 0) return;
        lqtyAmt = lqtyAmt % userBalance;
        if (lqtyAmt == 0 || userBalance == 0) return;
        address userProxy = governance.deriveUserProxyAddress(user);
        if(userProxy.code.length == 0) return;

        hevm.prank(user);
        lqty.approve(userProxy, type(uint256).max);
        hevm.prank(user);
        governance.depositLQTY(lqtyAmt);

        (,uint256 unallocatedLQTYOffsetFinal,,) = governance.userStates(user);

        emit TotalAllocatedOffsetBeforeAndAfter(
            unallocatedLQTYOffsetInital,
            unallocatedLQTYOffsetFinal
        );

        assert(unallocatedLQTYOffsetInital < unallocatedLQTYOffsetFinal);

    }

    function invariant_statusOnceUnregistrableShouldAlwaysBeUnregistrable(uint8 initiativeIndex,uint8 epochWeek) public {
        address randomInitiative = _getRandomInitiative(initiativeIndex);
        
        (IGovernance.InitiativeStatus beforeStatus,,) = governance.getInitiativeState(randomInitiative);
        if(epochWeek > 1){
            if(beforeStatus == IGovernance.InitiativeStatus.UNREGISTERABLE){
                hevm.warp(block.timestamp + epochWeek * governance.EPOCH_DURATION());
                (IGovernance.InitiativeStatus afterStatus,,) = governance.getInitiativeState(randomInitiative);
                assert(beforeStatus == afterStatus);
            }
        }
    }

    function invariant_afterClaimingAmtShouldNotbeMoreThanBoldAccured() public {
        __before(users[0]);
        uint256 totalClaimedAmt;
        uint256 boldAccured = governance.boldAccrued();

        for(uint256 i; i< deployedInitiatives.length; i++){
            uint256 amtClaimed = governance.claimForInitiative(deployedInitiatives[i]);
            totalClaimedAmt += amtClaimed;
            // console.log("This is the amt of intiative that has been claimed", deployedInitiatives[i], amtClaimed);
        }
        __after(users[0]);
        assert(totalClaimedAmt <= boldAccured);
    }


    //@audit I think this invariant doesn't make any sense cause the the staking v1 is not gaining any funds in real time
    // would be better if bold would have accured in the staking v1 as there part of investment in the fuzzing suite.
    function invariant_afterUserClaimsBalanceOfUserShouldIncrease(uint8 userIndex) public {
        (address randomUser, address proxy ) = _getRandomUser(userIndex);

        __before(users[0]);
        if(proxy.code.length != 0 ){
            uint256 beforeBoldOfUser = bold.balanceOf(randomUser);
            uint256 stakedAmt = IUserProxy(proxy).staked();
            // should we only check if the user has staked amt or we should check for code length because if user has staked then indeed his code.lnegth is not zero
            if(stakedAmt > 0) {
                uint256 afterBoldOfUser = bold.balanceOf(randomUser);
                hevm.prank(randomUser);
                governance.claimFromStakingV1(randomUser);
                assert(afterBoldOfUser >= beforeBoldOfUser);
            }
        }
        __after(users[0]);
    }

    // All allocated liquity of the intitatives sum would be equal to allocated lqty of the users
    function invariant_totalSumOfAllocatedLqtyOfUserEqualToInitiativesLqty() public {
        uint256 totalSumOfUsersAllocatedLqty;
        uint256 totalSumOfVoteAndVetoOfAnInitiative;
        // all user allocatedLqty sum first
        for(uint256 i; i < users.length; i++){
            // userStates
            (,,uint256 userAllocatedLqty,) = governance.userStates(users[i]);
            totalSumOfUsersAllocatedLqty += userAllocatedLqty;
        }

        for(uint256 i; i < deployedInitiatives.length; i++){
            (uint256 voteLqtyOfInitiative ,, uint256 vetoLqtyOfInitiative ,,) = governance.initiativeStates(deployedInitiatives[i]);
            totalSumOfVoteAndVetoOfAnInitiative += voteLqtyOfInitiative + vetoLqtyOfInitiative;
        }

        assert(totalSumOfUsersAllocatedLqty == totalSumOfVoteAndVetoOfAnInitiative);
    }

    // function invariant_codeLengthOfStakedusersShouldNotBeZero(uint8 userIndex) {
    //     (address randomUser, address proxy ) = _getRandomUser(userIndex);
    //     uint256 stakedAmt = IUserProxy(userDerieveProxydAdd).staked();
    //     if()
    // }

    // function echidna_zeroAllocatedLqtyUserCannotRegister() public returns(bool){
    //     (uint256 votes, uint256 epoch) = governance.votesSnapshot();

    //     // require(votes > 0, "votes count currently zero");
    //     if(votes > 0 ){
    //         for(uint8 i; i < users.length; i++){
    //             address user = users[i];
    //             address proxy = governance.deriveUserProxyAddress(user);

    //             if(proxy.code.length == 0){
    //                 hevm.prank(user);
    //                 bold.approve(address(governance), type(uint256).max);

    //                 hevm.prank(user);
    //                 address newInitiative = address(new BribeInitiative(address(governance), address(lusd), address(lqty)));
    
    //                 hevm.warp(block.timestamp + governance.EPOCH_DURATION());

    //                 (IGovernance.InitiativeStatus statusAfterInitiativeCreation,,) = governance.getInitiativeState(newInitiative);
                    
    //                 // now i have to make the return true or false for now
    //                 // that the status showdlnt be able to update to warm up it should be non existent;
    //                 hevm.prank(user);
    //                 try governance.registerInitiative(newInitiative) {
                        
    //                 } catch(bytes memory err)  {
    //                     emit ErrorBytes("Error while calling the register initiative",err);
    //                 }
    //                 (IGovernance.InitiativeStatus statusAfterInitiativeRegistration,,) = governance.getInitiativeState(newInitiative);
                    
    //                 // if(statusAfterInitiativeCreation != statusAfterInitiativeRegistration){
    //                 //     return false;
    //                 // }
    //                 if(statusAfterInitiativeCreation != statusAfterInitiativeRegistration){
    //                     emit VotesAndEpcoh(votes, epoch);
    //                     return false;
    //                 }
    //                 // assert(statusAfterInitiativeCreation == statusAfterInitiativeRegistration);
    //             }

    //         }
    //     }

    //     return true;
    // }

}


// View functions should never revert 

 // console.log("this is the address of user", userSelf);
        // console.log("this is the proxy address of user", derievedAdd);
        // console.log("this is the proxy address of user code length", derievedAdd.code.length);
        // console.log("this is the userproxy 1",user1Proxy);
        // console.log("this is the userproxy 1 this is the code length",user1Proxy.code.length);
        // address derievedAdd1 = governance.deriveUserProxyAddress(msg.sender);
        // console.log(msg.sender,"This is the sender before");
        // console.log(derievedAdd1,"This is the derieved address for the msg.sender");
        // hevm.prank(userSelf);
        // console.log(msg.sender,"This is the sender");
        // address userProxyDeployed = governance.deployUserProxy();
        // console.log("User1Proxy address", user1Proxy);
        // console.log("userProxyDeployed address", userProxyDeployed);
        // console.log(user,proxy);
        // console.log("this is the derieved address of user after deploying", userProxyDeployed);
        // console.log("this is the proxy address of user after deploying", derievedAdd);
        // console.log("this is the proxy address of user code length after deploying", derievedAdd);
        // console.log("this is the proxy address of user code length after deploying this is the code length", derievedAdd.code.length);
        // console.log("this is the proxy address of user", derievedAdd);
        // console.log("this is the proxy address of user code length", derievedAdd.code.length);



        //  console.log("This is the derieved address",derievedAdd );
        // console.log("This is the derieved address code length",derievedAdd.code.length);
        // hevm.prank(userSelf);
        // address userproxyRecentdeployed = governance.deployUserProxy();
        // address derivedrecentDeployedAddress = governance.deriveUserProxyAddress(userSelf);
        // console.log("user proxy address recently deployed", userproxyRecentdeployed);
        // console.log("derieve address of recently deployed", derivedrecentDeployedAddress);
        // console.log("derieve address of recently deployed", derivedrecentDeployedAddress.code.length);







    //     function invariant_offSetOfUserShouldIncreaseWithDeposit(uint256 lqtyAmt) public  {
    //     address[] memory localUsers = users;

    //     // Accumulator memory initialState = accumulateUserStates(localUsers);
    //     Accumulator memory initialState = accumulateUserStates(localUsers);

    //     console.log("This is the total initial unallocated lqty",  initialState.totalUnallocatedLQTY);
    //     console.log("This is the total initial unallocated lqty offset",  initialState.totalUnallocatedOffset);
    //     if(lqtyAmt > 0) {
    //         for(uint256 i; i< localUsers.length; i++){
    //             address user = localUsers[i];
    //             // if(lqty.balanceOf(user) == 0)
    //             uint256 userBalance = lqty.balanceOf(user);
    //             // if (userBalance == 0 || lqtyAmt == 0) return;
    //             emit UserDepositAndInitialBalance(user,userBalance);
    //             if (userBalance == 0) continue;
    //             console.log("This is the user for loop", user);
    //             lqtyAmt %= userBalance;
    //             if (lqtyAmt == 0) continue;

    //             address  userProxy = governance.deriveUserProxyAddress(user);

    //             hevm.prank(user);
    //             lqty.approve(userProxy, type(uint256).max);
    //             hevm.prank(user);
    //             governance.depositLQTY(lqtyAmt);
    //             emit LqtyAmt(lqtyAmt);
    //         }

    //         Accumulator memory finalState = accumulateUserStates(localUsers);

    //         console.log("This is the total final unallocated lqty",  finalState.totalUnallocatedLQTY);
    //         console.log("This is the total final unallocated lqty offset",  finalState.totalUnallocatedOffset);

    //         // return initialState.totalUnallocatedOffset < finalState.totalUnallocatedOffset ;
    //         emit TotalAllocatedOffsetBeforeAndAfter(initialState.totalUnallocatedOffset, finalState.totalUnallocatedOffset);
    //         assert(initialState.totalUnallocatedOffset < finalState.totalUnallocatedOffset);
    //     }

       
    // }



// function invariant_offSetOfUserShouldIncreaseWithDeposit(uint256 lqtyAmt) public {
//     address[] memory localUsers = users;

//     Accumulator memory initialState = accumulateUserStates(localUsers);
//     Accumulator memory initialState = accumulateUserStates(localUsers);

//     console.log("This is the total initial unallocated lqty", initialState.totalUnallocatedLQTY);
//     console.log("This is the total initial unallocated lqty offset", initialState.totalUnallocatedOffset);

//     for (uint256 i; i < localUsers.length; i++) {
//         address user = localUsers[i];
//         // if(lqty.balanceOf(user) == 0)
//         uint256 userBalance = lqty.balanceOf(user);
//         if (userBalance == 0 || lqtyAmt == 0) continue;
//         console.log("This is the user for loop", user);
//         lqtyAmt %= userBalance;
//         if (lqtyAmt == 0) continue;

//         address userProxy = governance.deriveUserProxyAddress(user);

//         hevm.prank(user);
//         lqty.approve(userProxy, type(uint256).max);
//         hevm.prank(user);
//         governance.depositLQTY(lqtyAmt);
//     }

//     Accumulator memory finalState = accumulateUserStates(localUsers);

//     console.log("This is the total final unallocated lqty", finalState.totalUnallocatedLQTY);
//     console.log("This is the total final unallocated lqty offset", finalState.totalUnallocatedOffset);

//     // return initialState.totalUnallocatedOffset < finalState.totalUnallocatedOffset ;
//     assert(initialState.totalUnallocatedOffset < finalState.totalUnallocatedOffset);
// }


// See if the user has lqty allocated 
// you cold go through loop for this 
// And if it is zero then nothing and if it is not zero than after some time the claimable amt should incerase
    

// function echidna_offSetOfUserShouldIncreaseWithTime() public returns(bool) {
    //     address[] memory localUsers = users;

    //     uint256 totalInitialLqtyAmtStaked;
    //     uint256 totalInitialUnallocatedLQTY;
    //     uint256 totalInitialUnallcatedOffset;

    //     uint256 totalFinalLqtyAmtStaked;
    //     uint256 totalFinalUnallocatedLQTY;
    //     uint256 totalFinalUnallcatedOffset;

    //     for(uint256 i; i<localUsers.length; i++){
    //         console.log("This is the user", localUsers[i]);
    //         address userDerieveProxydAdd = governance.deriveUserProxyAddress(localUsers[i]);
    //         if (userDerieveProxydAdd.code.length == 0) {
    //             continue;
    //         }
    //         uint256 userStakedLqty = IUserProxy(userDerieveProxydAdd).staked();
    //         console.log("this is the amt of lqty staked intially by the user", userStakedLqty);
    //         (uint256 userUnallocatedLqty, uint256 userUnallocatedOffset, ,) = governance.userStates(localUsers[i]);

    //         console.log("This is the user unallocated lqty initially", userUnallocatedLqty);
    //         console.log("THis is the user unallocates offset initially", userUnallocatedOffset);

    //         totalInitialLqtyAmtStaked += userStakedLqty;
    //         totalInitialUnallocatedLQTY += userUnallocatedLqty;
    //         totalInitialUnallcatedOffset += userUnallocatedOffset;
    //     }

    //     if(totalInitialLqtyAmtStaked != 0){

    //         hevm.warp(block.timestamp + governance.EPOCH_DURATION());


    //         for(uint256 i; i<localUsers.length; i++){
    //             // derieve user proxy is giving an error 
    //             console.log("This is the user", localUsers[i]);
    //             address userDerieveProxydAdd = governance.deriveUserProxyAddress(localUsers[i]);
    //             if (userDerieveProxydAdd.code.length == 0) {
    //                 continue;
    //             }
    //             uint256 userStakedLqty = IUserProxy(userDerieveProxydAdd).staked();
    //             console.log("this is the amt of lqty staked finally by the user", userStakedLqty);
    //             (uint256 userUnallocatedLqty, uint256 userUnallocatedOffset, ,) = governance.userStates(localUsers[i]);

    //             console.log("This is the user unallocated lqty finally", userUnallocatedLqty);
    //             console.log("THis is the user unallocates offset finally", userUnallocatedOffset);

    //             totalFinalLqtyAmtStaked += userStakedLqty;
    //             totalFinalUnallocatedLQTY += userUnallocatedLqty;
    //             totalFinalUnallcatedOffset += userUnallocatedOffset;
    //         }

    //         if(totalInitialUnallocatedLQTY == totalFinalUnallocatedLQTY){
    //             console.log("Gone through the if block which means totalInitialUnallocatedLQTY == totalFinalUnallocatedLQTY");
    //             // return (totalFinalUnallcatedOffset > totalInitialUallcatedOffset);
    //             // if(totalFinalUnallcatedOffset < totalInitialUnallcatedOffset){
    //             //     console.log("THis is the false block");
    //             //     return false;
    //             // }

    //             if(totalFinalUnallcatedOffset == totalInitialUnallcatedOffset){
    //                 console.log("initialState.totalUnallocatedOffset == finalState.totalUnallocatedOffset are the same");
    //             }
    //         }
    //     }

    //     return true;
    // }

    // function echidna_offSetOfUserShouldIncreaseWithTime() public returns (bool) {
    //     address[] memory localUsers = users;

    //     Accumulator memory initialState = accumulateUserStates(localUsers);
    //     console.log("this is the initial State staked lqty", initialState.totalStaked);
    //     console.log("this is the initial State total unallcated lqty amt", initialState.totalUnallocatedLQTY);
    //     console.log("this is the initial State total unallcated offset amt", initialState.totalUnallocatedOffset);

    //     if (initialState.totalStaked == 0) return true;

    //     hevm.warp(block.timestamp + 86400);

    //     Accumulator memory finalState = accumulateUserStates(localUsers);

    //     console.log("this is the final State staked lqty", finalState.totalStaked);
    //     console.log("this is the final State total unallcated lqty amt", finalState.totalUnallocatedLQTY);
    //     console.log("this is the final State total unallcated offset amt", finalState.totalUnallocatedOffset);

    //     if (initialState.totalUnallocatedLQTY == finalState.totalUnallocatedLQTY) {
    //         console.log("Initial and Final Unallocated LQTY are equal");
    //         if(initialState.totalUnallocatedOffset == finalState.totalUnallocatedOffset){
    //             console.log("initialState.totalUnallocatedOffset == finalState.totalUnallocatedOffset are the same");
    //         }
    //         // if (finalState.totalUnallocatedOffset < initialState.totalUnallocatedOffset) {
    //         //     console.log("Final offset is less than initial offset, reverting");
    //         //     return false;
    //         // }
    //     }

    //     return true;
    // }




// @audit instead of doing the all user do by single user at a time 
    // function invariant_offSetOfUserShouldIncreaseWithDepositForAllUsers(uint256 lqtyAmt) public {
    //     if (lqtyAmt == 0) return;

    //     address[] memory localUsers = users;
    //     Accumulator memory initialState = accumulateUserStates(localUsers);

    //     console.log("Initial unallocated LQTY:", initialState.totalUnallocatedLQTY);
    //     console.log("Initial unallocated offset:", initialState.totalUnallocatedOffset);

    //     for (uint256 i = 0; i < localUsers.length; ++i) {
    //         address user = localUsers[i];
    //         console.log("this is the user", user);
    //         uint256 userBalance = lqty.balanceOf(user);
    //         console.log("This is the user balance initally", userBalance);

    //         if (userBalance == 0) continue;

    //         uint256 adjustedAmt = lqtyAmt % userBalance;
    //         if (adjustedAmt == 0) continue;
    //         console.log("THis is the is the adjusted amt", adjustedAmt);
    //         address userProxy = governance.deriveUserProxyAddress(user);
    //         if(userProxy.code.length == 0) continue;
    //         console.log("This is the users staked lqty in the governance before depositing", IUserProxy(userProxy).staked());

    //         hevm.prank(user);
    //         lqty.approve(userProxy, type(uint256).max);
    //         hevm.prank(user);
    //         governance.depositLQTY(adjustedAmt);
    //         console.log("this is the lqty amt that user is depositing",adjustedAmt);
    //         console.log("this is the left over balance of the user finally", lqty.balanceOf(user));
    //     }

    //     Accumulator memory finalState = accumulateUserStates(localUsers);

    //     console.log("Final unallocated LQTY:", finalState.totalUnallocatedLQTY);
    //     console.log("Final unallocated offset:", finalState.totalUnallocatedOffset);

    //     emit TotalAllocatedOffsetBeforeAndAfter(
    //         initialState.totalUnallocatedOffset,
    //         finalState.totalUnallocatedOffset
    //     );

    //     assert(initialState.totalUnallocatedOffset < finalState.totalUnallocatedOffset);

    // }



     /* @audit these below function is a problem of the 
    bold acured or the cause i am not really able to claim an initiave money 

    -------------------------------Starts Here------------------------------

    // function echidna_BoldShouldBeSame() public returns(bool) {
    //     uint256 governanceBoldBalance = bold.balanceOf(address(governance));
    //     uint256 boldAccured = governance.boldAccrued();
    //     uint256 minAccured = governance.MIN_ACCRUAL();

    //     if(governanceBoldBalance <= minAccured) {
    //         emit BoldBalanceError(governanceBoldBalance,boldAccured);
    //         return (boldAccured == 0);
    //     }
    //     else{
    //         emit BoldBalanceError(governanceBoldBalance,boldAccured);
    //         return (boldAccured == governanceBoldBalance);
    //     }
    //     // return (governanceBoldBalance == boldAccured);
    // }

    //@audit ----------------------the below invariant is not working it is showing as pass 
    // function echidna_BoldShouldBeSame() public returns (bool) {
    //     uint256 governanceBoldBalance = bold.balanceOf(address(governance));
    //     uint256 boldAccured = governance.boldAccrued();
    //     uint256 minAccured = governance.MIN_ACCRUAL();

    //     emit BoldBalanceError(governanceBoldBalance, boldAccured);
    //     emit DebugNumbers("MIN_ACCRUAL", minAccured);

    //     if (governanceBoldBalance <= minAccured) {
    //         emit DebugPath("Path: balance below minAccured");
    //         return (boldAccured == 0);
    //     } else {
    //         emit DebugPath("Path: balance above minAccured");
    //         return (boldAccured == governanceBoldBalance);
    //     }
    // }


    // @audit ----------------- the below invariant is also not working i think there is problem with bold accured not being updated 
    // function echidna_claimInitiative() public returns(bool){
    //     address initiative = _getRandomInitiative(initiativeIndex);
    //     __before(users[0]);
    //     uint256 initiativeInitialBoldBalance = bold.balanceOf(initiative);
    //     // try governance.claimForInitiative(initiative)  {

    //     // }catch {
    //     //     emit Error("Initiative wasn't able claim the bold");
    //     // }
    //     uint256 amtClaimed = governance.claimForInitiative(initiative);
    //     uint256 initiativeFinalBoldBalance = bold.balanceOf(initiative);

    //     if(initiativeFinalBoldBalance != initiativeInitialBoldBalance + amtClaimed){
    //         return false;
    //     }
    //     __after(users[0]);
    //     return true;
    // }


    // @audit ----------------- the below invariant is also not working i think there is problem with bold accured not being updated 
    // function echidna_claimInitiave() public returns(bool) {
    //     uint256 deployedInitiativesLength = deployedInitiatives.length;
    //     uint256 initialBoldBalance ;
    //     uint256 totalClaimedAmt;
    //     for(uint256 i; i < deployedInitiativesLength; i++){
    //         address initiative = deployedInitiatives[i];
    //         uint256 initiativeInitialBoldBalance = bold.balanceOf(deployedInitiatives[i]);

    //         initialBoldBalance += initiativeInitialBoldBalance;

    //         uint256 claimedAmt = governance.claimForInitiative(initiative);
    //         totalClaimedAmt += claimedAmt;
    //     }

    //     return (totalClaimedAmt >= initialBoldBalance);
    // }

    -------------------------------Ends Here--------------------------------
    */