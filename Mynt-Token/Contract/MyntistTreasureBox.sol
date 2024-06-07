// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IGlobals.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./IFMYNT.sol";
import "hardhat/console.sol";

/**
 * @dev Interface of FMYNT for the ERC20 token standard.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title Myntist Treasure Box
 * @dev A contract for creating and managing treasure boxes with NFTs, Mynt Tokens and ETH rewards.
 */
contract TreasureBoxFmynt {

    /* ============== State Variables ============= */
    IGlobals private GLOBALS_INSTANCE;
    IFMYNT private FMYNT_INSTANCE;
    IERC20 private immutable foundersMyntContract;
    IERC20 private myntContract;
    address payable immutable ORIGIN_ADDRESS;
    bool private isMainMyntLaunched;

    uint256 private constant MAX_ETH_DEPOSIT = 100 ether;
    uint256 private constant MAX_TOKENS_DEPOSIT = 10000 ether;
    uint256 private constant ANNUAL_INTEREST_SCALE = 1e9;
    uint256 private constant ANNUAL_INTEREST_PERCENT = 2; // TBD
    uint256 private constant DAILY_INTEREST_RATE = (ANNUAL_INTEREST_PERCENT * ANNUAL_INTEREST_SCALE) / 365;
    uint256 private constant MIN_CREATION_DAYS = 1 days;
    uint256 private constant MAX_CREATION_DAYS = 729 days;
    uint256 private constant MIN_NFT = 1;
    uint256 private constant MAX_NFTS = 3;

    uint256 private nonFlushableEthAmount;   
    uint256 private nonFlushableTokenAmount;   
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
        uint256 totalReward;
        uint256 claimDate;
        uint256 remainingNfts;
        bool distribution;
        bool isBoxClaimed;
        bool isEthDeposit;
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
        uint256 linkedNfts,
        uint256 claimDate,
        uint256 depositAmount,
        uint256 totalReward,
        bool isEthdeposit
    );
    
    event RewardClaimed(
        address indexed claimer,
        uint256 indexed boxId,
        uint256 indexed nftId,
        uint256 rewardAmount,
        bool isClaimed
    );

    event TreasureBoxEthFunded(
        address indexed funder,
        uint256 boxId,
        uint256 amount,
        uint256 fundedAt
    );

    event TreasureBoxTokensFunded(
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

    event EthersFlushed(
        uint256 _amount, 
        address owner
    );

    event TokensFlushed(
        uint256 _amount, 
        address owner
    );

    /* ================== Modifier =============== */
    modifier onlyOwner() {
        require(msg.sender == ORIGIN_ADDRESS, "Only owner can call this function");
    
        _;
    }

    /* ============== Constructor ============= */
    /**
     * @dev Constructor sets the global settings for the contract.
     * @param _foundersMyntContractAddress The address of the ERC20 contract for the Founders Mynt tokens.
     * @notice This constructor initializes the Founders Mynt contract address and sets the origin address to the address deploying the contract.
     */
    constructor(address _foundersMyntContractAddress) {
        foundersMyntContract = IERC20(_foundersMyntContractAddress);
        FMYNT_INSTANCE = IFMYNT(_foundersMyntContractAddress);
        ORIGIN_ADDRESS = payable(msg.sender);
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
     * @dev Calculates the total interest of user and returns the reward based on deposit.
     * @param _claimDate The future date when the box can be claimed.
     * @param _depositAmount The amount of ETH/Tokens deposited.
     * @param isEthDeposit A boolean indicating if the deposit amount is in ETH (true) or tokens (false).
     * @return uint256 representing the calculated reward.
     */
    function calculateReward(uint256 _claimDate, uint256 _depositAmount, bool isEthDeposit) private view returns (uint256) {

        // Calculate Tokens
        uint256 daysDifference = (_claimDate - block.timestamp) / 1 days;
        uint256 userTotalInterest = daysDifference * DAILY_INTEREST_RATE;

        if (isEthDeposit) {
            return (userTotalInterest * _depositAmount) / 1e18;
        } else {
            return (userTotalInterest * _depositAmount);
        }
    }

    /**
     * @dev Creates a new treasure box with ETH instead of tokens.
     * @notice Requires a future claim date, at least one NFT, and deposit within allowed range.
     * @param _claimDate The future date when the box can be claimed.
     * @param _nftInfos Array of NftInfo structs detailing the NFTs included in the box.
     */
    function createTreasureBoxWithEth(uint256 _claimDate, NftInfo[] calldata _nftInfos) external payable {
        uint256 rewardTokens = calculateRewardEthToTokens(_claimDate, _nftInfos, msg.value);

        if (!isMainMyntLaunched) {
            uint256 treasureBoxAssets = FMYNT_INSTANCE.getTreasureBoxAssests();
            console.log("treasureBoxAssets, ", treasureBoxAssets);
            require(rewardTokens <= treasureBoxAssets, "Reward exceeds from treasure box available supply");
        } else{
            require(GLOBALS_INSTANCE.treasureBoxAddress() != address(0), "TreasureBox address is not set");
        }

        _boxIds.increment();
        uint256 newBoxId = _boxIds.current();
        
        // Saves info
        TreasureBox storage newBox = treasureBoxes[newBoxId];
        newBox.totalReward = rewardTokens;
        newBox.creator = msg.sender;
        newBox.depositAmount = msg.value;
        newBox.claimDate = _claimDate;
        newBox.remainingNfts = _nftInfos.length;
        newBox.isEthDeposit = true;
        nonFlushableEthAmount += msg.value;
        
        // Distribute myntRewardTokens base on NftValue  
        allocateNFTRewards(newBoxId, _nftInfos, rewardTokens);

        emit TreasureBoxCreated(msg.sender, newBoxId, _nftInfos.length, _claimDate, msg.value, rewardTokens, newBox.isEthDeposit);
    }

    /**
     * @dev Creates a new treasure box with tokens instead of ETH.
     * @notice Requires a future claim date, at least one NFT, and deposit within allowed range.
     * @param _claimDate The future date when the box can be claimed.
     * @param _nftInfos Array of NftInfo structs detailing the NFTs included in the box.
     * @param _tokenAmount The amount of FMYNT/MYNT tokens to deposit.
    */
    function createTreasureBoxWithTokens(uint256 _claimDate, NftInfo[] calldata _nftInfos, uint256 _tokenAmount) external {
        uint256 rewardTokens = calculateRewardTokenToTokens(_claimDate, _nftInfos, _tokenAmount);
        
        _boxIds.increment(); 
        uint256 newBoxId = _boxIds.current(); 

        // Saves info
        TreasureBox storage newBox = treasureBoxes[newBoxId];
        newBox.totalReward = rewardTokens;
        newBox.creator = msg.sender;
        newBox.depositAmount = _tokenAmount;
        newBox.claimDate = _claimDate;
        newBox.remainingNfts = _nftInfos.length;
        newBox.distribution = false; 
        nonFlushableTokenAmount += _tokenAmount;

        // Distribute myntRewardTokens based on NftValue  
        allocateNFTRewards(newBoxId, _nftInfos, rewardTokens);

        if (!isMainMyntLaunched) {
            // require(FMYNT_INSTANCE.treasureBoxAddress() != address(0), "Treasure box address is not set in FMYNT");
            require(FMYNT_INSTANCE.TREASURE_BOX() != address (0), "Treasure box address is not set in FMYNT");
            // require(rewardTokens <= FMYNT_INSTANCE.TREASURE_BOX_SUPPLY_CAP() - FMYNT_INSTANCE.treasureBoxMintedAmount(), "Reward exceeds from treasure box available supply");
            uint256 treasureBoxAssets = FMYNT_INSTANCE.getTreasureBoxAssests();
            console.log("treasureBoxAssets, ", treasureBoxAssets);
            require(rewardTokens <= treasureBoxAssets, "Reward exceeds from treasure box available supply");
            require(foundersMyntContract.balanceOf(msg.sender) >= _tokenAmount, "Insufficient tokens in sender's account");
            require(foundersMyntContract.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed");
        } else {
            require(GLOBALS_INSTANCE.treasureBoxAddress() != address(0), "Treasure box address is not set in MYNT");
            require(GLOBALS_INSTANCE.balanceOf(msg.sender) >= _tokenAmount, "Insufficient tokens in sender's account");
            require(GLOBALS_INSTANCE.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed");
        }
        emit TreasureBoxCreated(msg.sender, newBoxId, _nftInfos.length, _claimDate, _tokenAmount, rewardTokens, newBox.isEthDeposit);
    }

    /**
     * @dev Calculates the reward tokens for a given ETH deposit for a future treasure box.
     * @notice Calculation based on the claim date and number of NFTs.
     * @param _claimDate The future date when the box can be claimed.
     * @param _nftInfos Array of NftInfo structs for calculation context.
     * @return uint256 representing the calculated reward tokens.
     */
    function calculateRewardEthToTokens(uint256 _claimDate, NftInfo[] calldata _nftInfos, uint256 _depositAmountinEth) public view returns (uint256) {
        require(_claimDate > block.timestamp, "Claim date must be in the future");
        require(_claimDate <= block.timestamp + MAX_CREATION_DAYS, "Claim date higher than maximum");
        require(_claimDate >= block.timestamp + MIN_CREATION_DAYS, "Claim date less than minimum");
        require(_nftInfos.length >= MIN_NFT && _nftInfos.length <= MAX_NFTS, "Number of NFTs must be between 1 and 3");
        require(_depositAmountinEth > 0 && _depositAmountinEth <= MAX_ETH_DEPOSIT, "Deposit out of range");
        // require(FMYNT_INSTANCE.treasureBoxMintedAmount() <= FMYNT_INSTANCE.TREASURE_BOX_SUPPLY_CAP(), "Cannot create, treasure box supply cap reached");
        require(FMYNT_INSTANCE.getTreasureBoxAssests() > 0, "Cannot create, treasure box supply cap reached");

        uint256 rewardTokens = calculateReward(_claimDate, _depositAmountinEth, true);
 
        return rewardTokens;
    }

    /**
     * @dev Calculates the reward tokens for a given FMYNT/MYNT deposit for a future treasure box.
     * @notice Calculation based on the claim date and number of NFTs.
     * @param _claimDate The future date when the box can be claimed.
     * @param _nftInfos Array of NftInfo structs for calculation context.
     * @param _depositAmountInTokens The deposit amount in token for which to calculate the reward tokens.
     * @return uint256 representing the calculated reward tokens.
     */
    function calculateRewardTokenToTokens(uint256 _claimDate, NftInfo[] calldata _nftInfos, uint256 _depositAmountInTokens) public view returns (uint256) {
        require(_claimDate > block.timestamp, "Claim date must be in the future");
        require(_claimDate <= block.timestamp + MAX_CREATION_DAYS, "Claim date higher than maximum");
        require(_claimDate >= block.timestamp + MIN_CREATION_DAYS, "Claim date less than minimum");
        require(_nftInfos.length >= MIN_NFT && _nftInfos.length <= MAX_NFTS, "Number of NFTs must be between 1 and 3");
        require(_depositAmountInTokens > 0 && _depositAmountInTokens <= MAX_TOKENS_DEPOSIT, "Deposit out of range");
        // require(FMYNT_INSTANCE.treasureBoxMintedAmount() <= FMYNT_INSTANCE.TREASURE_BOX_SUPPLY_CAP(), "Cannot create, treasure box supply cap reached");
        require(FMYNT_INSTANCE.getTreasureBoxAssests() > 0, "Cannot create, treasure box supply cap reached");

        uint256 rewardTokens = calculateReward(_claimDate, _depositAmountInTokens, false);
 
        return rewardTokens;
    }

    /**
     * @dev Allocates reward tokens rewards among the NFTs in a newly created treasure box based on their value.
     * @param boxId The ID of the treasure box being allocated rewards.
     * @param _nftInfos An array of NftInfo structs containing details of the NFTs included in the treasure box.
     * @param _totalReward The total reward tokens rewards available for distribution among the NFTs.
     */
    function allocateNFTRewards(uint256 boxId, NftInfo[] calldata _nftInfos, uint256 _totalReward) private {
        uint256 totalNftValue = 0;
       
        for (uint256 i = 0; i < _nftInfos.length; ++i) {
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
            uint256 reward = (_nftInfos[i].nftValue * _totalReward) / totalNftValue;

            // Update the states
            rewards[boxId][_nftInfos[i].nftId] = reward;
            nftInfoMap[boxId].push(NftInfo(_nftInfos[i].nftContract, _nftInfos[i].nftId, _nftInfos[i].nftValue, _nftInfos[i].amount));
            nftUsed[_nftInfos[i].nftContract][_nftInfos[i].nftId] = true;
        }
    }

    /**
     * @dev Owner Sets the main Mynt contract address.
     * @notice Only the contract owner can call this function.
     * @param _mainMyntContractAddress The address of the main Mynt contract.
    */
    function setMainMyntContract(address _mainMyntContractAddress) external onlyOwner {
        require(_mainMyntContractAddress != address(0), "Invalid Mynt contract address");
        myntContract = IERC20(_mainMyntContractAddress);
        GLOBALS_INSTANCE = IGlobals(_mainMyntContractAddress);
        isMainMyntLaunched = true;
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
        require(block.timestamp >= box.claimDate, "Too early to claim");

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
        require(rewards[_boxId][_nftId] != 0 , "Reward already claimed for this NFT");

        NftInfo memory nftInfo = nftInfoMap[_boxId][nftIndex];
        require(verifyNFTOwnershipAndType(nftInfo.nftContract, nftInfo.nftId), "Caller does not own the NFTs");
        uint256 rewardAmount = rewards[_boxId][_nftId];

        // Update the states
        box.remainingNfts -= 1;
        box.totalReward -= rewardAmount;
 
        if (box.remainingNfts == 0) {
            box.isBoxClaimed = true;
        }

        // Reward Mynt reward tokens
        if (isMainMyntLaunched) {
            require(GLOBALS_INSTANCE.treasureBoxAddress() != address(0), "Treasure box address is not set in MYNT");
            GLOBALS_INSTANCE.mint(msg.sender, rewardAmount, GLOBALS_INSTANCE.treasureBoxAddress());
        } else {
            // require(FMYNT_INSTANCE.treasureBoxMintedAmount() <= FMYNT_INSTANCE.TREASURE_BOX_SUPPLY_CAP(), "Cannot claim, treasure box supply cap reached");
            require(FMYNT_INSTANCE.getTreasureBoxAssests() > 0, "Cannot claim, treasure box supply cap reached");
            // require(rewardAmount <= (FMYNT_INSTANCE.TREASURE_BOX_SUPPLY_CAP() - FMYNT_INSTANCE.treasureBoxMintedAmount()), "Reward exceeds from treasure box available supply");
            // require(FMYNT_INSTANCE.treasureBoxAddress() != address(0), "Treasure box address is not set in FMYNT");
            // require(FMYNT_INSTANCE.TREASURE_BOX() != address(0), "Treasure box address is not set in FMYNT");
            // FMYNT_INSTANCE.mint(msg.sender, rewardAmount, FMYNT_INSTANCE.treasureBoxAddress());
            FMYNT_INSTANCE.transferReward(rewardAmount);
        }

        if (box.depositAmount > 0) {
            distributeRaisedCoins(_boxId, _nftId, box.isEthDeposit);
        }
 
        delete rewards[_boxId][_nftId];

        emit RewardClaimed(msg.sender, _boxId, _nftId, rewardAmount, box.isBoxClaimed);
    }

    /**
     * @dev Distributes the accumulated ETH/Tokens from a treasure box among the contract owner and the creator of the treasure box.
     * @param _boxId The ID of the treasure box from which ETH/Tokens will be distributed.
     * @param _nftId The ID of the NFT triggering the distribution. Used for event logging.
     * @param isEthDeposit A boolean indicating if the deposit amount is in ETH (true) or tokens (false).
     */
    function distributeRaisedCoins(uint256 _boxId, uint256 _nftId, bool isEthDeposit) private {
        TreasureBox storage treasureBox = treasureBoxes[_boxId];

        uint256 distributionAmount = treasureBox.depositAmount / 2;
        
        if (isEthDeposit){
            nonFlushableEthAmount -= treasureBox.depositAmount; 
            treasureBox.depositAmount = 0; 
            treasureBox.distribution = true;
            transferFundsToOrigin(ORIGIN_ADDRESS, distributionAmount, isEthDeposit);
        }else{
            nonFlushableTokenAmount -= treasureBox.depositAmount; 
            treasureBox.depositAmount = 0; 
            treasureBox.distribution = true;
            transferFundsToOrigin(ORIGIN_ADDRESS, distributionAmount, isEthDeposit);
        }
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
        require(_boxId > 0 && _boxId <= _boxIds.current(), "Invalid box Id");
        require(block.timestamp < treasureBox.claimDate,"Cannot fund after maturity");
        require(treasureBox.isEthDeposit, "This TreasureBox does not accept tokens deposits.");

        treasureBox.depositAmount += msg.value;
        nonFlushableEthAmount += msg.value;
        
        emit TreasureBoxEthFunded(msg.sender, _boxId, msg.value, block.timestamp);
    }

    /**
     * @dev Allows funding of a treasure box using Mynt contract _depositTokens, increasing the total reward amount available for rewards.
     * @notice The treasure box must exist and not have reached its claim date.
     * @param _boxId The ID of the treasure box to fund.
     * @param _depositTokens The amount of tokens to add to the treasure box's rewards.
     */
    function fundTokensToTreasureBox(uint256 _boxId, uint256 _depositTokens) public 
    {
        TreasureBox storage treasureBox = treasureBoxes[_boxId];
    
        require(_depositTokens > 0, "Insufficient Mynt Tokens" );
        require(_boxId > 0 && _boxId <= _boxIds.current(), "Invalid Box ID");
        require(block.timestamp < treasureBox.claimDate,"Cannot Fund After Maturity");
        require(!treasureBox.isEthDeposit, "This TreasureBox does not accept Eth.");

        treasureBox.depositAmount += _depositTokens;
        nonFlushableTokenAmount += _depositTokens;

        if (!isMainMyntLaunched){
            require(foundersMyntContract.balanceOf(msg.sender) >= _depositTokens, "Insufficient tokens in sender's account");
            require(foundersMyntContract.transferFrom(msg.sender, address(this), _depositTokens), "Transfer failed");
        }   
        else {
            require(GLOBALS_INSTANCE.transferFrom(msg.sender, address(this), _depositTokens), "Transfer failed");
        }
        
        emit TreasureBoxTokensFunded(msg.sender, _boxId, _depositTokens, block.timestamp);
    }

    /**
     * @dev Flushes the contract's balance to the owner's address, excluding non-flushable amounts.
     * @notice Only the contract owner can call this function.
     */
    function flushEthToOwner() public onlyOwner {
        uint256 flushableEthAmount = address(this).balance - nonFlushableEthAmount;
        require(flushableEthAmount > 0, "MYNT: No ETH to flush");
        transferFundsToOrigin(ORIGIN_ADDRESS, flushableEthAmount, true);
        emit EthersFlushed(flushableEthAmount, ORIGIN_ADDRESS);
    }

    /**
     * @dev Flushes the contract's token balance to the owner's address, excluding non-flushable amounts.
     * @notice Only the contract owner can call this function.
     */
    function flushTokensToOwner() public onlyOwner {
        uint256 flushableTokenAmount = foundersMyntContract.balanceOf(address(this)) - nonFlushableTokenAmount;
        require(flushableTokenAmount > 0, "MYNT: No tokens to flush");
        require(foundersMyntContract.transfer(ORIGIN_ADDRESS, flushableTokenAmount), "Token transfer failed");
        emit TokensFlushed (flushableTokenAmount, ORIGIN_ADDRESS);
    }

    /**
     * @dev Transfers the specified amount of ETH/Tokens to the given Origin Address.
     * @param _recipient The address of the recipient.
     * @param _amount The amount of ETH/Tokens to transfer.
     * @param isEthDeposit A boolean indicating if the deposit amount is in ETH (true) or tokens (false).
     */
    function transferFundsToOrigin(address _recipient, uint256 _amount, bool isEthDeposit) private {
        if (isEthDeposit){
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            require(success, "Transfer fee failed");
        }else{
            if (!isMainMyntLaunched) {
                require(foundersMyntContract.balanceOf(address(this)) >= _amount, "Insufficient tokens in TreasureBoxContract");
                require(foundersMyntContract.transfer(ORIGIN_ADDRESS, _amount), "Token transfer failed");
            } else {
                // require(GLOBALS_INSTANCE.treasureBoxAddress() != address(0), "Treasure box address is not set");
                require(foundersMyntContract.balanceOf(address(this)) >= _amount, "Insufficient tokens in TreasureBoxContract");
                require(foundersMyntContract.transfer(ORIGIN_ADDRESS, _amount), "Token transfer failed");
                }
            }
    }
}

// ["https:QaADAsdasfeSDf/1.json", "https:QaADAsdasfeSDf/2.json", "https:QaADAsdasfeSDf/3.json"]
// 1716614619,  [["0xB9e2A2008d3A58adD8CC1cE9c15BF6D4bB9C6d72", 1,2,0],["0xB9e2A2008d3A58adD8CC1cE9c15BF6D4bB9C6d72", 2,4,0],["0xB9e2A2008d3A58adD8CC1cE9c15BF6D4bB9C6d72", 3,6,0]]
// 1717139546
