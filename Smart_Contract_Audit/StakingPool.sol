// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address user) external view returns (uint256);
}

contract StakingPool {
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    address public owner;

    uint256 public rewardRate;
    uint256 public totalStaked;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRate
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);

        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "invalid amount");

        updateRewards(msg.sender);

        stakingToken.transferFrom(msg.sender, address(this), amount);

        balances[msg.sender] += amount;
        totalStaked += amount;

        lastUpdate[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "insufficient");

        updateRewards(msg.sender);

        stakingToken.transfer(msg.sender, amount);

        balances[msg.sender] -= amount;
        totalStaked -= amount;

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external {
        updateRewards(msg.sender);

        uint256 reward = rewards[msg.sender];

        require(reward > 0, "no rewards");

        rewardToken.transfer(msg.sender, reward);

        rewards[msg.sender] = 0;

        emit Claimed(msg.sender, reward);
    }

    function updateRewards(address user) public {
        if (balances[user] > 0) {
            uint256 duration = block.timestamp - lastUpdate[user];

            uint256 pending =
                (balances[user] * rewardRate * duration) / 1e18;

            rewards[user] += pending;
        }

        lastUpdate[user] = block.timestamp;
    }

    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
    }

    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}
