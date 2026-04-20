pragma solidity 0.4.23;

import "./Recoverable.sol";
import "../zeppelin/contracts/token/ERC20/ERC20Basic.sol";
import "../zeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../zeppelin/contracts/math/SafeMath.sol";


/**
 * @title TokenVault smart contract for validating and handling token distribution
 * and lockup.
 * @author Zachary Kilgore @ Xelora Technologies LLC
 * @dev TokenVault is Recoverable (Multiownable): designated owners can reclaim
 * errant tokens or ether sent to the contract.
 */
contract TokenVault is Recoverable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  /** The ERC20 token distribution the vault manages. */
  ERC20Basic public token;

  /** The amount of tokens that should be allocated prior to locking the vault. */
  uint256 public tokensToBeAllocated;

  /** The total amount of tokens allocated through setAllocation. */
  uint256 public tokensAllocated;

  /** Total amount of tokens claimed. */
  uint256 public totalClaimed;

  /** UNIX timestamp when the contract was locked. */
  uint256 public lockedAt;

  /** UNIX timestamp when the contract was unlocked. */
  uint256 public unlockedAt;

  /**
   * Amount of time, in seconds, after locking that must pass before the vault
   * can be unlocked.
   */
  uint256 public vestingPeriod = 0;

  /** Mapping of accounts to token allocations. */
  mapping (address => uint256) public allocations;

  /** Mapping of tokens claimed by a beneficiary. */
  mapping (address => uint256) public claimed;


  /** Event to track that allocations have been set and the vault has been locked. */
  event Locked();

  /** Event to track when the vault has been unlocked. */
  event Unlocked();

  /**
   * Event to track successful allocation of amount and bonus amount.
   * @param beneficiary Account that allocation is for
   * @param amount Amount of tokens allocated
   */
  event Allocated(address indexed beneficiary, uint256 amount);

  /**
   * Event to track a beneficiary receiving an allotment of tokens.
   * @param beneficiary Account that received tokens
   * @param amount Amount of tokens received
   */
  event Distributed(address indexed beneficiary, uint256 amount);


  /** Ensure the vault is able to be loaded. */
  modifier vaultLoading() {
    require(lockedAt == 0, "Expected vault to be loadable");
    _;
  }

  /** Ensure the vault has been locked. */
  modifier vaultLocked() {
    require(lockedAt > 0, "Expected vault to be locked");
    _;
  }

  /** Ensure the vault has been unlocked. */
  modifier vaultUnlocked() {
    require(unlockedAt > 0, "Expected the vault to be unlocked");
    _;
  }


  /**
   * @notice Creates a TokenVault contract that stores a token distribution.
   * @param _token The address of the ERC20 token the vault is for
   * @param _tokensToBeAllocated The amount of tokens that will be allocated
   * prior to locking
   * @param _vestingPeriod The amount of time, in seconds, that must pass
   * after locking in the allocations and then unlocking the allocations for
   * claiming
   */
  constructor(
    ERC20Basic _token,
    uint256 _tokensToBeAllocated,
    uint256 _vestingPeriod
  )
    public
  {
    require(address(_token) != address(0), "Token address should not be blank");
    require(_tokensToBeAllocated > 0, "Token allocation should be greater than zero");

    token = _token;
    tokensToBeAllocated = _tokensToBeAllocated;
    vestingPeriod = _vestingPeriod;
  }

  /**
   * @notice Function to set allocations for accounts.
   * @dev To be called by owner, likely in a scripted fashion.
   * @param _beneficiary The address to allocate tokens for
   * @param _amount The amount of tokens to be allocated and made available
   * once unlocked
   * @return true if allocation has been set for beneficiary, false if not
   */
  function setAllocation(
    address _beneficiary,
    uint256 _amount
  )
    external
    onlyOwner
    vaultLoading
    returns(bool)
  {
    require(_beneficiary != address(0), "Beneficiary of allocation must not be blank");
    require(_amount != 0, "Amount of allocation must not be zero");
    require(allocations[_beneficiary] == 0, "Allocation amount for this beneficiary is not already set");

    // Update the storage
    allocations[_beneficiary] = allocations[_beneficiary].add(_amount);
    tokensAllocated = tokensAllocated.add(_amount);

    emit Allocated(_beneficiary, _amount);

    return true;
  }

  /**
   * @notice Finalize setting of allocations and begin the lock up (vesting) period.
   * @dev Should be called after every allocation has been set.
   * @return true if the vault has been successfully locked
   */
  function lock() external onlyOwner vaultLoading {
    require(tokensAllocated == tokensToBeAllocated, "Expected to allocate all tokens");
    require(token.balanceOf(address(this)) == tokensAllocated, "Vault must own enough tokens to distribute");

    // solium-disable-next-line security/no-block-members
    lockedAt = block.timestamp;

    emit Locked();
  }

  /**
   * @notice Unlock the vault, allowing the tokens to be distributed to their
   * beneficiaries.
   * @dev Must be locked prior to unlocking. Also, the vestingPeriod must be up.
   */
  function unlock() external onlyOwner vaultLocked {
    require(unlockedAt == 0, "Must not be unlocked yet");
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= lockedAt.add(vestingPeriod), "Lock up must be over");

    // solium-disable-next-line security/no-block-members
    unlockedAt = block.timestamp;

    emit Unlocked();
  }

  /**
   * @notice Claim whatever tokens account are allocated to the sender.
   * @dev Can only be called once contract has been unlocked.
   * @return true if balance successfully distributed to sender, false otherwise
   */
  function claim() public vaultUnlocked returns(bool) {
    return _transferTokens(msg.sender);
  }

  /**
   * @notice Utility function to actually transfer allocated tokens to their
   * owners.
   * @dev Can only be called by the owner. To be used in case an investor would
   * like their tokens transferred directly for them. Most likely by a script.
   * @param _beneficiary Address to transfer tokens to
   * @return true if balance transferred to beneficiary, false otherwise
   */
  function transferFor(
    address _beneficiary
  )
    public
    onlyOwner
    vaultUnlocked
    returns(bool)
  {
    return _transferTokens(_beneficiary);
  }

  /****************
   *** Internal ***
   ****************/

  /**
   * @dev Calculate the number of tokens a beneficiary can claim.
   * @param _beneficiary Address to check for
   * @return The amount of tokens available to be claimed
   */
  function _claimableTokens(address _beneficiary) internal view returns(uint256) {
    return allocations[_beneficiary].sub(claimed[_beneficiary]);
  }

  /**
   * @dev Internal function to transfer an amount of tokens to a beneficiary.
   * @param _beneficiary Account to transfer tokens to. The amount is derived
   * from the claimable amount in the vault
   * @return true if tokens transferred successfully, false if not
   */
  function _transferTokens(address _beneficiary) internal returns(bool) {
    uint256 _amount = _claimableTokens(_beneficiary);
    require(_amount > 0, "Tokens to claim must be greater than zero");

    claimed[_beneficiary] = claimed[_beneficiary].add(_amount);
    totalClaimed = totalClaimed.add(_amount);

    token.safeTransfer(_beneficiary, _amount);

    emit Distributed(_beneficiary, _amount);

    return true;
  }

}
