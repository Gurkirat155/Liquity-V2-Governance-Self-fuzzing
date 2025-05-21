// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import {SelfSetup} from "./SelfSetup.sol";
// // import {TargetFunctionsGovernanace} from "./TargetFiles/TargetFunctionsGovernanace.sol";
// import {BeforeAfter}from "./BeforeAfter.sol";
import {IGovernance} from "../src/interfaces/IGovernance.sol";
import {EchidnaTestingTargetFunctions} from "./EchidnaTestingTargetFunctions.sol";
import {BribeInitiative} from "../src/BribeInitiative.sol";

// To tun the tests
// echidna TestHarnessEchidnaWithHandlers/EchidnaTesting.sol --contract EchidnaTesting --config TestHarnessEchidnaWithHandlers/config.test.yaml
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

    function echidna_zeroAllocatedLqtyUserCannotRegister() public returns(bool){
        (uint256 votes,) = governance.votesSnapshot();

        // emit VotesAndEpcoh(votes, epoch);
        // require(votes > 0, "votes count currently zero");
        if(votes > 0){
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
                        // emit ErrorBytes("Error while calling the register initiative",err);
                    }
                    (IGovernance.InitiativeStatus statusAfterInitiativeRegistration,,) = governance.getInitiativeState(newInitiative);
                    
                    // if(statusAfterInitiativeCreation != statusAfterInitiativeRegistration){
                    //     return false;
                    // }
                    // if(statusAfterInitiativeCreation != statusAfterInitiativeRegistration){
                    //     return false;
                    // }
                    return statusAfterInitiativeCreation == statusAfterInitiativeRegistration;
                    // assert(statusAfterInitiativeCreation == statusAfterInitiativeRegistration);
                }

            }
        }

        return true;
    }
}