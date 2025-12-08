// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title IdeaNFT (Upgradeable)
 * @dev Implements an ERC721 NFT contract with URI storage and contract ownership management.
 * Allows minting of NFTs with unique URIs and updates of token URIs.
 * This contract uses UUPS (Universal Upgradeable Proxy Standard) for upgradeability.
 */
contract IdeaNFT is 
    Initializable,
    ERC721Upgradeable, 
    ERC721URIStorageUpgradeable, 
    OwnableUpgradeable,
    UUPSUpgradeable 
{
    // Custom Errors
    error TokenURICannotBeEmpty();
    error TokenIDMustBeGreaterThanZero();
    error NotOwnerOfToken();
    error NFTHaveExpired();
    error OwnerAddressCannotBeZero();
    error AtLeastOneTokenIdRequired();
    error OwnerOfTokenIdDoesNotExist();

    // Constants
    uint256 public constant EXPIRY_DURATION = 365 days;

    // Storage variables
    uint256 public _tokenIds;

    /**
     * @notice Represents a NFT related informations
     */
    struct NFT {
        uint128 mintedAt; 
        uint128 expiryTime;
        address royaltyReciever;
    }

    /**
     * @notice Maps a token ID to its NFT Struct.
     * @dev This mapping ensures that each token has a designated address to receive royalty payments, NFT creation time and expiry time.
     */
    mapping(uint256 => NFT) public NFTInfo;

    /**
     * @notice Emitted when a new NFT is minted.
     * @dev Includes the address of the recipient, the token ID, and the token's URI.
     */
    event NFTMinted(address recieverAddress, uint256 tokenId, string tokenURI);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the ERC721 token with the name "IdeaNFT" and symbol "IDEANFT".
     * @dev Initializer function that replaces constructor for upgradeable contracts.
     */
    function initialize() public initializer {
        if (msg.sender == address(0)) revert OwnerAddressCannotBeZero();

        __ERC721_init("IdeaNFT", "IDEANFT");
        __Ownable_init(msg.sender);
        __ERC721URIStorage_init();
        __UUPSUpgradeable_init();

        _tokenIds = 1;
    }

    /**
     * @notice Mints a newly minted NFT and assigns it to the caller.
     * @param _tokenURI The URI to be associated with the newly minted NFT.
     * @return newItemId The ID of the newly minted NFT.
     */
    function mintNFT(string memory _tokenURI) public returns (uint256){
        if (bytes(_tokenURI).length == 0) revert TokenURICannotBeEmpty();

        uint256 newItemId = _tokenIds;

        NFTInfo[_tokenIds] = NFT({
            mintedAt: uint128(block.timestamp),
            expiryTime: uint128(block.timestamp + EXPIRY_DURATION),
            royaltyReciever: msg.sender
        });

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        
        unchecked {
            _tokenIds += 1;
        }

        emit NFTMinted(msg.sender, newItemId, _tokenURI);
        return newItemId;
    }

    /**
     * @notice Updates the URI of an existing NFT.
     * @param _tokenId The ID of the NFT whose URI is being updated.
     * @param _uri The new URI to be set for the NFT.
     */
    function setTokenUri(uint256 _tokenId, string memory _uri) public {
        if (_tokenId == 0) revert TokenIDMustBeGreaterThanZero();
        if (bytes(_uri).length == 0) revert TokenURICannotBeEmpty();
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOfToken();
        if (block.timestamp > uint256(NFTInfo[_tokenId].expiryTime)) revert NFTHaveExpired();

        _setTokenURI(_tokenId, _uri);
    }

    /**
     * @notice Fetches the royalty reciever address by a given tokenId.
     * @param _tokenId The tokenId of the NFT owner.
     * @return Royalty reciever address.
     */
    function getRoyaltyReciever(uint256 _tokenId) public view returns (address) {
        if (_tokenId == 0) revert TokenIDMustBeGreaterThanZero();
        if (ownerOf(_tokenId) == address(0)) revert OwnerOfTokenIdDoesNotExist();

        return NFTInfo[_tokenId].royaltyReciever;
    }

    /**
     * @notice Fetches the NFT expiry time by a given tokenId.
     * @param _tokenId The tokenId of the NFT owner.
     * @return NFT expiry time.
     */
    function getNFTExpireTime(uint256 _tokenId) public view returns (uint256) {
        if (_tokenId == 0) revert TokenIDMustBeGreaterThanZero();
        if (ownerOf(_tokenId) == address(0)) revert OwnerOfTokenIdDoesNotExist();

        return uint256(NFTInfo[_tokenId].expiryTime);
    }

    /**
     * @dev Restrict NFT transfers if the condition is met.
     * Override `safeTransferFrom` to include the restriction
     * @param _from The current owner of the NFT.
     * @param _to The address to which the NFT is being transferred.
     * @param _tokenId The ID of the NFT being transferred.
     * @param _data Extra data to pass with the transfer.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) 
        public override(ERC721Upgradeable, IERC721) 
    {
        if (block.timestamp > uint256(NFTInfo[_tokenId].expiryTime)) revert NFTHaveExpired();
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Restrict NFT transfers if the condition is met.
     * Override `transferFrom` to include the restriction
     * @param _from The current owner of the NFT.
     * @param _to The address to which the NFT is being transferred.
     * @param _tokenId The ID of the NFT being transferred.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) 
        public override(ERC721Upgradeable, IERC721) 
    {
        if (block.timestamp > uint256(NFTInfo[_tokenId].expiryTime)) revert NFTHaveExpired();
        super.transferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev Returns the URI for a given tokenID by calling ERC721URIStorage's implementation.
     * This is used to fetch the metadata of the token.
     * @param tokenId The identifier for an NFT.
     * @return string memory The token URI.
     */
    function tokenURI(uint256 tokenId) 
        public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Checks if the contract implements an interface as per the ERC165 standard.
     * This override ensures checks against ERC721 and ERC721URIStorage's interfaces.
     * @param interfaceId The identifier of the interface to check.
     * @return bool True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) 
        public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Authorizes upgrade of the contract. Only the owner can upgrade.
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
