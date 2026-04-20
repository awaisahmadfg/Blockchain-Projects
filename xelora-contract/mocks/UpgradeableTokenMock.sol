pragma solidity 0.4.23;

import "../UpgradeableToken.sol";

/**
 * @title Mock implementation of an UpgradeableToken (for testing).
 */
contract UpgradeableTokenMock is UpgradeableToken {

  /**
   * @dev Constructor of a mock UpgradeableToken.
   * @param _totalSupply Amount of total supply the original token should have
   */
  constructor(uint256 _totalSupply) public {
    totalSupply_ = _totalSupply;
    balances[msg.sender] = _totalSupply;
    emit Transfer(0x0, msg.sender, _totalSupply);
  }

  function canUpgrade() public view returns(bool) {
    return true;
  }

}
