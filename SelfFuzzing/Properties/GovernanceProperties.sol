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
    

    function echidna_initiativeShouldReturnSameStatus() public returns(bool){
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

                // assert(_before.initiativeStatus[initiative] == _after.initiativeStatus[initiative]);
                if(_before.initiativeStatus[initiative] != _after.initiativeStatus[initiative]){
                    emit BeforeAfterStatus(uint8(_before.initiativeStatus[initiative]) , uint8(_after.initiativeStatus[initiative]));
                    return false;
                }
                // return(_before.initiativeStatus[initiative] == _after.initiativeStatus[initiative]);

            }
        }
        return true;
    }

    /* ------------------------commenting out revert properties for the fuzzer to function better
    ---------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------- */

    function echidna_epochShouldNotRevert() public returns(bool){
        try governance.epoch(){
            return true;
        } catch  {
            emit Error("Epoch should not revert");
            return false;
        }
    }

    function echidna_secondsWithinEpochShouldNotRevert() public returns(bool){
        
        try governance.secondsWithinEpoch() {
            return true;
        }catch {
            emit Error("Epoch should not revert");
            return false;
        }
    }

    function echidna_getTotalVotesAndStateShouldNotRevert() public returns(bool){
        try governance.getTotalVotesAndState() {
            return true;
        }
        catch {
            emit Error("Get total Votes and state should not revert");
            return false;
        }
    }

    function echidna_calculateVotingThresholdWithVotesShouldNotRevert() public  returns(bool) {
        (uint256 totalVotes,) = governance.votesSnapshot();
        try governance.calculateVotingThreshold(totalVotes) {
            return true;
        }catch{
            emit Error("Calculate Voting threshold should not revert");
            return false;
        }
    }

    function echidna_calculateVotingThresholdShouldNotRevert() public  returns(bool) {
        
        try governance.calculateVotingThreshold() {
            return true;
        }catch{
            emit Error("Calculate Voting threshold should not revert");
            return false;
        }
    }


    function echidna_getLatestVotingThresholdShouldNotRevert() public  returns(bool) {
        
        try governance.getLatestVotingThreshold() {
            return true;
        }catch{
            emit Error("Get latest voting threshold should not revert");
            return false;
        }
    }

    /* ------------------------commenting out revert properties for the fuzzer to function better
    ---------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------- */


    // function echidna_offSetShouldIncrease() public returns(bool) {}

    function echidna_zeroAllocatedLqtyUserCannotRegister() public returns(bool){
        (uint256 votes, uint256 epoch) = governance.votesSnapshot();

        // require(votes > 0, "votes count currently zero");
        if(votes > 0 ){
            for(uint8 i; i < users.length; i++){
                address user = users[i];
                address proxy = governance.deriveUserProxyAddress(user);

                if(proxy.code.length == 0){
                    hevm.prank(user);
                    bold.approve(address(governance), type(uint256).max);

                    hevm.prank(user);
                    address newInitiative = address(new BribeInitiative(address(governance), address(lusd), address(lqty)));
    
                    hevm.warp(block.timestamp + governance.EPOCH_DURATION());

                    (IGovernance.InitiativeStatus statusAfterInitiativeCreation,,) = governance.getInitiativeState(newInitiative);
                    
                    // now i have to make the return true or false for now
                    // that the status showdlnt be able to update to warm up it should be non existent;
                    hevm.prank(user);
                    try governance.registerInitiative(newInitiative) {
                        
                    } catch(bytes memory err)  {
                        emit ErrorBytes("Error while calling the register initiative",err);
                    }
                    (IGovernance.InitiativeStatus statusAfterInitiativeRegistration,,) = governance.getInitiativeState(newInitiative);
                    
                    // if(statusAfterInitiativeCreation != statusAfterInitiativeRegistration){
                    //     return false;
                    // }
                    if(statusAfterInitiativeCreation != statusAfterInitiativeRegistration){
                        emit VotesAndEpcoh(votes, epoch);
                        return false;
                    }
                    // assert(statusAfterInitiativeCreation == statusAfterInitiativeRegistration);
                }

            }
        }

        return true;
    }


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