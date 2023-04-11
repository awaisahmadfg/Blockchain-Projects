// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface MintingContract {
    function fGetRoyaltyReceiver(
        uint256 _tokenid
    ) external view returns (address reciver);

    function fgetRoyaltyFeeInPBP(
        uint256 _tokenId
    ) external view returns (uint256 _royaltyfee);
}

contract Marketplace is
    Initializable,
    ERC1155HolderUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    MintingContract private mintingContract;

    address mintingContractAddress;

    address public MarketPlaceOwner;
    uint256 public serviceFeePercentage;

    uint256 public fixedPriceId;
    uint256 public auctionId;

    function initialize(address _mintingContract) public initializer {
        serviceFeePercentage = 250;
        MarketPlaceOwner = msg.sender;
        mintingContractAddress = _mintingContract;
        mintingContract = MintingContract(_mintingContract);

        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    struct FixedPrice {
        bool isSold;
        bool listed;
        uint256 price;
        uint256 tokenId;
        uint256 noOfCopies;
        address owner;
        address newOwner;
        address nftAddress;
    }

    struct Auction {
        bool isSold;
        bool listed;
        bool nftClaimed;
        uint256 tokenId;
        uint256 numberofcopies;
        uint256 initialPrice;
        uint256 auctionEndTime;
        uint256 auctionStartTime;
        uint256 currentBidAmount;
        address nftOwner;
        address nftAddress;
        address currentBidder;
    }

    mapping(uint256 => Auction) public auction;
    mapping(uint256 => FixedPrice) public fixedPrice;

    function listItemForFixedPrice(
        uint256 _tokenId,
        uint256 _noOfCopies,
        uint256 _price,
        address _nftAddress
    )
        external
        whenNotPaused
        OnlyTokenHolders(_tokenId, _nftAddress)
        returns (uint256)
    {
        require(_tokenId >= 0, "No Negative number is allowed");
        require(_noOfCopies > 0, "nft amount can't be zero");
        require(_price > 0, "price can not be 0");
        require(_nftAddress != address(0), "Invalid NFT Address");

        fixedPriceId++;

        fixedPrice[fixedPriceId].owner = msg.sender;
        fixedPrice[fixedPriceId].listed = true;
        fixedPrice[fixedPriceId].price = _price;
        fixedPrice[fixedPriceId].tokenId = _tokenId;
        fixedPrice[fixedPriceId].noOfCopies = _noOfCopies;

        if (_nftAddress != mintingContractAddress) {
            fixedPrice[fixedPriceId].nftAddress = mintingContractAddress;
            IERC1155Upgradeable(mintingContractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _noOfCopies,
                "0x00"
            );
        } else {
            fixedPrice[fixedPriceId].nftAddress = _nftAddress;
            IERC1155Upgradeable(_nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _noOfCopies,
                "0x00"
            );
        }

        return fixedPriceId;
    }

    //--List item for Auction--------------------------------------------------------------------/

    function listItemForAuction(
        uint256 _initialPrice,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        uint256 _tokenId,
        uint256 _numberofcopies,
        address _nftAddress
    )
        external
        whenNotPaused
        OnlyTokenHolders(_tokenId, _nftAddress)
        returns (uint256)
    {
        require(_initialPrice > 0, "intial price can't be zero.");
        require(_tokenId >= 0, "tokenid can't be negative.");
        require(_numberofcopies > 0, "0 amount can't be listed.");
        require(_nftAddress != address(0), "Invalid address.");
        require(_auctionStartTime >= block.timestamp && _auctionEndTime > block.timestamp, "startTime and end time must be greater then currentTime");
        require(_auctionStartTime < _auctionEndTime,"Auction start time must be less than end time");

        auctionId++;

        auction[auctionId].listed = true;
        auction[auctionId].tokenId = _tokenId;
        auction[auctionId].numberofcopies = _numberofcopies;
        auction[auctionId].initialPrice = _initialPrice;
        auction[auctionId].auctionStartTime = _auctionStartTime;
        auction[auctionId].auctionEndTime = _auctionEndTime;
        auction[auctionId].nftOwner = msg.sender;

        if (_nftAddress != mintingContractAddress) {
            auction[auctionId].nftAddress = mintingContractAddress;
            IERC1155Upgradeable(mintingContractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _numberofcopies,
                "0x00"
            );
        } else {
            auction[auctionId].nftAddress = _nftAddress;
            IERC1155Upgradeable(_nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _numberofcopies,
                "0x00"
            );
        }

        return auctionId;
    }

    // Buy Fixed Price---------------------------------------------------------------------------------------------------

    function BuyFixedPriceItem(
        uint256 _fixedId
    ) external payable whenNotPaused {
        require(_fixedId > 0, "inavlid auction id");
        require(
            msg.sender != fixedPrice[_fixedId].owner,
            "owner of this nft can not buy"
        );
        require(
            msg.value >= fixedPrice[_fixedId].price,
            "send wrong amount in fifxed price"
        );
        require(fixedPrice[fixedPriceId].listed, "nft isnt listed yet.");
        require(!fixedPrice[_fixedId].isSold, "Item is already Sold");

        fixedPrice[_fixedId].newOwner = msg.sender;
        uint256 serviceFee = calulatePlatFormServiceFee(
            fixedPrice[_fixedId].price,
            serviceFeePercentage
        );
        console.log("serviceFee: ", serviceFee);

        if (mintingContractAddress == fixedPrice[fixedPriceId].nftAddress) {
            uint256 _royaltyPercentage = mintingContract.fgetRoyaltyFeeInPBP(
                fixedPrice[_fixedId].tokenId
            );

            console.log("_royaltyPercentage: ", _royaltyPercentage);

            address _royaltyReciver = mintingContract.fGetRoyaltyReceiver(
                fixedPrice[_fixedId].tokenId
            );
            console.log("_royaltyReciver: ", _royaltyReciver);

            uint256 royaltyFee = calculateRoyaltyFee(
                fixedPrice[_fixedId].price,
                _royaltyPercentage
            );
            
            console.log("royaltyFee: ", royaltyFee); // 2 ETH

            uint256 totalFee = serviceFee + royaltyFee; // 2500 + 2e^18 = 10,000,000,000,000,002,500 = 10.0000000000000025 wei = 0.00000000000000001 Eth
            console.log("totalFee: ", totalFee);
            uint256 amountSendToSeller = fixedPrice[_fixedId].price.sub(totalFee); // 9,999,999,999,999,999,989.9999999999999975

            console.log("amountSendToSeller: ", amountSendToSeller);
            transferFunds(MarketPlaceOwner, serviceFee);
            console.log("serviceFee", serviceFee);
            transferFunds(_royaltyReciver, royaltyFee);
            console.log("2nd one");
            transferFunds(fixedPrice[_fixedId].owner, amountSendToSeller);
            console.log("3rd one");
            
        } else {
            uint256 amountSendToSeller = fixedPrice[_fixedId].price.sub(
                serviceFee
            );

            transferFunds(MarketPlaceOwner, serviceFee);
            transferFunds(fixedPrice[_fixedId].owner, amountSendToSeller);
        }

        fixedPrice[_fixedId].isSold = true;

        IERC1155Upgradeable(fixedPrice[_fixedId].nftAddress).safeTransferFrom(
            address(this),
            fixedPrice[_fixedId].newOwner,
            fixedPrice[_fixedId].tokenId,
            fixedPrice[_fixedId].noOfCopies,
            "0x00"
        );
    }

    function startBid(uint256 _auctionId) external payable whenNotPaused {
        require(_auctionId > 0, "inavlid auction id");
        require(
            block.timestamp > auction[_auctionId].auctionStartTime && block.timestamp < auction[_auctionId].auctionEndTime,
            "you canot bid before auction started and after AuctionEnd"
        );
        require(
            msg.sender != auction[_auctionId].nftOwner,
            "Seller can not place the bid on his own NFT"
        );
        require(
            msg.value >= auction[_auctionId].initialPrice,
            "place a higher Bid than initial price"
        );
        require(
            auction[_auctionId].listed,
            "Nft must be listed before bidding"
        );
        require(!auction[_auctionId].isSold, "Item is already Sold");

        address currentBidder = auction[_auctionId].currentBidder;

        uint256 currentBidAmount = auction[_auctionId].currentBidAmount;

        console.log("currentBidAmount: ", currentBidAmount);
        console.log("msg.value: ", msg.value);

        require(
            msg.value > currentBidAmount,
            "There is already higer or equal bid exist"
        );

        if (msg.value > currentBidAmount) {
            transferFunds(currentBidder, currentBidAmount);
        }

        auction[_auctionId].currentBidder = msg.sender;
        auction[_auctionId].currentBidAmount = msg.value;

    }

    function auctionEnd(uint256 _auctionId) external {
        require(_auctionId > 0, "inavlid auction id");
        require(
            msg.sender == auction[_auctionId].nftOwner,
            "Only the seller of NFT can end this auction"
        );
        require(
            block.timestamp < auction[_auctionId].auctionEndTime,
            "auction has ended, no more bids accepted"
        );
        require(
            !auction[_auctionId].isSold,
            "You have already ended the auction"
        );
        require(
            !auction[_auctionId].nftClaimed,
            "Higiest bidder already claimed the nft."
        );

        uint256 serviceFee = calulatePlatFormServiceFee(
            auction[_auctionId].currentBidAmount,
            serviceFeePercentage
        );

        if (mintingContractAddress == auction[_auctionId].nftAddress) {
            address _royaltyReciver = mintingContract.fGetRoyaltyReceiver(
                auction[_auctionId].tokenId
            );
            uint256 _royaltyPercentage = mintingContract.fgetRoyaltyFeeInPBP(
                auction[_auctionId].tokenId
            );

            uint256 royaltyFee = calculateRoyaltyFee(
                auction[_auctionId].currentBidAmount,
                _royaltyPercentage
            );
            uint256 totalFee = serviceFee + royaltyFee;
            uint256 amountSendToSeller = auction[_auctionId].currentBidAmount.sub(
                totalFee
            );

            transferFunds(MarketPlaceOwner, serviceFee);
            transferFunds(_royaltyReciver, royaltyFee);
            transferFunds(auction[_auctionId].nftOwner, amountSendToSeller);
        } else {
            uint256 amountSendToSeller = auction[_auctionId].currentBidAmount.sub(
                serviceFee
            );

            transferFunds(MarketPlaceOwner, serviceFee);
            transferFunds(auction[_auctionId].nftOwner, amountSendToSeller);
        }

        auction[_auctionId].isSold = true;

        IERC1155Upgradeable(auction[_auctionId].nftAddress).safeTransferFrom(
            address(this),
            auction[_auctionId].currentBidder,
            auction[_auctionId].tokenId,
            auction[_auctionId].numberofcopies,
            "0x00"
        );
    }

    // Claim NFT

    function claimNft(uint256 _auctionId) external {
        require(_auctionId > 0, "inavlid auction id");
        require(
            msg.sender == auction[_auctionId].currentBidder,
            "Only Higest Bidder can claim the NFT"
        );
        require(
            !auction[_auctionId].nftClaimed,
            "Higiest bidder already claimed the nft."
        );

        if (!auction[_auctionId].isSold) {
            require(
                block.timestamp > auction[_auctionId].auctionEndTime,
                "Canot claim nft auctiom time not ended!"
            );
        } else {
            revert(
                "Auction Ended by the Seller and NFT Already tranfered to your wallet"
            );
        }

        uint256 serviceFee = calulatePlatFormServiceFee(
            auction[_auctionId].currentBidAmount,
            serviceFeePercentage
        );

        if (mintingContractAddress == auction[_auctionId].nftAddress) {
            address _royaltyReciver = mintingContract.fGetRoyaltyReceiver(
                auction[_auctionId].tokenId
            );
            uint256 _royaltyPercentage = mintingContract.fgetRoyaltyFeeInPBP(
                auction[_auctionId].tokenId
            );

            uint256 royaltyFee = calculateRoyaltyFee(
                auction[_auctionId].currentBidAmount,
                _royaltyPercentage
            );
            uint256 totalFee = serviceFee + royaltyFee;
            uint256 amountSendToSeller = auction[_auctionId].currentBidAmount.sub(
                totalFee
            );

            transferFunds(MarketPlaceOwner, serviceFee);
            transferFunds(_royaltyReciver, royaltyFee);
            transferFunds(auction[_auctionId].nftOwner, amountSendToSeller);
        } else {
            uint256 amountSendToSeller = auction[_auctionId].currentBidAmount.sub(
                serviceFee
            );

            transferFunds(MarketPlaceOwner, serviceFee);
            transferFunds(auction[_auctionId].nftOwner, amountSendToSeller);
        }

        auction[_auctionId].nftClaimed = true;

        IERC1155Upgradeable(auction[_auctionId].nftAddress).safeTransferFrom(
            address(this),
            auction[_auctionId].currentBidder,
            auction[_auctionId].tokenId,
            auction[_auctionId].numberofcopies,
            "0x00"
        );
    }

    function cancellListingForFixedPRice(uint256 listingID) external {
        require(
            msg.sender == fixedPrice[listingID].owner,
            "You are not the owner"
        );
        require(fixedPrice[listingID].listed, "NFT is not liosted yet.");
        require(
            !fixedPrice[listingID].isSold,
            "NFT is already sold , can not perform this action now"
        );

        IERC1155Upgradeable(fixedPrice[listingID].nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            fixedPrice[listingID].tokenId,
            fixedPrice[listingID].noOfCopies,
            "0x00"
        );

        fixedPrice[listingID].listed = false;
        fixedPrice[listingID].price = 0;
        fixedPrice[listingID].tokenId = 0;
        fixedPrice[listingID].noOfCopies = 0;
        fixedPrice[listingID].nftAddress = address(0);
    }

    function cancellListingForAuction(uint256 listingID) external {
        require(
            msg.sender == auction[listingID].nftOwner,
            "You are not the owner"
        );
        require(
            !auction[listingID].isSold,
            "NFT is alrady sold , can not perform this action now"
        );
        require(!auction[listingID].nftClaimed, "NFT is alrady claimed,");

        IERC1155Upgradeable(auction[listingID].nftAddress).safeTransferFrom(
            address(this),
            auction[listingID].nftOwner,
            auction[listingID].tokenId,
            auction[listingID].numberofcopies,
            "0x00"
        );

        auction[listingID].listed = false;
        auction[listingID].tokenId = 0;
        auction[listingID].numberofcopies = 0;
        auction[listingID].initialPrice = 0;
        auction[listingID].auctionEndTime = 0;
        auction[listingID].auctionStartTime = 0;
        auction[listingID].nftAddress = address(0);
        auction[listingID].currentBidAmount = 0;
        auction[listingID].currentBidder = address(0);
    }

    function setPlatFormServiceFeePercentage(
        uint256 _platFormServiceFeePercentage
    ) public returns (uint256) {
        require(
            msg.sender == MarketPlaceOwner,
            "Only Owner can set ServiceFee"
        );
        require(
            _platFormServiceFeePercentage >= 100 &&
                _platFormServiceFeePercentage <= 1000,
            "fee % must between in 1% to 10% "
        );

        serviceFeePercentage = _platFormServiceFeePercentage;
        return serviceFeePercentage;
    }

    function calulatePlatFormServiceFee(
        uint256 _salePrice,
        uint256 _serviceFeePercentage
    ) private pure returns (uint256) {
        require(_salePrice != 0, "Price of NFT can not be zero");
        require(_serviceFeePercentage != 0, "_PBP can not be zero");

        uint256 serviceFee = _salePrice.mul(_serviceFeePercentage).div(10000);

        return serviceFee;
    }

    function calculateRoyaltyFee(
        uint256 _salePrice,
        uint256 _royaltyFeePercentage
    ) private pure returns (uint256) {
        require(_salePrice != 0, "_salePrice can not be zero");
        require(_royaltyFeePercentage != 0, "_PBP  can not zero");

        uint256 RoyaltyFee = _salePrice.mul(_royaltyFeePercentage).div(10000);

        return RoyaltyFee;
    }

    function transferFunds(address _recipient, uint256 _amount) private {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Transfer  fee failed");
    }

    modifier onlyOwnerr() {
        require(msg.sender == MarketPlaceOwner, "Only the contract fundReceivor can call this function");
        _; 
    }

    function withdrawFunds() payable public onlyOwnerr {
        require(address(this).balance > 0, "Ether balance is 0 in contract");
        (bool success, ) = payable(MarketPlaceOwner).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    modifier OnlyTokenHolders(uint256 _tokenid, address _nftAddress) {
        require(
            IERC1155Upgradeable(_nftAddress).balanceOf(msg.sender, _tokenid) >
                0,
            "You are not the owner of Token"
        );
        _;
    }


}

//0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
