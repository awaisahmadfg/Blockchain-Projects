// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Wrapped Ether", "MockToken") {
        // Mint 1000000000000000000000000000 WETH to the deployer for initial testing liquidity
        _mint(msg.sender, 1000000000000000000000000000 * 10**18);
    }

    // Function to deposit ETH and mint WETH
    function deposit() public payable {
        _mint(msg.sender, msg.value); // Mint WETH equivalent to the deposited ETH amount
    }

    // Function to withdraw ETH and burn WETH
    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount, "MockWETH: Insufficient balance to withdraw");
        _burn(msg.sender, amount); // Burn WETH first to prevent reentrancy attacks
        payable(msg.sender).transfer(amount); // Transfer ETH back to the sender
    }

    // Fallback function to receive ETH and automatically mint WETH
    receive() external payable {
        deposit();
    }
}

