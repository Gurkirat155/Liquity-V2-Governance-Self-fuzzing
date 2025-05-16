// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import {SelfSetup} from "./SelfSetup.sol";
// // import {TargetFunctionsGovernanace} from "./TargetFiles/TargetFunctionsGovernanace.sol";
// import {BeforeAfter}from "./BeforeAfter.sol";
import {IGovernance} from "../src/interfaces/IGovernance.sol";
import {EchidnaTestingTargetFunctions} from "./EchidnaTestingTargetFunctions.sol";

contract EchidnaTesting is EchidnaTestingTargetFunctions {


    constructor() payable{
        setup();
    }


    function echidna_initiativeShouldReturnSameStatus() public returns(bool){
        if(_before.epoch == _after.epoch) {
            for(uint256 i;i <deployedInitiatives.length; i++){
                address initiative = deployedInitiatives[i];

                // emit InitialBeforeAfterStatus(uint8(_before.initiativeStatus[initiative]) , uint8(_after.initiativeStatus[initiative]));

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
                    // emit BeforeAfterStatus(uint8(_before.initiativeStatus[initiative]) , uint8(_after.initiativeStatus[initiative]));
                    return false;
                }
                // return(_before.initiativeStatus[initiative] == _after.initiativeStatus[initiative]);

            }
        }
        return true;
    }

}