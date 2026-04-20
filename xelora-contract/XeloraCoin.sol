pragma solidity 0.4.23;

import "../zeppelin/contracts/token/ERC20/PausableToken.sol";
import "./UpgradeableToken.sol";
import "./Recoverable.sol";


/**
 * @title XeloraCoin ERC20 Compliant Token Contract
 * @author Zachary Kilgore @ Xelora Technologies LLC
 * @dev XeloraCoin is a standard ERC20 token that has the following additional
 * properties:
 *
 * - Upgradeable: Allows for the token to be upgraded to a new contract.
 * - Multiownable (via Recoverable): Multiple owner accounts; owners may add or
 * remove other owners while at least one remains.
 * - Recoverable: Allows owners to recover ether and tokens
 * sent to the contract in error that would otherwise be trapped.
 * - Pauseable: Owned contract that allows the ERC20 functionality (transfer,
 * approval, etc) to be paused and unpaused by the owner in case of emergency.
 */
contract XeloraCoin is PausableToken, UpgradeableToken {

  string public constant name = "XeloraCoin";
  string public constant symbol = "FXC";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 100000000000 * (10 ** uint256(decimals));


  /**
    * @notice XeloraCoin (ERC20 Token) contract constructor.
    * @dev Assigns all tokens to contract creator.
    */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

  /**
   * @dev Allow UpgradeableToken functionality only if contract is not paused.
   */
  function canUpgrade() public view returns(bool) {
    return !paused;
  }

}
