// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IdeaNFT
 * @dev Implements an ERC721 NFT contract with URI storage and contract ownership management.
 * Allows minting of NFTs with unique URIs and updates of token URIs.
 */
contract IdeaNFT is ERC721URIStorage, Ownable{
    uint256 private _tokenIds = 1;

    /**
     * @notice Initializes the ERC721 token with the name "Mindminer" and symbol "IdeaNFT".
     * @dev Constructor that sets up the token details and assigns the contract owner.
     */
    constructor() ERC721("Mindminer", "IdeaNFT") Ownable(msg.sender){}

    event NFTMinted(address from, uint256 tokenId, string tokenURI);

    /**
     * @notice Mints a newly minted NFT and assigns it to the caller.
     * @param _tokenURI The URI to be associated with the newly minted NFT.
     * @return newItemId The ID of the newly minted NFT.
     */
    function mintNFT(string memory _tokenURI) public returns (uint) {
        require(bytes(_tokenURI).length > 0, "Token URI cannot be empty");
        uint256 newItemId = _tokenIds;
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _tokenIds += 1;

        emit NFTMinted(msg.sender, newItemId, _tokenURI);
        return newItemId;
    }

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @param _newOwner The address of the new owner.
     */
    function setOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        transferOwnership(_newOwner);
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
        _setTokenURI(_tokenId, _uri);
    }

    /**
     * @notice Fetches the token Ids and token uris owned by a given address.
     * @param _owner The address of the token owner.
     * @return tokenIds and uris The list of token IDs and uris owned by the address.
     */
    function getTokenIdsAndUris(address _owner) public view returns (uint256[] memory, string[] memory) {
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
}
