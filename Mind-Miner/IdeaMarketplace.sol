// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IIdeaNFT {
    function tokenRoyaltyReceivers(uint256 tokenId) external view returns (address);
}

/**
 * @title IdeaMarketplace
 * @dev Implements an NFT marketplace that allows listing and buying NFTs at fixed prices.
 */
contract IdeaMarketplace is ERC721 {
    
    address ideaNftContractAddress;
    IIdeaNFT private ideaNftContract;
    address MarketPlaceOwner;

    uint256 public fixedPriceId;
    uint256 public serviceFeePercentage;

    /**
     * @notice Initializes the IdeaMarketplace contract with the given IdeaNFT contract address.
     * @dev Sets the service fee percentage and marketplace owner.
     * @param _ideaNftAddress The address of the IdeaNFT contract.
     */
    constructor(address _ideaNftAddress) ERC721("IdeaMarketplace", "IMKT") {
        serviceFeePercentage = 500;
        MarketPlaceOwner = msg.sender;
        ideaNftContractAddress = _ideaNftAddress;
        ideaNftContract = IIdeaNFT(_ideaNftAddress);
    }

    event NFTListed(address nftOwner, uint256 tokenId, uint256 listedPrice, uint256 royaltyFeePercentage);
    event NFTDelisted(uint256 tokenId);
    event NFTBought(uint256 listId, address newOwner, uint256 tokenId);

    /**
     * @notice Represents a fixed price listing for an NFT.
     */
    struct FixedPrice {
        bool isSold;
        bool listed;
        uint256 nftPrice;
        uint256 tokenId;
        uint256 royaltyFeePercentage;
        address owner;
        address newOwner;
        address nftAddress;
    }

    /**
     * @notice Mapping from NFT ID to FixedPrice struct.
     */
    mapping(uint256 => FixedPrice) public fixedPrice;

    /**
     * @notice Lists an NFT for sale at a fixed price on the marketplace.
     * @dev Transfers the NFT from the owner to the marketplace contract.
     * @param _tokenId The ID of the NFT to list.
     * @param _nftPrice The price at which to list the NFT.
     * @param _nftContractAddress The address of the NFT contract.
     * @param _royaltyFeePercentage The percentage of royalty fee (max 10%).
     * @return The ID of the fixed price listing.
     */
    function listNftForFixedPrice(uint256 _tokenId, uint256 _nftPrice, address _nftContractAddress, uint256 _royaltyFeePercentage) external OnlyTokenHolders(_tokenId, _nftContractAddress) returns (uint256) {
        require(_tokenId > 0, "Token Id must be greater than zero");
        require(_nftPrice > 0, "List price cannot be zero");
        require(_nftContractAddress != address(0), "Contract address cannot be empty");
        require(_royaltyFeePercentage <= 1000, "Royalties must be 10% or less");

        address currentOwner = IERC721(_nftContractAddress).ownerOf(_tokenId);
        require(currentOwner == msg.sender, "Caller is not the token owner");
        require(currentOwner != address(0), "Owner does not exist");

        fixedPriceId++;

        fixedPrice[_tokenId] = FixedPrice({
            isSold: false,
            listed: true,
            nftPrice: _nftPrice,
            tokenId: _tokenId,
            royaltyFeePercentage: _royaltyFeePercentage,
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

        emit NFTListed(msg.sender, _tokenId, _nftPrice, _royaltyFeePercentage);
        return fixedPriceId;
    }

    /**
     * @notice Buys an NFT listed at a fixed price.
     * @dev Transfers funds and NFT ownership.
     * @param _fixedId The tokenId of the fixed price listing.
     */
    function buyFixedPriceNft(uint256 _fixedId) external payable {
        require(_fixedId > 0, "Inavlid fixed NFT id");
        require(msg.sender != fixedPrice[_fixedId].owner, "Owner of this NFT can not buy");
        require(msg.value >= fixedPrice[_fixedId].nftPrice, "Payment does not meet the required fixed price for this NFT");
        require(fixedPrice[_fixedId].listed, "Nft isn't listed yet.");
        require(!fixedPrice[_fixedId].isSold, "Item is already sold");

        fixedPrice[_fixedId].newOwner = msg.sender;
        
        uint256 serviceFee = calulateMindminerServiceFee(
            fixedPrice[_fixedId].nftPrice,
            serviceFeePercentage
        );

        if (ideaNftContractAddress == fixedPrice[fixedPriceId].nftAddress) {
            uint256 _royaltyPercentage = fixedPrice[_fixedId].royaltyFeePercentage;
            address _royaltyReciever = ideaNftContract.tokenRoyaltyReceivers(fixedPrice[_fixedId].tokenId);

            uint256 royaltyFee = calculateRoyaltyFee(
                fixedPrice[_fixedId].nftPrice,
                _royaltyPercentage
            );

            uint256 totalFee = serviceFee + royaltyFee;
            uint256 amountSendToSeller = fixedPrice[_fixedId].nftPrice - totalFee;
  
            transferFunds(MarketPlaceOwner, serviceFee);
            transferFunds(_royaltyReciever, royaltyFee);
            transferFunds(fixedPrice[_fixedId].owner, amountSendToSeller);
        }else{
            uint256 amountSendToSeller = fixedPrice[_fixedId].nftPrice - serviceFee;
            transferFunds(MarketPlaceOwner, serviceFee);
            transferFunds(fixedPrice[_fixedId].owner, amountSendToSeller);
        }

        fixedPrice[_fixedId].isSold = true;

        IERC721(fixedPrice[_fixedId].nftAddress).transferFrom(address(this), fixedPrice[_fixedId].newOwner, fixedPrice[_fixedId].tokenId);
        emit NFTBought(_fixedId, msg.sender, fixedPrice[_fixedId].tokenId);
    }

    /**
     * @notice Calculates the service fee charged by the marketplace.
     * @dev Uses basis points for percentage calculation.
     * @param _salePrice The sale price of the NFT.
     * @param _serviceFeePercentage The service fee percentage (in basis points).
     * @return The calculated service fee amount.
     */
    function calulateMindminerServiceFee(uint256 _salePrice, uint256 _serviceFeePercentage)private pure returns (uint256){
        require(_salePrice != 0, "Price of NFT can not be zero");

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
        require(_salePrice != 0, "SalePrice can not be zero");

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
        require(success, "Transfer fee failed");
    }

    /**
     * @notice Modifier to restrict access to the owner of a specific token ID.
     * @dev Ensures that the caller owns the specified token.
     * @param _tokenId The token ID to check ownership of.
     * @param _nftContractAddress The address of the NFT contract.
     */
    modifier OnlyTokenHolders(uint256 _tokenId, address _nftContractAddress) {
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender, "You are not the owner of this tokenId"
        );
        _;
    }

    /**
     * @notice Cancels a fixed price listing and returns the NFT to the owner.
     * @dev Resets the listing data and transfers the NFT back to the owner.
     * @param _listingId The TokenId of the listing to cancel.
     */
    function cancelListingForFixedPrice(uint256 _listingId) external {
        require(msg.sender == fixedPrice[_listingId].owner, "You are not the owner");
        require(fixedPrice[_listingId].listed, "NFT is not listed yet.");
        require(!fixedPrice[_listingId].isSold, "NFT is already sold, can't perform this action now");

        IERC721(fixedPrice[_listingId].nftAddress).transferFrom(
            address(this),
            msg.sender,
            fixedPrice[_listingId].tokenId
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

        emit NFTDelisted(_listingId);
    }
}
