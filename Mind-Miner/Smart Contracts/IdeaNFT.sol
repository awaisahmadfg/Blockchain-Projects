// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IdeaNFT
 * @dev Implements an ERC721 NFT contract with URI storage and contract ownership management.
 * Allows minting of NFTs with unique URIs and updates of token URIs.
 */
contract IdeaNFT is ERC721, ERC721URIStorage, Ownable{
    uint256 public _tokenIds = 1;

    /**
     * @notice Initializes the ERC721 token with the name "IdeaNFT" and symbol "IDEANFT".
     * @dev Constructor that sets up the token details and assigns the contract owner.
     */
    constructor() ERC721("IdeaNFT", "IDEANFT") Ownable(msg.sender){}

    /**
     * @notice Emitted when a new NFT is minted.
     * @dev Includes the address of the recipient, the token ID, and the token's URI.
     */
    event NFTMinted(address recieverAddress, uint256 tokenId, string tokenURI);

    /**
     * @notice Represents a NFT related informations
     */
    struct NFT {
        uint256 mintedAt;
        uint256 expiryTime;
        address royaltyReciever;
    }

    /**
     * @notice Maps a token ID to its NFT Struct.
     * @dev This mapping ensures that each token has a designated address to receive royalty payments, NFT creation time and expiry time.
     */
    mapping(uint256 => NFT ) public NFTInfo;

    /**
     * @notice Mints a newly minted NFT and assigns it to the caller.
     * @param _tokenURI The URI to be associated with the newly minted NFT.
     * @return newItemId The ID of the newly minted NFT.
     */
    function mintNFT(string memory _tokenURI) public returns (uint256){
        require(bytes(_tokenURI).length > 0, "Token URI cannot be empty");

        uint256 newItemId = _tokenIds;

        NFTInfo[_tokenIds] = NFT({
            mintedAt: block.timestamp,
            expiryTime: block.timestamp + 365 days,
            royaltyReciever: msg.sender
        });

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _tokenIds += 1;

        emit NFTMinted(msg.sender, newItemId, _tokenURI);
        return newItemId;
    }

    /**
     * @notice Updates the URI of an existing NFT.
     * @param _tokenId The ID of the NFT whose URI is being updated.
     * @param _uri The new URI to be set for the NFT.
     */
    function setTokenUri(uint256 _tokenId, string memory _uri) public {
        require(_tokenId > 0, "Token ID must be greater than zero");
        require(bytes(_uri).length > 0, "Token URI cannot be empty");
        require(ownerOf(_tokenId) == msg.sender, "Not owner of token");
        require(block.timestamp <= NFTInfo[_tokenId].expiryTime, "NFT have expired");

        _setTokenURI(_tokenId, _uri);
    }

    /**
     * @notice Fetches the token Ids and token uris owned by a given address.
     * @param _owner The address of the token owner.
     * @return tokenIds and uris The list of token IDs and uris owned by the address.
     */
    function getTokenIdsAndUris(address _owner) public view returns (uint256[] memory, string[] memory) {
        require(_owner != address(0), "Owner address can't be zero");
        require(balanceOf(_owner) >=1, "Atleast one token Id required");

        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        string[] memory uris = new string[](tokenCount);
        uint256 index = 0;

        for (uint256 tokenId = 1; tokenId < _tokenIds; tokenId++) {
            if (ownerOf(tokenId) == _owner) {
                tokenIds[index] = tokenId;
                uris[index] = tokenURI(tokenId);
                index++;
            }
        }

        return (tokenIds, uris);    
    }

    /**
     * @notice Fetches the royalty reciever address by a given tokenId.
     * @param _tokenId The tokenId of the NFT owner.
     * @return Royalty reciever address.
     */
    function getRoyaltyReciever(uint256 _tokenId) public view returns (address) {
        require(_tokenId > 0, "Token ID must be greater than zero");
        require(ownerOf(_tokenId) != address(0), "Owner of this token Id does not exists");

        return NFTInfo[_tokenId].royaltyReciever;
    }

    /**
     * @notice Fetches the NFT expiry time by a given tokenId.
     * @param _tokenId The tokenId of the NFT owner.
     * @return NFT expiry time.
     */
    function getNFTExpireTime(uint256 _tokenId) public view returns (uint256) {
        require(_tokenId > 0, "Token ID must be greater than zero");
        require(ownerOf(_tokenId) != address(0), "Owner of this token Id does not exists");

        return NFTInfo[_tokenId].expiryTime;
    }

    /**
     * @dev Restrict NFT transfers if the condition is met.
     * Override `safeTransferFrom` to include the restriction
     * @param _from The current owner of the NFT.
     * @param _to The address to which the NFT is being transferred.
     * @param _tokenId The ID of the NFT being transferred.
     * @param _data Extra data to pass with the transfer.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override(ERC721, IERC721)  {
        require(block.timestamp <= NFTInfo[_tokenId].expiryTime, "NFT have expired");
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Restrict NFT transfers if the condition is met.
     * Override `transferFrom` to include the restriction
     * @param _from The current owner of the NFT.
     * @param _to The address to which the NFT is being transferred.
     * @param _tokenId The ID of the NFT being transferred.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public override(ERC721, IERC721) {
        require(block.timestamp <= NFTInfo[_tokenId].expiryTime, "NFT have expired");
        super.transferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev Returns the URI for a given tokenID by calling ERC721URIStorage's implementation.
     * This is used to fetch the metadata of the token.
     * @param tokenId The identifier for an NFT.
     * @return string memory The token URI.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Checks if the contract implements an interface as per the ERC165 standard.
     * This override ensures checks against ERC721 and ERC721URIStorage's interfaces.
     * @param interfaceId The identifier of the interface to check.
     * @return bool True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
