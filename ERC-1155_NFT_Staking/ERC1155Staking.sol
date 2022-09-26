// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects
contract Staking is Ownable,ERC1155Holder,ReentrancyGuard{

    // Total stakes
    uint256 public totalStaked;

    using SafeERC20 for IERC20;

    // Interfaces for ERC20 and ERC1155
    IERC20 public immutable RewardToken;
    IERC1155 public immutable NFTToken;

    // CONTRACT OWNER address
    address private contractOwner;
   
    // uint256 private totalTokens;

    // uint256 month = 2629743;
    // uint256 constant deno = 100;

    // Rewards Day Wise: Means 1000 tokens in a day, It means these are the No of tokens which will recive every second    
    // uint256 public EMISSION_RATE = (1000 * 10 ** decimals()) / 1 days;


    // Staker info
    struct Staker {
        // Amount of ERC1155 Tokens staked
        uint256 amountStaked;
        // Last time of details update for this User
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;

        // uint256 _amount;
    }

    // Rewards per hour per token deposited in wei.
    // Rewards are cumulated once every hour.
    uint256 private rewardsPerHour = 100000;

    uint256 public remaining;

    mapping (address => bool) public unstaked;

    mapping (uint => uint) public copies;

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;
    
    // Mapping of Token Id to staker. Made for the SC to remeber
    // who to send back the ERC1155 Token to.
    mapping(uint256 => address) public stakerAddress;

    // Constructor function
    constructor(IERC1155 _NFTToken, IERC20 _RewardToken) {
        contractOwner = msg.sender;
        NFTToken = _NFTToken;
        RewardToken = _RewardToken;
    }

    event Stake(address indexed owner, uint256 id, uint256 amount, uint256 time);
    event UnStake(address indexed owner, uint256 id, uint256 amount, uint256 time, uint256 rewardTokens);



    // @notice It will calculate the rate of the token reward
    // @dev It will block.timestamp to track the time.
    // @return Return the reward rate %


    // function calculateRate() public view returns(uint8) {
    //     uint256 time = stakers[msg.sender].timeOfLastUpdate;
    //     if(block.timestamp - time < month) {
    //         return 0;
    //     } else if(block.timestamp - time <  month * 6 ) {
    //         return 5;
    //     } else if(block.timestamp - time < 12 * month) {
    //         return 10;
    //     } else {
    //         return 15;
    //     }
    // }

    // If address already has ERC1155 Token/s staked, calculate the rewards.
    // For every new Token Id in param transferFrom user to this Smart Contract,
    // increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give timeOfLastUpdate the
    // value of now.
    function stakeNFTs(uint256[] calldata _tokenIds,uint256[] memory _amount) public nonReentrant {
        
        // If wallet has tokens staked, calculate the rewards before adding the new token
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        uint256 len = _tokenIds.length;
        totalStaked += _tokenIds.length; // Total stakes
        for (uint256 i; i < len; ++i) {

             // Wallet must own the token they are trying to stake
 //           require(NFTToken.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake tokens you don't own!");
            
            // setting copies to the specific id
            copies[_tokenIds[i]] = _amount[i]; 
            
            // Transfer the token from the wallet to the Smart contract
            NFTToken.safeTransferFrom(msg.sender, address(this), _tokenIds[i], _amount[i], "0x00");
            
            // Update the mapping of the tokenId to the staker's address
            stakerAddress[_tokenIds[i]] = msg.sender;
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
    // the amountStaked of the user and transfer the ERC1155 token back to them
    function UnstakeNFTs(uint256[] calldata _tokenIds,uint256[] memory _amount) public nonReentrant {

         // If wallet has tokens staked, calculate the rewards before adding the new token
//        require( stakers[msg.sender].amountStaked > 0, "You have no tokens staked");
        //


        // Update the rewards for this user, as the amount of rewards decreases with less tokens.
        uint256 rewards = calculateRewards(msg.sender);
        stakers[msg.sender].unclaimedRewards += rewards;

        // Find the index of this token id in the stakedTokens array
        uint256 len = _tokenIds.length;

        for (uint256 i; i < len; ++i) {

            // Wallet must own the token they are trying to withdraw
            // require(stakerAddress[_tokenIds[i]] == msg.sender,"wallet");
        
        
            remaining = copies[_tokenIds[i]] - _amount[i];
            copies[_tokenIds[i]] = remaining;
        
            // Set this token's .staker to be address 0 to mark it as no longer staked
            stakerAddress[_tokenIds[i]] = address(0);

            // Transfer the token back to the withdrawer
            NFTToken.safeTransferFrom(address(this), msg.sender, _tokenIds[i],_amount[i], "0x00");

        }

        // Decrement the amount staked for this wallet
        if (remaining == 0){
            stakers[msg.sender].amountStaked -= len;
        }

        // set the total stake
        totalStaked = stakers[msg.sender].amountStaked;

        // Update the timeOfLastUpdate for the withdrawer
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        
        // setting true to unstake
        unstaked[msg.sender] = true;
    }


    // function unstake(uint256[] calldata _tokenIds,uint256[] memory _amount) external {
    //     UnstakeNFTs(uint256[] calldata _tokenIds,uint256[] memory _amount);
    // }



    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;
        require(unstaked[msg.sender] == true,"Cannot Claim before stake and Unstake");
        require(rewards > 0, "You have no rewards to claim");
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;
        RewardToken.safeTransferFrom(contractOwner, msg.sender, rewards);
        // RewardToken.transfer( msg.sender, rewards);
        // RewardToken.safeTransfer( msg.sender, rewards);
        unstaked[msg.sender] = false;
    }
    
    // Set the rewardsPerHour variable
    function setRewardsPerHour(uint256 _value) public onlyOwner {
        rewardsPerHour = _value;
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
    // since last update in hours and mulitplying it to ERC1155 Tokens Staked
    // and rewardsPerHour.
    function calculateRewards(address _staker) public view returns (uint256 _rewards)
    {
        return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) * stakers[msg.sender].amountStaked)) * rewardsPerHour) / 3600);
    }

}