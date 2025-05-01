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

NOTE:-
no no this `IUserProxy(governance.deriveUserProxyAddress(user)).staked();` means that `allocatedLqty + unallcoatedLqty` both where as `governance.userStates[randomUser].allocatedLQTY` means only allocated lqty.
