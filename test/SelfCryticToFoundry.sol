// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// import {SelfSetup} from "./SelfSetup.sol";
import {SelfSetup} from "../SelfFuzzing/SelfSetup.sol";
import {TargetFunctionsGovernanace} from "../SelfFuzzing/TargetFiles/TargetFunctionsGovernanace.sol";
import {Test, console} from "forge-std/Test.sol";
import {IGovernance} from "../src/interfaces/IGovernance.sol";
import {IUserProxy} from "../src/interfaces/IUserProxy.sol";
// import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {BribeInitiative} from "../src/BribeInitiative.sol";

contract SelfCryticToFoundry is Test,TargetFunctionsGovernanace {


        function setUp() public {
            setup();
        }

        // forge test --match-test test_handlerClampedDepositLqtyUser -vvvv
        function test_handlerClampedDepositLqtyUser() public {
            // vm.prank(users[0]);
            // console.log(governance.owner(), "This is the owner of the contract");
            // console.log(lqty.balanceOf(users[0]), "This is the balance of the user before");
            uint256 initialBal = lqty.balanceOf(users[0]);
            uint256 amtToStake = 10000000 %  initialBal;
            console.log("Balance to deposit",  initialBal - amtToStake);
            console.log("This is user 0 ", users[0]);
            console.log("This is user 1 ", users[1]);
            console.log("This is governance", address(governance));
            console.log("This is userproxy", address(user1Proxy));
            console.log("This is address of the selfCrytic ", address(this));
            console.log(users[8 % users.length], "This is the user which we are taking");
            handler_clampedDepositLqtyUser(8, 10000000);
            console.log(lqty.balanceOf(users[0]), "This is the balance of the user after");

            // assert(lqty.balanceOf(users[0]), 10000);
            assertEq(lqty.balanceOf(users[0]), initialBal - amtToStake);
            
        }

        // forge test --mt test_handlerUnclampedDepositLqty -vvv
        function test_handlerUnclampedDepositLqty() public {
            uint8 randomUser = 9;
            address user = users[randomUser % users.length ];
            uint256 amtToDeposit = 10000000;
            uint256 initialBalOfuser = lqty.balanceOf(user);
            console.log("User balance before deposit", initialBalOfuser);
            assertEq(initialBalOfuser, initialLqtyAllocatedPerUser);
            handler_unclampedDepositLqtyUser(randomUser, amtToDeposit);
            uint256 finalBalOfuser = lqty.balanceOf(user);
            console.log("User balance before deposit", finalBalOfuser);
            assertEq(finalBalOfuser, initialBalOfuser - amtToDeposit);
        }


        // forge test --mt test_handlerAllocateLqty -vv
        function test_handlerAllocateLqty() public {
            
            uint8 randomUserIndex = 9;
            uint256 amtOfLqtyToStake = 10000000;
            // address user = users[randomUserIndex % users.length];
            (address user , address proxy) = _getRandomUser(randomUserIndex);
            console.log("This is the user that will be allocating lqty and ",user);
            console.log("Total number of users", users.length);
            assertEq(lqty.balanceOf(user),initialLqtyAllocatedPerUser);

            handler_clampedDepositLqtyUser(randomUserIndex,amtOfLqtyToStake);
            uint256 userStakedLqty = IUserProxy(proxy).staked();
            console.log("This is the user's staked lqty",userStakedLqty);
            assertEq(userStakedLqty,amtOfLqtyToStake);


            // console.log("This is users balance",);
            vm.warp(block.timestamp + governance.EPOCH_DURATION());
            handler_makeInitiative();
            handler_registerInitiative(10, 7);
            assertEq(deployedInitiatives.length, 2);
            address newInitiative = deployedInitiatives[7 % deployedInitiatives.length];
            (IGovernance.InitiativeStatus afterRegisteringStatus,,) = governance.getInitiativeState(newInitiative);
            vm.warp(block.timestamp + governance.EPOCH_DURATION());
            console.log("This is status of new initiative", uint256(afterRegisteringStatus));

            handler_allocateLqty(randomUserIndex,3,100000,0);

        }


        // forge test --match-test test_handlerRegisterInitiative -vvvv
        function test_handlerRegisterInitiative() public {
            assertEq(deployedInitiatives.length, 1);
            // console.log(users.length , "THese are the total users");
            console.log("This is the address for the cryticToFoundry",address(this));

            // console.log( "These are the Initially deployed intiatives", deployedInitiatives.length);
            address intiative1 = deployedInitiatives[0];
            (IGovernance.InitiativeStatus beforeStatus,,) = governance.getInitiativeState(intiative1);

            (uint256 epochRegistrationOfInitiativeBefore1) = governance.registeredInitiatives(intiative1);

            
            console.log("This is the beforeStatus of initiative1 ",uint256(beforeStatus));
            console.log("This is the current epoch",governance.epoch());
            console.log("This is the epoch where initiative1 was registered",epochRegistrationOfInitiativeBefore1);
            
    
            vm.warp(block.timestamp + governance.EPOCH_DURATION());
 
            handler_makeInitiative();

            address newInitiative = deployedInitiatives[7 % deployedInitiatives.length];
            (IGovernance.InitiativeStatus afterMakingInitiativeStatus,,) = governance.getInitiativeState(newInitiative);

            (uint256 epochRegistrationOfInitiativeAfter1) = governance.registeredInitiatives(newInitiative);

            
            console.log("This is the after Making Initiative, Status of new initiative2 ",uint256(afterMakingInitiativeStatus));
            // console.log("This is the current epoch",governance.epoch());
            console.log("This is the epoch where new initiative2 was made",epochRegistrationOfInitiativeAfter1);
            assertEq(uint256(afterMakingInitiativeStatus), 0, "Cause it is not registered yet so it is 0");

            handler_registerInitiative(10, 7);
            // handler_registerInitiative(7);
            (IGovernance.InitiativeStatus afterRegisteringStatus,,) = governance.getInitiativeState(newInitiative);

            (uint256 epochRegistrationOfInitiativeAfterRegisteration1) = governance.registeredInitiatives(newInitiative);


            assertEq(uint256(afterRegisteringStatus), 1, "Cause it is registered so it is 1 so it is WARM");
            console.log("This is the after registering Initiative, Status of new initiative2 ",uint256(afterRegisteringStatus));
            // console.log("This is the current epoch",governance.epoch());
            console.log("This is the epoch where new initiative2 was registered",epochRegistrationOfInitiativeAfterRegisteration1);
            assertEq(deployedInitiatives.length, 2);
        }

        function helperFunction_DepositLqty(uint8 userIndex, uint256 lqtyAmt) public returns(address) {
            uint8 randomUserIndex = userIndex;
            uint256 amtOfLqtyToStake = lqtyAmt;
            (address user , address proxy) = _getRandomUser(randomUserIndex);
            uint256 initialBalOfUser = lqty.balanceOf(user);
            console.log("Initial bal of the user",initialBalOfUser);
            assertEq(lqty.balanceOf(user),initialLqtyAllocatedPerUser);
            handler_clampedDepositLqtyUser(randomUserIndex,amtOfLqtyToStake);
            uint256 userStakedLqty = IUserProxy(proxy).staked();
            console.log("This is the user's staked lqty",userStakedLqty);
            assertEq(userStakedLqty,amtOfLqtyToStake);
            uint256 finalUserLqtyBalance = lqty.balanceOf(user);
            console.log("Final bal of the user",finalUserLqtyBalance);
            assertEq(finalUserLqtyBalance , initialBalOfUser - userStakedLqty);
            return user;
            // console.log(lqty.balanceOf(user), "This is user balance after depositing");
        }
        
        function helperFunction_DeployAndRegisterInitiave(uint8 userIndex, uint256 lqtyAmt) public returns(address,address) {
            uint256 initiallyDeployedInitiative = deployedInitiatives.length;
            address user = helperFunction_DepositLqty(userIndex,lqtyAmt);
            vm.warp(block.timestamp + governance.EPOCH_DURATION());

            handler_makeInitiative();

            address lastInitiative = deployedInitiatives[deployedInitiatives.length - 1];
            console.log("This is the last initiative",lastInitiative);

            vm.startPrank(user);
            bold.approve(address(governance), type(uint256).max);
            governance.registerInitiative(lastInitiative);
            vm.stopPrank();

            assertEq(deployedInitiatives.length, initiallyDeployedInitiative + 1);
            return (user,lastInitiative);
        }

        function test_invarintZeroAllocatedLqtyRegisterNotPossible() public {
            echdina_zeroAllocatedLqtyUserCannotRegister();
        }

        function test_handleClaimForInitiative() public {
            uint256 lqtyAmtTodeposit = 5000e18;
            (address userWhoDeployedInitiative, address initiativeAddress) = helperFunction_DeployAndRegisterInitiave(9,lqtyAmtTodeposit);
            (IGovernance.InitiativeStatus afterRegisteringStatus,,) = governance.getInitiativeState(initiativeAddress);
            vm.warp(block.timestamp + governance.EPOCH_DURATION());
            console.log("This is status of new initiative", uint256(afterRegisteringStatus));
            // 309485009821345068724781055
            // 500000000000000000000
            // 9000000000000000000000
            // 309484509821345068724781055

            // 10000000000000000000000
            // 9000000000000000000000
            // 1000000000000000000000
            // 108864000000000000000000000
            // 7776000000000000000000000000
            // 3628800000000000000000000000
            uint8 initiativeToAllocateAndClaimIndex = 3;
            address initiativeToAllocateAndClaim = _getRandomInitiative(initiativeToAllocateAndClaimIndex);
            console.log("This is the initiave to allocate and claim", initiativeToAllocateAndClaim);
            console.log("Bold accured till now", governance.boldAccrued());
            console.log("Bold accured for the governanace till now", bold.balanceOf(address(governance)));
            handler_allocateLqty(9,initiativeToAllocateAndClaimIndex,2000e18,0);
            vm.warp(block.timestamp + governance.EPOCH_DURATION());
            console.log("Initiative bold balance before the claim", bold.balanceOf(initiativeToAllocateAndClaim));

            (IGovernance.InitiativeStatus afterAllocatingLqty,,) = governance.getInitiativeState(initiativeAddress);
            vm.warp(block.timestamp + governance.EPOCH_DURATION());
            console.log("This is status of new initiative", uint256(afterAllocatingLqty));

            // handler_claimForInitiative(initiativeToAllocateAndClaimIndex);
            (IGovernance.InitiativeVoteSnapshot memory initiativeSnapshot, IGovernance.InitiativeState memory initiativeState,) = governance.getInitiativeSnapshotAndState(initiativeToAllocateAndClaim);

            console.log("These are total votes for the initiative Vote snapshot", initiativeSnapshot.votes);
            console.log("These are total votes for the initiative state ", initiativeState.voteLQTY);

            uint256 votingThreshold = governance.calculateVotingThreshold();
            console.log("This is the voting threshold",votingThreshold);
            console.log("This is the min voting threshold", governance.VOTING_THRESHOLD_FACTOR());
            (uint256 votes,uint256 votesOffset,,) = governance.userStates(userWhoDeployedInitiative);
            console.log("This is the votes of the user", votes);
            console.log("This is the votes offset of the user", votesOffset);
            uint256 claimableAmt = governance.claimForInitiative(initiativeToAllocateAndClaim);
            console.log("Claimble Amt of the initiative",claimableAmt);
            // 30000000000000000
            // 51839481600000000
            // 517881600000000
            
            console.log("Initiative bold balance after the claim", bold.balanceOf(initiativeToAllocateAndClaim));
        }

    function test_zeroAllocatedLqtyUserCannotRegister() public {
        (uint256 votes, uint256 epoch) = governance.votesSnapshot();
        console.log("This is the total votes for the epoch", votes);
        console.log("This is the epcoh", epoch);
        // test_handleClaimForInitiative();
        // test_handlerAllocateLqty();
        hevm.warp(block.timestamp + governance.EPOCH_DURATION());
        (uint256 newVotes, uint256 newEpoch) = governance.votesSnapshot();
        console.log("This is the total new Votes for the new Epoch", newVotes);
        console.log("This is the epcoh", newEpoch);
        
        // IGovernance.VoteSnapshot memory snapshot = IGovernance.VoteSnapshot(1e18, governance.epoch());
        // governance.tester_setVotesSnapshot(snapshot);
        
        for(uint8 i; i < users.length; i++){
            address user = users[i];
            address proxy = governance.deriveUserProxyAddress(user);
            console.log("This is the user", user);
            console.log("This is the proxy code.length before", proxy.code.length);
            // console.log("this is the lqty staked", IUserProxy((proxy)).staked());
            if(proxy.code.length == 0){
                hevm.prank(user);
                bold.approve(address(governance), type(uint256).max);

                hevm.prank(user);
                address newInitiative = address(new BribeInitiative(address(governance), address(lusd), address(lqty)));
                console.log("This is user", user);
                console.log("This is the proxy code.length after making an inititiave", proxy.code.length);

                (IGovernance.InitiativeStatus status1,,) = governance.getInitiativeState(newInitiative);
                console.log("This is the status after making the intitative", uint(status1));
                
                // vm.startPrank(user);
                // governance.registerInitiative(lastInitiative);
                // vm.stopPrank();
                // hevm.prank(user);
                // governance.deployUserProxy();
                
                hevm.warp(block.timestamp + governance.EPOCH_DURATION());
                // vm.expectRevert("Governance: insufficient-lqty");
                hevm.prank(user);
                governance.registerInitiative(newInitiative);
                (IGovernance.InitiativeStatus status2,,) = governance.getInitiativeState(newInitiative);
                console.log("This is the status after calling registering the intitative", uint(status2));
                console.log("This is the proxy code.length after register inititiative", proxy.code.length);
            }
        }

        // (address user, address proxy) = _getRandomUser(randomNumber);
        // // address user = 0x4000000000000000000000000000000000000000;
        // // address proxy = governance.deriveUserProxyAddress(user);
        // // 0x4000000000000000000000000000000000000000
        // console.log("This is the user", user);
        // console.log("This is the user proxy address", proxy);
        // console.log("This is the user proxy address code length", proxy.code.length);
        // hevm.prank(user);
        // address derivedAddrss =  governance.deployUserProxy();
        // console.log("This is the derieved address after deployemtn", derivedAddrss);
        // console.log("This is the derieved address code length after deployemtn", derivedAddrss.code.length);
        

        // bold.approve(address(governance), type(uint256).max);
        // if(proxy.code.length == 0){
        //     address newInitiative = address(new BribeInitiative(address(governance), address(lusd), address(lqty)));
            
        //     // vm.startPrank(user);
        //     // governance.registerInitiative(lastInitiative);
        //     // vm.stopPrank();

        //     hevm.warp(block.timestamp + governance.EPOCH_DURATION());
        //     // bold.approve(address(governance), type(uint256).max);
        //     // hevm.prank(user);
        //     // hevm.prank(0x4000000000000000000000000000000000000000);
        //     governance.registerInitiative(newInitiative);
        //     // try governance.registerInitiative(newInitiative) {
                
        //     // } catch  {
                
        //     // }
        // }

    }

}
//   This is governance 0x13136008B64FF592819B2FA6d43F2835C452020e
//   This is userproxy 0xF4c9906A80739D2876932786F322e4A06152f418
//   This is address of the selfCrytic or  cryticToFoundry 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496

// hevm.prank(user);
                // try governance.registerInitiative(newInitiative) {
                    
                // } catch(bytes memory err)  {
                //     emit ErrorBytes("Error while calling the register initiative",err);
// }