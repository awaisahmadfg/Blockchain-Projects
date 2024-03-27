// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC721 is IERC165 {
    // ERC721 function to return the owner of a given tokenId
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
