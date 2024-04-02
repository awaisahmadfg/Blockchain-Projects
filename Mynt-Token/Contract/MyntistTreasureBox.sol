// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IGlobals.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "hardhat/console.sol";

contract MyntistTreasureBox {

    /* ============== State Variables ============= */
    IGlobals public GlobalsInstance;
    uint256 private constant MAX_DEPOSIT = 100 ether;
    uint256 private constant ANNUAL_INTEREST_PERCENT = 10;
    address public myntistPlatformAddress;
    uint256 public nonFlushableAmount;
    uint256 public nextBoxId = 1;

    /* ================== Structs ================= */
    struct NftInfo {
        address nftContract;
        uint256 nftId;
        uint256 nftValue;
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
   //  mapping(address => TreasureBox[]) public treasureBoxes;
    mapping(uint256 => TreasureBox) public treasureBoxes;
    mapping(uint256 => mapping(uint256 => NftInfo)) public nftInfoMap;
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
        address creator,
        uint256 amount,
        uint256 fundedAt
    );

    event CoinsDistributed(
        address indexed treasureBoxOwner,
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
    constructor(address _myntContractAddress, address _walletAddress) {
        GlobalsInstance = IGlobals(_myntContractAddress);
        myntistPlatformAddress = _walletAddress;
    }

    /* ================== Functions =============== */
    function isERC721(address contractAddress) internal view returns (bool) {
        return ERC165Checker.supportsInterface(contractAddress, type(IERC721).interfaceId);
    }

    function isERC1155(address contractAddress) internal view returns (bool) {
        return ERC165Checker.supportsInterface(contractAddress, type(IERC1155).interfaceId);
    }

    function checkTokenOwnerType(address contractAddress, uint256 tokenId) internal view returns (bool) {
        if (isERC721(contractAddress)) {
            return IERC721(contractAddress).ownerOf(tokenId) == msg.sender;
        } else if (isERC1155(contractAddress)) {
            return IERC1155(contractAddress).balanceOf(msg.sender, tokenId) > 0;
        } else {
            revert("Unsupported NFT standard");
        }
    }

    function calculateDailyInterestRate() private pure returns (uint256) {
        return ANNUAL_INTEREST_PERCENT * 1e18 / 365 / 100;
    }

    function calculateReward(uint256 depositAmount, uint256 totalEth, uint256 userInterest) private pure returns (uint256) {
        return userInterest * depositAmount / totalEth;
    }

    function createTreasureBox(uint256 _claimDate, NftInfo[] calldata _nftInfos) external payable {
        require(_claimDate > block.timestamp, "Claim date must be in the future");
        require(_nftInfos.length > 0, "At least one NFT required");
        require(msg.value > 0 && msg.value <= MAX_DEPOSIT, "Deposit out of range");

        // TreasureBox storage newBox = treasureBoxes[msg.sender].push();
        TreasureBox storage newBox = treasureBoxes[nextBoxId];
        newBox.creator = msg.sender;
        newBox.depositAmount = msg.value;
        newBox.claimDate = _claimDate;
        newBox.remainingNfts = _nftInfos.length;
        newBox.ethDistribution = false;

        uint256 totalEth = nonFlushableAmount += msg.value;
        uint256 daysDifference = (_claimDate - block.timestamp) / 1 days;
        uint256 userInterest = daysDifference * calculateDailyInterestRate();
        uint256 myntTokens = calculateReward(msg.value, totalEth, userInterest);
        newBox.totalMyntReward = myntTokens;
        
        distributeRewardToNFTOwner(nextBoxId, _nftInfos, myntTokens);

        emit TreasureBoxCreated(msg.sender, nextBoxId, _claimDate, msg.value, myntTokens);
        nextBoxId++;
    }

    function distributeRewardToNFTOwner(uint256 boxId, NftInfo[] calldata _nftInfos, uint256 _totalMyntReward) private {
        uint256 totalNftValue = 0;
       
        for (uint256 i = 0; i < _nftInfos.length; ++i) {
            totalNftValue += _nftInfos[i].nftValue;
        }

        for (uint256 i = 0; i < _nftInfos.length; ++i) {
            require(_nftInfos[i].nftId > 0 && _nftInfos[i].nftValue > 0, "NFT ID and value must be greater than zero.");
            require(checkTokenOwnerType(_nftInfos[i].nftContract, _nftInfos[i].nftId), "Caller does not own the NFTs");

            uint256 reward = (_nftInfos[i].nftValue * _totalMyntReward) / totalNftValue;
            
            rewards[boxId][_nftInfos[i].nftId] = reward;
            nftInfoMap[boxId][_nftInfos[i].nftId] = NftInfo(_nftInfos[i].nftContract, _nftInfos[i].nftId, _nftInfos[i].nftValue);
            require(!nftUsed[_nftInfos[i].nftContract][_nftInfos[i].nftId], "NFT already used in a treasure box");
            nftUsed[_nftInfos[i].nftContract][_nftInfos[i].nftId] = true;
        }
    }

    function claimTreasureBox(uint256 _boxId, uint256 _nftId) external {
        require(_boxId > 0 && _boxId < nextBoxId, "Invalid box ID");
        TreasureBox storage box = treasureBoxes[_boxId];
        require(box.creator != address(0), "TreasureBox does not exist.");
        require(box.remainingNfts > 0, "No NFTs left to claim");
        // require(block.timestamp >= box.claimDate, "Too early to claim");
        
        NftInfo storage nftInfo = nftInfoMap[_boxId][_nftId];
        require(nftInfo.nftId != 0, "NFT ID Not found in Treasure Box");
        require(checkTokenOwnerType(nftInfo.nftContract, nftInfo.nftId), "Caller is not the NFT owner");

        uint256 rewardAmount = rewards[_boxId][_nftId];
        require(rewardAmount > 0, "No reward for this NFT");

        GlobalsInstance.mint(msg.sender, rewardAmount, GlobalsInstance.getTreasureBoxAddress());

        if (box.depositAmount > 0){
            distributeRaisedCoins(box.creator, _boxId, _nftId);
        }

        box.remainingNfts -= 1;
        box.totalMyntReward -= rewardAmount;

        delete nftInfoMap[_boxId][_nftId];
        delete rewards[_boxId][_nftId];

        if (box.remainingNfts == 0) {
            delete  treasureBoxes[_boxId];
        }

        emit RewardClaimed(msg.sender, _boxId, _nftId, rewardAmount);
    }

    function distributeRaisedCoins(address _creator, uint256 _boxId, uint256 _nftId) internal {
        // TreasureBox storage treasureBox = treasureBoxes[_creator][_boxId - 1];
        TreasureBox storage treasureBox = treasureBoxes[_boxId];

        // Calculate how much to distribute to each party
        uint256 distributionAmount = treasureBox.depositAmount / 3;

        transferFunds(myntistPlatformAddress, distributionAmount);
        transferFunds(_creator, distributionAmount);

        // Effects
        treasureBox.depositAmount -= distributionAmount * 3;
        nonFlushableAmount -= distributionAmount * 3 + treasureBox.depositAmount; // Decrement nonFlushableAmount with remainder

        treasureBox.depositAmount = 0; // Reset
        treasureBox.ethDistribution = true;

        emit CoinsDistributed(_creator, _boxId, _nftId, distributionAmount);
    }

    function fundEthToTreasureBox(address _creator, uint256 _boxId) external payable
    {
        // TreasureBox storage treasureBox = treasureBoxes[_creator][_boxId - 1];
        TreasureBox storage treasureBox = treasureBoxes[_boxId];

        require(msg.value > 0, "Insufficient ETH/BNB");
        // require(treasureBoxes[_creator].length > 0, "Invalid Creator Address");
        require(treasureBox.creator != address(0), "TreasureBox does not exist.");
        require(_boxId > 0 && _boxId < nextBoxId, "Invalid Box ID");
        require(block.timestamp < treasureBox.claimDate,"Cannot Fund After Maturity");

        // Add the new deposit to the total deposit.
        treasureBox.depositAmount += msg.value;

        nonFlushableAmount += msg.value; // Increment nonFlushableAmount

        emit TreasureBoxFunded(msg.sender, _creator, msg.value, block.timestamp);
    }

    function fundTokensToTreasureBox(address _creator, uint256 _boxId, uint256 _myntTokens) external 
    {
        // TreasureBox storage treasureBox = treasureBoxes[_creator][_boxId -1 ];
        TreasureBox storage treasureBox = treasureBoxes[_boxId];

        require(_myntTokens > 0, "Insufficient Mynt Tokens" );
        // require(treasureBoxes[_creator].length > 0, "Invalid Creator Address");
        // require(_boxId > 0 && _boxId <= treasureBoxes[_creator].length, "Invalid Box ID");
        require(treasureBox.creator != address(0), "TreasureBox does not exist.");
        require(_boxId > 0 && _boxId < nextBoxId, "Invalid Box ID");
        require(block.timestamp < treasureBox.claimDate,"Cannot Fund After Maturity");

        // Transfer Mynt tokens to the treasure box
        bool success = GlobalsInstance.transferFrom(msg.sender, _creator, _myntTokens);
        require(success, "Transfer failed");

        treasureBox.totalMyntReward += _myntTokens; 
 
        emit TreasureBoxFunded(msg.sender, _creator, _myntTokens, block.timestamp);
    }

    // Owner of the contract recieve ETH
    function flushContractBalanceToOwner() external onlyOwner {
        uint256 flushableAmount = address(this).balance - nonFlushableAmount;
        require(address(this).balance != 0 && flushableAmount != 0, "MYNT: No Value to flush");
        transferFunds(GlobalsInstance.FLUSH_ADDR(), flushableAmount);
    }

    function transferFunds(address _recipient, uint256 _amount) private {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Transfer fee failed");
    }
}

// ["https:QaADAsdasfeSDf/1.json", "https:QaADAsdasfeSDf/2.json", "https:QaADAsdasfeSDf/3.json"]

// 1712484909
// [[1,2],[2,4],[3,6]]   [[4,2],[5,4],[6,6]]  [[7,2],[8,4],[9,6]]
// 500000000000000000
// [["0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D", 1,2],["0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D", 2,4],["0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D", 3,6]]    
// [["0x0245E4d26621E8aCbB153f6358BEF708e3f99De1", 4,2],["0x0245E4d26621E8aCbB153f6358BEF708e3f99De1", 5,4],["0x0245E4d26621E8aCbB153f6358BEF708e3f99De1", 6,6]]  
