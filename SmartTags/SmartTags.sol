// SPDX-License-Identifier: MIT

pragma solidity ^0.8.32;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title SmartTags
 * @notice ERC721-based Property Registration System for Real Estate Tokenization
 * @dev Allows authorized registrars to register and update property records
 * @dev UUPS Upgradeable Contract
 */
contract SmartTags is 
    Initializable,
    ERC721Upgradeable, 
    ERC721URIStorageUpgradeable, 
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable 
{
    // ============ State Variables ============
    uint256 private _nextTokenId;
    address public SUPER_ADMIN;

    // ============ Mappings ============
    mapping(uint256 => Property) private _properties;
    mapping(string => bool) private _usedCids;

    // ============ Structs ============
    
    /**
     * @notice Property structure storing essential property information
     * @param tokenId The unique digitel token ID
     * @param cid The IPFS Content Identifier
     * @param landOwner The address of the property owner
     */
    struct Property {
        uint256 tokenId;
        string cid;
        address landOwner;
    }

    // ============ Events ============
    
    /**
     * @notice Emitted when a new property is registered
     * @param tokenId The unique token ID of the registered property
     * @param landOwner The address of the property owner
     * @param cid The IPFS Content Identifier
     */
    event PropertyRegistered(
        uint256 indexed tokenId,
        address indexed landOwner,
        string cid
    );

    /**
     * @notice Emitted when a property's metadata is updated
     * @param tokenId The unique token ID of the updated property
     * @param updatedBy The address that performed the update
     * @param oldCid The previous IPFS Content Identifier
     * @param newCid The new IPFS Content Identifier
     */
    event PropertyUpdated(
        uint256 indexed tokenId,
        address indexed updatedBy,
        string oldCid,
        string newCid
    );

    // ============ Custom Errors ============

    error InvalidCID();
    error CIDAlreadyUsed();    
    error PropertyNotFound();    
    error SameCIDProvided();    
    error NotAuthorized();
    error InvalidAddress();

    // ============ Modifiers ============
    
    /**
     * @notice Restricts access to only the SUPER_ADMIN
     * @dev Uses custom error for gas efficiency
     */
    modifier onlyRegistrar() {
        if (msg.sender != SUPER_ADMIN) {
            revert NotAuthorized();
        }
        _;
    }

    // ============ Initializer ============
    
    /**
     * @notice Initializes the SmartTags contract
     * @dev Replaces constructor for upgradeable contracts
     */
    function initialize() public initializer {
        if (msg.sender == address(0)) {
            revert InvalidAddress();
        }
        
        __ERC721_init("SmartTags", "STA");
        __ERC721URIStorage_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        SUPER_ADMIN = msg.sender;
        _nextTokenId = 1;
    }

    // ============ External Functions ============
    
    /**
     * @notice Registers a new property by creating a Digitel Token id with IPFS metadata
     * @param cid The IPFS Content Identifier containing property metadata
     * @return tokenId The unique token ID assigned to the new property
     * @dev Requirements:
     * - `cid` must not be empty and within length limits
     * - `cid` must not have been used before
     */
    function registerLand(string calldata cid)
        external
        onlyRegistrar
        nonReentrant
        returns (uint256 tokenId)
    {   
        if (bytes(cid).length == 0) {
            revert InvalidCID();
        }

        if (_usedCids[cid]) {
            revert CIDAlreadyUsed();
        }

        // Generate new token ID with unchecked arithmetic for gas optimization
        tokenId = _nextTokenId;
        unchecked {
            _nextTokenId++;
        }

        _usedCids[cid] = true;
        _properties[tokenId] = Property({
            tokenId: tokenId,
            cid: cid,
            landOwner: SUPER_ADMIN
        });

        _safeMint(SUPER_ADMIN, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", cid)));

        emit PropertyRegistered(tokenId, SUPER_ADMIN, cid);
    }

    /**
     * @notice Updates the metadata of an existing property
     * @param tokenId The unique token ID of the property to update
     * @param newCid The new IPFS Content Identifier for the property metadata
     * @dev Requirements:
     * - `tokenId` must exist
     * - Caller must be either the SUPER_ADMIN
     * - `newCid` must not be empty and within length limits
     * - `newCid` must not have been used before
     * - `newCid` must be different from current CID
     */
    function updateProperty(uint256 tokenId, string calldata newCid)
        external
        onlyRegistrar
        nonReentrant
    {
        if (_ownerOf(tokenId) == address(0)) {
            revert PropertyNotFound();
        }

        if (bytes(newCid).length == 0) {
            revert InvalidCID();
        }

        if (_usedCids[newCid]) {
            revert CIDAlreadyUsed();
        }

        if (keccak256(bytes(_properties[tokenId].cid)) == keccak256(bytes(newCid))) {
            revert SameCIDProvided();
        }

        string memory oldCid = _properties[tokenId].cid;

        _usedCids[oldCid] = false;
        _usedCids[newCid] = true;
        _properties[tokenId].cid = newCid;

        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", newCid)));

        emit PropertyUpdated(tokenId, msg.sender, oldCid, newCid);
    }

    /**
     * @notice Retrieves the property information for a given token ID
     * @param tokenId The unique token ID of the property to query
     * @return Property struct containing the property's information
     * @dev Requirements:
     * - `tokenId` must exist
     */
    function getProperty(uint256 tokenId) external view returns (Property memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert PropertyNotFound();
        }
        return _properties[tokenId];
    }

    // ============ Public View Functions ============

    /**
     * @notice Checks if a CID has already been used
     * @param cid The IPFS Content Identifier to check
     * @return True if the CID has been used, false otherwise
     */
    function isCIDUsed(string calldata cid) external view returns (bool) {
        return _usedCids[cid];
    }

    /**
     * @notice Returns the next token ID that will be assigned
     * @return The next token ID
     */
    function getNextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    // ============ Required Overrides ============
    
    /**
     * @notice Returns the token URI for a given token ID
     * @param tokenId The unique token ID to query
     * @return The token URI (IPFS URL)
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @notice Checks if the contract supports a given interface
     * @param interfaceId The interface identifier to check
     * @return True if the interface is supported, false otherwise
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Internal function to burn a token and delete its URI
     * @param tokenId The unique token ID to burn
     * @dev Overrides ERC721URIStorageUpgradeable _burn function
     */
    function _burn(uint256 tokenId) 
        internal 
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable) 
    {
        super._burn(tokenId);
    }

    // ============ UUPS Upgrade Authorization ============
    
    /**
     * @notice Authorizes an upgrade of the contract
     * @dev Only SUPER_ADMIN can authorize upgrades
     * @param newImplementation The address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRegistrar
    {}
}
