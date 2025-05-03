// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// import {SelfSetup} from "./SelfSetup.sol";
import {SelfSetup} from "../SelfFuzzing/SelfSetup.sol";
import {TargetFunctionsGovernanace} from "../SelfFuzzing/TargetFiles/TargetFunctionsGovernanace.sol";
import {Test, console} from "forge-std/Test.sol";
import {IGovernance} from "../src/interfaces/IGovernance.sol";
// import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

contract SelfCryticToFoundry is Test,TargetFunctionsGovernanace {


        function setUp() public {
            setup();
        }
        // forge test --match-test test_handlerdepositTesting -vvvv

        function test_handlerdepositTesting() public {
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

            // handler_registerInitiative(10, 7);
            handler_registerInitiative(7);
            (IGovernance.InitiativeStatus afterRegisteringStatus,,) = governance.getInitiativeState(newInitiative);

            (uint256 epochRegistrationOfInitiativeAfterRegisteration1) = governance.registeredInitiatives(newInitiative);


            assertEq(uint256(afterRegisteringStatus), 1, "Cause it is registered so it is 1 so it is WARM");
            console.log("This is the after registering Initiative, Status of new initiative2 ",uint256(afterRegisteringStatus));
            // console.log("This is the current epoch",governance.epoch());
            console.log("This is the epoch where new initiative2 was registered",epochRegistrationOfInitiativeAfterRegisteration1);
            assertEq(deployedInitiatives.length, 2);
        }

}
//   This is governance 0x13136008B64FF592819B2FA6d43F2835C452020e
//   This is userproxy 0xF4c9906A80739D2876932786F322e4A06152f418
//   This is address of the selfCrytic or  cryticToFoundry 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
