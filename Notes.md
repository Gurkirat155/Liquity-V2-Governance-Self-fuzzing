1. Upon staking LQTY user can the voting power increases is proportional to 
    - amount deposited 
    - how long user has staked for

2. Staking staking LQTY also unlocks additional rewards continues to earn LUSD and ETH rewards from Liquity V1.

3. User can withdrawLQTY at any time there is no lock up

4. The funds must be split into 75% for the liquidity pool and 25% for the goverance.

5. Minimum debt of 2000 BOLD is required.

6. Lockup should intiate when the borrow market goes above 75%.
    - Example:
    Let’s say there is $10M in collateral deposits in the system.
    If users have borrowed $7.5M or more, the LTV reaches 75%.
    At this point, borrowers cannot withdraw collateral until the LTV ratio is back below 75%.

    - How Can the Borrow Market Recover Below 75% LTV?
    Borrowers can lower the LTV in two ways:

    Repay their loans (reducing the borrowed amount).
    More users deposit collateral (increasing the denominator in the LTV formula).
    Once the LTV falls below 75%, withdrawals are unlocked again.

7. Troves get liquidated if the LTV goes above the maximum value (90.91% for ETH and 83.33% for wstETH and rETH).

8. max Loan-To-Value (LTV)
    - ETH will have a LTV of 90.91% while wstETH and rETH will have it at 83.33%.

9. Emergency Collateral Shutdown
    If market conditions become too extreme (e.g., ETH price crashes massively in minutes), Liquity V2 has an emergency collateral shutdown mechanism.
    - What Happens?
        ❌ New borrowing is halted.
        ❌ Liquidations might be forced to protect remaining Stability Pool reserves.
        ❌ Users may be given options to withdraw collateral or settle loans in an orderly manner.

10. When user withdraws LQTY or unstakes some amount of the LQTY than the voting power starts from the beginning 
 - it is possible to increase or reduce an existing stake. Keep in mind that the new amount added starts off with a voting power of 0, while reducing your stake will leave your staking age unchanged.

11. Any user having at least 0.01% of the total voting power of all LQTY staked and paying the registration fee of  1'000 BOLD can propose new incentives.

12. To qualify for incentives, an initiative must reach a relative threshold of 2% of all votes.

13. Protocol Liquidity Incentives accrue and are then distributed on a weekly cadence across to all qualifying initiatives, or target addresses. 

## what it is this protocol 
this protocol let's user deposit and ETH and LST as collatarel and mint stablecoin BOLD


## Uses cases for BOLD tokens find out what they mean and their incententives 

Uses cases There are 4 main use-cases:
Borrow BOLD
1-click multiply (staked) ETH
Earn yield by depositing BOLD
Stake LQTY to direct PIL and earn


## Voting Power = LQTY Staked × Staking Age


## Protocol Constants

``` Solidity
REGISTRATION_FEE =        100e18   // Fee in BOLD tokens to register
REGISTRATION_THRESHOLD = 0.001e18 // 0.1% of total voting power
UNREG_THRESHOLD         = 3e18     // 300% of total voting power
UNREG_AFTER_EPOCHS      = 4        // Auto-unregister if no win in 4 epochs
VOTING_THRESHOLD        = 0.03e18  // 3% of total voting power
```
We'll assume:

- Total LQTY voting power this epoch = 1,000,000e18


### 1. ✅ Registering an Initiative

To register:
- Pay 100 BOLD
- Have ≥ 0.1% of voting power

``` Solidity
REGISTRATION_THRESHOLD = 0.001e18 × 1,000,000e18 = 1,000e18
```
So a user must have at least 1,000 LQTY voting power to register.

### 2. 🗳️ Voting & Vetoing

Anyone can now vote for or veto the initiative using LQTY.

Votes are calculated using:
``` Solidity
    _lqtyToVotes(lqtyAmount, timestamp, offset)
    = (lqtyAmount × timestamp) - offset
```


So:

- Early voting gives more influence.
- You lose vote weight if you move LQTY mid-epoch (offset increases).


### 🏆 3. Winning an Epoch

Even if you get the most votes, your initiative must pass the minimum participation threshold to be considered:

``` Solidity
    VOTING_THRESHOLD = 0.03e18 × 1,000,000e18 = 30,000e18
```
You must receive at least 30,000 LQTY-weighted votes to be eligible.

Example:
Initiative	Votes	Vetos	Result
A	45,000	5,000	✅ Wins (most votes, > vetos, passes threshold)
B	25,000	2,000	❌ Below threshold
C	10,000	4,000	❌ Below threshold


### 🎁 4. Claiming Rewards

Say initiative A asked for 500 BOLD tokens, and total votes across all eligible initiatives = 100,000.

Initiative A got 45,000 votes.

``` Solidity
    share = (45,000 / 100,000) × 500 = 225 BOLD
```
So initiative A can claim 225 BOLD tokens.

### ❌ 5. Unregistration Logic

🔴 A. Veto-based Unregistration
You’re unregistered at end of epoch if:

You got most vetos, AND
Vetos ≥ 300% of total voting power
``` Solidity
    UNREG_THRESHOLD = 3e18 × 1,000,000e18 = 3,000,000e18
```

You would need at least 3 million LQTY votes against you, AND be the most vetoed initiative to be unregistered.

⚠️ This is a very high bar, likely intended for catastrophic cases or attacks.

🔁 B. Inactivity Unregistration
If an initiative fails to win for 4 consecutive epochs, it is automatically unregistered.

No vetos needed — this prevents spam and stale initiatives.

✅ Full Example Summary (Using New Params)

Step	Outcome
Register	✅ Needs 1,000 LQTY + 100 BOLD
Vote	Weighted by LQTY × time
Threshold to win	Needs ≥ 30,000 votes (3%)
Win condition	Most votes, > vetos
Claim	Proportional to vote share
Removal A	Most vetos and ≥ 3M vetos
Removal B	Didn’t win for 4 epochs




# Explaining `calculateVotingThreshold` function 

1. 🎯 What does this function do?

This function tells us:

How many votes does an initiative need to be considered valid and eligible for rewards?
Even if an initiative gets the most votes, we want to make sure it’s:

Not getting rewarded with dust (very low amount of BOLD)
Getting enough real voting participation from the community

2. 🧩 Why do we need this?

Let’s say:

A bad actor creates a fake initiative
It gets just 1 vote because no one else is active this week
That 1 vote is technically the winner
It claims rewards, even though no one really voted
👎 That’s a problem. We don’t want initiatives to win like this.

So the function says:

“To be eligible, you must meet at least two minimum conditions:”

3. ✅ What are those two conditions?

a. Enough votes overall (aka voting participation)
There’s a system-wide rule:

“Each initiative must get at least X% of total votes cast to be valid.”
This is the VOTING_THRESHOLD_FACTOR.

If 100,000 votes are cast this week, and the threshold is 3%, then:
- You need at least 3,000 votes to be valid.

b. Enough votes to get paid at least 500 BOLD (aka not a dust reward)
Even if you win and participation is low, you need enough votes so that:

“You’re earning at least 500 BOLD in rewards.”
If you only get 2 votes and each vote is worth 10 BOLD → you only earn 20 BOLD.

That’s too low — it’s below MIN_CLAIM = 500 BOLD.

In that case, the initiative is ignored, even if it wins.


4. 📊 So what does the function do exactly?

``` Solidity
    function calculateVotingThreshold(uint256 _votes) public view returns (uint256) {
        if (_votes == 0) return 0;

        uint256 minVotes; // to reach MIN_CLAIM: snapshotVotes * MIN_CLAIM / boldAccrued
        uint256 payoutPerVote = boldAccrued * WAD / _votes;
        if (payoutPerVote != 0) {
            minVotes = MIN_CLAIM * WAD / payoutPerVote;
        }
        return max(_votes * VOTING_THRESHOLD_FACTOR / WAD, minVotes);
    }
```

- 🪵 `if (_votes == 0) return 0;`
If no one voted at all, nothing to calculate → return 0.

- 📏 `payoutPerVote = boldAccrued * WAD / _votes;`
We calculate:

How many BOLD tokens does each vote earn?
boldAccrued: total BOLD to be distributed this epoch (say 20,000 BOLD)
_votes: total number of votes across all initiatives
If 100,000 votes were cast:

``` Solidity
    payoutPerVote = (20,000 * 1e18) / 100,000 = 200e18
```
Means: each vote earns 200 BOLD


- ✅ `return max(participationThreshold, minVotes);`
We return whichever is higher:

The minimum votes required due to low payout per vote
OR the normal participation threshold (like 3% of total votes)
This ensures:

You don’t win with low participation
You don’t claim tiny amounts of BOLD

- 🧠 What does MIN_CLAIM mean?

It’s the minimum reward you must earn to get paid.

If your share of the reward is < MIN_CLAIM (like 500 BOLD), you get nothing.

This avoids paying people 1 BOLD, 0.1 BOLD, etc.



🧪 Example — Full Flow

Assume:

boldAccrued = 20,000 BOLD
_votes = 100,000
VOTING_THRESHOLD_FACTOR = 3%
MIN_CLAIM = 500

Step 1: Calculate payout per vote
20,000 / 100,000 = 0.2 BOLD/vote

Step 2: Calculate min votes to earn 500 BOLD
500 / 0.2 = 2,500 votes

Step 3: Voting threshold via participation
100,000 × 0.03 = 3,000 votes

Final answer:
max(2,500, 3,000) = 3,000

So, you need at least 3,000 votes to be valid and claim BOLD.



``` Solidity

```




## Doubts
- what is LST coin --  this is in V1 not in V2 so don't worry
- How is BOLD a stablecoin how is it backed --  backed by eth, reth etc
- What is Trove in detail like each adress could have multiple troves
    - Each Trove allows you to manage a loan, adjusting collateral and debt values as needed, as well as setting your own interest rate.

- Understand `How am I compensated for liquidating a Trove` in detail
- What is the refundable gas depos

