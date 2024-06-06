
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;

    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "hardhat/console.sol";

    contract FMYNT is ERC20, Ownable {

        address public treasureBoxAddress;
        uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18; // 1 billion tokens with 18 decimals
        uint256 public constant TREASURE_BOX_SUPPLY_CAP = (TOTAL_SUPPLY * 20) / 100; // 20% of the total supply
        uint256 public treasureBoxMintedAmount;

        constructor() ERC20("FMYNT", "FMYNT") Ownable(msg.sender) {
            _mint(msg.sender, TOTAL_SUPPLY); 
        }

        function mint(address _receiver, uint256 _amount, address _contractAddress) external{
            require(_contractAddress == treasureBoxAddress, "Caller is not the treasurebox contract");
            require(treasureBoxMintedAmount + _amount <= TREASURE_BOX_SUPPLY_CAP, "Treasure box supply cap reached");
            _mint(_receiver, _amount);
            treasureBoxMintedAmount += _amount;
        }

        function mintTokens(uint _amount, address _reciever) external onlyOwner{
            _mint(_reciever, _amount);
        }

        function setTreasureBoxAddress(address _treasureBoxAddress) external {
            require(_treasureBoxAddress != address(0), "Invalid treasureBox contract address");
            require(msg.sender == owner(), "Caller is not the contract owner");
            treasureBoxAddress = _treasureBoxAddress;
        }
    }
