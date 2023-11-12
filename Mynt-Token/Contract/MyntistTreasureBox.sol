// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./UTXORedeemableToken.sol";
import "./IERC721.sol";
import "hardhat/console.sol";

contract MyntistTreasureBox is UTXORedeemableToken {

    /* ============== State Variables ============= */
    uint256 public constant MAX_DEPOSIT = 1e20; // TBD 
    uint256 public exchangeRate = 1e16; // TBD  
    uint256 public constant PERCENTAGE_SCALE = 10000; 
    address public owner = msg.sender;
    address public myntistPlatformAddress; 
    uint256 public totalTreasureBoxes;
    IERC721 public NFTAddress;
    uint256 public nonFlushableAmount;

    /* ================== Structs ================= */
    struct TreasureBox {
        address creator;
        uint256 depositAmount;
        uint256 externalDepositAmount;
        uint256 totalMyntReward;
        uint256 claimDate;
        uint256 createdAt;
        uint256[] rewards;
        bool ethDistribution;
        NFTInfo[] nftInfo;
    }

    struct NFTInfo {
        uint256 nftIds;
        uint256 nftValues;
    }

    /* ================== Modifiers =============== */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
    _;
    }

    /* ================== Mappings =============== */
    mapping(address => TreasureBox[]) public treasureBoxes;
    mapping(uint256 => bool) public treasureBoxIsClaimed;
    mapping(uint256 => address) public nftToBoxCreator;
    
    /* ================== Events ================= */
    event TreasureBoxCreated(uint256 indexed treasureBoxId, address indexed creator, uint256 claimDate, NFTInfo[] nftInfo, uint256 depositAmount, uint256 totalReward);
    event RewardClaimed(address indexed claimer, uint256 indexed boxId, uint256 indexed nftId, uint256 rewardAmount);
    event TreasureBoxFunded(address indexed funder, uint256 amount, uint256 fundedAt);
    event CoinsDistributed(address indexed treasureBoxOwner, uint256 indexed boxId, uint256 indexed _nftId, uint256 distributionAmount);

    /* ================== Functions =============== */
    function checkOwnership(uint256 tokenId) internal view returns (address) {
        return IERC721(NFTAddress).ownerOf(tokenId);
    }

    function createTreasureBox(uint256 _claimDate, NFTInfo[] memory _nftInfos, uint256 _numberOfTokens) external payable {
        require(_claimDate > block.timestamp, "Claim date must be in the future");
        require(_nftInfos.length > 0, "Must link at least one NFT");

        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);
        // require(g._stakePenaltyTotal != 0, "Cannot Create TreasureBox, Penalty Total is Zero" );
        uint256 requiredDeposit = calculateRequiredDeposit(_numberOfTokens);
        require(msg.value == requiredDeposit && msg.value > 0 && msg.value <= MAX_DEPOSIT, "Invalid deposit or out of range.");

        // Push an empty struct
        TreasureBox storage newBox = treasureBoxes[msg.sender].push(); 

        // Calculates TotalMyntReward: HARD CODED VALUE
        uint256 totalTreasureReward = 100000000000000000000; // calculateTotalTreasureReward(100000000000000000000);

        // Insert The values
        newBox.creator = msg.sender;
        newBox.depositAmount = msg.value;
        newBox.claimDate = _claimDate;
        newBox.createdAt = block.timestamp;
        newBox.totalMyntReward = totalTreasureReward;
        newBox.ethDistribution = false;

        // Calculate the rewards are distributed to the NFT owner based on the value of their NFTs.
        uint256[] memory rewards = distributeRewardToNFTOwner(_nftInfos, totalTreasureReward);

        for(uint256 i = 0; i < _nftInfos.length; ++i) {
            require(_nftInfos[i].nftIds > 0 && _nftInfos[i].nftValues > 0, "NFT ID and value must be greater than zero.");
            nftToBoxCreator[_nftInfos[i].nftIds] = msg.sender;
            // Check Ownership
            require(msg.sender == checkOwnership(_nftInfos[i].nftIds), "Caller does not own the NFTs");
            // Push Manually in Dynamic Array
            newBox.nftInfo.push(_nftInfos[i]);
            // Store the Computed reward
            newBox.rewards.push(rewards[i]);
        }

        // Update the Information
        totalTreasureBoxes++;
        nonFlushableAmount += msg.value;

        emit TreasureBoxCreated(totalTreasureBoxes, msg.sender, _claimDate, _nftInfos, msg.value, totalTreasureReward);
    }

    function claimTreasureBox(uint256 _boxId, uint256 _nftId) external {
        address boxCreator = nftToBoxCreator[_nftId];
        require(boxCreator != address(0), "NFT is not associated with any Box");
        require(_boxId > 0 && _boxId <= treasureBoxes[boxCreator].length, "Invalid box ID");
        TreasureBox storage treasureBox = treasureBoxes[boxCreator][_boxId - 1];        
        // require(block.timestamp >= treasureBox.claimDate, "Reward cannot be claimed yet");
        require(msg.sender == checkOwnership(_nftId), "Caller does not own the NFTs");

        // Mint Mynt-Tokens to The Claimer
        uint256 rewardAmount;
        
        bool isNFTFound;
        for (uint256 i = 0; i < treasureBox.nftInfo.length; i++) {
            if (treasureBox.nftInfo[i].nftIds == _nftId) {
                isNFTFound = true;
                rewardAmount = treasureBox.rewards[i];
                _mint(msg.sender, rewardAmount);
                    if (treasureBox.depositAmount != 0){
                        distributeRaisedCoins(treasureBox.creator, _boxId, _nftId);
                    }
                    break;
            }
        }
        
        // require(isNFTFound, "Invalid NFT ID");
        removeNFTAndReward(treasureBox, _nftId);
        
        // Update the claim status and delete the box if all NFTs are claimed.
        if (treasureBox.nftInfo.length == 0) {
            treasureBoxIsClaimed[_boxId] = true;
            delete treasureBoxes[boxCreator][_boxId - 1];
            totalTreasureBoxes--;
        }

        emit RewardClaimed(msg.sender, _boxId, _nftId, rewardAmount);
    }

    function distributeRewardToNFTOwner(NFTInfo[] memory _nftInfo, uint256 _totalMyntReward) internal pure returns(uint256[] memory) {
        
        uint256 totalValues = 0;
        uint256[] memory rewards = new uint256[](_nftInfo.length);
        
        for(uint256 i = 0; i < _nftInfo.length; ++i) {
            // Total sum of values
            totalValues += _nftInfo[i].nftValues;
        }

        for(uint256 i = 0; i < _nftInfo.length; ++i) {
            // The Percentage for each NFT value
            rewards[i] = _totalMyntReward * _nftInfo[i].nftValues / totalValues ;
        }
        return rewards;
    }

    function getLinkedNFTsAndValues(address creator, uint256 boxId) external view returns (NFTInfo[] memory _nftInfo) {
        require(boxId > 0 && boxId <= treasureBoxes[creator].length, "Invalid box ID");
        _nftInfo = treasureBoxes[creator][boxId - 1].nftInfo;
    }

    // function isLinkedNFT(TreasureBox storage treasureBox, uint256 nftId) private view returns (bool) {
    //     for (uint256 i = 0; i < treasureBox.nftInfo.length; ++i) {
    //         if (treasureBox.nftInfo[i].nftIds == nftId) {
    //         return true;
    //     }
    // }
    // return false;
    // }

    function removeNFTAndReward(TreasureBox storage treasureBox, uint256 nftId) private {
        for (uint256 i = 0; i < treasureBox.nftInfo.length; ++i) {
            if (treasureBox.nftInfo[i].nftIds == nftId) {
                treasureBox.nftInfo[i] = treasureBox.nftInfo[treasureBox.nftInfo.length - 1];
                treasureBox.rewards[i] = treasureBox.rewards[treasureBox.rewards.length - 1];
                treasureBox.nftInfo.pop();
                treasureBox.rewards.pop();
                return;
            }
        }
    }

    function calculateRequiredDeposit(uint256 _numberOfTokens) internal view returns (uint256){
        uint256 required = _numberOfTokens * exchangeRate;
        return required;
    }

    function setExchangeRate(uint256 _value) external onlyOwner{
        exchangeRate = _value;
    }

    function distributeRaisedCoins(address _creator, uint256 _boxId, uint256 _nftId) internal {

        TreasureBox storage treasureBox = treasureBoxes[_creator][_boxId-1];

        // Calculate how much to distribute to each party
        uint256 distributionAmount = treasureBox.depositAmount / 3;
        console.log("distributionAmount: ", distributionAmount); 

        // Transfer to Platform
        transferFunds(myntistPlatformAddress, distributionAmount);

        // Transfer to TreasureBox Owner
        transferFunds(_creator, distributionAmount);

        // Effects    
        treasureBox.depositAmount -= distributionAmount * 3;
        nonFlushableAmount -= distributionAmount * 3 + treasureBox.depositAmount; // Decrement nonFlushableAmount with remainder

        treasureBox.depositAmount = 0; // Reset
        treasureBox.ethDistribution = true;

        emit CoinsDistributed(_creator, _boxId, _nftId, distributionAmount);
    }

    function fundToTreasureBox(address _creator, uint256 _boxId) external payable{
        TreasureBox storage treasureBox = treasureBoxes[_creator][_boxId-1];

        require(msg.value > 0, "Insufficient ETH/BNB");
        require(_boxId > 0 && _boxId <= treasureBoxes[_creator].length, "Invalid Box ID");
        require(!treasureBoxIsClaimed[_boxId], "Box already claimed");
        require(block.timestamp < treasureBox.claimDate, "Cannot Fund After Maturity");
        
        // Add the new deposit to the total deposit.
        treasureBox.depositAmount += msg.value;  

        nonFlushableAmount += msg.value; // Increment nonFlushableAmount

        // Add to the external deposit to keep track of it separately.
        treasureBox.externalDepositAmount += msg.value; // TBD
        
        emit TreasureBoxFunded(msg.sender, msg.value, block.timestamp);
    }

    // Owner of the contract recieve ETH
    function flushContractBalanceToOwner() external onlyOwner
    {
        uint256 flushableAmount = address(this).balance - nonFlushableAmount;
        require(address(this).balance != 0 && flushableAmount != 0, "MYNT: No Value to flush");
        transferFunds(FLUSH_ADDR, flushableAmount); 
    }

    function transferFunds(address _recipient, uint256 _amount) private {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Transfer fee failed");
    }
}

// ["https:QaADAsdasfeSDf/1.json", "https:QaADAsdasfeSDf/2.json", "https:QaADAsdasfeSDf/3.json"]

// 1698982892 // 1697531417 30
// [[1,2],[2,4],[3,6]]   [[4,2],[5,4],[6,6]]  [[7,2],[8,4],[9,6]]
// 500000000000000000
// 0xDEC9f2793e3c17cd26eeFb21C4762fA5128E0399

// TASK: create & Claim should work properly