// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Properties/GovernanceProperties.sol";
// import "../BeforeAfter.sol";


contract TargetFunctionsGovernanace is GovernanceProperties{
    
    

    function handler_clampedDepositLqtyUser(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser,address proxy) = _getRandomUser(userIndex);
        // console.log("This is the user in handler_clampedDepositLqtyUser", randomUser);
        address proxyAddress ;
        __before(randomUser);
        if(randomUser == users[1] && user2ProxyCreated == false){
            hevm.prank(randomUser);
            try governance.deployUserProxy()  returns (address proxyAdd) {
                user2Proxy = proxyAdd;
                proxyAddress = proxyAdd;
                hevm.prank(randomUser);
                lqty.approve(proxyAdd, type(uint256).max);
                user2ProxyCreated = true;
            } catch(bytes memory err)  {
                emit ErrorBytes("User 2 proxy didn't deploy",err);
            }
        }
        // console.log("THis is the proxy add", proxyAddress);
        // console.log("THis is the code length after deploying", proxyAddress.code.length);
        lqtyAmt %= lqty.balanceOf(randomUser);
        hevm.prank(randomUser);
        lqty.approve(proxy, type(uint256).max);
        hevm.prank(randomUser);
        governance.depositLQTY(lqtyAmt);
        __after(randomUser);
        // console.log("This is the lqty stanked in handler_clampedDepositLqtyUser",lqtyAmt);
    } 

    // @doubt since the `depositLQTY` function already calls `_increaseUserVoteTrackers` in that function deployes a userproxy when the user hasn't deployed it yet then above `handler_clampedDepositLqtyUser` function becomes invalid.
    function handler_unclampedDepositLqtyUser(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser, address proxy) = _getRandomUser(userIndex);
        __before(randomUser);
        // console.log("This is the user in handler_unclampedDepositLqtyUser", randomUser);
        lqtyAmt %= lqty.balanceOf(randomUser);
        hevm.prank(randomUser);
        lqty.approve(proxy, type(uint256).max);
        hevm.prank(randomUser);
        governance.depositLQTY(lqtyAmt);
        __after(randomUser);
        // console.log("This is the lqty stanked in handler_unclampedDepositLqtyUser",lqtyAmt);
    }

    function handler_unclampedWithdrawLqtyUser(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser,) = _getRandomUser(userIndex);
        __before(randomUser);
        hevm.prank(randomUser);
        governance.withdrawLQTY(lqtyAmt);
        __after(randomUser);
    }

    // There are two options with below handler 
    // 1. to withdraw all staked amounts at once calling the resetAllocations functions like recon did Done
    // 2. To withdraw some amount that has been unallocated.
    function handler_clampedWithdrawLqtyUser(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser, address proxy) = _getRandomUser(userIndex);
        __before(randomUser);
        uint256 userStakedLqty = IUserProxy(proxy).staked();

        // Skip if user has no staked LQTY
        if (userStakedLqty == 0) {
            return;
        }

        hevm.prank(randomUser);
        try governance.resetAllocations(deployedInitiatives, true){
            
        } catch  {
            emit Error("Reset Allocations unsuccessful due to Dos");
        }
        
        lqtyAmt %= userStakedLqty;

        hevm.prank(randomUser);
        try governance.withdrawLQTY(lqtyAmt) {
            
        } catch (bytes memory err) {
            emit ErrorBytes("Clamped withdraw lqty unsuccessful", err);
        }
        __after(randomUser);
    }

    // This below function was created so that user could withdraw it's unallocated Lqty.
    function handler_unclampedWithdrawUnallocatedLqty(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser,) = _getRandomUser(userIndex);
        __before(randomUser);
        (uint256 userStakedUnallocatedLqty,,, ) = governance.userStates(randomUser);

        // Skip if user has no staked LQTY
        if (userStakedUnallocatedLqty == 0) {
            return;
        }

        lqtyAmt %= userStakedUnallocatedLqty;

        hevm.prank(randomUser);
        try governance.withdrawLQTY(lqtyAmt) {
            
        } catch  {
            emit Error("Unclamped withdraw lqty unsuccessful");
        }
        __after(randomUser);
    }

    // Make the reward recipeit or the parameter of tghe function random and also the msg.sneder should be random
    // and then add a try and catch block which emits users address not deployed
    function handler_claimStakingV1(uint8 rewardRecipient, uint8 msgSender) public {
        (address randomUser,) = _getRandomUser(rewardRecipient);
        __before(randomUser);
        (address msgSenderAdd,) = _getRandomUser(msgSender);

        hevm.prank(msgSenderAdd);
        try governance.claimFromStakingV1(randomUser) {
            
        } catch  {
            emit Error("User couldn't claim the reward");
        }
        __after(randomUser);
    }

    function handler_makeInitiative() public {  
        __before(users[0]); 
        address initiative = address(new BribeInitiative(address(governance), address(lusd), address(lqty)));
        deployedInitiatives.push(initiative);
        __after(users[0]);
    }

    function handler_resetAllocations(uint8 userIndex) public {
        (address randomUser, ) = _getRandomUser(userIndex);
        __before(randomUser);

        hevm.prank(randomUser);
        governance.resetAllocations(deployedInitiatives, true);
        __after(randomUser);
    }

    function handler_unregisterInitiative(uint8 initiativeIndex) public {
        address randomInitiative = _getRandomInitiative(initiativeIndex);
        __before(users[0]);
        governance.unregisterInitiative(randomInitiative);
        __after(users[0]);
    }

    function handler_deployUserProxy() public {
        __before(users[0]);
        governance.deployUserProxy();
        __after(users[0]);
    }

    function handler_registerInitiative(uint8 userIndex, uint8 initiativeIndex) public {
        (address randomUser,) = _getRandomUser(userIndex);
        address initiative = _getRandomInitiative(initiativeIndex);

        // if(initiative == deployedInitiatives[0] ) return;
        if(deployedInitiatives.length < 1) return;

        __before(users[0]);
        hevm.prank(randomUser);
        bold.approve(address(governance), type(uint256).max);
        hevm.prank(randomUser);
        governance.registerInitiative(initiative);
        __after(users[0]);
    }


    function handler_snapshotVotesForInitiative(uint8 initiativeIndex) public {
        address initiative = _getRandomInitiative(initiativeIndex);
        __before(users[0]);
        governance.snapshotVotesForInitiative(initiative);
        __after(users[0]);
    }

    function handler_allocateLqty(uint8 userIndex, uint8 initiativeIndex, uint256 votesLqty, uint256 vetosLqty) public  {
        (address randomUser, address proxy ) = _getRandomUser(userIndex);
        // console.log("This is the user in handler_allocateLqty", randomUser);
        __before(randomUser);
        uint256 stakedLqty = IUserProxy(proxy).staked();
        address initiative = _getRandomInitiative(initiativeIndex);
        // console.log("This is the initiative address in handler_allocateLqty",initiative);
        (uint256 votes ,, uint256 vetos ,,) = governance.lqtyAllocatedByUserToInitiative(randomUser,initiative);
        address[] memory initiativeToReset ;
        if(votes !=0 || vetos !=0){
            initiativeToReset = new address[](1);
            initiativeToReset[0] = initiative;
        }
        address[] memory initiatives = new address[](1);
        initiatives[0] = initiative;

        int256[] memory votesLqtyAllocated = new int256[](1);
        votesLqtyAllocated[0] = int256(votesLqty % stakedLqty);

        int256[] memory vetosLqtyAllocated = new int256[](1);
        vetosLqtyAllocated[0] = int256(vetosLqty % stakedLqty);

        int256 totalLqty = votesLqtyAllocated[0] + vetosLqtyAllocated[0];

        require(totalLqty > 0 &&  totalLqty <= int256(stakedLqty));

        hevm.prank(randomUser);
        governance.allocateLQTY(initiativeToReset, initiatives, votesLqtyAllocated, vetosLqtyAllocated);
        __after(randomUser);

        // for(uint256 i; i<initiatives.length; i++){
        //     console.log("THis is the total initiaves", initiatives[i]);
        // }

        // for(uint256 i; i<votesLqtyAllocated.length; i++){
        //     console.log("THis is the total votes calculated in handler_allocateLqty",votesLqtyAllocated[i]);
        //     console.log("THis is the total vetos calculated in handler_allocateLqty",vetosLqtyAllocated[i]);
        // }
    }

    function handler_claimForInitiative(uint8 initiativeIndex) public {
        address initiative = _getRandomInitiative(initiativeIndex);
        __before(users[0]);
        governance.claimForInitiative(initiative);
        __after(users[0]);
    }

    function handler_getLatestVotingThreshold() public  {
        __before(users[0]);
        governance.getLatestVotingThreshold();
        __after(users[0]);
    }

    function handler_callBoldAccured() public {
        __before(users[0]);
        governance.boldAccrued();
        __after(users[0]);
    }

}




    // function handler_registerInitiative(uint8 initiativeIndex) public {
    //     address initiative = _getRandomInitiative(initiativeIndex);
    //     if(deployedInitiatives.length < 1) return;
    //     __before(users[0]);
    //     governance.registerInitiative(initiative);
    //     __after(users[0]);
    // }

    // function handler_secondsWithinEpoch() public {
    //     __before(users[0]);
    //     governance.secondsWithinEpoch();
    //     __after(users[0]);
    // }

    // function handler_epoch() public {
    //     governance.epoch();
    // }


    // function handler_makeInitiative() public {
    //     address initiative = new BribeInitiative(address(governance), address(bold), address(lqty));
    // }

    // 1. Deposit user1,2 should they be clubbed into one or two one is ok
    // BUT WHY HAVE THEY DEPLOYED USER PROXY AND THEN USED DEPOSIT LQTY IN THE HANDLER, SINCE IN THE `depositLQTY` function it already calls and deployed a userproxy if someone who hasn't deposited any lqty

    // 2. Deposit via permit
    // 3. Withdraw 
    // 4. Withdraw via permit
    // 5. ClaimV1staking
    // 6. AllocateLqty
    // 7. View function
    // 8. make the following deposit and withdraw
        // depositLQTY(uint256 _lqtyAmount, bool _doSendRewards, address _recipient)
        // withdrawLQTY(uint256 _lqtyAmount, bool _doSendRewards, address _recipient)

    // MAKE BEFORE AND AFTER
    // 9. MAke reset allocation
    // 10. Make users a new intitative handler



// ---------------------- this is invariant 
    // function handler_claimForInitiative(uint8 initiativeIndex) public returns(bool){
    //     address initiative = _getRandomInitiative(initiativeIndex);
    //     __before(users[0]);
    //     uint256 initiativeInitialBoldBalance = bold.balanceOf(initiative);
    //     try governance.claimForInitiative(initiative) returns(uint256 claimableAmount) {
    //         // claimableAmount ;
    //         uint256 initiativeFinalBoldBalance = bold.balanceOf(initiative);
            
    //         return (initiativeFinalBoldBalance == initiativeInitialBoldBalance + claimableAmount);
    //     }catch {
    //         emit Error("Initiative wasn't able claim the bold");
    //         return false;
    //     }
    //     __after(users[0]);
    //     return true;
    // }