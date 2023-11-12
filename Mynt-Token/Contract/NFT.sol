// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyntistERC721 is ERC721, Ownable, ERC721URIStorage, ERC721Burnable{
    /* ============ Mutable Variables ============ */
    uint256 public noOfTokenId = 0;

    /* =============== Constructor =============== */
    constructor() ERC721("MyntistNFT", "MNFT") {}

    /* ================== Events ================= */
    event Minted(address indexed minter, uint256 indexed numOftokenIds, uint256 indexed numNftsToMint);

    /* ================= Functions =============== */
    function mint(string[] memory tokenUris) public {
        require(tokenUris.length > 0, "TokenURIs array cannot be empty");
        
        for (uint256 i = 0; i < tokenUris.length; ++i) {
            uint256 tokenIds = ++noOfTokenId;
            _safeMint(msg.sender, tokenIds);
            _setTokenURI(tokenIds, tokenUris[i]);
            emit Minted(msg.sender, tokenIds, tokenUris.length);
        }
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // burn the NFT from Different smart contract
    function burn(uint256 nftId) public override  {
        require(_exists(nftId), "Invalid NFT Id");
        _burn(nftId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)public view override(ERC721, ERC721URIStorage) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
// ["https:QaADAsdasfeSDf/1.json", "https:QaADAsdasfeSDf/2.json", "https:QaADAsdasfeSDf/3.json"]
// [[1,2],[2,4],[3,6]]   [[4,2],[5,4],[6,6]]  [[7,2],[8,4],[9,6]]