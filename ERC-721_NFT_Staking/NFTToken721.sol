// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTToken is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("NFTToken", "NTK") {}

    function Mint( uint256 tokenId, string memory uri) public    {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _safeTransfer(address from,address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
     //   require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

//     function _transfer(address from, address to, uint256 tokenId) internal virtual override {
//         require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
//         require(to != address(0), "ERC721: transfer to the zero address");

//         _beforeTokenTransfer(from, to, tokenId);

//         // Clear approvals from the previous owner
// //        delete _tokenApprovals[tokenId];

// //        _balances[from] -= 1;
// //        _balances[to] += 1;
// //        _owners[tokenId] = to;

//         emit Transfer(from, to, tokenId);

//         _afterTokenTransfer(from, to, tokenId);
//     }


}