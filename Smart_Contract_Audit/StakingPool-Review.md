# StakingPool.sol Review

## Scope

Reviewed file: `StakingPool.sol`

The contract is a simplified staking pool where users deposit an ERC20 staking token, accrue rewards over time, withdraw stake, and claim reward tokens.

## Executive Summary

The highest-impact issues are around ERC20 transfer handling, reward accounting, and unsafe external-call ordering. In its current form, a failed token transfer can still be treated as successful, reward-rate changes can apply retroactively to old staking periods, and owner-controlled emergency withdrawals can remove user deposits.

The contract is also missing common production safeguards such as `SafeERC20`, reentrancy protection, constructor validation, reward-funding controls, and clear reward-rate semantics.

## Findings

### 1. Unchecked ERC20 transfer return values

Severity: High

Location:

- `StakingPool.sol:55`
- `StakingPool.sol:70`
- `StakingPool.sol:85`
- `StakingPool.sol:113`

Issue:

The contract calls `transfer` and `transferFrom` but does not check the returned boolean. Some ERC20 tokens return `false` instead of reverting on failure.

Impact:

- `stake()` can credit a user with staking balance even if `transferFrom()` failed.
- `withdraw()` can reduce a user's internal balance even if the staking token transfer failed.
- `claimRewards()` can erase a user's rewards even if the reward transfer failed.
- `emergencyWithdraw()` can silently fail while the owner assumes funds were recovered.

Suggested fix:

Use OpenZeppelin `SafeERC20`, or at minimum require the transfer return value.

```solidity
using SafeERC20 for IERC20;

stakingToken.safeTransferFrom(msg.sender, address(this), amount);
stakingToken.safeTransfer(msg.sender, amount);
rewardToken.safeTransfer(msg.sender, reward);
```

If not using OpenZeppelin:

```solidity
require(stakingToken.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
require(stakingToken.transfer(msg.sender, amount), "transfer failed");
require(rewardToken.transfer(msg.sender, reward), "reward transfer failed");
```

`SafeERC20` is preferred because it also supports tokens that do not return a boolean.

### 2. Reward-rate changes affect previous unclaimed time

Severity: High

Location:

- `StakingPool.sol:96`
- `StakingPool.sol:105`

Issue:

Rewards are calculated using the current `rewardRate` for the entire time since a user's last update. When the owner changes `rewardRate`, users who have not recently interacted will have all previous unaccounted time calculated using the new rate.

Example:

1. Alice stakes while `rewardRate = 10`.
2. Alice waits 30 days without interacting.
3. Owner sets `rewardRate = 0`.
4. Alice claims.
5. Her 30 days of rewards are calculated at `0`, not at `10`.

The reverse is also true: increasing the rate can overpay users for past time.

Impact:

Rewards can be underpaid or overpaid depending on when users interact. This makes reward distribution unfair and unpredictable.

Suggested fix:

Use a global reward accumulator, such as `rewardPerTokenStored`, and update it before changing `rewardRate`.

```solidity
modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastRewardUpdateTime = block.timestamp;

    if (account != address(0)) {
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    _;
}

function setRewardRate(uint256 newRate)
    external
    onlyOwner
    updateReward(address(0))
{
    rewardRate = newRate;
    emit RewardRateUpdated(newRate);
}
```

### 3. Reward formula likely distributes the wrong amount

Severity: High or Medium, depending on intended design

Location:

- `StakingPool.sol:23`
- `StakingPool.sol:96`

Issue:

The contract tracks `totalStaked`, but the reward calculation does not use it:

```solidity
(balances[user] * rewardRate * duration) / 1e18
```

This means `rewardRate` is treated as a per-token reward rate, not a total pool emission rate. In most staking pools, `rewardRate` means total rewards emitted per second and users receive a pro-rata share based on `balance / totalStaked`.

Impact:

If the intended design is a fixed pool emission rate, the current code overpays as more users stake. Total emissions grow with total deposits and can easily exceed the reward tokens funded to the contract.

Suggested fix:

Use a `rewardPerToken()` accumulator:

```solidity
function rewardPerToken() public view returns (uint256) {
    if (totalStaked == 0) {
        return rewardPerTokenStored;
    }

    return rewardPerTokenStored
        + ((block.timestamp - lastRewardUpdateTime) * rewardRate * 1e18) / totalStaked;
}

function earned(address account) public view returns (uint256) {
    return ((balances[account]
        * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18)
        + rewards[account];
}
```

If the intended design is truly per-staked-token rewards, rename and document `rewardRate` as something like `rewardRatePerTokenPerSecond`, and add strict funding checks.

### 4. External calls happen before state updates

Severity: High for untrusted tokens, Medium otherwise

Location:

- `StakingPool.sol:70-73`
- `StakingPool.sol:85-87`

Issue:

`withdraw()` transfers staking tokens before reducing the user's internal balance. `claimRewards()` transfers reward tokens before zeroing the user's reward balance.

Impact:

A malicious token or callback-capable token can reenter the contract and call `withdraw()` or `claimRewards()` again before state is updated. This can allow repeated withdrawals or repeated reward claims.

Suggested fix:

Follow checks-effects-interactions and add `nonReentrant`.

```solidity
function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
    require(amount > 0, "invalid amount");
    require(balances[msg.sender] >= amount, "insufficient");

    balances[msg.sender] -= amount;
    totalStaked -= amount;

    stakingToken.safeTransfer(msg.sender, amount);

    emit Withdrawn(msg.sender, amount);
}

function claimRewards() external nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    require(reward > 0, "no rewards");

    rewards[msg.sender] = 0;
    rewardToken.safeTransfer(msg.sender, reward);

    emit Claimed(msg.sender, reward);
}
```

### 5. Owner can withdraw user deposits through `emergencyWithdraw`

Severity: High

Location:

- `StakingPool.sol:109-114`

Issue:

The owner can call `emergencyWithdraw()` for any token, including the staking token and reward token.

Impact:

The owner can remove all user-staked principal from the contract. Even if the owner is trusted, a compromised owner key can drain the pool.

Suggested fix:

Either remove this function or restrict it to unrelated tokens accidentally sent to the contract.

```solidity
function recoverERC20(address token, uint256 amount) external onlyOwner {
    require(token != address(stakingToken), "cannot recover staking token");
    require(token != address(rewardToken), "cannot recover reward token");

    IERC20(token).safeTransfer(msg.sender, amount);
    emit TokenRecovered(token, amount);
}
```

If reward-token recovery is required, only allow recovery of surplus rewards after accounting for all outstanding liabilities.

### 6. No reward funding or solvency control

Severity: Medium

Location:

- `StakingPool.sol:78-87`
- `StakingPool.sol:105-107`

Issue:

Rewards accrue without checking whether the contract has enough reward tokens to pay them. The owner can set any `rewardRate`, even one that creates liabilities far above the contract's reward balance.

Impact:

Users may accrue rewards that cannot be paid. With the current unchecked transfer behavior, a failed reward payment can even clear a user's reward balance.

Suggested fix:

Add an explicit reward funding function, reward duration, and cap the reward rate by available funding.

```solidity
function notifyRewardAmount(uint256 reward, uint256 duration)
    external
    onlyOwner
    updateReward(address(0))
{
    require(duration > 0, "invalid duration");

    rewardToken.safeTransferFrom(msg.sender, address(this), reward);
    rewardRate = reward / duration;
    periodFinish = block.timestamp + duration;
}
```

### 7. Fee-on-transfer staking tokens break accounting

Severity: Medium

Location:

- `StakingPool.sol:55-58`

Issue:

`stake()` credits the user with the requested `amount`, not the amount actually received by the contract. Fee-on-transfer or deflationary tokens may transfer less than `amount`.

Impact:

The pool can become insolvent because internal balances and `totalStaked` exceed the actual staking token balance.

Suggested fix:

Either explicitly reject fee-on-transfer tokens or credit the actual received amount.

```solidity
uint256 balanceBefore = stakingToken.balanceOf(address(this));
stakingToken.safeTransferFrom(msg.sender, address(this), amount);
uint256 received = stakingToken.balanceOf(address(this)) - balanceBefore;

require(received > 0, "nothing received");

balances[msg.sender] += received;
totalStaked += received;
```

### 8. Missing constructor validation

Severity: Low

Location:

- `StakingPool.sol:38-48`

Issue:

The constructor does not validate `_stakingToken` or `_rewardToken`.

Impact:

Deploying with a zero address or wrong token address permanently breaks core functionality.

Suggested fix:

```solidity
require(_stakingToken != address(0), "zero staking token");
require(_rewardToken != address(0), "zero reward token");
```

### 9. `withdraw(0)` is allowed

Severity: Low

Location:

- `StakingPool.sol:65-75`

Issue:

`withdraw()` does not require `amount > 0`.

Impact:

Users can emit meaningless `Withdrawn` events and use `withdraw(0)` as a reward checkpoint. This is not a critical vulnerability, but it is inconsistent with `stake()`.

Suggested fix:

```solidity
require(amount > 0, "invalid amount");
```

### 10. `updateRewards()` should usually be internal or wrapped in a modifier

Severity: Informational

Location:

- `StakingPool.sol:92`

Issue:

Anyone can call `updateRewards(user)` for any user. This does not directly steal funds, but it exposes internal accounting as a public state-changing function.

Impact:

The function increases surface area and allows third parties to force accounting writes for other users.

Suggested fix:

Make it `internal` and use an `updateReward(user)` modifier on stake, withdraw, claim, and reward-rate updates. If a public checkpoint function is desired, name it explicitly, such as `checkpoint(address user)`.

## General Improvements

Recommended improvements:

- Use OpenZeppelin `IERC20`, `SafeERC20`, `ReentrancyGuard`, and `Ownable2Step`.
- Mark token addresses as `immutable`.
- Add events for `RewardRateUpdated`, `TokenRecovered`, and ownership changes.
- Add `earned(address user)` and `pendingRewards(address user)` view functions.
- Decide and document the meaning of `rewardRate`.
- Add reward-funding logic so rewards cannot exceed funded amounts.
- Use checks-effects-interactions consistently.
- Add tests for staking, withdrawing, claiming, reward-rate changes, insufficient rewards, fee-on-transfer tokens, and transfer failures.

## Suggested Safer Structure

This is the accounting pattern I would recommend for a production-style fixed-emission staking pool:

```solidity
uint256 public rewardRate; // total reward tokens emitted per second
uint256 public rewardPerTokenStored;
uint256 public lastRewardUpdateTime;

mapping(address => uint256) public userRewardPerTokenPaid;
mapping(address => uint256) public rewards;

modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastRewardUpdateTime = block.timestamp;

    if (account != address(0)) {
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    _;
}

function rewardPerToken() public view returns (uint256) {
    if (totalStaked == 0) {
        return rewardPerTokenStored;
    }

    return rewardPerTokenStored
        + ((block.timestamp - lastRewardUpdateTime) * rewardRate * 1e18) / totalStaked;
}

function earned(address account) public view returns (uint256) {
    return ((balances[account]
        * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18)
        + rewards[account];
}
```

This fixes the largest accounting issue because rewards are distributed proportionally to all stakers and reward-rate changes only affect future time.
