// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IIdeaNFT {
    function getRoyaltyReciever(uint256 tokenId) external view returns (address);
    function getNFTExpireTime(uint256 tokenId) external view returns (uint256);
}

/**
 * @title IdeaMarketplace (Upgradeable)
 * @dev Implements an NFT marketplace that allows listing and buying NFTs for fixed prices and auction.
 * This contract uses UUPS (Universal Upgradeable Proxy Standard) for upgradeability.
 */
contract IdeaMarketplace is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    // Custom Errors
    error TokenIdMustBeGreaterThanZero();
    error ListPriceCannotBeZero();
    error ContractAddressCannotBeEmpty();
    error NFTHaveExpired();
    error InvalidFixedNFTId();
    error OwnerCannotBuyOwnNFT();
    error PaymentDoesNotMeetRequiredPrice();
    error NFTNotListedYet();
    error ItemAlreadySold();
    error InvalidAuctionId();
    error CannotBidBeforeAuctionStartedOrAfterEnd();
    error SellerCannotPlaceBidOnOwnNFT();
    error BidMustBeHigherThanInitialPrice();
    error NFTMustBeListedBeforeBidding();
    error HigherOrEqualBidAlreadyExists();
    error OnlySellerCanEndAuction();
    error AuctionHasEnded();
    error AuctionAlreadyEnded();
    error HighestBidderAlreadyClaimedNFT();
    error OnlyHighestBidderCanClaimNFT();
    error CannotClaimNFTAsAuctionTimeNotEnded();
    error AuctionEndedNFTTransferredToHighestBidder();
    error PriceOfNFTCannotBeZero();
    error SalePriceCannotBeZero();
    error TransferFeeFailed();
    error NotOwnerOfTokenId();
    error OwnerOfTokenIdDoesNotExist();
    error NotOwnerOfListing();
    error NFTNotListed();
    error NFTCannotBeCancelledAsAlreadySold();
    error InitialPriceCannotBeZero();
    error TokenIdCannotBeNegative();
    error InvalidAddress();
    error StartTimeAndEndTimeMustBeGreaterThanCurrentTime();
    error AuctionStartTimeMustBeLessThanEndTime();
    error InvalidIdeaNFTAddress();

    address public ideaNftContractAddress;
    IIdeaNFT public ideaNftContract;

    uint256 public fixedPriceId;
    uint256 public auctionId;
    uint256 public serviceFeePercentage;
    uint256 public royaltyFeePercentage;
    address public marketPlaceOwner;

    event NFTListed(address nftOwner, uint256 tokenId, uint256 listedPrice);
    event NFTDelisted(uint256 tokenId, address nftOwner);
    event NFTBought(uint256 listId, address newOwner, uint256 tokenId);

    /**
     * @notice Represents a fixed price NFT data.
     * @dev Packed struct: bools and uint128 values packed to save storage slots
     */
    struct FixedPrice {
        bool isSold;
        bool listed;
        uint128 nftPrice;
        uint128 tokenId;
        uint128 royaltyFeePercentage;
        address owner;
        address newOwner;
        address nftAddress;
    }

    /**
     * @notice Represents a auction base NFT data.
     * @dev Packed struct: bools and smaller uint types packed to save storage slots
     */
    struct Auction {
        bool isSold;
        bool listed;
        bool nftClaimed;
        uint128 tokenId;
        uint128 initialPrice;
        uint128 currentBidAmount;
        uint64 auctionEndTime;
        uint64 auctionStartTime;
        uint128 royaltyFeePercentage;
        address nftOwner;
        address nftAddress;
        address currentBidder;
    }

    /**
     * @notice Mapping from NFT ID to FixedPrice struct.
     */
    mapping(uint256 => FixedPrice) public fixedPrice;

    /**
     * @notice Mapping from NFT ID to Auction struct.
     */
    mapping(uint256 => Auction) public auction;  

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the IdeaMarketplace contract with the given IdeaNFT contract address.
     * @dev Initializer function that replaces constructor for upgradeable contracts.
     * @param _ideaNftAddress The address of the IdeaNFT contract.
     */
    function initialize(address _ideaNftAddress) public initializer {
        if (_ideaNftAddress == address(0)) revert InvalidIdeaNFTAddress();
        if (msg.sender == address(0)) revert InvalidAddress();

        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        serviceFeePercentage = 1000;
        royaltyFeePercentage = 500;
        marketPlaceOwner = msg.sender;
        ideaNftContractAddress = _ideaNftAddress;
        ideaNftContract = IIdeaNFT(_ideaNftAddress);
    }

    /**
     * @notice Lists an NFT for sale at a fixed price on the marketplace.
     * @dev Transfers the NFT from the owner to the marketplace contract.
     * @param _tokenId The ID of the NFT to list.
     * @param _nftPrice The price at which to list the NFT.
     * @param _nftContractAddress The address of the NFT contract.
     * @return The ID of the fixed price listing.
     */
    function listNftForFixedPrice(uint256 _tokenId, uint256 _nftPrice, address _nftContractAddress) external OnlyTokenHolders(_tokenId, _nftContractAddress) returns (uint256) {
        if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();
        if (_nftPrice == 0) revert ListPriceCannotBeZero();
        if (_nftContractAddress == address(0)) revert ContractAddressCannotBeEmpty();
        uint256 expiryTime = ideaNftContract.getNFTExpireTime(_tokenId);
        if (block.timestamp > expiryTime) revert NFTHaveExpired();

        address originalCreator = ideaNftContract.getRoyaltyReciever(_tokenId);

        if (fixedPrice[_tokenId].royaltyFeePercentage == 0) {
            if (msg.sender == originalCreator) {
                fixedPrice[_tokenId].royaltyFeePercentage = uint128(royaltyFeePercentage);
            }   
        }

        uint128 effectiveRoyaltyFee = fixedPrice[_tokenId].royaltyFeePercentage;

        unchecked {
            fixedPriceId++;
        }

        fixedPrice[_tokenId] = FixedPrice({
            isSold: false,
            listed: true,
            nftPrice: uint128(_nftPrice),
            tokenId: uint128(_tokenId),
            royaltyFeePercentage: effectiveRoyaltyFee,
            owner: msg.sender,
            newOwner: address(0),
            nftAddress: _nftContractAddress
        });
        
        if (_nftContractAddress != ideaNftContractAddress) {
            fixedPrice[fixedPriceId].nftAddress = ideaNftContractAddress;
            IERC721(address(_nftContractAddress)).transferFrom(msg.sender, address(this), _tokenId);
        }else{
            fixedPrice[fixedPriceId].nftAddress = _nftContractAddress;
            IERC721(address(_nftContractAddress)).transferFrom(msg.sender, address(this), _tokenId);
        }

        emit NFTListed(msg.sender, _tokenId, _nftPrice);
        return fixedPriceId;
    }

    /**
     * @notice Buys an NFT listed at a fixed price.
     * @dev Transfers funds and NFT ownership.
     * @param _fixedId The tokenId of the fixed price listing.
     */
    function buyFixedPriceNft(uint256 _fixedId) external payable {
        if (_fixedId == 0) revert InvalidFixedNFTId();
        if (msg.sender == fixedPrice[_fixedId].owner) revert OwnerCannotBuyOwnNFT();
        if (msg.value < uint256(fixedPrice[_fixedId].nftPrice)) revert PaymentDoesNotMeetRequiredPrice();
        if (!fixedPrice[_fixedId].listed) revert NFTNotListedYet();
        if (fixedPrice[_fixedId].isSold) revert ItemAlreadySold();
        uint256 expiryTime = ideaNftContract.getNFTExpireTime(uint256(fixedPrice[_fixedId].tokenId));
        if (block.timestamp > expiryTime) revert NFTHaveExpired();
        
        fixedPrice[_fixedId].newOwner = msg.sender;
        
        uint256 serviceFee = calulateMindminerServiceFee(
            uint256(fixedPrice[_fixedId].nftPrice),
            serviceFeePercentage
        );

        if (ideaNftContractAddress == fixedPrice[fixedPriceId].nftAddress) {
            uint128 _royaltyPercentage = fixedPrice[_fixedId].royaltyFeePercentage;
            address _royaltyReciever = ideaNftContract.getRoyaltyReciever(uint256(fixedPrice[_fixedId].tokenId));

            uint256 royaltyFee = calculateRoyaltyFee(
                uint256(fixedPrice[_fixedId].nftPrice),
                uint256(_royaltyPercentage)
            );

            uint256 totalFee;
            uint256 amountSendToSeller;
            unchecked {
                totalFee = serviceFee + royaltyFee;
                amountSendToSeller = uint256(fixedPrice[_fixedId].nftPrice) - totalFee;
            }

            transferFunds(marketPlaceOwner, serviceFee);
            transferFunds(_royaltyReciever, royaltyFee);
            transferFunds(fixedPrice[_fixedId].owner, amountSendToSeller);
        }else{
            uint256 amountSendToSeller;
            unchecked {
                amountSendToSeller = uint256(fixedPrice[_fixedId].nftPrice) - serviceFee;
            }
            transferFunds(marketPlaceOwner, serviceFee);
            transferFunds(fixedPrice[_fixedId].owner, amountSendToSeller);
        }

        fixedPrice[_fixedId].isSold = true;

        IERC721(fixedPrice[_fixedId].nftAddress).transferFrom(address(this), fixedPrice[_fixedId].newOwner, uint256(fixedPrice[_fixedId].tokenId));
        emit NFTBought(_fixedId, msg.sender, uint256(fixedPrice[_fixedId].tokenId));
    }

    /**
     * @notice Lists an NFT for sale for auction on the marketplace.
     * @dev Transfers the NFT from the owner to the marketplace contract.
     * @param _initialPrice The price of that NFT which is listing for auction.
     * @param _auctionStartTime The NFT start time for the auction.
     * @param _auctionEndTime The NFT end time for the auction.
     * @param _tokenId The ID of the NFT to list.
     * @param _nftContractAddress The address of the NFT contract.
     * @return The ID of the auction.
     */
    function listItemForAuction( uint256 _initialPrice, uint256 _auctionStartTime, uint256 _auctionEndTime, uint256 _tokenId, address _nftContractAddress) external OnlyTokenHolders(_tokenId, _nftContractAddress) returns (uint256) {
        if (_initialPrice == 0) revert InitialPriceCannotBeZero();
        if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();
        if (_nftContractAddress == address(0)) revert InvalidAddress();
        if (_auctionStartTime < block.timestamp || _auctionEndTime <= block.timestamp) revert StartTimeAndEndTimeMustBeGreaterThanCurrentTime();
        if (_auctionStartTime >= _auctionEndTime) revert AuctionStartTimeMustBeLessThanEndTime();
        uint256 expiryTime = ideaNftContract.getNFTExpireTime(_tokenId);
        if (block.timestamp > expiryTime) revert NFTHaveExpired();

        address originalCreator = ideaNftContract.getRoyaltyReciever(_tokenId);
        if (auction[_tokenId].royaltyFeePercentage == 0) {
            if (msg.sender == originalCreator) {
                auction[_tokenId].royaltyFeePercentage = uint128(royaltyFeePercentage);
            }   
        }

        uint128 effectiveRoyaltyFee = auction[_tokenId].royaltyFeePercentage;

        unchecked {
            auctionId++;
        }

        auction[_tokenId] = Auction({
            isSold: false,
            listed: true,
            nftClaimed: false,
            tokenId: uint128(_tokenId),
            initialPrice: uint128(_initialPrice),
            auctionEndTime: uint64(_auctionEndTime),
            auctionStartTime: uint64(_auctionStartTime),
            currentBidAmount: 0,
            royaltyFeePercentage: effectiveRoyaltyFee,
            nftOwner: msg.sender,
            nftAddress: _nftContractAddress,
            currentBidder: address(0)
        });

        if (_nftContractAddress != ideaNftContractAddress) {
            auction[auctionId].nftAddress = ideaNftContractAddress;
            IERC721(address(_nftContractAddress)).transferFrom(msg.sender, address(this), _tokenId);
        }else{
            fixedPrice[auctionId].nftAddress = _nftContractAddress;
            IERC721(address(_nftContractAddress)).transferFrom(msg.sender, address(this), _tokenId);
        }

        emit NFTListed(msg.sender, _tokenId, _initialPrice);
        return auctionId;
    }
 
    /**
     * @notice Allows users to place a bid on an auction-listed NFT.
     * @dev Ensures the auction is ongoing, the bid meets minimum requirements, and the caller isn't the seller.
     *      First bid can be equal to or greater than initial price. Subsequent bids must be strictly greater than current bid.
     * @param _auctionId The ID of the auction to place a bid on.
     */
    function startBid(uint256 _auctionId) external payable {
        if (_auctionId == 0) revert InvalidAuctionId();
        if (block.timestamp <= uint256(auction[_auctionId].auctionStartTime) || block.timestamp >= uint256(auction[_auctionId].auctionEndTime)) revert CannotBidBeforeAuctionStartedOrAfterEnd();
        if (msg.sender == auction[_auctionId].nftOwner) revert SellerCannotPlaceBidOnOwnNFT();
        if (!auction[_auctionId].listed) revert NFTMustBeListedBeforeBidding();
        if (auction[_auctionId].isSold) revert ItemAlreadySold();
        uint256 expiryTime = ideaNftContract.getNFTExpireTime(uint256(auction[_auctionId].tokenId));
        if (block.timestamp > expiryTime) revert NFTHaveExpired();

        address currentBidder = auction[_auctionId].currentBidder;
        uint256 currentBidAmount = uint256(auction[_auctionId].currentBidAmount);
        uint256 initialPrice = uint256(auction[_auctionId].initialPrice);

        // If no bids exist, bid must be >= initial price
        if (currentBidder == address(0)) {
            if (msg.value < initialPrice) revert BidMustBeHigherThanInitialPrice();
        } else {
            // If bids exist, bid must be strictly greater than current bid
            if (msg.value <= currentBidAmount) revert HigherOrEqualBidAlreadyExists();
        }

        if (currentBidder != address(0)) {
            transferFunds(currentBidder, currentBidAmount);
        }

        auction[_auctionId].currentBidder = msg.sender;
        auction[_auctionId].currentBidAmount = uint128(msg.value);
    }

    /**
     * @notice Ends the auction, transfers the NFT to the highest bidder, and distributes payments (service fee, royalty, and seller's share).
     * @dev Can only be called by the NFT owner, and ensures the auction hasn't ended, and the NFT hasn't been claimed.
     * @param _auctionId The ID of the auction to end.
     */
    function auctionEnd(uint256 _auctionId) external {
        if (_auctionId == 0) revert InvalidAuctionId();
        if (msg.sender != auction[_auctionId].nftOwner) revert OnlySellerCanEndAuction();
        if (block.timestamp >= uint256(auction[_auctionId].auctionEndTime)) revert AuctionHasEnded();
        if (auction[_auctionId].isSold) revert AuctionAlreadyEnded();
        if (auction[_auctionId].nftClaimed) revert HighestBidderAlreadyClaimedNFT();
        uint256 expiryTime = ideaNftContract.getNFTExpireTime(uint256(auction[_auctionId].tokenId));
        if (block.timestamp > expiryTime) revert NFTHaveExpired();

        uint256 serviceFee = calulateMindminerServiceFee(uint256(auction[_auctionId].currentBidAmount), serviceFeePercentage);

        if (ideaNftContractAddress == auction[_auctionId].nftAddress) {
            address _royaltyReceiver = ideaNftContract.getRoyaltyReciever(uint256(auction[_auctionId].tokenId));
            uint128 _royaltyPercentage = auction[_auctionId].royaltyFeePercentage;

            uint256 royaltyFee = calculateRoyaltyFee(
                uint256(auction[_auctionId].currentBidAmount),
                uint256(_royaltyPercentage)
            );
            uint256 totalFee;
            uint256 amountSendToSeller;
            unchecked {
                totalFee = serviceFee + royaltyFee;
                amountSendToSeller = uint256(auction[_auctionId].currentBidAmount) - totalFee;
            }

            transferFunds(marketPlaceOwner, serviceFee);
            transferFunds(_royaltyReceiver, royaltyFee);
            transferFunds(auction[_auctionId].nftOwner, amountSendToSeller);
        } else {
            uint256 amountSendToSeller;
            unchecked {
                amountSendToSeller = uint256(auction[_auctionId].currentBidAmount) - serviceFee;
            }

            transferFunds(marketPlaceOwner, serviceFee);
            transferFunds(auction[_auctionId].nftOwner, amountSendToSeller);
        }

        auction[_auctionId].isSold = true;

        IERC721(auction[_auctionId].nftAddress).transferFrom(
            address(this),
            auction[_auctionId].currentBidder,
            uint256(auction[_auctionId].tokenId)
        );
    }

    /**
     * @notice Allows the highest bidder to claim the NFT after auction ends.
     * @dev Ensures only the highest bidder can claim, checks auction status, and handles payment distribution (service fee, royalty, and seller's share).
     * @param _auctionId The ID of the auction for the NFT being claimed.
     */
    function claimNft(uint256 _auctionId) external {
        if (_auctionId == 0) revert InvalidAuctionId();
        if (msg.sender != auction[_auctionId].currentBidder) revert OnlyHighestBidderCanClaimNFT();
        if (auction[_auctionId].nftClaimed) revert HighestBidderAlreadyClaimedNFT();
        uint256 expiryTime = ideaNftContract.getNFTExpireTime(uint256(auction[_auctionId].tokenId));
        if (block.timestamp > expiryTime) revert NFTHaveExpired();

        if (!auction[_auctionId].isSold) {
            if (block.timestamp <= uint256(auction[_auctionId].auctionEndTime)) revert CannotClaimNFTAsAuctionTimeNotEnded();
        } else {
            revert AuctionEndedNFTTransferredToHighestBidder();
        }

        uint256 serviceFee = calulateMindminerServiceFee(
            uint256(auction[_auctionId].currentBidAmount),
            serviceFeePercentage
        );

        if (ideaNftContractAddress == auction[_auctionId].nftAddress) {
            address _royaltyReciver = ideaNftContract.getRoyaltyReciever(uint256(auction[_auctionId].tokenId));
            uint128 _royaltyPercentage = auction[_auctionId].royaltyFeePercentage;

            uint256 royaltyFee = calculateRoyaltyFee(
                uint256(auction[_auctionId].currentBidAmount),
                uint256(_royaltyPercentage)
            );
            uint256 totalFee;
            uint256 amountSendToSeller;
            unchecked {
                totalFee = serviceFee + royaltyFee;
                amountSendToSeller = uint256(auction[_auctionId].currentBidAmount) - totalFee;
            }

            transferFunds(marketPlaceOwner, serviceFee);
            transferFunds(_royaltyReciver, royaltyFee);
            transferFunds(auction[_auctionId].nftOwner, amountSendToSeller);
        } else {
            uint256 amountSendToSeller;
            unchecked {
                amountSendToSeller = uint256(auction[_auctionId].currentBidAmount) - serviceFee;
            }

            transferFunds(marketPlaceOwner, serviceFee);
            transferFunds(auction[_auctionId].nftOwner, amountSendToSeller);
        }

        auction[_auctionId].nftClaimed = true;

        IERC721(auction[_auctionId].nftAddress).transferFrom(
            address(this),
            auction[_auctionId].currentBidder,
            uint256(auction[_auctionId].tokenId)
        );
    }

    /**
     * @notice Calculates the service fee charged by the marketplace.
     * @dev Uses basis points for percentage calculation.
     * @param _salePrice The sale price of the NFT.
     * @param _serviceFeePercentage The service fee percentage (in basis points).
     * @return The calculated service fee amount.
     */
    function calulateMindminerServiceFee(uint256 _salePrice, uint256 _serviceFeePercentage) private pure returns (uint256){
        if (_salePrice == 0) revert PriceOfNFTCannotBeZero();
        uint256 serviceFee = (_salePrice * _serviceFeePercentage) / 10000;

        return serviceFee;
    }

    /**
     * @notice Calculates the royalty fee for the NFT.
     * @dev Uses basis points for percentage calculation.
     * @param _salePrice The sale price of the NFT.
     * @param _royaltyFeePercentage The royalty fee percentage (in basis points).
     * @return The calculated royalty fee amount.
     */
    function calculateRoyaltyFee( uint256 _salePrice, uint256 _royaltyFeePercentage) private pure returns (uint256) {
        if (_salePrice == 0) revert SalePriceCannotBeZero();
        uint256 RoyaltyFee = (_salePrice * _royaltyFeePercentage) / 10000;

        return RoyaltyFee;
    }

    /**
     * @notice Transfers funds to a recipient.
     * @dev Uses a low-level call to send Ether.
     * @param _recipient The address of the recipient.
     * @param _amount The amount to transfer.
     */
    function transferFunds(address _recipient, uint256 _amount) private {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) revert TransferFeeFailed();
    }

    /**
     * @notice Modifier to restrict access to the owner of a specific token ID.
     * @dev Ensures that the caller owns the specified token.
     * @param _tokenId The token ID to check ownership of.
     * @param _nftContractAddress The address of the NFT contract.
     */
    modifier OnlyTokenHolders(uint256 _tokenId, address _nftContractAddress) {
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) != msg.sender) revert NotOwnerOfTokenId();
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == address(0)) revert OwnerOfTokenIdDoesNotExist();
        _;
    }

    /**
     * @notice Cancels a fixed price listing and returns the NFT to the owner.
     * @dev Resets the listing data and transfers the NFT back to the owner.
     * @param _listingId The TokenId of the listing to cancel.
     */
    function cancelListingForFixedPrice(uint256 _listingId) external {
        if (msg.sender != fixedPrice[_listingId].owner) revert NotOwnerOfListing();
        if (!fixedPrice[_listingId].listed) revert NFTNotListed();
        if (fixedPrice[_listingId].isSold) revert NFTCannotBeCancelledAsAlreadySold();
        uint256 expiryTime = ideaNftContract.getNFTExpireTime(uint256(fixedPrice[_listingId].tokenId));
        if (block.timestamp > expiryTime) revert NFTHaveExpired();
        
        IERC721(fixedPrice[_listingId].nftAddress).transferFrom(
            address(this),
            msg.sender,
            uint256(fixedPrice[_listingId].tokenId)
        );

        fixedPrice[_listingId] = FixedPrice({
            isSold: false,
            listed: false,
            nftPrice: 0,
            tokenId: 0,
            royaltyFeePercentage: 0,
            owner: address(0),
            newOwner: address(0),
            nftAddress:  address(0)
        });

        emit NFTDelisted(_listingId, msg.sender);
    }

    /**
     * @notice Cancels a auction base listing and returns the NFT to the owner.
     * @dev Resets the listing data and transfers the NFT back to the owner.
     * @param _listingId The TokenId of the listing to cancel.
     */
    function cancelListingForAuction(uint256 _listingId) external {
        if (msg.sender != auction[_listingId].nftOwner) revert NotOwnerOfListing();
        if (!auction[_listingId].listed) revert NFTNotListed();
        if (auction[_listingId].isSold) revert NFTCannotBeCancelledAsAlreadySold();
        uint256 expiryTime = ideaNftContract.getNFTExpireTime(uint256(auction[_listingId].tokenId));
        if (block.timestamp > expiryTime) revert NFTHaveExpired();

        IERC721(auction[_listingId].nftAddress).transferFrom(
            address(this),
            msg.sender,
            uint256(auction[_listingId].tokenId)
        );

        if(auction[_listingId].currentBidder != address(0)){
            transferFunds(auction[_listingId].currentBidder, uint256(auction[_listingId].currentBidAmount));
        }
        
        auction[_listingId] = Auction({
            isSold: false,
            listed: false,
            nftClaimed: false,
            tokenId: 0,
            initialPrice: 0,
            auctionEndTime: 0,
            auctionStartTime: 0,
            currentBidAmount: 0,
            royaltyFeePercentage: 0,
            nftOwner: address(0),
            nftAddress: address(0),
            currentBidder: address(0)
        });

        emit NFTDelisted(_listingId, msg.sender);
    }

    /**
     * @dev Authorizes upgrade of the contract. Only the owner can upgrade.
     * @param newImplementation Address of the new implementation contract
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
