// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ============ Interfaces ============
interface IGlobals{
    function mint(address _receiver, uint256 _amount, address _contractAddress) external;
    function treasureBoxAddress() external view returns (address);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
