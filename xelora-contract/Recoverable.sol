pragma solidity 0.4.23;

import "./Multiownable.sol";
import "../zeppelin/contracts/token/ERC20/ERC20Basic.sol";
import "../zeppelin/contracts/token/ERC20/SafeERC20.sol";


/**
 * @title Recoverable ensures ether and ERC20 tokens can be claimed by the
 * owner of the contract.
 * @author Zachary Kilgore @ Xelora Technologies LLC
 * @dev Prevents accidental loss of tokens and ether erroneously sent to
 * this contract. Uses Multiownable: any owner may reclaim; assets go to
 * the calling owner address.
 */
contract Recoverable is Multiownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Transfer errant ERC20 tokens held by the contract to the caller.
   */
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(msg.sender, balance);
  }

  /**
   * @dev Transfer all ether held by the contract to the caller.
   */
  function reclaimEther() external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

}
