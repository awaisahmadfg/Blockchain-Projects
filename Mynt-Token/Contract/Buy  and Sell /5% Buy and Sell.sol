// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FoundersMynt is Ownable, Pausable, ERC20{

    using SafeMath for uint256;
    uint256 constant ONE_BILLION_ETHERS = 1000000000 ether;
    uint256 constant TWENTY_THOUSANDS = 20000;
    uint8 constant TAX_PERCENTAGE = 5;
    address payable constant ORIGIN_ADDRESS = payable(0xA33d159Be1Bb7f094Baa2cfb4a5f6f9ac72D77CE);

    mapping (address => bool) taxedAccounts;
    
    constructor() Ownable(msg.sender) ERC20("FOUNDERS_MYNT_TOKEN","FMYNT"){
        _mint(address(this),ONE_BILLION_ETHERS);
        _transfer(address(this), ORIGIN_ADDRESS, calculatePercentage(ONE_BILLION_ETHERS,10)); //10% private safe
        _transfer(address(this), ORIGIN_ADDRESS, calculatePercentage(ONE_BILLION_ETHERS,10)); //10% team tokens
        _transfer(address(this), ORIGIN_ADDRESS, calculatePercentage(ONE_BILLION_ETHERS,10)); //10% treasure box and gamification
    }

    function calculatePercentage(uint256 _amount, uint256 _percentage) public pure returns(uint256){
        return (_amount.mul(_percentage)).div(100);
    }

    function transfer(address to, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 taxDeduction;
        if(taxedAccounts[to] == true){
            taxDeduction = calculatePercentage(value, TAX_PERCENTAGE);
            _transfer(owner, ORIGIN_ADDRESS, taxDeduction);
        }
        _transfer(owner, to, value.sub(taxDeduction));
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        address spender = _msgSender();
        uint256 taxDeduction;
        _spendAllowance(from, spender, value);
        if(taxedAccounts[to] == true){
            taxDeduction = calculatePercentage(value, TAX_PERCENTAGE);
            _transfer(from, ORIGIN_ADDRESS, taxDeduction);
        }
        _transfer(from, to, value.sub(taxDeduction));
        return true;
    }

    function buyFoundersMynt() public payable whenNotPaused {
        require(msg.value >= 0.00005 ether, "Minimum 0.00005 ethers required.");
        require(balanceOf(address(this)) >= msg.value.mul(TWENTY_THOUSANDS), "Not enugh tokens left to buy.");
        uint256 taxDeduction = calculatePercentage(msg.value.mul(TWENTY_THOUSANDS), TAX_PERCENTAGE);
        _transfer(address(this), ORIGIN_ADDRESS, taxDeduction);
        _transfer(address(this), msg.sender, (msg.value.mul(TWENTY_THOUSANDS)).sub(taxDeduction));
    }

    function flushEth() public onlyOwner {
        require(address(this).balance > 0, "This contract does not hold any ethers.");
        ORIGIN_ADDRESS.transfer(address(this).balance);
    }

    function addTaxedAccount(address _taxedAddress) public onlyOwner {
        require(_taxedAddress != address(0), "Empty address is not allowed.");
        taxedAccounts[_taxedAddress] = true;
    }

    function deleteTaxedAccount(address _taxedAddress) public onlyOwner {
        require(_taxedAddress != address(0), "Empty address is not allowed.");
        require(taxedAccounts[_taxedAddress] == true , "This address is not in the taxed accounts list");
        delete taxedAccounts[_taxedAddress];
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function checkTaxedAccount(address _taxedAddress) public view returns(bool){
        return taxedAccounts[_taxedAddress];
    }
}
