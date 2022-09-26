// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTToken is ERC1155, ERC1155Burnable, Ownable {
    
    constructor() ERC1155("NFTToken") {}


    function mint(uint256 id, uint256 amount) public        
    {
        _mint(msg.sender, id, amount, "");
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) public
    {
        _mintBatch(msg.sender, ids, amounts, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri (uint256 id) override public pure returns (string memory){
        return string(
            abi.encodePacked(
            "https://gateway.pinata.cloud/ipfs/QmdSxMBC7gre5ePZBBaRZcHGprCj2NQxsohsEQeb9c3szi/",
            Strings.toString(id), 
            ".json"
        )
        );
    }
}