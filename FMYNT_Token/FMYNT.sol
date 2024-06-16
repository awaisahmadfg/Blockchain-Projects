
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract FMYNT is ERC20, Ownable {
    using SafeMath for uint256;

    event FeeTaken(address sender, uint256 feeAmount);
    event TransferDetails(address sender, address recipient, uint256 amountWithFee, uint256 feeDeducted);
    
    address public immutable FEE_RECIEVER;

    // Constants
    uint256 public constant BUY_TAX = 5; // 5% buy tax
    uint256 public constant SELL_TAX = 5; // 5% sell tax
    uint256 public constant TOTAL_SUPPLY = 1e9 * 1e18; // 1 billion tokens
    
    // Uniswap Integration
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address public mockTokenAddress;

    // Tax Tracking
    mapping(address => bool) public _isExcludedFromFee;  // List of addresses excluded from tax

    constructor(address _feeReceiver, address _mockTokenAddress) Ownable(msg.sender) ERC20("Founders Mynt Token","FMYNT"){
        _mint(msg.sender, TOTAL_SUPPLY);
        FEE_RECIEVER = _feeReceiver; // Initialize feeReceiver from constructor parameter
        mockTokenAddress = _mockTokenAddress;

        // Replace with actual Uniswap router address
        // Example: Uniswap V2 Router on Ethereum Sepolia = 0x425141165d3DE9FEC831896C016617a52363b687
        // Sepolia working router is : 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
        // For BSC pancakeswap: 0x9A082015c919AD0E47861e5Db9A1c7070E81A2C7 or 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3, 0xD99D1c33F9fC3444f8101754aBC46c52416550D1      
        uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); 

        // Create Uniswap pair with WETH
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(mockTokenAddress)); // uniswapV2Router.WETH()

        // Exclude contract addresses and Owner from tax
        //_isExcludedFromFee[address(this)] = true;
        // _isExcludedFromFee[owner()] = true;
        //_isExcludedFromFee[uniswapV2Pair] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool)  {
        address sender = _msgSender(); // From OpenZeppelin's context for keeping track of the sender
        uint256 fees = 0;

        console.log("Sender: ", sender);
        console.log("Recipient: ", recipient);

        // If any account belongs to _isExcludedFromFee account then remove the fee
        /* The contract first checks if the sender (user performing the swap) and the recipient 
        (typically the Uniswap pair) are excluded from fees. In your setup, the Uniswap pair and 
        the contract itself are excluded, but the user is generally not.*/
        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            // Buy
            if (sender == uniswapV2Pair) { // && recipient != address(uniswapV2Router)
                fees = amount.mul(BUY_TAX).div(100);
            }
            // Sell
            else if (recipient == uniswapV2Pair) {
                fees = amount.mul(SELL_TAX).div(100); // for 1 FMYNT 0.05 FMYNT would deduct
            }

            if (fees > 0) {
                _transfer(sender, address(this), fees); // Transfer the fees to the contract itself
                swapTokensForTokens(fees); // Swap the fees for Token
                emit FeeTaken(sender, fees);
                amount = amount.sub(fees); // Subtract the fees from the transfer amount
            }
        }

        // The remaining amount of FMYNT (0.95 FMYNT if the initial amount was 1 FMYNT) is then transferred to the Uniswap pair as part of the user’s original sell order.
        _transfer(sender, recipient, amount); // Perform the actual transfer
        emit TransferDetails(sender, recipient, amount, fees);
        return true;
    }

    function transferFrom( address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        uint256 currentAllowance = allowance(sender, spender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, spender, currentAllowance - amount);

        uint256 fees = 0;
        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            // Apply tax logic similarly as in the transfer function
            if (sender == uniswapV2Pair) {  // Assumed Buy Transaction
                fees = amount.mul(BUY_TAX).div(100);
            } else if (recipient == uniswapV2Pair) {  // Assumed Sell Transaction
                fees = amount.mul(SELL_TAX).div(100); 
        }

        if (fees > 0) {
            _transfer(sender, address(this), fees);
            swapTokensForTokens(fees);  // Swap the fees for Token, consider reentrancy concerns
            emit FeeTaken(sender, fees);
            amount = amount.sub(fees);
        }
    }
        _transfer(sender, recipient, amount);
        emit TransferDetails(sender, recipient, amount, fees);

        return true;
    }

    function swapTokensForTokens(uint256 tokenAmount) private {
        // Generate the uniswap pair path of FMYNT -> MockToken
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = mockTokenAddress; // uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount); // Approving the Uniswap router to handle the required amount of FMYNT

        // Make the swap: To swap the deducted fee (0.05 FMYNT) for MockToken.
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // set to 0 to accept any amount of tokens
            path,
            FEE_RECIEVER, // The Token received from this swap is then sent to the FEE_RECIEVER.
            block.timestamp
        );
    }
}
