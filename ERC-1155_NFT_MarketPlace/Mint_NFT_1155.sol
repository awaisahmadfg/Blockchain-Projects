// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

contract Minting is Initializable, ERC1155URIStorageUpgradeable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    // State Variables ---------------------------------------------------------------------- //

    string public name ;
    uint256 public constant price = 60000000000000000; // 0.06 ether; // 120000000000000000
    
    uint256 public currentNFTLimit;
    address private fundReceivor; 

    // This modifier only allows the FundReceivor to call the function
    modifier onlyFundReceivor() {
        require(msg.sender == fundReceivor, "Only the contract fundReceivor can call this function");
        _; 
    }

    struct NFT{
        address minter;
        uint256 royaltyPercentage;
        address royaltyReceiver;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name)  initializer public
    {
         name = _name ;
         fundReceivor = msg.sender;
         currentNFTLimit = 100;
        __ERC1155_init("MintsClub");
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    // Mappings------------------------------------------------------------------------------ //
    mapping (uint256 => NFT) public nft;
    mapping(address => mapping(uint => bool)) private ownerOf;

    // Events-------------------------------------------------------------------------------- //
    event Mints(address minter , uint256 tokenid , uint256 amount , uint256 royaltyFeePercentage);
    event BatchMints(address minter , uint256[] tokenid , uint256[] amount , uint256[] royaltyFeePercentage);  
    event LazyMints(address minter , address fundReceivor , uint256 tokenid , uint256 amount , uint256 royaltyFeePercentage); 

    // functions----------------------------------------------------------------------------- //
    
    function ChangeNFTAmountLimit(uint256 _amount) public onlyOwner returns (uint256) {
        require(_amount != 0, "NFT amount cannot be zero");
        currentNFTLimit = _amount;
        return currentNFTLimit;
    }

    function fgetRoyaltyFeeInPBP(uint256 _tokenId) external view returns (uint256 _royaltyfee)
    {
        return nft[_tokenId].royaltyPercentage;
    }

    // get royalty reciver address
    function fGetRoyaltyReceiver(uint256 _tokenid) external view returns(address reciver)
    {
        return nft[_tokenid].royaltyReceiver;
    }

    function lazyMintNft( uint256 _tokenId , uint256 _amount , string memory _tokenUri , uint256 _royaltyFeePercentage) external payable whenNotPaused
    {
        require(_tokenId != 0, "TokenId cannot be 0");
        require(msg.value == price, "Payment must be equal to the required price.");
        require(_amount > 0 && _amount <= 100, "Each NFT can have no more than 100 copies and amount cannot be zero");
        require(bytes(_tokenUri).length > 0, "tokenuri cannot be empty");
        require(_royaltyFeePercentage >= 150 && _royaltyFeePercentage <= 2000 , "Royalties  should be in between from 1.5 % to 20%");
        require(!ownerOf[msg.sender][_tokenId] , "Token already exists");
        
        _mint(msg.sender,_tokenId,_amount,"0x00");
        _setURI(_tokenId, _tokenUri);
        ownerOf[msg.sender][_tokenId] = true;

        nft[_tokenId] = NFT({
            minter: msg.sender,
            royaltyPercentage: _royaltyFeePercentage,
            royaltyReceiver: msg.sender
        });

        emit LazyMints(msg.sender , fundReceivor ,_tokenId , _amount , _royaltyFeePercentage);
    }

    function creatorFunds() payable public onlyFundReceivor {
        require(address(this).balance > 0, "Ether balance is 0 in contract");
        (bool success, ) = payable(fundReceivor).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Single Minting 
    function mintNft(uint256 _tokenId , uint256 _amount , string memory _tokenUri , uint256 _royaltyFeePercentage) external payable whenNotPaused
    {
        require(_tokenId != 0, "TokenId cannot be 0");
        require(msg.value == price, "Payment must be equal to the required price.");
        require(_amount > 0 && _amount <= 100, "Invalid amount: NFT amount must be between 1 and 100"); 
        require(bytes(_tokenUri).length > 0, "tokenuri cannot be empty");
        require(_royaltyFeePercentage >= 150 && _royaltyFeePercentage <= 2000 , "Royalties can't be greater than 20%");
        require(!ownerOf[msg.sender][_tokenId] , "Token already exists");

        _mint(msg.sender,_tokenId,_amount,"0x00");
        _setURI(_tokenId, _tokenUri);
        ownerOf[msg.sender][_tokenId] = true;

        nft[_tokenId] = NFT({
            minter: msg.sender,
            royaltyPercentage: _royaltyFeePercentage,
            royaltyReceiver: msg.sender
        });
        
        emit Mints(msg.sender,_tokenId,_amount,_royaltyFeePercentage);
    }

    // Batch Minting
    // Setting Differnet Royalty for differnt token ids
    function mintBatch( uint256[] memory _tokenIds, uint256[] memory _amounts, string[] memory _tokenUris, uint256[] memory _royaltyFeePercentage) external payable whenNotPaused
    { 
        require(_tokenUris.length == _amounts.length && _tokenIds.length == _amounts.length && _tokenIds.length == _royaltyFeePercentage.length, "Array lengths must match");
        require(_tokenIds.length * price == msg.value, "Incorrect payment amount");

        uint256 len = _tokenIds.length;
        
        for (uint256 i = 0; i < len; i++)
        {
            require(ownerOf[msg.sender][_tokenIds[i]] == false, "Token already exists");
            require(_amounts[i] <= 100, "Each NFT can have no more than 100 copies"); 
            require(_royaltyFeePercentage[i] >= 150 && _royaltyFeePercentage[i] <= 2000 , "Royalties  should be in between from 1.5 % to 20%");
            require(!ownerOf[msg.sender][_tokenIds[i]] , "Token already exists");

            _setURI(_tokenIds[i], _tokenUris[i]);
            ownerOf[msg.sender][_tokenIds[i]] = true;

            nft[_tokenIds[i]] = NFT({
                minter: msg.sender,
                royaltyPercentage: _royaltyFeePercentage[i],
                royaltyReceiver: msg.sender
            });
        } 
        _mintBatch(msg.sender, _tokenIds, _amounts, "0x00");
        emit BatchMints(msg.sender,_tokenIds,_amounts,_royaltyFeePercentage);
    }

    // Edit NFT
    function EditNFTUri(uint256 tokenId, string memory newUri) public  
    {
        require(ownerOf[msg.sender][tokenId] == true, "You are not the Owner");
        _setURI(tokenId, newUri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}