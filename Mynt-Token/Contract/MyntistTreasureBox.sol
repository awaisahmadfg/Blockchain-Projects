// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IGlobals.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/**
 * @dev Interface for the ERC20 token standard.
 */
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title Myntist Treasure Box
 * @dev A contract for creating and managing treasure boxes with NFTs, Mynt Tokens and ETH rewards.
 */
contract MyntistTreasureBox {

    /* ============== State Variables ============= */
    IGlobals private immutable GlobalsInstance;
    IERC20 private immutable foundersMyntContract;
    address private immutable walletAddress;

    uint256 private constant MAX_DEPOSIT = 100 ether;
    uint256 private constant ANNUAL_INTEREST_SCALE = 1e8;
    uint256 private constant ANNUAL_INTEREST_PERCENT = 10;
    uint256 private constant DAILY_INTEREST_RATE = (ANNUAL_INTEREST_PERCENT * ANNUAL_INTEREST_SCALE) / 365;
    uint256 private constant MIN_CREATION_DAYS = 1 days;
    uint256 private constant MAX_CREATION_DAYS = 729 days;

    uint256 private nonFlushableAmount;   
    using Counters for Counters.Counter;
    Counters.Counter private _boxIds;

    /* ================== Structs ================= */
    struct NftInfo {
        address nftContract;
        uint256 nftId;
        uint256 nftValue;
        uint256 amount;
    }

    struct TreasureBox {
        address creator;
        uint256 depositAmount;
        uint256 totalMyntReward;
        uint256 claimDate;
        uint256 remainingNfts;
        bool ethDistribution;
    }

    /* ================== Mappings =============== */
    mapping(uint256 => TreasureBox) public treasureBoxes;
    mapping(uint256 => NftInfo[]) public nftInfoMap;
    mapping(uint256 => mapping(uint256 => uint256)) public rewards; 
    mapping(address => mapping(uint256 => bool)) private nftUsed;

    /* ================== Events ================= */
    event TreasureBoxCreated(
        address indexed creator,
        uint256 indexed boxId,
        uint256 claimDate,
        uint256 depositAmount,
        uint256 totalReward
    );
    
    event RewardClaimed(
        address indexed claimer,
        uint256 indexed boxId,
        uint256 indexed nftId,
        uint256 rewardAmount
    );

    event TreasureBoxFunded(
        address indexed funder,
        uint256 boxId,
        uint256 amount,
        uint256 fundedAt
    );

    event CoinsDistributed(
        uint256 indexed boxId,
        uint256 indexed nftId,
        uint256 distributionAmount
    );
    
    /* ================== Modifiers =============== */
    modifier onlyOwner() {
        require(msg.sender == GlobalsInstance.contractOwner(), "Only owner can call this function");
        _;
    }

    /* ============== Constructor ============= */

    /**
     * @dev Constructor sets the global settings for the contract.
     * @param _myntContractAddress Address of the IGlobals contract for Mynt token settings.
     * @param _walletAddress Address where ETH funds will be transferred.
     */
    constructor(address _myntContractAddress, address _walletAddress, address _foundersMyntContractAddress) {
        foundersMyntContract = IERC20(_foundersMyntContractAddress);
        GlobalsInstance = IGlobals(_myntContractAddress);
        walletAddress = _walletAddress;
    }

    /* ================== Functions =============== */
    
    /**
     * @dev Determines if the given address supports the ERC721 interface.
     * @param contractAddress The address of the contract to check.
     * @return bool indicating if the contract supports ERC721.
     */
    function isERC721(address contractAddress) private view returns (bool) {
        return ERC165Checker.supportsInterface(contractAddress, type(IERC721).interfaceId);
    }

    /**
     * @dev Determines if the given address supports the ERC1155 interface.
     * @param contractAddress The address of the contract to check.
     * @return bool indicating if the contract supports ERC1155.
     */
    function isERC1155(address contractAddress) private view returns (bool) {
        return ERC165Checker.supportsInterface(contractAddress, type(IERC1155).interfaceId);
    }

    /**
     * @dev Verifies the ownership and type (ERC721 or ERC1155) of an NFT.
     * @param contractAddress The address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @return bool indicating if the caller owns the NFT and if it's a supported type.
     */
    function verifyNFTOwnershipAndType(address contractAddress, uint256 tokenId) private view returns (bool) {
        if (isERC721(contractAddress)) {
            return IERC721(contractAddress).ownerOf(tokenId) == msg.sender;
        } else if (isERC1155(contractAddress)) {
            return IERC1155(contractAddress).balanceOf(msg.sender, tokenId) > 0;
        } else {
            revert("Unsupported NFT standard");
        }
    }

    /**
     * @dev Calculates the reward for a deposit based on the user's interest.
     * @param depositAmount The amount of ETH deposited.
     * @param userInterest The interest rate applied to the deposit.
     * @return uint256 representing the calculated reward.
     */
    function calculateReward(uint256 depositAmount, uint256 userInterest) private pure returns (uint256) {
        return (userInterest * depositAmount) / 1e18;
    }

    /**
     * @dev Creates a new treasure box with the given parameters.
     * @notice Requires a future claim date, at least one NFT, and deposit within allowed range.
     * @param _claimDate The future date when the box can be claimed.
     * @param _nftInfos Array of NftInfo structs detailing the NFTs included in the box.
     */
    function createTreasureBox(uint256 _claimDate, NftInfo[] calldata _nftInfos) external payable {
        require(_claimDate > block.timestamp, "Claim date must be in the future");
        require(_claimDate <= block.timestamp + MAX_CREATION_DAYS, "Claim date higher than maximum");
        require(_claimDate >= block.timestamp + MIN_CREATION_DAYS, "Claim date less than minimum");
        require(_nftInfos.length > 0, "At least one NFT required");
        require(msg.value > 0 && msg.value <= MAX_DEPOSIT, "Deposit out of range");

        // Calculate Tokens
        uint256 daysDifference = (_claimDate - block.timestamp) / 1 days;
        uint256 userInterest = daysDifference * DAILY_INTEREST_RATE;
        uint256 myntTokens = calculateReward(msg.value, userInterest);
        require(foundersMyntContract.balanceOf(address(this)) >= myntTokens, "Insufficient tokens in foundersMyntContract");

        _boxIds.increment(); 
        uint256 newBoxId = _boxIds.current(); 
        
        // Saves info
        TreasureBox storage newBox = treasureBoxes[newBoxId];
        newBox.totalMyntReward = myntTokens;
        newBox.creator = msg.sender;
        newBox.depositAmount = msg.value;
        newBox.claimDate = _claimDate;
        newBox.remainingNfts = _nftInfos.length;
        newBox.ethDistribution = false;
        nonFlushableAmount += msg.value;
        
        // Distribute myntTokens base on NftValue  
        allocateNFTRewards(newBoxId, _nftInfos, myntTokens);

        emit TreasureBoxCreated(msg.sender, newBoxId, _claimDate, msg.value, myntTokens);
    }

    /**
     * @dev Calculates the equivalent Mynt tokens for a given ETH deposit for a future treasure box.
     * @notice Calculation based on the claim date and number of NFTs.
     * @param _claimDate The future date when the box can be claimed.
     * @param _nftInfos Array of NftInfo structs for calculation context.
     * @param _depositAmountInEther The deposit amount in Ether for which to calculate the equivalent Mynt tokens.
     * @return uint256 representing the calculated Mynt tokens.
     */
    function calculateEthToMyntTokens(uint256 _claimDate, NftInfo[] calldata _nftInfos, uint256 _depositAmountInEther) public view returns (uint256) {
        require(_claimDate > block.timestamp, "Claim date must be in the future");
        require(_claimDate <= block.timestamp + MAX_CREATION_DAYS, "Claim date higher than maximum");
        require(_claimDate >= block.timestamp + MIN_CREATION_DAYS, "Claim date less than minimum");
        require(_nftInfos.length > 0, "At least one NFT required");

        // Convert ether value to wei
        uint256 _ethValueInWei = _depositAmountInEther * 1 ether;

        // Calculate Tokens
        uint256 daysDifference = (_claimDate - block.timestamp) / 1 days;
        uint256 userInterest = daysDifference * DAILY_INTEREST_RATE;
        uint256 myntTokens = calculateReward(_ethValueInWei, userInterest);
        return myntTokens;
    }

    /**
     * @dev Allocates Mynt token rewards among the NFTs in a newly created treasure box based on their value.
     * @param boxId The ID of the treasure box being allocated rewards.
     * @param _nftInfos An array of NftInfo structs containing details of the NFTs included in the treasure box.
     * @param _totalMyntReward The total Mynt token rewards available for distribution among the NFTs.
     */
    function allocateNFTRewards(uint256 boxId, NftInfo[] calldata _nftInfos, uint256 _totalMyntReward) private {
        uint256 totalNftValue = 0;
       
        for (uint256 i = 0; i < _nftInfos.length; ++i) {
            require(_nftInfos[i].nftId >= 1 && _nftInfos[i].nftId <= 9, "NFT ID must be in the range of 1 to 9");
            require(verifyNFTOwnershipAndType(_nftInfos[i].nftContract, _nftInfos[i].nftId ), "Caller does not own the NFTs");
            require(!nftUsed[_nftInfos[i].nftContract][_nftInfos[i].nftId], "NFT already used in a treasure box");

            NftInfo memory info = _nftInfos[i];
            if (isERC721(info.nftContract)) {
                require(info.amount == 0, "Amount must be zero for ERC721 tokens");
            }
            else if (isERC1155(info.nftContract)) {
                require(info.amount >= 1, "Amount should be greater or equal to one for ERC1155 tokens");
            } 
        
            totalNftValue += _nftInfos[i].nftValue;
        }
  
        for (uint256 i = 0; i < _nftInfos.length; ++i) {

            // Formula
            uint256 reward = (_nftInfos[i].nftValue * _totalMyntReward) / totalNftValue;

            // Update the states
            rewards[boxId][_nftInfos[i].nftId] = reward;
            nftInfoMap[boxId].push(NftInfo(_nftInfos[i].nftContract, _nftInfos[i].nftId, _nftInfos[i].nftValue, _nftInfos[i].amount));
            nftUsed[_nftInfos[i].nftContract][_nftInfos[i].nftId] = true;
        }
    }

    /**
     * @dev Allows the owner of an NFT within a specific treasure box to claim their share of the rewards.
     * @notice The treasure box must exist, and the NFT must be part of it. Rewards are claimed once.
     * @param _boxId The ID of the treasure box from which to claim rewards.
     * @param _nftId The ID of the NFT for which to claim rewards.
     */
    function claimTreasureBox(uint256 _boxId, uint256 _nftId) external {
        require(_boxId > 0 && _boxId <= _boxIds.current(), "Invalid box ID");
        TreasureBox storage box = treasureBoxes[_boxId];
        require(box.remainingNfts > 0, "No NFTs left to claim");
        // require(block.timestamp >= box.claimDate, "Too early to claim");
        
        // Finds NFT
        bool found = false;
        uint256 nftIndex;
        for (uint256 i = 0; i < nftInfoMap[_boxId].length; i++) {
            if (nftInfoMap[_boxId][i].nftId == _nftId) {
                found = true;
                nftIndex = i;
                break;
            }
        }

        require(found, "NFT ID Not found in Treasure Box");

        NftInfo memory nftInfo = nftInfoMap[_boxId][nftIndex];
        require(verifyNFTOwnershipAndType(nftInfo.nftContract, nftInfo.nftId), "Caller does not own the NFTs");
        uint256 rewardAmount = rewards[_boxId][_nftId];
        require(foundersMyntContract.balanceOf(address(this)) >= rewardAmount, "Insufficient tokens in foundersMyntContract");

        // Reward Mynt tokens and ETH
        require(foundersMyntContract.transfer(msg.sender, rewardAmount), "Token transfer failed");
        if (box.depositAmount > 0){
            distributeRaisedCoins(_boxId, _nftId);
        }

        // Update the states
        box.remainingNfts -= 1;
        box.totalMyntReward -= rewardAmount;

        delete rewards[_boxId][_nftId];
        if (box.remainingNfts == 0) {
            delete treasureBoxes[_boxId];
        }

        emit RewardClaimed(msg.sender, _boxId, _nftId, rewardAmount);
    }

    /**
     * @dev Distributes the accumulated ETH from a treasure box among the contract owner and the creator of the treasure box.
     * @param _boxId The ID of the treasure box from which ETH will be distributed.
     * @param _nftId The ID of the NFT triggering the distribution. Used for event logging.
     */
    function distributeRaisedCoins(uint256 _boxId, uint256 _nftId) private {
        TreasureBox storage treasureBox = treasureBoxes[_boxId];

        uint256 distributionAmount = treasureBox.depositAmount / 2;

        nonFlushableAmount -= treasureBox.depositAmount; 
        treasureBox.depositAmount = 0; 
        treasureBox.ethDistribution = true;

        transferFunds(walletAddress, distributionAmount);
        emit CoinsDistributed(_boxId, _nftId, distributionAmount);
    }

    /**
     * @dev Allows funding of a treasure box with ETH, increasing the total deposit amount available for rewards.
     * @notice The treasure box must exist and not have reached its claim date.
     * @param _boxId The ID of the treasure box to fund.
     */
    function fundEthToTreasureBox(uint256 _boxId) public payable
    {
        TreasureBox storage treasureBox = treasureBoxes[_boxId];

        require(msg.value > 0, "Insufficient ETH/BNB");
        require(_boxId > 0 && _boxId <= _boxIds.current(), "Invalid Box ID");
        require(block.timestamp < treasureBox.claimDate,"Cannot Fund After Maturity");

        treasureBox.depositAmount += msg.value;
        nonFlushableAmount += msg.value;

        emit TreasureBoxFunded(msg.sender, _boxId, msg.value, block.timestamp);
    }

    /**
     * @dev Allows funding of a treasure box with FoundersMynt tokens, increasing the total Mynt reward.
     * @notice The treasure box must exist and not have reached its claim date.
     * @param _boxId The ID of the treasure box to fund.
     * @param _myntTokens The amount of Mynt tokens to add to the treasure box's rewards.
     */
    function fundTokensToTreasureBox(address _ERC20TokenContract, uint256 _boxId, uint256 _myntTokens) public 
    {
        TreasureBox storage treasureBox = treasureBoxes[_boxId];
    
        require(_ERC20TokenContract != address(0), "Invalid ERC20 token contract address");
        require(_myntTokens > 0, "Insufficient Mynt Tokens" );
        require(_boxId > 0 && _boxId <= _boxIds.current(), "Invalid Box ID");
        require(block.timestamp < treasureBox.claimDate,"Cannot Fund After Maturity");

        treasureBox.totalMyntReward += _myntTokens; 

        bool success = IERC20(_ERC20TokenContract).transferFrom(msg.sender, treasureBox.creator, _myntTokens);
        require(success, "Transfer failed");
 
        emit TreasureBoxFunded(msg.sender, _boxId, _myntTokens, block.timestamp);
    }

    /**
     * @dev Flushes the contract's balance to the owner's address, excluding non-flushable amounts.
     * @notice Only the contract owner can call this function.
     */
    function flushContractBalanceToOwner() public onlyOwner {
        uint256 flushableAmount = address(this).balance - nonFlushableAmount;
        require(address(this).balance != 0 && flushableAmount != 0, "MYNT: No Value to flush");
        transferFunds(GlobalsInstance.FLUSH_ADDR(), flushableAmount);
    }

    /**
     * @dev Transfers the specified amount of ETH to the given recipient.
     * @param _recipient The address of the recipient.
     * @param _amount The amount of ETH to transfer.
     */
    function transferFunds(address _recipient, uint256 _amount) private {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Transfer fee failed");
    }
}

// ["https:QaADAsdasfeSDf/1.json", "https:QaADAsdasfeSDf/2.json", "https:QaADAsdasfeSDf/3.json"]

// 1723107685
// [["0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D", 1,2,1],["0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D", 2,4,1],["0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D", 3,6,1]] 
// [["0xe2899bddFD890e320e643044c6b95B9B0b84157A", 1,2,0],["0xe2899bddFD890e320e643044c6b95B9B0b84157A", 2,4,0],["0xe2899bddFD890e320e643044c6b95B9B0b84157A", 3,6,0]] 
