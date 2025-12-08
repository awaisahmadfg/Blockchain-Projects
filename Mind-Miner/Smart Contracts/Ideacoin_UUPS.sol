// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MindMiner IdeaCoin (Upgradeable)
 * @dev Implements an ERC20 token for distributing rewards called IdeaCoin and MATIC. 
 * The tokens are initially minted to this contract and distributed based on specific reward criteria to incentivize platform engagement.
 * This contract uses UUPS (Universal Upgradeable Proxy Standard) for upgradeability.
 */
contract IdeaCoin is 
    Initializable,
    ERC20Upgradeable, 
    OwnableUpgradeable, 
    ERC20BurnableUpgradeable,
    UUPSUpgradeable 
{
    using SafeERC20 for IERC20;

    // Custom Errors
    error InvalidMaticAddress();
    error AllIdeaCoinsDistributed();
    error InvalidRecipientAddress();
    error InvalidAmount();
    error AdjustedAmountTooLow();
    error AdjustedAmountExceedsRemainingSupply();
    error MindminerPortionTooLow();
    error MindminerPortionExceedsRemainingSupply();
    error UserHasNoIdeaCoins();
    error OwnerInsufficientMaticBalance();
    error ExceedsMaxSupply();
    error AmountExceedsLimit();

    // Constants
    uint256 public constant MAX_SUPPLY = 21000000 * (10 ** 18);
    uint256 public constant MAX_SINGLE_DISTRIBUTION = 1000000 * (10 ** 18);
    address public constant MINDMINER_WALLET = 0xd7b7cafF029f863050A5D9e05B9b2Ce659fdDA92;
    
    uint128 public totalRewardsDistributed; 
    uint128 public remainingSupply;
    IERC20 public MATIC;

    event IdeaRewardDistributed(address indexed recipient, uint256 amount);
    event MaticRewardDistributed(address indexed recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the ERC20 token with the name "IdeaCoin" and symbol "IDEA".
     * @dev Initializer function that replaces constructor for upgradeable contracts.
     * Mints all IdeaCoins to this contract and initializes remainingSupply with MAX_SUPPLY.
     * @param _maticAddress The address of the MATIC token contract
     */
    function initialize(address _maticAddress) public initializer {
        if (_maticAddress == address(0)) revert InvalidMaticAddress();

        __ERC20_init("IdeaCoin", "IDEA");
        __Ownable_init(msg.sender);
        __ERC20Burnable_init();
        __UUPSUpgradeable_init();

        uint256 maxSupply = MAX_SUPPLY;
        remainingSupply = uint128(maxSupply);       
        MATIC = IERC20(_maticAddress);
        _mint(address(this), maxSupply);
    }

    /**
     * @dev Distributes Idea rewards while adjusting the amount based on the remaining supply and adjacent factor to slowly deplete the supply.
     * @notice Distributes adjusted IdeaCoin rewards to a specified wallet address.
     * @param _to The recipient's address.
     * @param _amount The initial amount to distribute before adjustment.
     */
    function distributeIdeaReward(address _to, uint256 _amount) public onlyOwner {
        if (_amount > MAX_SINGLE_DISTRIBUTION) revert AmountExceedsLimit();
        
        uint256 _maxSupply = MAX_SUPPLY;
        uint256 _totalRewardsDistributed = uint256(totalRewardsDistributed);
        
        // Calculate remainingSupply from totalRewardsDistributed for consistency
        uint256 _remainingSupply = _maxSupply - _totalRewardsDistributed;
        
        if (_totalRewardsDistributed >= _maxSupply) revert AllIdeaCoinsDistributed();
        if (_to == address(0)) revert InvalidRecipientAddress();
        if (_amount == 0) revert InvalidAmount();
        
        uint256 adjustedAmount = (_amount * _remainingSupply) / _maxSupply;
        uint256 mindminerPortion = (_amount * _remainingSupply) / (_maxSupply * 10);
        
        if (adjustedAmount == 0) revert AdjustedAmountTooLow();
        if (adjustedAmount > _remainingSupply) revert AdjustedAmountExceedsRemainingSupply();
        if (mindminerPortion == 0) revert MindminerPortionTooLow();
        if (mindminerPortion > _remainingSupply) revert MindminerPortionExceedsRemainingSupply();
        
        // Validate total distribution doesn't exceed supply
        uint256 totalToDistribute = adjustedAmount + mindminerPortion;
        uint256 newTotalRewardsDistributed = _totalRewardsDistributed + totalToDistribute;
        if (newTotalRewardsDistributed > _maxSupply) {
            revert ExceedsMaxSupply();
        }

        totalRewardsDistributed = uint128(newTotalRewardsDistributed);
        remainingSupply = uint128(_maxSupply - newTotalRewardsDistributed);

        _transfer(address(this), _to, adjustedAmount);
        _transfer(address(this), MINDMINER_WALLET, mindminerPortion);

        emit IdeaRewardDistributed(_to, adjustedAmount);
    }

    /**
     * @dev Transfers MATIC from the Owner to the recipient.
     * @notice User claims MATIC rewards based on their IdeaCoins holding.
     * @param _to The recipient's address.
     * @param _amount The amount of MATIC to distribute.
     */
    function distributeMaticReward(address _to, uint256 _amount) public onlyOwner {
        if (_to == address(0)) revert InvalidRecipientAddress();
        if (_amount == 0) revert InvalidAmount();

        uint256 ideaBalance = balanceOf(_to);
        if (ideaBalance == 0) revert UserHasNoIdeaCoins();
        if (MATIC.balanceOf(msg.sender) < _amount) revert OwnerInsufficientMaticBalance();

        MATIC.safeTransferFrom(msg.sender, _to, _amount);

        emit MaticRewardDistributed(_to, _amount);
    }

    /**
     * @dev Authorizes upgrade of the contract. Only the owner can upgrade.
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
