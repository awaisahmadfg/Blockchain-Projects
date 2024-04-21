// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title MJC ERC20 Contract
 * @dev Implementation of the ERC20 token.
 */
contract MJC is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the MJC token contract.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     */
    function initialize(string memory name, string memory symbol) initializer public {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        // Mint initial supply to the owner
        uint256 initialSupply = 67000000 * (10 ** uint256(decimals())); 
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Mints new tokens and assigns them to the specified address.
     * @param to The address to which new tokens will be minted.
     * @param amount The amount of tokens to mint.
     */ 
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}

