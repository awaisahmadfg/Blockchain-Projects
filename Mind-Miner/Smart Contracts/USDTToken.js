// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DummyUSDT
 * @dev ERC20 token with 6 decimals for testing reward distribution (USDT-compatible).
 * Uses OpenZeppelin ERC20 + Ownable. Initial supply minted to deployer.
 */
contract DummyUSDT is ERC20, Ownable {
    uint8 private constant _DECIMALS = 6;

    constructor() ERC20("Dummy USDT", "USDT") Ownable(msg.sender) {
        // Mint 1 Million 1,000,000 USDT (6 decimals) to deployer for testing purpose
        _mint(msg.sender, 1_000_000 * (10 ** _DECIMALS));
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @dev Optional: mint more tokens (owner only). Useful for testnets.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
