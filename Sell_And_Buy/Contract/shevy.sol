// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract HoldTimeLockEarn is Context, IERC20, IERC20Metadata, Ownable {

    /* ============== State Variable ============= */
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotalSupply; 
    uint256 private immutable _tTotalSupply; 
    string private _name;
    string private _symbol;
    address[] private _excludedFromReward;          

    uint256 public taxFee = 200; 
    uint256 public totalFees;
    uint256 public highTaxFee = 4000; 
    uint256 public timeLockDuration = 5 minutes;
    bool public timeLockEnabled = false;
    uint256 public lastSellTime;

    /* ============== Mappings ============= */
    mapping(address => uint256) private _rBalances; 
    mapping(address => uint256) private _tBalances; 
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromReward;

    /* ============== Events ============= */
    event SetFee(uint256 value);

    /* ============== Constructor ============= */
    constructor(address owner_) Ownable(owner_) {
        _name = 'HOLD&TIMELOCK';
        _symbol = 'EARN';
        _tTotalSupply = 1000000000 * 10 ** decimals();
        excludeFromFee(owner_);
        excludeFromFee(address(this));
        _mint(owner_, _tTotalSupply);
        _transferOwnership(owner_);
    }

    /* ============== Functions ============= */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tTotalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 rate = _getRate();
        return _rBalances[account] / rate;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address account, address spender) public view virtual override returns (uint256) {
        return _allowances[account][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setFee(uint256 newTxFee) public onlyOwner {
        taxFee = newTxFee;
        emit SetFee(taxFee);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!isExcludedFromReward[account], "Address already excluded");
        require(_excludedFromReward.length < 100, "Excluded list is too long");

        if (_rBalances[account] > 0) {
            uint256 rate = _getRate();
            _tBalances[account] = _rBalances[account] / rate;
        }
        isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) public onlyOwner {
        require(isExcludedFromReward[account], "Account is already included");
        uint256 nExcluded = _excludedFromReward.length;
        for (uint256 i = 0; i < nExcluded; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[
                    _excludedFromReward.length - 1
                ];
                _tBalances[account] = 0;
                isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function withdrawTokens(address tokenAddress, address receiverAddress) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        return tokenContract.transfer(receiverAddress, amount);
    }

    function _getRate() private view returns (uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _tTotalSupply;
        uint256 nExcluded = _excludedFromReward.length;
        for (uint256 i = 0; i < nExcluded; i++) {
            address account = _excludedFromReward[i];
            uint256 rBalance = _rBalances[account];
            uint256 tBalance = _tBalances[account];
            if (rBalance > rSupply || tBalance > tSupply) {
                return rSupply / tSupply;
            }
            rSupply -= rBalance;
            tSupply -= tBalance;
        }
        if (rSupply < _rTotalSupply / _tTotalSupply) {
            return rSupply / tSupply;
        }
        return _rTotalSupply / _tTotalSupply;
    }

    function _getTaxValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tax = (tAmount * taxFee) / 10000;
        uint256 newAmount = tAmount - tax;
        return (tax, newAmount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");
        uint256 rate = _getRate();
        uint256 rAmount = amount * rate;
        _rBalances[account] += rAmount;
        _rTotalSupply += rAmount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 rate = _getRate();
        uint256 rAmount = amount * rate;
        uint256 accountBalance = _rBalances[account];
        require(accountBalance >= rAmount, "ERC20: burn amount exceeds balance");
        unchecked {
            _rBalances[account] = accountBalance - rAmount;
        }
        _rTotalSupply -= rAmount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address account, address spender, uint256 amount) private {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function _spendAllowance(address account, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(account, spender);
        if (currentAllowance != MAX) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(account, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Check for TimeLock
        if (timeLockEnabled && (from == owner() || to == owner())) {
            require(block.timestamp > lastSellTime + timeLockDuration, "TimeLock: Cannot transfer now");
        }

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            _transferWithoutFee(from, to, amount);
        } else {
            _transferWithFee(from, to, amount);
        }

        // Set last sell time
        if (to == owner() && timeLockEnabled) {
            lastSellTime = block.timestamp;
        }
    }

    function _transferWithoutFee(address sender, address recipient, uint256 tAmount) private {
        uint256 rate = _getRate();
        uint256 rAmount = tAmount * rate;
        _rBalances[sender] -= rAmount;
        _rBalances[recipient] += rAmount;
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferWithFee(address sender, address recipient, uint256 tAmount) private {

        // Check if a time lock is active
        if (timeLockEnabled && (sender == owner() || recipient == owner())) {
            require(block.timestamp > lastSellTime + timeLockDuration, "TimeLock: Cannot transfer now");
            taxFee = highTaxFee; // Set the high tax fee during the time lock
        } else {
            taxFee = 200; // Reset to the default tax fee (2%)
        }

        (uint256 tFee, uint256 newAmount) = _getTaxValues(tAmount);
        totalFees += tFee;
        uint256 rate = _getRate();
        uint256 rAmount = tAmount * rate;
        uint256 rFee = tFee * rate;
        uint256 newRAmount = newAmount * rate;
        _rBalances[sender] -= rAmount;
        _rBalances[recipient] += newRAmount;
        _rBalances[address(this)] += rFee;
        emit Transfer(sender, recipient, newAmount);
    }

    // TimeLock Functions
    function enableTimeLock(bool _enabled) external onlyOwner {
        timeLockEnabled = _enabled;
    }

    function setTimeLockDuration(uint256 _duration) external onlyOwner {
        require(_duration <= 30 days, "TimeLock: Duration too long");
        timeLockDuration = _duration;
    }

    // Owner can change the tax
    function setTaxPercentages(uint256 newDefaultTax, uint256 newFinalTax) public onlyOwner {
        taxFee = newDefaultTax;
        highTaxFee = newFinalTax;
    }

}
