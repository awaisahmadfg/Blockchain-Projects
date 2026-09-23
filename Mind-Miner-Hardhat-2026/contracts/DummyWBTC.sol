// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DummyWBTC
 * @dev ERC20 token with 8 decimals for testnet RC/WBTC pool testing (WBTC-compatible).
 * Uses OpenZeppelin ERC20 + Ownable. Initial supply minted to deployer.
 */
contract DummyWBTC is ERC20, Ownable {
    uint8 private constant _DECIMALS = 8;

    constructor() ERC20("Dummy WBTC", "WBTC") Ownable(msg.sender) {
        // Mint 100 WBTC (8 decimals) to deployer
        _mint(msg.sender, 100 * (10 ** _DECIMALS));
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
