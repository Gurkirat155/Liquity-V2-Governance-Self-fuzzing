// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "../SelfSetup.sol";
import {BeforeAfter}from "../BeforeAfter.sol";

contract GovernanceProperties is SelfSetup, BeforeAfter {
// abstract contract GovernanceProperties is SelfSetup {


    event InitialBeforeAfterStatus(uint8 beforeStatus, uint8 afterStatus);
    event BeforeAfterStatus(uint8 beforeStatus, uint8 afterStatus);


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

                // emit BeforeAfterStatus(uint8(_before.initiativeStatus[initiative]) , uint8(_after.initiativeStatus[initiative]));

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

    // function echidna_offSetShouldIncrease() public {

    // }

    

}
// View functions should never revert 
