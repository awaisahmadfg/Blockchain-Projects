pragma solidity 0.4.23;


/**
 * @title Multiownable
 * @dev Multiple addresses may act as owners. The `onlyOwner` modifier allows
 * any current owner to execute protected functions. Use `addOwner` and
 * `removeOwner` to manage the set; the last owner cannot be removed.
 */
contract Multiownable {

  mapping(address => bool) public isOwner;

  uint256 public ownerCount;

  event OwnerAdded(address indexed account);

  event OwnerRemoved(address indexed account);


  constructor() public {
    isOwner[msg.sender] = true;
    ownerCount = 1;
    emit OwnerAdded(msg.sender);
  }


  modifier onlyOwner() {
    require(isOwner[msg.sender], "Must be contract owner");
    _;
  }


  /**
   * @notice Grant owner rights to an account.
   * @param _account Address to add as an owner
   */
  function addOwner(address _account) external onlyOwner {
    require(_account != address(0), "Owner must not be zero address");
    require(!isOwner[_account], "Account is already an owner");

    isOwner[_account] = true;
    ownerCount += 1;

    emit OwnerAdded(_account);
  }


  /**
   * @notice Revoke owner rights from an account.
   * @param _account Address to remove from owners
   */
  function removeOwner(address _account) external onlyOwner {
    require(isOwner[_account], "Account is not an owner");
    require(ownerCount > 1, "Cannot remove the last owner");

    isOwner[_account] = false;
    ownerCount -= 1;

    emit OwnerRemoved(_account);
  }

}
