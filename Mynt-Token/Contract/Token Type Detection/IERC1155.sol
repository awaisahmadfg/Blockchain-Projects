// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";

interface IERC1155 is IERC165 {
    // ERC1155 function to return the amount of a given tokenId owned by an account
    function balanceOf(address account, uint256 tokenId) external view returns (uint256);
}
