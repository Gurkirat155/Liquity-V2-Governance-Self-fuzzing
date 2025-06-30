# 📄 Fuzzing Suite for Liquity v2 Governance

A structured fuzzing test suite using Echidna and Foundry to validate invariants in the Liquity v2 Governance contract.

## 📁 Folder Structure

Folder Structure
Setup Instructions
Running the Fuzzer
Fuzzing Configuration
Understanding Output
Writing Invariants
Debugging Failures
Best Practices
Contributing
License


``` bash
├── SelfFuzzing/
│   ├── TargetFiles/TargetFunctionsGovernance.sol     # Handler functions
│   ├── Properties/GovernanceProperties.sol           # Invariant test functions
│   ├── SelfCryticTester.sol                          # Entry point for Echidna
│   ├── FoundryTest.sol                               # Manual debugging via Foundry
│   ├── SelfSetup.sol                                 # Setup File for the project
│   ├── BeforeAfter.sol                               # Ghost Variables
│   ├── corpus/                                       # Output folder for coverage, reproducers
│   ├── utils                                         # test utilities
│   └── config.yaml                                   # Echidna config file
│
└── test/SelfCryticToFoundry                          # Manual debugging and proving bugs in Foundry
```


## 🛠 Setup Instructions

1. Echidna installation process - [Echidna setup process](https://github.com/crytic/echidna?tab=readme-ov-file#installation)  

2. To run the echidna fuzzing suite, run the below cmd in the root folder:
```bash
  echidna SelfFuzzing/SelfCryticTester.sol --contract SelfCryticTester --config SelfFuzzing/config.yaml
```

## 🧠 Understanding Output

- corpus/coverage.html: Visual report of code coverage
- corpus/reproducers.txt: Minimal sequence of calls that triggered a bug

## ✅ Writing Invariants

Each invariant follows this structure:

- Preconditions: Ensure inputs are valid
- Action: Execute the test logic
- Ghost Variables: Track state before/after
- Postconditions: Assert the expected state


## 🔐 Invariants Explained

This fuzzing suite tests several core invariants in the Liquity v2 Governance contract to ensure that state transitions respect critical assumptions and safety guarantees of the protocol.

1. **invariant_initiativeShouldReturnSameStatus**:-
This invariant ensures that initiative status remains unchanged during the same epoch, unless it transitions through explicitly allowed states. For example:
- NONEXISTENT → WARM_UP
- CLAIMABLE → CLAIMED
- UNREGISTERABLE → DISABLED
If no valid transition occurs, the status must remain stable throughout the epoch. This protects against unexpected or unauthorized changes to an initiative’s state mid-epoch.

2. **invariant_offSetOfUserShouldIncreaseWithDepositForSingleUser**:-
When a user deposits LQTY, their offset (voting power) should increase. This invariant ensures that the unallocatedLQTYOffset for the user always increases post-deposit. If the offset remains unchanged, it signals that either the deposit failed silently or the offset wasn’t properly updated — both of which are serious issues in governance logic.

3. **invariant_stakedLQTYTokenBalanceOfUserShouldIncreaseWhenDeposited**:-
This invariant validates that the user's staked balance increases by exactly the amount deducted from their EOA (wallet) when depositing LQTY tokens.
It compares the before/after LQTY balance in the user's wallet and their recorded staked LQTY to ensure no tokens are lost or unaccounted for during the staking process.

4. **invariant_totalSumOfAllocatedLqtyOfUserEqualToInitiativesLqty**:-
This invariant checks accounting consistency across the protocol: the sum of all LQTY allocated by users must exactly match the sum of voteLQTY + vetoLQTY across all initiatives.
This ensures the protocol doesn’t over-count or misassign voting power, keeping user intent and initiative metrics perfectly aligned.

5. **invariant_afterClaimingAmtShouldNotbeMoreThanBoldAccured**:-
This invariant ensures that the total amount claimed by all initiatives never exceeds the total BOLD accrued by the governance contract. It prevents economic exploitation where initiatives could claim more rewards than were actually available.

6. **invariant_afterUserClaimsBalanceOfUserShouldIncrease**:-
When a user claims rewards from the legacy Staking V1 system, their BOLD token balance must increase. This invariant verifies that reward distribution works correctly and no tokens are lost or misrouted during the claim.

Note: This test assumes the staking contract is funded or mock-balanced in the fuzzing setup. If not, the invariant might be skipped or marked as optional.

7. **invariant_statusOnceUnregistrableShouldAlwaysBeUnregistrable**:-
This was a candidate invariant (commented out in the code) meant to assert that once an initiative becomes UNREGISTERABLE, it should stay that way permanently. While this logic may hold for some protocols, it was excluded here due to protocol-specific transitions that might override this state in future epochs.














