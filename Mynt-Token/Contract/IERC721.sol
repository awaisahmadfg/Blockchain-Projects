// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC165.sol";

// ============ Interfaces ============
interface IERC721 is IERC165 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
