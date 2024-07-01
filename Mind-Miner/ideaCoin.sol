
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MindMiner IdeaCoin
 * @dev Implements an ERC20 token for distributing rewards called IdeaCoin. 
 * The tokens are initially minted to this contract and distributed based on specific reward criteria to incentivize platform engagement.
 */
contract IdeaCoin is ERC20, Ownable {
    uint256 private MAX_SUPPLY =  21000000 * (10 ** 18); 
    uint256 public totalRewardsDistributed; 
    uint256 public remainingSupply;

    mapping(address => uint256) public IdeaBalance;
    event RewardDistributed(address indexed recipient, uint256 adjustedAmount);

    /**
     * @dev Constructor that mints all IdeaCoins to this contract.
     * @notice Initializes the ERC20 token with the name "IdeaCoin" and symbol "IDEA".
     * Initializes remainingSupply with MAX_SUPPLY upon deployment.
     */
    constructor() ERC20("IdeaCoin", "IDEA") Ownable(msg.sender) {
        _mint(address(this), MAX_SUPPLY);
        remainingSupply = MAX_SUPPLY;       
    }

    /**
     * @dev Distributes rewards while adjusting the amount based on the remaining supply and adjacent factor to slowly deplete the supply.
     * @notice Distributes adjusted IdeaCoin rewards to a specified wallet address.
     * @param to The recipient's address.
     * @param amount The initial amount to distribute before adjustment.
     */
    function distributeRewards(address to, uint256 amount) external onlyOwner{
        require(totalRewardsDistributed < MAX_SUPPLY, "All Idea coins have been distributed.");
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid amount");
        
        uint256 adjustedAmount = (amount * remainingSupply) / MAX_SUPPLY;
        
        require(adjustedAmount > 0, "Adjusted amount is too low");
        require(adjustedAmount <= remainingSupply, "Adjusted amount exceeds remaining supply");
        
        totalRewardsDistributed += adjustedAmount;
        remainingSupply = MAX_SUPPLY - totalRewardsDistributed;
        IdeaBalance[to] += adjustedAmount; 

        _transfer(address(this), to, adjustedAmount);

        emit RewardDistributed(to, adjustedAmount);
    }
}
