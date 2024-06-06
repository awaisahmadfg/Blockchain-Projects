// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============ Interfaces ============
interface IFMYNT{
    function mint(address _receiver, uint256 _amount, address _contractAddress) external;
    function treasureBoxMintedAmount() external view returns (uint256);
    function TREASURE_BOX_SUPPLY_CAP() external view returns (uint256);
    function treasureBoxAddress() external view returns (address);
}
