// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MindMiner IdeaCoin
 * @dev Implements an ERC20 token for distributing rewards called IdeaCoin and MATIC. 
 * The tokens are initially minted to this contract and distributed based on specific reward criteria to incentivize platform engagement.
 */
contract IdeaCoin is ERC20, Ownable {
    uint256 private MAX_SUPPLY =  21000000 * (10 ** 18); 
    uint256 public totalRewardsDistributed; 
    uint256 public remainingSupply;

    IERC20 private immutable MATIC;
    uint256 public constant IDEA_COINS_REQUIRED = 500 * 10 ** 18;

    mapping(address => uint256) public userIdeaBalance;
    event IdeaRewardDistributed(address indexed recipient, uint256 amount);
    event MaticRewardDistributed(address indexed recipient, uint256 amount);

    /**
     * @notice Initializes the ERC20 token with the name "IdeaCoin" and symbol "IDEA".
     * @dev Constructor that mints all IdeaCoins to this contract.
     * Initializes remainingSupply with MAX_SUPPLY upon deployment.
     */
    constructor(address _maticAddress) ERC20("IdeaCoin", "IDEA") Ownable(msg.sender) {
        require(_maticAddress != address(0), "MATIC address cannot be zero");
        remainingSupply = MAX_SUPPLY;       
        MATIC = IERC20(_maticAddress);
        _mint(address(this), MAX_SUPPLY);
    }

    /**
     * @dev Distributes Idea rewards while adjusting the amount based on the remaining supply and adjacent factor to slowly deplete the supply.
     * @notice Distributes adjusted IdeaCoin rewards to a specified wallet address.
     * @param _to The recipient's address.
     * @param _amount The initial amount to distribute before adjustment.
     */
    function distributeIdeaReward(address _to, uint256 _amount) external onlyOwner{
        require(totalRewardsDistributed < MAX_SUPPLY, "All Idea coins have been distributed.");
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Invalid amount");
        
        uint256 adjustedAmount = (_amount * remainingSupply) / MAX_SUPPLY;
        
        require(adjustedAmount > 0, "Adjusted amount is too low");
        require(adjustedAmount <= remainingSupply, "Adjusted amount exceeds remaining supply");
        
        totalRewardsDistributed += adjustedAmount;
        remainingSupply = MAX_SUPPLY - totalRewardsDistributed;
        userIdeaBalance[_to] += adjustedAmount; 

        _transfer(address(this), _to, adjustedAmount);

        emit IdeaRewardDistributed(_to, adjustedAmount);
    }

    /**
     * @notice Distributes MATIC rewards to a recipient based on their IdeaCoin holdings.
     * @dev Transfers MATIC from the contract to the recipient.
     * @param _to The recipient's address.
     * @param _amount The amount of MATIC to distribute.
     */
    function distributeMaticReward(address _to, uint256 _amount) external onlyOwner{
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Invalid amount");
        require(MATIC.balanceOf(msg.sender) >= _amount, "Owner does not have enough MATIC");
        uint256 ideaBalance = balanceOf(_to); 
        require(ideaBalance >= IDEA_COINS_REQUIRED, "User doesn't have 500 IdeaCoins");
        
        _burn(_to, IDEA_COINS_REQUIRED);
        bool transferSuccess = MATIC.transferFrom(msg.sender, _to, _amount);
        require(transferSuccess, "MATIC transfer failed");
        emit MaticRewardDistributed(_to, _amount);
    } 
}
