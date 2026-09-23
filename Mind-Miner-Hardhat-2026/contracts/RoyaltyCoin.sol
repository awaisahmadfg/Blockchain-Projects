// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

/**
 * @dev Minimal swap relay deployed once from `RoyaltyCoin.initialize`.
 *      Uniswap V2 forbids swap output to pool token addresses (`INVALID_TO`); RC is token0,
 *      so quote tokens land here and are forwarded back atomically — standard swapAndLiquify pattern.
 */
contract RoyaltyCoinQuoteReceiver {
    using SafeERC20 for IERC20;

    address public immutable royaltyCoin;

    error Unauthorized();

    constructor(address royaltyCoin_) {
        if (royaltyCoin_ == address(0)) revert Unauthorized();
        royaltyCoin = royaltyCoin_;
    }

    function forwardQuoteToken(address quoteToken) external returns (uint256 amount) {
        if (msg.sender != royaltyCoin) revert Unauthorized();
        amount = IERC20(quoteToken).balanceOf(address(this));
        if (amount > 0) {
            IERC20(quoteToken).safeTransfer(royaltyCoin, amount);
        }
    }
}

/**
 * @title MindMiner RoyaltyCoin (Upgradeable)
 * @dev ERC20 reward token with:
 *      - 75% rewards pool distributed over time via `distributeRoyaltyCoinReward`
 *      - Per-call MindMiner + liquidity fees on each reward via `distributeRoyaltyCoinReward` params (default 5% + 5% from web3)
     *      - Configurable buy/sell tax on Uniswap trades for registered pairs (default 5%, owner via `setTradeFeeBps`)
 *      - Router set once in `initialize`; pairs resolved from Uniswap V2 factory via `addQuoteToken`
 *      - `rewardOperator` may call reward distribution; owner retains upgrade/fee/LP admin (e.g. Gnosis Safe)
 */
contract RoyaltyCoin is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ERC20BurnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    struct AccountConfig {
        bool isAmmPair; 
        bool isExcludedFromFee;
    }

    uint256 public constant MAX_SUPPLY = 21_000_000 * (10 ** 18);
    uint256 public constant MAX_SINGLE_DISTRIBUTION = 1_000_000 * (10 ** 18);
    uint256 public constant REWARDS_SUPPLY = 15_750_000 * (10 ** 18);
    uint256 public constant LIQUIDITY_SUPPLY = 3_150_000 * (10 ** 18);
    uint256 public constant MARKET_SUPPLY = 1_050_000 * (10 ** 18);
    uint256 public constant TEAM_SUPPLY = 1_050_000 * (10 ** 18);

    // Mainnet wallets
    address public constant LIQUIDITY_TREASURY_WALLET = 0xB683ffE74275c1404956A7f96685FDDeF90AF9F2;
    address public constant MARKET_WALLET = 0x04414575e5e06FE195329f61017292b2B561968F;
    address public constant TEAM_WALLET = 0x00b1c9498C2d8848a189427d7ad23156A9a733a5;
    address public constant MINDMINER_WALLET = 0xd7b7cafF029f863050A5D9e05B9b2Ce659fdDA92;

    uint256 public constant BPS = 10_000;
    uint256 public constant MINDMINER_FEE_BPS = 500;
    uint256 public constant LIQUIDITY_FEE_BPS = 500;
    uint256 public constant DEFAULT_TRADE_FEE_BPS = 500;
    uint256 public constant MAX_TRADE_FEE_BPS = 500;
    uint256 public constant MAX_REWARD_FEE_BPS = 1_000;

    // Custom Errors
    error AllRoyaltyCoinsDistributed();
    error InvalidRecipientAddress();
    error InvalidAmount();
    error AdjustedAmountTooLow();
    error AdjustedAmountExceedsRemainingSupply();
    error MindminerPortionTooLow();
    error LiquidityPortionTooLow();
    error MindminerPortionExceedsRemainingSupply();
    error LiquidityPortionExceedsRemainingSupply();
    error UserHasNoRoyaltyCoins();
    error InvalidRewardTokenAddress();
    error ExceedsMaxSupply();
    error AmountExceedsLimit();
    error InvalidRouterAddress();
    error InvalidQuoteTokenAddress();
    error PairDoesNotExist();
    error QuoteTokenAlreadyRegistered();
    error QuoteTokenNotRegistered();
    error DexNotConfigured();
    error BelowLiquidityThreshold();
    error SwapFailed();
    error InvalidRewardFeeBps();
    error InvalidTradeFeeBps();
    error UnauthorizedRewardOperator();
    error InvalidOperatorAddress();

    uint128 public totalRewardsDistributed;
    uint128 public remainingSupply;
    address public liquidityQuoteReceiver;

    IUniswapV2Router02 public uniswapV2Router;

    /// @dev Pair contracts use isAmmPair; wallets/router use isExcludedFromFee (one slot each)
    mapping(address => AccountConfig) private _accounts;

    uint256 public liquidityAddThreshold;
    uint256 public tradeFeeBps;
    bool private _inSwap;

    address public rewardOperator;

    event RoyaltyCoinRewardDistributed(address indexed recipient, uint256 amount);
    event UsdtRewardDistributed(address indexed recipient, uint256 amount);
    event MindminerFeeSent(uint256 amount);
    event LiquidityFeesAccumulated(uint256 amount, string source);
    event LiquidityAddedToPool(address indexed pair, address indexed quoteToken, uint256 royaltyCoinAmount, uint256 quoteAmount, uint256 liquidityMinted);
    event QuoteTokenAdded(address indexed quoteToken, address indexed pair);
    event QuoteTokenRemoved(address indexed quoteToken, address indexed pair);
    event LiquidityAddThresholdUpdated(uint256 amount);
    event TradeFeeBpsUpdated(uint256 tradeFeeBps);
    event LiquidityQuoteReceiverSet(address indexed receiver);
    event RewardOperatorUpdated(address indexed operator);

    modifier onlyRewardOperator() {
        if (msg.sender != rewardOperator) revert UnauthorizedRewardOperator();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Deploys RoyaltyCoin (RC) and mints the fixed 21M token supply.
     * @dev Supply allocation:
     *      - 75% (15.75M) → contract rewards pool (`remainingSupply` tracks unreleased amount)
     *      - 15% (3.15M)  → liquidity treasury wallet
     *      - 5%  (1.05M)  → market wallet
     *      - 5%  (1.05M)  → team wallet
     *      `MINDMINER_WALLET` is set as owner (admin ops + USDT treasury). Deploy wallet is one-time
     *      setup only. Contract, router, and treasury wallets are marked fee-exempt.
     *      After deployment, create the RC/USDT pool on Uniswap, then call `addQuoteToken(usdt)`.
     *      Additional pairs (WETH, WBTC, etc.) can be enabled later via `addQuoteToken`.
     * @param router Uniswap V2 router address for the target network (e.g. Ethereum mainnet or Sepolia).
     */
    function initialize(address router) public initializer {
        if (router == address(0)) revert InvalidRouterAddress();

        __ERC20_init("RoyaltyCoin", "RC");
        __Ownable_init(MINDMINER_WALLET);
        __ERC20Burnable_init();
        __UUPSUpgradeable_init();

        remainingSupply = uint128(REWARDS_SUPPLY);
        tradeFeeBps = DEFAULT_TRADE_FEE_BPS;
        uniswapV2Router = IUniswapV2Router02(router);
        liquidityQuoteReceiver = address(new RoyaltyCoinQuoteReceiver(address(this)));
        emit LiquidityQuoteReceiverSet(liquidityQuoteReceiver);

        _mint(address(this), REWARDS_SUPPLY);
        _mint(LIQUIDITY_TREASURY_WALLET, LIQUIDITY_SUPPLY);
        _mint(MARKET_WALLET, MARKET_SUPPLY);
        _mint(TEAM_WALLET, TEAM_SUPPLY);

        _accounts[owner()].isExcludedFromFee = true;
        _accounts[address(this)].isExcludedFromFee = true;
        _accounts[router].isExcludedFromFee = true;
        _accounts[MINDMINER_WALLET].isExcludedFromFee = true;
        _accounts[LIQUIDITY_TREASURY_WALLET].isExcludedFromFee = true;
        _accounts[MARKET_WALLET].isExcludedFromFee = true;
        _accounts[TEAM_WALLET].isExcludedFromFee = true;

        rewardOperator = MINDMINER_WALLET;
        emit RewardOperatorUpdated(MINDMINER_WALLET);
    }

    /**
     * @notice Sets the wallet allowed to call reward distribution functions.
     */
    function setRewardOperator(address operator) external onlyOwner {
        if (operator == address(0)) revert InvalidOperatorAddress();
        rewardOperator = operator;
        emit RewardOperatorUpdated(operator);
    }

    /**
     * @notice Registers a quote token after its RC pair exists on Uniswap.
     * @dev Enables buy/sell tax (`tradeFeeBps`) and allows LP adds via `addAccumulatedLiquidityToPool`.
     * @param quoteToken Quote token address (e.g. USDT, WETH).
     */
    function addQuoteToken(address quoteToken) external onlyOwner {
        address pair = _pairForQuote(quoteToken);
        if (_accounts[pair].isAmmPair) revert QuoteTokenAlreadyRegistered();

        _accounts[pair].isAmmPair = true;
        emit QuoteTokenAdded(quoteToken, pair);
    }

    /** @dev Looks up RC/quote pair from Uniswap factory. Reverts if pool does not exist. */
    function _pairForQuote(address quoteToken) private view returns (address pair) {
        if (address(uniswapV2Router) == address(0)) revert DexNotConfigured();
        if (quoteToken == address(0)) revert InvalidQuoteTokenAddress();
        pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), quoteToken);
        if (pair == address(0)) revert PairDoesNotExist();
    }

    /** @dev Same as `_pairForQuote`, plus checks the pair is registered for tax/LP. */
    function _requireRegisteredPair(address quoteToken) private view returns (address pair) {
        pair = _pairForQuote(quoteToken);
        if (!_accounts[pair].isAmmPair) revert QuoteTokenNotRegistered();
    }

    /**
     * @notice Disables trade tax for a quote token's RC pair.
     * @param quoteToken Quote token address (e.g. USDT, WETH).
     */
    function removeQuoteToken(address quoteToken) external onlyOwner {
        address pair = _requireRegisteredPair(quoteToken);
        _accounts[pair].isAmmPair = false;
        emit QuoteTokenRemoved(quoteToken, pair);
    }

    /**
     * @notice Sets minimum accumulated RC required before admin can add LP.
     * @dev Pass 0 for no minimum (default).
     */
    function setLiquidityAddThreshold(uint256 amount) external onlyOwner {
        liquidityAddThreshold = amount;
        emit LiquidityAddThresholdUpdated(amount);
    }

    /**
     * @notice Sets the buy/sell trade tax rate for registered Uniswap pairs.
     * @dev Bps scale: 500 = 5%. Owner may set 0–500 (0%–5%). Default is 5%.
     */
    function setTradeFeeBps(uint256 bps) external onlyOwner {
        if (bps > MAX_TRADE_FEE_BPS) revert InvalidTradeFeeBps();
        tradeFeeBps = bps;
        emit TradeFeeBpsUpdated(bps);
    }

    /** @notice Returns RC in contract available for LP (trade tax + reward LP fees, excluding unreleased rewards). */
    function accumulatedLiquidityBalance() public view returns (uint256) {
        return _accumulatedLiquidityBalance();
    }

    /**
     * @notice Distributes RC rewards from the 75% pool to a user.
     * @dev Split: ~90% user, 5% MindMiner, 5% LP. Default 500/500 bps Fees are on top of scaled
     *      `_amount` (max 10% each, per call). Example: 1000/0 → 10% MindMiner, 0% LP. Scales as pool depletes.
     * @param _to Recipient address.
     * @param _amount Requested reward amount (max 1M per call).
     * @param mindminerFeeBps MindMiner fee in bps (max 1000; 500 = 5%).
     * @param liquidityFeeBps LP reserve fee in bps (max 1000; 500 = 5%).
     */
    function distributeRoyaltyCoinReward(
        address _to,
        uint256 _amount,
        uint256 mindminerFeeBps,
        uint256 liquidityFeeBps
    ) public onlyRewardOperator {
        if (_amount > MAX_SINGLE_DISTRIBUTION) revert AmountExceedsLimit();
        if (mindminerFeeBps > MAX_REWARD_FEE_BPS || liquidityFeeBps > MAX_REWARD_FEE_BPS) {
            revert InvalidRewardFeeBps();
        }

        uint256 maxSupply = REWARDS_SUPPLY;
        uint256 totalDistributed = uint256(totalRewardsDistributed);
        uint256 rewardsRemaining = maxSupply - totalDistributed;

        if (totalDistributed >= maxSupply) revert AllRoyaltyCoinsDistributed();
        if (_to == address(0)) revert InvalidRecipientAddress();
        if (_amount == 0) revert InvalidAmount();

        uint256 adjustedAmount = (_amount * rewardsRemaining) / maxSupply;
        uint256 mindminerPortion = (adjustedAmount * mindminerFeeBps) / BPS;
        uint256 liquidityPortion = (adjustedAmount * liquidityFeeBps) / BPS;

        if (adjustedAmount == 0) revert AdjustedAmountTooLow();
        if (mindminerFeeBps > 0 && mindminerPortion == 0) revert MindminerPortionTooLow();
        if (liquidityFeeBps > 0 && liquidityPortion == 0) revert LiquidityPortionTooLow();
        if (adjustedAmount > rewardsRemaining) revert AdjustedAmountExceedsRemainingSupply();
        if (mindminerPortion > rewardsRemaining) revert MindminerPortionExceedsRemainingSupply();
        if (liquidityPortion > rewardsRemaining) revert LiquidityPortionExceedsRemainingSupply();

        uint256 totalToDistribute = adjustedAmount + mindminerPortion + liquidityPortion;
        uint256 newTotalDistributed = totalDistributed + totalToDistribute;
        if (newTotalDistributed > maxSupply) revert ExceedsMaxSupply();

        totalRewardsDistributed = uint128(newTotalDistributed);
        remainingSupply = uint128(maxSupply - newTotalDistributed);

        _transfer(address(this), _to, adjustedAmount);
        if (mindminerPortion > 0) {
            _transfer(address(this), MINDMINER_WALLET, mindminerPortion);
            emit MindminerFeeSent(mindminerPortion);
        }
        if (liquidityPortion > 0) {
            emit LiquidityFeesAccumulated(liquidityPortion, "reward");
        }

        emit RoyaltyCoinRewardDistributed(_to, adjustedAmount);
    }

    /**
     * @notice Sends ERC20 reward (e.g. USDT) from the reward operator wallet to an RC holder.
     * @dev Callable by `rewardOperator` only. Operator must approve this contract first. Recipient must hold RC tokens.
     */
    function distributeUsdtReward(address _to, uint256 _amount, address rewardToken) external onlyRewardOperator {
        if (rewardToken == address(0)) revert InvalidRewardTokenAddress();
        if (_to == address(0)) revert InvalidRecipientAddress();
        if (_amount == 0) revert InvalidAmount();
        if (balanceOf(_to) == 0) revert UserHasNoRoyaltyCoins();

        IERC20(rewardToken).safeTransferFrom(rewardOperator, _to, _amount);

        emit UsdtRewardDistributed(_to, _amount);
    }

    /**
     * @notice Swaps half of accumulated RC for quote token, then adds LP to the chosen pool.
     * @dev One tx = one pool. LP tokens go to `LIQUIDITY_TREASURY_WALLET`.
     *      Quote swap output goes to `liquidityQuoteReceiver` (see `RoyaltyCoinQuoteReceiver`) because
     *      RC is token0 in its pairs and Uniswap rejects `to = address(this)`.
     * @param quoteToken Quote token of the target pool (e.g. USDT).
     */
    function addAccumulatedLiquidityToPool(address quoteToken) external onlyOwner {
        address pair = _requireRegisteredPair(quoteToken);

        uint256 accumulated = _accumulatedLiquidityBalance();
        if (accumulated == 0) revert InvalidAmount();
        if (liquidityAddThreshold > 0 && accumulated < liquidityAddThreshold) revert BelowLiquidityThreshold();
        if (!_swapAndAddLiquidity(pair, quoteToken, accumulated)) revert SwapFailed();
    }

    /** @dev UUPS — only owner can upgrade the implementation. */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /** @dev Applies trade fee on registered Uniswap pair transfers; fee stays in contract for LP. */
    function _update(address from, address to, uint256 value) internal override {
        if (from == address(0) || to == address(0)) {
            super._update(from, to, value);
            return;
        }

        uint256 tradeFee;

        if (_shouldTakeFee(from, to) && tradeFeeBps > 0) {
            tradeFee = (value * tradeFeeBps) / BPS;
        }

        if (tradeFee == 0) {
            super._update(from, to, value);
            return;
        }

        super._update(from, address(this), tradeFee);
        super._update(from, to, value - tradeFee);
        emit LiquidityFeesAccumulated(tradeFee, "trade");
    }

    /** @dev Fee on Uniswap buys/sells only. Skips exempt wallets and internal swaps. */
    function _shouldTakeFee(address from, address to) private view returns (bool) {
        if (_inSwap) return false;

        AccountConfig storage fromConfig = _accounts[from];
        AccountConfig storage toConfig = _accounts[to];

        if (fromConfig.isExcludedFromFee || toConfig.isExcludedFromFee) return false;
        return fromConfig.isAmmPair || toConfig.isAmmPair;
    }

    /** @dev Contract RC balance minus unreleased rewards reserve — safe to use for LP. */
    function _accumulatedLiquidityBalance() private view returns (uint256) {
        uint256 contractBalance = balanceOf(address(this));
        uint256 rewardsReserve = uint256(remainingSupply);
        if (contractBalance <= rewardsReserve) return 0;
        return contractBalance - rewardsReserve;
    }

    /** @dev 50% RC → quote swap, then addLiquidity with remaining RC + quote. Sets `_inSwap` to avoid double tax. */
    function _swapAndAddLiquidity(address pair, address quoteToken, uint256 tokens) private returns (bool) {
        if (tokens == 0 || liquidityQuoteReceiver == address(0)) return false;

        _inSwap = true;

        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;
        uint256 initialQuoteBalance = IERC20(quoteToken).balanceOf(address(this));

        _approve(address(this), address(uniswapV2Router), tokens);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = quoteToken;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            liquidityQuoteReceiver,
            block.timestamp
        );

        uint256 forwarded = RoyaltyCoinQuoteReceiver(liquidityQuoteReceiver).forwardQuoteToken(quoteToken);
        uint256 quoteReceived = IERC20(quoteToken).balanceOf(address(this)) - initialQuoteBalance;
        if (forwarded != quoteReceived || quoteReceived == 0 || otherHalf == 0) {
            _inSwap = false;
            return false;
        }

        _approve(address(this), address(uniswapV2Router), otherHalf);
        IERC20(quoteToken).forceApprove(address(uniswapV2Router), quoteReceived);

        (uint256 royaltyCoinUsed, uint256 quoteUsed, uint256 liquidity) = uniswapV2Router.addLiquidity(
            address(this),
            quoteToken,
            otherHalf,
            quoteReceived,
            0,
            0,
            LIQUIDITY_TREASURY_WALLET,
            block.timestamp
        );

        _inSwap = false;

        emit LiquidityAddedToPool(pair, quoteToken, royaltyCoinUsed, quoteUsed, liquidity);
        return royaltyCoinUsed > 0 && quoteUsed > 0;
    }
}
