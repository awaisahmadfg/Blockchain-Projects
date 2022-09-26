// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.4;

contract RewardToken is ERC20, ERC20Burnable, Ownable {
    
    uint256 public _totalSupply=1000000 * 10**decimals();

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, _totalSupply);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(amount <= _totalSupply, "Cannot Approve more than total supply");
        _approve(owner, spender, amount);
        return true;
    }
}