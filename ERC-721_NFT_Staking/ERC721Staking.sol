// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ERC721Staking is Ownable, ReentrancyGuard,ERC721Holder {
    using SafeERC20 for IERC20;

    // Total stakes
    uint256 public totalStaked;

    // Interfaces for ERC20 and ERC721
    IERC20 public immutable RewardToken;
    IERC721 public immutable NFTToken;
    
    // CONTRACT OWNER address
    address private contractOwner;

    mapping (address => bool) public unstaked;

    // Staker info
    struct Staker {
        // Amount of ERC721 Tokens staked
        uint256 amountStaked;
        // Last time of details update for this User
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
    }

    // Rewards per hour per token deposited in wei.
    // Rewards are cumulated once every hour.
    uint256 private rewardsPerHour = 100000;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;
    
    // Mapping of Token Id to staker. Made for the SC to remeber
    // who to send back the ERC721 Token to.
    mapping(uint256 => address) public stakedAssets;

    // Constructor function
    constructor(IERC721 _NFTToken, IERC20 _RewardToken) {
        contractOwner = msg.sender;
        NFTToken = _NFTToken;
        RewardToken = _RewardToken;
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // For every new Token Id in param transferFrom user to this Smart Contract,
    // increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stakeNfts(uint256[] calldata _tokenIds) external nonReentrant {
        
        // If wallet has tokens staked, calculate the rewards before adding the new token
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        uint256 len = _tokenIds.length;
        totalStaked += _tokenIds.length; // Total stakes
        for (uint256 i; i < len; ++i) {

             // Wallet must own the token they are trying to stake
            require(NFTToken.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");
            
            // Transfer the token from the wallet to the Smart contract
            NFTToken.transferFrom(msg.sender, address(this), _tokenIds[i]);

            // Save who is the staker/depositor of the token           
            // Update the mapping of the tokenId to the stakedAssets
            stakedAssets[_tokenIds[i]] = msg.sender;
        }
        
        // Increment the amount staked for this wallet
        stakers[msg.sender].amountStaked += len;

        // set the total stake
        totalStaked = stakers[msg.sender].amountStaked;
        
        // Update the timeOfLastUpdate for the staker
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    }

    // Check if user has any ERC721 Tokens Staked and if he tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards and for each
    // ERC721 Token in param: check if msg.sender is the original staker, decrement
    // the amountStaked of the user and transfer the ERC721 token back to them
    function unstakeNfts(uint256[] calldata _tokenIds) external nonReentrant {

         // If wallet has tokens staked, calculate the rewards before adding the new token
        require( stakers[msg.sender].amountStaked > 0, "You have no tokens staked");
        
        // Update the rewards for this user, as the amount of rewards decreases with less tokens.
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        // Find the index of this token id in the stakedTokens array
        uint256 len = _tokenIds.length;
        // totalStaked += _tokenIds.length; // Total stakes
        for (uint256 i; i < len; ++i) {

            // Wallet must own the token they are trying to withdraw
            require(stakedAssets[_tokenIds[i]] == msg.sender);

            // Set this token's .staker to be address 0 to mark it as no longer staked
            stakedAssets[_tokenIds[i]] = address(0);

            // Transfer the token back to the withdrawer
            NFTToken.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        // Decrement the amount staked for this wallet
        stakers[msg.sender].amountStaked -= len;

        // set the total stake
        totalStaked = stakers[msg.sender].amountStaked;

        // Update the timeOfLastUpdate for the withdrawer
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;

        // setting true to unstake
        unstaked[msg.sender] = true;
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external {

        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(unstaked[msg.sender] == true,"Cannot Claim before stake and Unstake");
      //  unstaked = false;
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        RewardToken.transferFrom(contractOwner, msg.sender, rewards);
        unstaked[msg.sender] = false;
    }

    // Set the rewardsPerHour variable
    function setRewardsPerHour(uint256 _newValue) public onlyOwner {
        rewardsPerHour = _newValue;
    }

    //////////
    // View //
    //////////

    function userStakeInfo(address _user) public view returns (uint256 _tokensStaked, uint256 _availableRewards)
    {
        return (stakers[_user].amountStaked, availableRewards(_user));
    }

    function availableRewards(address _user) public view returns (uint256) {
        require(stakers[_user].amountStaked > 0, "User has no tokens staked");
        uint256 _rewards = stakers[_user].unclaimedRewards + calculateRewards(_user);
        return _rewards;
    }

    /////////////
    // Internal//
    /////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker) public view returns (uint256 _rewards)
    {
        return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) * stakers[msg.sender].amountStaked)) * rewardsPerHour) / 3600);
    }



}