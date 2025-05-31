// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Governance} from "../src/Governance.sol";
import {SelfSetup} from "./SelfSetup.sol";
import {IGovernance} from "../src/interfaces/IGovernance.sol";
import {IBribeInitiative} from "../src/interfaces/IBribeInitiative.sol";
// import {Asserts} from "@chimera/Asserts.sol";
import {IUserProxy} from "../src/interfaces/IUserProxy.sol";

abstract contract BeforeAfter is SelfSetup {

    struct Vars {
        uint256 epoch;
        mapping(address => IGovernance.InitiativeStatus) initiativeStatus;
        // initiative => user => epoch => claimed
        mapping(address initiative => mapping(address user => mapping(uint256 epoch => bool claimed))) claimedBribeForInitiativeAtEpoch;
        mapping(address user => uint256 lqtyBalance) userLqtyBalance;
        mapping(address user => uint256 lusdBalance) userLusdBalance;
    }

    struct Accumulator {
        uint256 totalStaked;
        uint256 totalUnallocatedLQTY;
        uint256 totalUnallocatedOffset;
    }

    Vars _before;
    Vars _after;

    function __before(address user) internal {
        uint256 currentEpoch =  governance.epoch();
        _before.epoch = currentEpoch;

        for(uint256 i; i< deployedInitiatives.length; i++){
            address initiative = deployedInitiatives[i];
            (IGovernance.InitiativeStatus status, , ) = governance.getInitiativeState(initiative);
            _before.initiativeStatus[initiative] = status;

            _before.claimedBribeForInitiativeAtEpoch[initiative][user][currentEpoch] = IBribeInitiative(initiative).claimedBribeAtEpoch(user, currentEpoch);
        }

        for(uint256 i; i< users.length;i++){
            _before.userLqtyBalance[users[i]] = lqty.balanceOf(users[i]);
            _before.userLusdBalance[users[i]] = lusd.balanceOf(users[i]);
        }

    } 

    function __after(address user) internal {
        uint256 currentEpoch =  governance.epoch();
        _after.epoch = currentEpoch;

        for(uint256 i; i< deployedInitiatives.length; i++){
            address initiative = deployedInitiatives[i];
            (IGovernance.InitiativeStatus status, , ) = governance.getInitiativeState(initiative);
            _after.initiativeStatus[initiative] = status;

            _after.claimedBribeForInitiativeAtEpoch[initiative][user][currentEpoch] = IBribeInitiative(initiative).claimedBribeAtEpoch(user, currentEpoch);
        }

        for(uint256 i; i< users.length;i++){
            _after.userLqtyBalance[users[i]] = lqty.balanceOf(users[i]);
            _after.userLusdBalance[users[i]] = lusd.balanceOf(users[i]);
        }
    } 

    function accumulateUserStates(address[] memory localUsers) internal view returns (Accumulator memory acc) {
        for (uint256 i = 0; i < localUsers.length; i++) {
            address user = localUsers[i];
            address proxy = governance.deriveUserProxyAddress(user);

            if (proxy.code.length == 0) continue;

            uint256 staked = IUserProxy(proxy).staked();

            (uint256 unallocatedLQTY, uint256 unallocatedOffset, ,) = governance.userStates(user);

            acc.totalStaked += staked;
            acc.totalUnallocatedLQTY += unallocatedLQTY;
            acc.totalUnallocatedOffset += unallocatedOffset;
        }
    }

}