// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title PatentMarketplace (Upgradeable)
 * @dev ERC721 PatentToken with URI storage, expiry, and royalties, plus fixed-price and auction listings.
 */
contract PatentMarketplace is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    address public constant MINDMINER_WALLET = 0xd7b7cafF029f863050A5D9e05B9b2Ce659fdDA92;

    // Custom Errors — Marketplace
    error ListPriceCannotBeZero();
    error ContractAddressCannotBeEmpty();
    error InvalidFixedPatentTokenId();
    error OwnerCannotBuyOwnPatentToken();
    error PaymentDoesNotMeetRequiredPrice();
    error PatentTokenNotListedYet();
    error ItemAlreadySold();
    error InvalidAuctionId();
    error CannotBidBeforeAuctionStartedOrAfterEnd();
    error SellerCannotPlaceBidOnOwnPatentToken();
    error BidMustBeHigherThanInitialPrice();
    error PatentTokenMustBeListedBeforeBidding();
    error HigherOrEqualBidAlreadyExists();
    error OnlySellerCanEndAuction();
    error AuctionHasEnded();
    error AuctionAlreadyEnded();
    error HighestBidderAlreadyClaimedPatentToken();
    error OnlyHighestBidderCanClaimPatentToken();
    error CannotClaimPatentTokenAsAuctionTimeNotEnded();
    error AuctionEndedPatentTokenTransferredToHighestBidder();
    error PriceOfPatentTokenCannotBeZero();
    error SalePriceCannotBeZero();
    error TransferFeeFailed();
    error NotOwnerOfTokenId();
    error NotOwnerOfListing();
    error PatentTokenNotListed();
    error PatentTokenCannotBeCancelledAsAlreadySold();
    error InitialPriceCannotBeZero();
    error TokenIdCannotBeNegative();
    error InvalidAddress();
    error StartTimeAndEndTimeMustBeGreaterThanCurrentTime();
    error AuctionStartTimeMustBeLessThanEndTime();
    error InvalidPaymentToken();
    error PaymentTokenNotConfigured();
    error UnexpectedEth();
    error EthPaymentRequired();

    // Custom Errors — PatentToken
    error TokenURICannotBeEmpty();
    error TokenIdMustBeGreaterThanZero();
    error NotOwnerOfToken();
    error PatentTokenExpired();
    error OwnerAddressCannotBeZero();
    error OwnerOfTokenIdDoesNotExist();

    uint256 public constant EXPIRY_DURATION = 365 days;

    uint256 public _tokenIds;

    uint256 public serviceFeePercentage;
    uint256 public royaltyFeePercentage;
    address public marketPlaceOwner;
    address public usdtToken;

    /**
     * @notice PatentToken metadata including mint time, expiry, and royalty receiver.
     */
    struct PatentTokenInfo {
        uint128 mintedAt;
        uint128 expiryTime;
        uint128 royaltyFeePercentage;
        address royaltyReciever;
    }

    mapping(uint256 => PatentTokenInfo) public patentTokenInfo;

    /**
     * @notice Fixed-price listing data.
     */
    struct FixedPrice {
        bool isSold;
        bool listed;
        uint128 patentTokenPrice;
        uint128 tokenId;
        uint128 royaltyFeePercentage;
        address owner;
        address newOwner;
        address patentTokenAddress;
        address paymentToken;
    }

    /**
     * @notice Auction listing data.
     */
    struct Auction {
        bool isSold;
        bool listed;
        bool patentTokenClaimed;
        uint128 tokenId;
        uint128 initialPrice;
        uint128 currentBidAmount;
        uint64 auctionEndTime;
        uint64 auctionStartTime;
        uint128 royaltyFeePercentage;
        address patentTokenOwner;
        address patentTokenAddress;
        address currentBidder;
        address paymentToken;
    }

    mapping(uint256 => FixedPrice) public fixedPrice;
    mapping(uint256 => Auction) public auction;

    event PatentTokenMinted(address recieverAddress, uint256 tokenId, string tokenURI);
    event PatentTokenListed(address patentTokenOwner, uint256 tokenId, uint256 listedPrice);
    event PatentTokenDelisted(uint256 tokenId, address patentTokenOwner);
    event PatentTokenBought(uint256 listId, address newOwner, uint256 tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes PatentToken (ERC721) and marketplace settings.
     * @param _usdtToken ERC20 USDT address for USDT-denominated listings (mainnet: Tether USDT).
     * @dev `MINDMINER_WALLET` is owner and receives 10% service fees on sales. Creator royalty is
     *      10% on secondary sales. Deploy wallet is one-time setup only.
     */
    function initialize(address _usdtToken) public initializer {
        __ERC721_init("PatentToken", "PT");
        __ERC721URIStorage_init();
        __Ownable_init(MINDMINER_WALLET);
        __UUPSUpgradeable_init();

        if (_usdtToken == address(0)) revert InvalidAddress();

        _tokenIds = 1;
        serviceFeePercentage = 1000;
        royaltyFeePercentage = 1000;
        marketPlaceOwner = MINDMINER_WALLET;
        usdtToken = _usdtToken;
    }

    /**
     * @notice Mints a new PatentToken to `_recipient`.
     * @param _recipient Wallet that receives the minted PatentToken (royalty receiver).
     * @param _tokenURI URI for the PatentToken metadata.
     * @return newItemId Minted token ID.
     */
    function mintPatentToken(address _recipient, string memory _tokenURI) public onlyOwner returns (uint256) {
        if (_recipient == address(0)) revert OwnerAddressCannotBeZero();
        if (bytes(_tokenURI).length == 0) revert TokenURICannotBeEmpty();

        uint256 newItemId = _tokenIds;

        patentTokenInfo[_tokenIds] = PatentTokenInfo({
            mintedAt: uint128(block.timestamp),
            expiryTime: uint128(block.timestamp + EXPIRY_DURATION),
            royaltyFeePercentage: 0,
            royaltyReciever: _recipient
        });

        _safeMint(_recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        unchecked {
            _tokenIds += 1;
        }

        emit PatentTokenMinted(_recipient, newItemId, _tokenURI);
        return newItemId;
    }

    /**
     * @notice Updates the URI of an existing PatentToken.
     */
    function setTokenUri(uint256 _tokenId, string memory _uri) public {
        if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();
        if (bytes(_uri).length == 0) revert TokenURICannotBeEmpty();
        if (ownerOf(_tokenId) != msg.sender) revert NotOwnerOfToken();
        if (block.timestamp > uint256(patentTokenInfo[_tokenId].expiryTime)) revert PatentTokenExpired();

        _setTokenURI(_tokenId, _uri);
    }

    /**
     * @notice Returns the royalty receiver for a token ID.
     */
    function getRoyaltyReciever(uint256 _tokenId) public view returns (address) {
        if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();
        if (ownerOf(_tokenId) == address(0)) revert OwnerOfTokenIdDoesNotExist();

        return patentTokenInfo[_tokenId].royaltyReciever;
    }

    /**
     * @notice Returns the PatentToken expiry timestamp.
     */
    function getPatentTokenExpireTime(uint256 _tokenId) public view returns (uint256) {
        if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();
        if (ownerOf(_tokenId) == address(0)) revert OwnerOfTokenIdDoesNotExist();

        return uint256(patentTokenInfo[_tokenId].expiryTime);
    }

    /**
     * @notice Lists a PatentToken at a fixed price.
     */
    function listPatentTokenForFixedPrice(
        uint256 _tokenId,
        uint256 _patentTokenPrice,
        address _patentTokenContractAddress,
        address _paymentToken
    ) external OnlyTokenHolders(_tokenId, _patentTokenContractAddress) returns (uint256) {
        if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();
        if (_patentTokenPrice == 0) revert ListPriceCannotBeZero();
        if (_patentTokenContractAddress == address(0)) revert ContractAddressCannotBeEmpty();
        _requireValidPaymentToken(_paymentToken);
        uint256 expiryTime = getPatentTokenExpireTime(_tokenId);
        if (block.timestamp > expiryTime) revert PatentTokenExpired();

        address originalCreator = getRoyaltyReciever(_tokenId);

        if (patentTokenInfo[_tokenId].royaltyFeePercentage == 0) {
            if (msg.sender == originalCreator) {
                patentTokenInfo[_tokenId].royaltyFeePercentage = uint128(royaltyFeePercentage);
            }
        }

        uint128 effectiveRoyaltyFee = patentTokenInfo[_tokenId].royaltyFeePercentage;

        fixedPrice[_tokenId] = FixedPrice({
            isSold: false,
            listed: true,
            patentTokenPrice: uint128(_patentTokenPrice),
            tokenId: uint128(_tokenId),
            royaltyFeePercentage: effectiveRoyaltyFee,
            owner: msg.sender,
            newOwner: address(0),
            patentTokenAddress: _patentTokenContractAddress,
            paymentToken: _paymentToken
        });

        IERC721(_patentTokenContractAddress).transferFrom(msg.sender, address(this), _tokenId);

        emit PatentTokenListed(msg.sender, _tokenId, _patentTokenPrice);
        return _tokenId;
    }

    /**
     * @notice Buys a fixed-price PatentToken listing.
     */
    function buyFixedPricePatentToken(uint256 _fixedId) external payable {
        if (_fixedId == 0) revert InvalidFixedPatentTokenId();
        if (msg.sender == fixedPrice[_fixedId].owner) revert OwnerCannotBuyOwnPatentToken();
        if (!fixedPrice[_fixedId].listed) revert PatentTokenNotListedYet();
        if (fixedPrice[_fixedId].isSold) revert ItemAlreadySold();
        uint256 expiryTime = getPatentTokenExpireTime(uint256(fixedPrice[_fixedId].tokenId));
        if (block.timestamp > expiryTime) revert PatentTokenExpired();

        address paymentToken = fixedPrice[_fixedId].paymentToken;
        uint256 price = uint256(fixedPrice[_fixedId].patentTokenPrice);
        _collectPayment(paymentToken, price);

        fixedPrice[_fixedId].newOwner = msg.sender;

        uint256 serviceFee = calulateMindminerServiceFee(price, serviceFeePercentage);

        if (address(this) == fixedPrice[_fixedId].patentTokenAddress) {
            uint128 _royaltyPercentage = fixedPrice[_fixedId].royaltyFeePercentage;
            address _royaltyReciever = getRoyaltyReciever(uint256(fixedPrice[_fixedId].tokenId));

            uint256 royaltyFee = calculateRoyaltyFee(price, uint256(_royaltyPercentage));

            uint256 totalFee;
            uint256 amountSendToSeller;
            unchecked {
                totalFee = serviceFee + royaltyFee;
                amountSendToSeller = price - totalFee;
            }

            transferFunds(paymentToken, marketPlaceOwner, serviceFee);
            transferFunds(paymentToken, _royaltyReciever, royaltyFee);
            transferFunds(paymentToken, fixedPrice[_fixedId].owner, amountSendToSeller);
        } else {
            uint256 amountSendToSeller;
            unchecked {
                amountSendToSeller = price - serviceFee;
            }
            transferFunds(paymentToken, marketPlaceOwner, serviceFee);
            transferFunds(paymentToken, fixedPrice[_fixedId].owner, amountSendToSeller);
        }

        fixedPrice[_fixedId].isSold = true;

        IERC721(fixedPrice[_fixedId].patentTokenAddress).transferFrom(
            address(this),
            fixedPrice[_fixedId].newOwner,
            uint256(fixedPrice[_fixedId].tokenId)
        );
        emit PatentTokenBought(_fixedId, msg.sender, uint256(fixedPrice[_fixedId].tokenId));
    }

    /**
     * @notice Lists a PatentToken for auction.
     */
    function listItemForAuction(
        uint256 _initialPrice,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        uint256 _tokenId,
        address _patentTokenContractAddress,
        address _paymentToken
    ) external OnlyTokenHolders(_tokenId, _patentTokenContractAddress) returns (uint256) {
        if (_initialPrice == 0) revert InitialPriceCannotBeZero();
        if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();
        if (_patentTokenContractAddress == address(0)) revert InvalidAddress();
        _requireValidPaymentToken(_paymentToken);
        if (_auctionStartTime < block.timestamp || _auctionEndTime <= block.timestamp) {
            revert StartTimeAndEndTimeMustBeGreaterThanCurrentTime();
        }
        if (_auctionStartTime >= _auctionEndTime) revert AuctionStartTimeMustBeLessThanEndTime();
        uint256 expiryTime = getPatentTokenExpireTime(_tokenId);
        if (block.timestamp > expiryTime) revert PatentTokenExpired();

        address originalCreator = getRoyaltyReciever(_tokenId);
        if (patentTokenInfo[_tokenId].royaltyFeePercentage == 0) {
            if (msg.sender == originalCreator) {
                patentTokenInfo[_tokenId].royaltyFeePercentage = uint128(royaltyFeePercentage);
            }
        }

        uint128 effectiveRoyaltyFee = patentTokenInfo[_tokenId].royaltyFeePercentage;

        auction[_tokenId] = Auction({
            isSold: false,
            listed: true,
            patentTokenClaimed: false,
            tokenId: uint128(_tokenId),
            initialPrice: uint128(_initialPrice),
            auctionEndTime: uint64(_auctionEndTime),
            auctionStartTime: uint64(_auctionStartTime),
            currentBidAmount: 0,
            royaltyFeePercentage: effectiveRoyaltyFee,
            patentTokenOwner: msg.sender,
            patentTokenAddress: _patentTokenContractAddress,
            currentBidder: address(0),
            paymentToken: _paymentToken
        });

        IERC721(_patentTokenContractAddress).transferFrom(msg.sender, address(this), _tokenId);

        emit PatentTokenListed(msg.sender, _tokenId, _initialPrice);
        return _tokenId;
    }

    /**
     * @notice Places a bid on an auction listing.
     */
    function startBid(uint256 _auctionId, uint256 _bidAmount) external payable {
        if (_auctionId == 0) revert InvalidAuctionId();
        if (
            block.timestamp <= uint256(auction[_auctionId].auctionStartTime)
                || block.timestamp >= uint256(auction[_auctionId].auctionEndTime)
        ) revert CannotBidBeforeAuctionStartedOrAfterEnd();
        if (msg.sender == auction[_auctionId].patentTokenOwner) revert SellerCannotPlaceBidOnOwnPatentToken();
        if (!auction[_auctionId].listed) revert PatentTokenMustBeListedBeforeBidding();
        if (auction[_auctionId].isSold) revert ItemAlreadySold();
        uint256 expiryTime = getPatentTokenExpireTime(uint256(auction[_auctionId].tokenId));
        if (block.timestamp > expiryTime) revert PatentTokenExpired();

        address paymentToken = auction[_auctionId].paymentToken;
        address currentBidder = auction[_auctionId].currentBidder;
        uint256 currentBidAmount = uint256(auction[_auctionId].currentBidAmount);
        uint256 initialPrice = uint256(auction[_auctionId].initialPrice);
        uint256 bidAmount = _collectBid(paymentToken, _bidAmount);

        if (currentBidder == address(0)) {
            if (bidAmount < initialPrice) revert BidMustBeHigherThanInitialPrice();
        } else {
            if (bidAmount <= currentBidAmount) revert HigherOrEqualBidAlreadyExists();
        }

        if (currentBidder != address(0)) {
            transferFunds(paymentToken, currentBidder, currentBidAmount);
        }

        auction[_auctionId].currentBidder = msg.sender;
        auction[_auctionId].currentBidAmount = uint128(bidAmount);
    }

    /**
     * @notice Ends an auction early and transfers the PatentToken to the highest bidder.
     */
    function auctionEnd(uint256 _auctionId) external {
        if (_auctionId == 0) revert InvalidAuctionId();
        if (msg.sender != auction[_auctionId].patentTokenOwner) revert OnlySellerCanEndAuction();
        if (block.timestamp >= uint256(auction[_auctionId].auctionEndTime)) revert AuctionHasEnded();
        if (auction[_auctionId].isSold) revert AuctionAlreadyEnded();
        if (auction[_auctionId].patentTokenClaimed) revert HighestBidderAlreadyClaimedPatentToken();
        uint256 expiryTime = getPatentTokenExpireTime(uint256(auction[_auctionId].tokenId));
        if (block.timestamp > expiryTime) revert PatentTokenExpired();

        address paymentToken = auction[_auctionId].paymentToken;

        uint256 serviceFee = calulateMindminerServiceFee(
            uint256(auction[_auctionId].currentBidAmount),
            serviceFeePercentage
        );

        if (address(this) == auction[_auctionId].patentTokenAddress) {
            address _royaltyReceiver = getRoyaltyReciever(uint256(auction[_auctionId].tokenId));
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

            transferFunds(paymentToken, marketPlaceOwner, serviceFee);
            transferFunds(paymentToken, _royaltyReceiver, royaltyFee);
            transferFunds(paymentToken, auction[_auctionId].patentTokenOwner, amountSendToSeller);
        } else {
            uint256 amountSendToSeller;
            unchecked {
                amountSendToSeller = uint256(auction[_auctionId].currentBidAmount) - serviceFee;
            }

            transferFunds(paymentToken, marketPlaceOwner, serviceFee);
            transferFunds(paymentToken, auction[_auctionId].patentTokenOwner, amountSendToSeller);
        }

        auction[_auctionId].isSold = true;

        IERC721(auction[_auctionId].patentTokenAddress).transferFrom(
            address(this),
            auction[_auctionId].currentBidder,
            uint256(auction[_auctionId].tokenId)
        );
    }

    /**
     * @notice Allows the highest bidder to claim the PatentToken after auction ends.
     */
    function claimPatentToken(uint256 _auctionId) external {
        if (_auctionId == 0) revert InvalidAuctionId();
        if (msg.sender != auction[_auctionId].currentBidder) revert OnlyHighestBidderCanClaimPatentToken();
        if (auction[_auctionId].patentTokenClaimed) revert HighestBidderAlreadyClaimedPatentToken();
        uint256 expiryTime = getPatentTokenExpireTime(uint256(auction[_auctionId].tokenId));
        if (block.timestamp > expiryTime) revert PatentTokenExpired();

        if (!auction[_auctionId].isSold) {
            if (block.timestamp <= uint256(auction[_auctionId].auctionEndTime)) {
                revert CannotClaimPatentTokenAsAuctionTimeNotEnded();
            }
        } else {
            revert AuctionEndedPatentTokenTransferredToHighestBidder();
        }

        address paymentToken = auction[_auctionId].paymentToken;

        uint256 serviceFee = calulateMindminerServiceFee(
            uint256(auction[_auctionId].currentBidAmount),
            serviceFeePercentage
        );

        if (address(this) == auction[_auctionId].patentTokenAddress) {
            address _royaltyReciver = getRoyaltyReciever(uint256(auction[_auctionId].tokenId));
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

            transferFunds(paymentToken, marketPlaceOwner, serviceFee);
            transferFunds(paymentToken, _royaltyReciver, royaltyFee);
            transferFunds(paymentToken, auction[_auctionId].patentTokenOwner, amountSendToSeller);
        } else {
            uint256 amountSendToSeller;
            unchecked {
                amountSendToSeller = uint256(auction[_auctionId].currentBidAmount) - serviceFee;
            }

            transferFunds(paymentToken, marketPlaceOwner, serviceFee);
            transferFunds(paymentToken, auction[_auctionId].patentTokenOwner, amountSendToSeller);
        }

        auction[_auctionId].patentTokenClaimed = true;

        IERC721(auction[_auctionId].patentTokenAddress).transferFrom(
            address(this),
            auction[_auctionId].currentBidder,
            uint256(auction[_auctionId].tokenId)
        );
    }

    /**
     * @notice Cancels a fixed-price listing and returns the PatentToken to the owner.
     */
    function cancelListingForFixedPrice(uint256 _listingId) external {
        if (msg.sender != fixedPrice[_listingId].owner) revert NotOwnerOfListing();
        if (!fixedPrice[_listingId].listed) revert PatentTokenNotListed();
        if (fixedPrice[_listingId].isSold) revert PatentTokenCannotBeCancelledAsAlreadySold();
        uint256 expiryTime = getPatentTokenExpireTime(uint256(fixedPrice[_listingId].tokenId));
        if (block.timestamp > expiryTime) revert PatentTokenExpired();

        IERC721(fixedPrice[_listingId].patentTokenAddress).transferFrom(
            address(this),
            msg.sender,
            uint256(fixedPrice[_listingId].tokenId)
        );

        fixedPrice[_listingId] = FixedPrice({
            isSold: false,
            listed: false,
            patentTokenPrice: 0,
            tokenId: 0,
            royaltyFeePercentage: 0,
            owner: address(0),
            newOwner: address(0),
            patentTokenAddress: address(0),
            paymentToken: address(0)
        });

        emit PatentTokenDelisted(_listingId, msg.sender);
    }

    /**
     * @notice Cancels an auction listing and returns the PatentToken to the owner.
     */
    function cancelListingForAuction(uint256 _listingId) external {
        if (msg.sender != auction[_listingId].patentTokenOwner) revert NotOwnerOfListing();
        if (!auction[_listingId].listed) revert PatentTokenNotListed();
        if (auction[_listingId].isSold) revert PatentTokenCannotBeCancelledAsAlreadySold();
        uint256 expiryTime = getPatentTokenExpireTime(uint256(auction[_listingId].tokenId));
        if (block.timestamp > expiryTime) revert PatentTokenExpired();

        IERC721(auction[_listingId].patentTokenAddress).transferFrom(
            address(this),
            msg.sender,
            uint256(auction[_listingId].tokenId)
        );

        if (auction[_listingId].currentBidder != address(0)) {
            transferFunds(
                auction[_listingId].paymentToken,
                auction[_listingId].currentBidder,
                uint256(auction[_listingId].currentBidAmount)
            );
        }

        auction[_listingId] = Auction({
            isSold: false,
            listed: false,
            patentTokenClaimed: false,
            tokenId: 0,
            initialPrice: 0,
            auctionEndTime: 0,
            auctionStartTime: 0,
            currentBidAmount: 0,
            royaltyFeePercentage: 0,
            patentTokenOwner: address(0),
            patentTokenAddress: address(0),
            currentBidder: address(0),
            paymentToken: address(0)
        });

        emit PatentTokenDelisted(_listingId, msg.sender);
    }

    function calulateMindminerServiceFee(uint256 _salePrice, uint256 _serviceFeePercentage)
        private
        pure
        returns (uint256)
    {
        if (_salePrice == 0) revert PriceOfPatentTokenCannotBeZero();
        uint256 serviceFee = (_salePrice * _serviceFeePercentage) / 10000;

        return serviceFee;
    }

    function calculateRoyaltyFee(uint256 _salePrice, uint256 _royaltyFeePercentage) private pure returns (uint256) {
        if (_salePrice == 0) revert SalePriceCannotBeZero();
        uint256 RoyaltyFee = (_salePrice * _royaltyFeePercentage) / 10000;

        return RoyaltyFee;
    }

    function _requireValidPaymentToken(address _paymentToken) private view {
        if (_paymentToken == address(0)) return;
        if (usdtToken == address(0)) revert PaymentTokenNotConfigured();
        if (_paymentToken != usdtToken) revert InvalidPaymentToken();
    }

    function _collectPayment(address _paymentToken, uint256 _amount) private {
        if (_paymentToken == address(0)) {
            if (msg.value < _amount) revert PaymentDoesNotMeetRequiredPrice();
            return;
        }
        if (msg.value != 0) revert UnexpectedEth();
        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _collectBid(address _paymentToken, uint256 _bidAmount) private returns (uint256 bidAmount) {
        if (_paymentToken == address(0)) {
            if (msg.value == 0) revert EthPaymentRequired();
            return msg.value;
        }
        if (msg.value != 0) revert UnexpectedEth();
        if (_bidAmount == 0) revert PaymentDoesNotMeetRequiredPrice();
        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _bidAmount);
        return _bidAmount;
    }

    function transferFunds(address _paymentToken, address _recipient, uint256 _amount) private {
        if (_amount == 0) return;
        if (_paymentToken == address(0)) {
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            if (!success) revert TransferFeeFailed();
            return;
        }
        IERC20(_paymentToken).safeTransfer(_recipient, _amount);
    }

    modifier OnlyTokenHolders(uint256 _tokenId, address _patentTokenContractAddress) {
        if (IERC721(_patentTokenContractAddress).ownerOf(_tokenId) != msg.sender) revert NotOwnerOfTokenId();
        if (IERC721(_patentTokenContractAddress).ownerOf(_tokenId) == address(0)) revert OwnerOfTokenIdDoesNotExist();
        _;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data)
        public
        override(ERC721Upgradeable, IERC721)
    {
        if (block.timestamp > uint256(patentTokenInfo[_tokenId].expiryTime)) revert PatentTokenExpired();
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override(ERC721Upgradeable, IERC721) {
        if (block.timestamp > uint256(patentTokenInfo[_tokenId].expiryTime)) revert PatentTokenExpired();
        super.transferFrom(_from, _to, _tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
