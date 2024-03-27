// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Correct path for OpenZeppelin's ERC721 interface
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; // Correct path for OpenZeppelin's ERC1155 interface

contract TokenTypeChecker {
    function isERC721(address contractAddress) public view returns (bool) {
        return ERC165Checker.supportsInterface(contractAddress, type(IERC721).interfaceId);
    }

    function isERC1155(address contractAddress) public view returns (bool) {
        return ERC165Checker.supportsInterface(contractAddress, type(IERC1155).interfaceId);
    }
}
