// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import {Setup} from "../Setup.sol";
import "../Properties/GovernanceProperties.sol";


abstract contract TargetFunctionsGovernanace is GovernanceProperties{
    
    event Error(string);

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

    // @audit this should be in selfCryticTester
    // constructor() payable{
    //     setup();
    // }

    function handler_clampedDepositLqtyUser(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser,) = _getRandomUser(userIndex);
        __before(randomUser);
        if(randomUser == users[2] && user2ProxyCreated){
            VM.prank(randomUser);
            try governance.deployUserProxy()  returns (address proxyAdd) {
                user2Proxy = proxyAdd;
                lqty.approve(user2Proxy,lqtyAmt);
                user2ProxyCreated = true;
            } catch  {
                emit Error("User 2 proxy didn't deploy");
            }
        }
        else{
            VM.prank(randomUser);
            governance.depositLQTY(lqtyAmt % lqty.balanceOf(randomUser));
        }
        /// @audit Add amount to allocated ghost variable 
        __after(randomUser);
    } 

    // @doubt since the `depositLQTY` function already calls `_increaseUserVoteTrackers` in that function deployes a userproxy when the user hasn't deployed it yet then above `handler_clampedDepositLqtyUser` function becomes invalid.
    function handler_unclampedDepositLqtyUser(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser,) = _getRandomUser(userIndex);
        __before(randomUser);
        VM.prank(randomUser);
        governance.depositLQTY(lqtyAmt);
        __after(randomUser);
        /// @audit Add amount to allocated ghost variable 
    }

    function handler_unclampedWithdrawLqtyUser(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser,) = _getRandomUser(userIndex);
        __before(randomUser);
        VM.prank(randomUser);
        governance.withdrawLQTY(lqtyAmt);
        __after(randomUser);
        /// @audit Add amount to unallocated ghost variable minus that so that we could compare in the invariant that we'll define in properties.
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

        VM.prank(randomUser);
        try governance.resetAllocations(deployedInitiatives, true){
            
        } catch  {
            emit Error("Reset Allocations unsuccessful due to Dos");
        }
        
        lqtyAmt %= userStakedLqty;

        VM.prank(randomUser);
        governance.withdrawLQTY(lqtyAmt);
        __after(randomUser);
    }

    function handler_unclampedWithdrawLqty(uint8 userIndex, uint256 lqtyAmt) public {
        (address randomUser,) = _getRandomUser(userIndex);
        __before(randomUser);
        (uint256 userStakedUnallocatedLqty,,, ) = governance.userStates(randomUser);

        // Skip if user has no staked LQTY
        if (userStakedUnallocatedLqty == 0) {
            return;
        }

        lqtyAmt %= userStakedUnallocatedLqty;

        VM.prank(randomUser);
        governance.withdrawLQTY(lqtyAmt);
        __after(randomUser);
    }

    // Make the reward recipeit or the parameter of tghe function random and also the msg.sneder should be random
    // and then add a try and catch block which emits users address not deployed
    function handler_claimStakingV1(uint8 rewardRecipient, uint8 msgSender) public {
        (address randomUser,) = _getRandomUser(rewardRecipient);
        __before(randomUser);
        (address msgSenderAdd,) = _getRandomUser(msgSender);

        VM.prank(msgSenderAdd);
        try governance.claimFromStakingV1(randomUser) {
            
        } catch  {
            emit Error("User couldn't claim the reward");
        }
        __after(randomUser);
    }

    function handler_makeInitiative() public {
        address initiative = address(new BribeInitiative(address(governance), address(lusd), address(lqty)));
        deployedInitiatives.push(initiative);
    }

    function handler_resetAllocations(uint8 userIndex) public {
        (address randomUser, ) = _getRandomUser(userIndex);
        __before(randomUser);

        VM.prank(randomUser);
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

    function handler_registerInitiative(uint8 initiativeIndex) public {
        address initiative = _getRandomInitiative(initiativeIndex);
        __before(users[0]);
        governance.registerInitiative(initiative);
        __after(users[0]);
    }

    function handler_snapshotVotesForInitiative(uint8 initiativeIndex) public {
        address initiative = _getRandomInitiative(initiativeIndex);
        __before(users[0]);
        governance.snapshotVotesForInitiative(initiative);
        __after(users[0]);
    }

    //     address[] calldata _initiativesToReset,
    //     address[] calldata _initiatives,
    //     int256[] calldata _absoluteLQTYVotes,
    //     int256[] calldata _absoluteLQTYVetos
    //     For user 1 and user 2 
    function handler_allocateLqty(uint8 userIndex, uint8 initiativeIndex, uint256 votesLqty, uint256 vetosLqty) public  {
        (address randomUser, address proxy ) = _getRandomUser(userIndex);

        uint256 stakedLqty = IUserProxy(proxy).staked();
        address initiative = _getRandomInitiative(initiativeIndex);
        (uint256 votes ,, uint256 vetos ,,) = governance.lqtyAllocatedByUserToInitiative(randomUser,initiative);
        address[] memory initiativeToReset ;
        if(votes !=0 || vetos !=0){
            initiativeToReset = new address[](1);
            initiativeToReset[1] = initiative;
        }
        address[] memory initiatives;
        initiatives[0] = initiative;

        int256[] memory votesLqtyAllocated;
        votesLqtyAllocated[0] = int256(votesLqty % stakedLqty);

        int256[] memory vetosLqtyAllocated;
        vetosLqtyAllocated[0] = int256(vetosLqty % stakedLqty);

        int256 totalLqty = votesLqtyAllocated[0] + vetosLqtyAllocated[0];

        require(totalLqty > 0 &&  totalLqty <= int256(stakedLqty));

        VM.prank(randomUser);
        governance.allocateLQTY(initiativeToReset, initiatives, votesLqtyAllocated, vetosLqtyAllocated);
    }


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

}