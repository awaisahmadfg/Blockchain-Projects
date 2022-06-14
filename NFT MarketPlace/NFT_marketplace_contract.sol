// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract NFTMarketPlace is ERC1155, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    struct Listing{
        uint256 savedTokenId;
        uint256 royalityFee;
        uint256 serviceFee;
        uint256 afterCutPrice;
        uint256 amount;
        uint256 price;
        uint256 soldPrice;
        address seller;
        address newOwner;
        bool    forSale;
    }
    struct Auction{
        uint256 heighestBiddingAmount;
        uint256 auctionStartingTime;
        uint256 auctionEndingTime;
        uint256 savedTokenId;
        uint256 soldPrice;
        uint256 royalityFee;
        uint256 serviceFee;
        uint256 afterCutPrice;
        uint256 amount;
        uint256 minimumPrice;
        address seller;
        address newOwner;
        address heighestBidder;
    }
    uint256 private tokenId;
    uint256 public defaultRoyalityfee;
    uint256 public defaultServicefee;
    address public marketPlaceOwner;
    mapping(uint256 => string) private tokenURIs;
    mapping(uint256 => Listing) private listings;
    mapping(uint256 => Auction) private auctions;
    mapping(uint256 => address) private nftOwnerAddresses;
    constructor(uint256 _setRoyalityFee,uint256 _setServiceFee) ERC1155("") {
        marketPlaceOwner = msg.sender;
        setRoyalityFeePercentage(_setRoyalityFee);
        setServiceFeePercentage(_setServiceFee);
    }
    function setURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        tokenURIs[_tokenId] = _tokenURI;
    }
    function getURI(uint256 _tokenId) public view returns (string memory) {
        string memory tokenURI = tokenURIs[_tokenId];
        return tokenURI;
    }
    function mint(address _accountAddress, uint256 _amount, string memory _tokenURI) public nonReentrant {
        tokenId++;
        _mint(_accountAddress, tokenId, _amount, "0x00");
        setURI(tokenId, _tokenURI);
        nftOwnerAddresses[tokenId] = msg.sender;
    }
    function ListToken(uint256 _tokenId, uint256 _tokenAmount, uint256 _tokenPrice) public nonReentrant ApproveForAll() onlyTokenHolders(_tokenId) returns(bool){
        Listing memory listing = Listing(_tokenId, 0, 0, 0, _tokenAmount, _tokenPrice,0, msg.sender,0x0000000000000000000000000000000000000000,true);
        //safeTransferFrom(msg.sender, address(this), _tokenId, _tokenAmount, "0x00");
        listings[_tokenId] = listing;
        return true;
    }
    function getListingInfo() public view returns (Listing memory) {
        return listings[tokenId];
    }
    function BuyToken(uint _tokenId) payable public nonReentrant returns(bool){
        Listing storage listing = listings[_tokenId];
        require(msg.sender != listing.seller, "Seller cannot be buyer");
        require(msg.value >= listing.price,"You have to pay actual price to buy this NFT.");
         listing.royalityFee =  calculateRoyaltyFee(listing.price);
         listing.serviceFee = calculateServicetyFee(listing.price);
         listing.afterCutPrice = listing.price - (listing.serviceFee + listing.royalityFee);
        _safeTransferFrom(listing.seller, msg.sender, _tokenId, listing.amount, "0x00");
        payable(listing.seller).transfer(listing.afterCutPrice);
        payable(nftOwnerAddresses[tokenId]).transfer(listing.royalityFee);
        payable(marketPlaceOwner).transfer(listing.serviceFee);
        listings[_tokenId].newOwner = msg.sender;
        listings[_tokenId].soldPrice = msg.value;
        return true;
    }
    function StartAuction(uint256 _tokenId, uint256 _tokenAmount, uint256 _tokenMinimumPrice, uint256 _auctionEndingTime,uint256 _auctionStartingtime ) public nonReentrant {
        Auction memory auction = Auction(0, _auctionStartingtime, _auctionEndingTime, _tokenId,0, 0, 0, 0, _tokenAmount, _tokenMinimumPrice,
            msg.sender, 0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000);
        auctions[_tokenId] = auction;
    }
    function getAuctionInfo() public view returns (Auction memory) {
        return auctions[tokenId];
    }
    function startBidding(uint256 _tokenId) public nonReentrant payable{
        Auction storage auction = auctions[_tokenId];
        require(auction.auctionStartingTime <= auction.auctionEndingTime,"Bidding time is ended.");
        require(msg.value > auction.minimumPrice,"Bidding amount must be heigher then minimum amount.");
        require(msg.value > auction.heighestBiddingAmount,"There is already higher or equal bid");
        uint256 currentBid = auction.heighestBiddingAmount;
        address currentBidder = auction.heighestBidder;
        if(msg.value > currentBid){
            payable(currentBidder).transfer(currentBid);
        }
        auction.heighestBiddingAmount = msg.value;
        auction.heighestBidder = msg.sender;
    }
    function auctionEnded(uint256 _tokenId) public nonReentrant {
        Auction storage auction = auctions[_tokenId];
        require(auction.auctionEndingTime > auction.auctionStartingTime,"Bidding time is not ended yet.");
        auction.royalityFee =  calculateRoyaltyFee(auction.heighestBiddingAmount);
        auction.serviceFee = calculateServicetyFee(auction.heighestBiddingAmount);
        auction.afterCutPrice = auction.heighestBiddingAmount - (auction.serviceFee + auction.royalityFee);
        _safeTransferFrom(auction.seller, auction.heighestBidder, _tokenId, auction.amount, "0x00");
        payable(auction.seller).transfer(auction.afterCutPrice);
        payable(nftOwnerAddresses[tokenId]).transfer(auction.royalityFee);
        payable(marketPlaceOwner).transfer(auction.serviceFee);
        auctions[_tokenId].newOwner = auction.heighestBidder;
        auctions[_tokenId].soldPrice = auction.heighestBiddingAmount;
    }
    // uint256 public royalityfee;
    function calculateRoyaltyFee(uint256 _salePrice) public view returns (uint256) {
        require(defaultRoyalityfee != 0,"Set royalityfee first.");
        require(defaultRoyalityfee <= 10000, "ERC2981: royalty fee will exceed salePrice");
        uint256 royalityfee = _salePrice.mul(defaultRoyalityfee).div(10000);
        return royalityfee;
    }
    function calculateServicetyFee(uint256 _salePrice) public view returns (uint256) {
        require(defaultServicefee != 0,"Set Service fee first.");
        require(defaultServicefee <= 10000, "ERC2981: royalty fee will exceed salePrice");
        uint256 servicefee = _salePrice.mul(defaultServicefee).div(10000);
        return servicefee;
    }
    function setRoyalityFeePercentage(uint256 _newRoyalityFee) public nonReentrant onlyOwner() {
        defaultRoyalityfee = _newRoyalityFee;
    }
    function setServiceFeePercentage(uint256 _newServiceFee) public nonReentrant onlyOwner() {
        defaultServicefee = _newServiceFee;
    }
    modifier onlyTokenHolders(uint256 tokenid){
        require(balanceOf(msg.sender,tokenid) > 0 , "Only owners of this token can access this");
         _;
    }
    modifier ApproveForAll() {
        require(isApprovedForAll(msg.sender, address(this)) ,"You have to approve amount of tokens First");
        _;
    }
}
