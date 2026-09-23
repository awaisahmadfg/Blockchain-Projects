// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Minimal Uniswap V2 mocks for RoyaltyCoin unit tests (factory, pair marker, router).
 */
contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) private _pairs;

    event PairCreated(address indexed token0, address indexed token1, address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL");
        require(tokenA != address(0) && tokenB != address(0), "ZERO");
        pair = address(new MockUniswapV2Pair());
        _pairs[tokenA][tokenB] = pair;
        _pairs[tokenB][tokenA] = pair;
        emit PairCreated(tokenA, tokenB, pair);
    }

    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        pair = _pairs[tokenA][tokenB];
        if (pair == address(0)) {
            pair = _pairs[tokenB][tokenA];
        }
    }
}

contract MockUniswapV2Pair {}

contract MockUniswapV2Router {
    address public immutable factory;
    address public lastLiquidityRecipient;

    constructor(address factory_) {
        factory = factory_;
    }

    /**
     * @dev Simplified swap: RC (18 dec) -> USDT (6 dec) at 1:1e-12 rate for testing.
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256,
        address[] calldata path,
        address to,
        uint256
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        uint256 amountOut = amountIn / 1e12;
        IERC20(path[1]).transfer(to, amountOut);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256,
        uint256,
        address to,
        uint256
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        lastLiquidityRecipient = to;
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);
        amountA = amountADesired;
        amountB = amountBDesired;
        liquidity = amountADesired + amountBDesired;
    }
}
