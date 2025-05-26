1. Check if the deployed user proxy matches the msg.sender address or not, or could it be mismatched some times.
2. Check of an intiative would be unregistered after four epochs or not.
3. The voting threshold should increse in the next epoch because (as the voting power increses linearly so as it it would be incresed in the upcoming epoch so that's why votes required will also increse in upococming epoch)
4. Users allocated lqty should increase by time
5. Views functions should never revert.(make a different folder)
6. Users cannot register if they have zero lqty staked or zero offset
7. Initative cannot register without giving registration fee and a person who has staked lqty and has voting power or offset
8. Make ghost variable for registered initiaitive and check if the registered in smart contract and in ghost variables are the same.
9. Make a ghost variables for unregistered intiative
10. On resetting the allocations the allocated lqty should be zero
11. After a initiaive wins it bold amt should increase and if it fails than bold doesn't increase
12. When claimed the from the V1 then the lqty or lusd should increase
13. Users should not be allowed to register before 2 epochs `Governance: registration-not-yet-enabled`
14. Users should not be able register initiative 
15. check_unregisterable_consistecy

NOTE:-
no no this `IUserProxy(governance.deriveUserProxyAddress(user)).staked();` means that `allocatedLqty + unallcoatedLqty` both where as `governance.userStates[randomUser].allocatedLQTY` means only allocated lqty.

#### Coverage Improved
- claimFromStakingV1()
- withdrawLQTY
- depositLQTY
- registerInitiative (First let the users have bold so he could transfer the registration fee)
- secondsWithinEpoch() 


#### Coverage remaining 

- getLatestVotingThreshold
- calculateVotingThreshold
- Via Permit Withdraw and deposit
- getInitiativeState() is not properly covered (coverage not full for this function)
- _resetInitiatives()
- resetAllocations
- allocateLQTY not covered at all
- claimForInitiative not covered at all
- getTotalVotesAndState handler missing
- handler_unclampedDepositLqtyUser
- handler_unclampedWithdrawLqty()
- handler_resetAllocations
- handler_allocateLqty
- handler_deployUserProxy()


#### Functions remaining 
- make handler_makeInitiative which makes a random initiatives

# Test All handlers with foundry
# Increase the invariants

## Learnings
- // Ok so derieved address is equal to userproxy contract address
- *Before the coverage was not increasing so i debugged my handlers with foundry which i didn't knew before so changed the token approve type(uint256).max*
- for  `registerInitiative` not working, edited the from `handler_registerInitiative(uint8)` to `handler_registerInitiative(uint8,uint8)` in the config.yaml blacklist that's why it wasn't getting covered in the 
and also had to edit the handler itself approving of the token was missing and also the msg.sender who is approving that was not being passed.

changed the handler from 
``` Solidity
    function handler_registerInitiative(uint8 initiativeIndex) public {
        address initiative = _getRandomInitiative(initiativeIndex);
        if(deployedInitiatives.length < 1) return;
        __before(users[0]);
        governance.registerInitiative(initiative);
        __after(users[0]);
    }
```    

to
``` Solidity
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
```  

