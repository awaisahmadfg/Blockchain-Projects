pragma solidity 0.4.23;

import "../Recoverable.sol";


/**
 * @title PayableRecoverableMock mocks a payable contract that inherits
 * Recoverable to test the recovery of ether.
 */
contract PayableRecoverableMock is Recoverable {

  function () public payable {
  }

}
