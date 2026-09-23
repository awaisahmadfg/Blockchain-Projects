// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DummyWETH
 * @dev ERC20 token with 18 decimals for testnet RC/WETH pool testing (WETH-compatible).
 * Uses OpenZeppelin ERC20 + Ownable. Initial supply minted to deployer.
 */
contract DummyWETH is ERC20, Ownable {
    uint8 private constant _DECIMALS = 18;

    constructor() ERC20("Dummy WETH", "WETH") Ownable(msg.sender) {
        // Mint 1,000 WETH (18 decimals) to deployer
        _mint(msg.sender, 1_000 * (10 ** _DECIMALS));
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
