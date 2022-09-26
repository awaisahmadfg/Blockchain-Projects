// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// Simple ERC721 Smart Contract made for Rewards.

contract RewardToken is ERC20 {

    
    uint256 public _totalSupply=1000000 * 10**decimals();

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
       // _mint(msg.sender, 1000000 * 10**decimals());
         _mint(msg.sender, _totalSupply);
    }


    function safeTransfer(IERC20 token, address to, uint256 value) public{
    
    require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token,address from, address to,uint256 value) public{
    
    require(token.transferFrom(from, to, value));
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(amount <= _totalSupply, "Cannot Approve more than total supply");
        _approve(owner, spender, amount);
        return true;
    }

    

} 