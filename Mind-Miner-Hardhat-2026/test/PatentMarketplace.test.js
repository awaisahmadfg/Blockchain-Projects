const { loadFixture, time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { deployPatentMarketplaceFixture } = require("./helpers/fixtures");
const { ZERO_ADDRESS, EXPIRY_DURATION, MINDMINER_WALLET } = require("./helpers/constants");

const TOKEN_URI = "ipfs://patent-metadata";
const ONE_ETHER = ethers.parseEther("1");

describe("PatentMarketplace", function () {
  describe("Initialization", function () {
    it("sets MINDMINER_WALLET as owner and marketplace fee receiver", async function () {
      const { marketplaceRead, deployer } = await loadFixture(deployPatentMarketplaceFixture);

      expect(await marketplaceRead.owner()).to.equal(MINDMINER_WALLET);
      expect(await marketplaceRead.marketPlaceOwner()).to.equal(MINDMINER_WALLET);
      expect(deployer.address).to.not.equal(MINDMINER_WALLET);
    });

    it("sets ERC721 metadata and default fee config", async function () {
      const { marketplace } = await loadFixture(deployPatentMarketplaceFixture);

      expect(await marketplace.name()).to.equal("PatentToken");
      expect(await marketplace.symbol()).to.equal("PT");
      expect(await marketplace.serviceFeePercentage()).to.equal(1000n);
      expect(await marketplace.royaltyFeePercentage()).to.equal(1000n);
      expect(await marketplace.marketPlaceOwner()).to.equal(MINDMINER_WALLET);
      expect(await marketplace._tokenIds()).to.equal(1n);
    });

    it("sets USDT token from initialize", async function () {
      const { marketplace, usdtAddress } = await loadFixture(deployPatentMarketplaceFixture);
      expect(await marketplace.usdtToken()).to.equal(usdtAddress);
    });

    it("reverts initialize with zero USDT address", async function () {
      const PatentMarketplace = await ethers.getContractFactory("PatentMarketplace");
      await expect(
        upgrades.deployProxy(PatentMarketplace, [ZERO_ADDRESS], { kind: "uups" })
      ).to.be.revertedWithCustomError(PatentMarketplace, "InvalidAddress");
    });
  });

  describe("mintPatentToken", function () {
    it("mints to recipient with expiry and royalty receiver", async function () {
      const { marketplace, creator } = await loadFixture(deployPatentMarketplaceFixture);

      await expect(marketplace.mintPatentToken(creator.address, TOKEN_URI))
        .to.emit(marketplace, "PatentTokenMinted")
        .withArgs(creator.address, 1n, TOKEN_URI);

      expect(await marketplace.ownerOf(1)).to.equal(creator.address);
      expect(await marketplace.tokenURI(1)).to.equal(TOKEN_URI);
      expect(await marketplace.getRoyaltyReciever(1)).to.equal(creator.address);

      const info = await marketplace.patentTokenInfo(1);
      expect(info.expiryTime).to.equal(info.mintedAt + EXPIRY_DURATION);
    });

    it("increments token id counter", async function () {
      const { marketplace, creator, buyer } = await loadFixture(deployPatentMarketplaceFixture);

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.mintPatentToken(buyer.address, "ipfs://second");

      expect(await marketplace.ownerOf(2)).to.equal(buyer.address);
      expect(await marketplace._tokenIds()).to.equal(3n);
    });

    it("reverts zero recipient or empty URI", async function () {
      const { marketplace, creator } = await loadFixture(deployPatentMarketplaceFixture);

      await expect(
        marketplace.mintPatentToken(ZERO_ADDRESS, TOKEN_URI)
      ).to.be.revertedWithCustomError(marketplace, "OwnerAddressCannotBeZero");

      await expect(
        marketplace.mintPatentToken(creator.address, "")
      ).to.be.revertedWithCustomError(marketplace, "TokenURICannotBeEmpty");
    });

    it("reverts when deploy wallet tries to mint", async function () {
      const { marketplaceRead, deployer, creator } = await loadFixture(deployPatentMarketplaceFixture);

      await expect(
        marketplaceRead.connect(deployer).mintPatentToken(creator.address, TOKEN_URI)
      ).to.be.revertedWithCustomError(marketplaceRead, "OwnableUnauthorizedAccount");
    });

    it("reverts for non-owner", async function () {
      const { marketplaceRead, creator } = await loadFixture(deployPatentMarketplaceFixture);

      await expect(
        marketplaceRead.connect(creator).mintPatentToken(creator.address, TOKEN_URI)
      ).to.be.revertedWithCustomError(marketplaceRead, "OwnableUnauthorizedAccount");
    });
  });

  describe("setTokenUri", function () {
    it("allows owner to update URI before expiry", async function () {
      const { marketplace, creator } = await loadFixture(deployPatentMarketplaceFixture);
      await marketplace.mintPatentToken(creator.address, TOKEN_URI);

      const updated = "ipfs://updated";
      await marketplace.connect(creator).setTokenUri(1, updated);
      expect(await marketplace.tokenURI(1)).to.equal(updated);
    });

    it("reverts for non-owner, zero id, empty uri, expired token", async function () {
      const { marketplace, creator, other } = await loadFixture(deployPatentMarketplaceFixture);
      await marketplace.mintPatentToken(creator.address, TOKEN_URI);

      await expect(
        marketplace.connect(other).setTokenUri(1, "ipfs://x")
      ).to.be.revertedWithCustomError(marketplace, "NotOwnerOfToken");

      await expect(
        marketplace.connect(creator).setTokenUri(0, TOKEN_URI)
      ).to.be.revertedWithCustomError(marketplace, "TokenIdMustBeGreaterThanZero");

      await expect(
        marketplace.connect(creator).setTokenUri(1, "")
      ).to.be.revertedWithCustomError(marketplace, "TokenURICannotBeEmpty");

      await time.increase(EXPIRY_DURATION + 1n);
      await expect(
        marketplace.connect(creator).setTokenUri(1, "ipfs://late")
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });
  });

  describe("Views: getRoyaltyReciever / getPatentTokenExpireTime", function () {
    it("reverts for invalid token id", async function () {
      const { marketplace } = await loadFixture(deployPatentMarketplaceFixture);

      await expect(marketplace.getRoyaltyReciever(0)).to.be.revertedWithCustomError(
        marketplace,
        "TokenIdMustBeGreaterThanZero"
      );

      await expect(marketplace.getPatentTokenExpireTime(999)).to.be.revertedWithCustomError(
        marketplace,
        "ERC721NonexistentToken"
      );
    });
  });

  describe("Fixed-price listing", function () {
    async function mintAndApprove(fixture, holder) {
      const { marketplace, marketplaceAddress } = fixture;
      await marketplace.mintPatentToken(holder.address, TOKEN_URI);
      await marketplace.connect(holder).approve(marketplaceAddress, 1);
      return 1n;
    }

    it("lists patent token and escrows it in marketplace", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;
      await mintAndApprove(fixture, creator);

      await expect(
        marketplace
          .connect(creator)
          .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS)
      )
        .to.emit(marketplace, "PatentTokenListed")
        .withArgs(creator.address, 1n, ONE_ETHER);

      const listing = await marketplace.fixedPrice(1);
      expect(listing.listed).to.equal(true);
      expect(listing.patentTokenPrice).to.equal(ONE_ETHER);
      expect(listing.paymentToken).to.equal(ZERO_ADDRESS);
      expect(await marketplace.ownerOf(1)).to.equal(marketplaceAddress);
    });

    it("sets royalty fee when original creator lists", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;
      await mintAndApprove(fixture, creator);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      const listing = await marketplace.fixedPrice(1);
      expect(listing.royaltyFeePercentage).to.equal(1000n);
    });

    it("sets zero royalty when non-creator lists without prior creator listing", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).transferFrom(creator.address, buyer.address, 1);
      await marketplace.connect(buyer).approve(marketplaceAddress, 1);

      await marketplace
        .connect(buyer)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      const listing = await marketplace.fixedPrice(1);
      expect(listing.royaltyFeePercentage).to.equal(0n);
      expect((await marketplace.patentTokenInfo(1)).royaltyFeePercentage).to.equal(0n);
    });

    it("pays no creator royalty when non-creator listed the token", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, other, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).transferFrom(creator.address, buyer.address, 1);
      await marketplace.connect(buyer).approve(marketplaceAddress, 1);
      await marketplace
        .connect(buyer)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      const serviceFee = (ONE_ETHER * 1000n) / 10000n;
      const sellerAmount = ONE_ETHER - serviceFee;

      const creatorBefore = await ethers.provider.getBalance(creator.address);
      const buyerBefore = await ethers.provider.getBalance(buyer.address);
      const mindminerBefore = await ethers.provider.getBalance(MINDMINER_WALLET);

      await marketplace.connect(other).buyFixedPricePatentToken(1, { value: ONE_ETHER });

      expect(await marketplace.ownerOf(1)).to.equal(other.address);
      expect((await ethers.provider.getBalance(MINDMINER_WALLET)) - mindminerBefore).to.equal(
        serviceFee
      );
      expect((await ethers.provider.getBalance(creator.address)) - creatorBefore).to.equal(0n);
      expect((await ethers.provider.getBalance(buyer.address)) - buyerBefore).to.equal(
        sellerAmount
      );
    });

    it("reverts when listing an expired patent token", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);
      await time.increase(EXPIRY_DURATION + 1n);

      await expect(
        marketplace
          .connect(creator)
          .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });

    it("reverts invalid list params", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, other, marketplaceAddress } = fixture;
      await mintAndApprove(fixture, creator);

      await expect(
        marketplace.connect(creator).listPatentTokenForFixedPrice(0, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "ERC721NonexistentToken");

      await expect(
        marketplace.connect(creator).listPatentTokenForFixedPrice(1, 0, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "ListPriceCannotBeZero");

      await expect(
        marketplace.connect(creator).listPatentTokenForFixedPrice(1, ONE_ETHER, ZERO_ADDRESS, ZERO_ADDRESS)
      ).to.be.reverted;

      await expect(
        marketplace.connect(other).listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "NotOwnerOfTokenId");
    });

    it("buys listed token and sends 10% service fee to MINDMINER_WALLET", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, marketplaceAddress } = fixture;
      await mintAndApprove(fixture, creator);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      const serviceFee = (ONE_ETHER * 1000n) / 10000n;
      const royaltyFee = (ONE_ETHER * 1000n) / 10000n;
      const sellerAmount = ONE_ETHER - serviceFee - royaltyFee;

      const mindminerBefore = await ethers.provider.getBalance(MINDMINER_WALLET);
      const creatorBefore = await ethers.provider.getBalance(creator.address);

      await expect(marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER }))
        .to.emit(marketplace, "PatentTokenBought")
        .withArgs(1n, buyer.address, 1n);

      expect(await marketplace.ownerOf(1)).to.equal(buyer.address);

      const mindminerAfter = await ethers.provider.getBalance(MINDMINER_WALLET);
      const creatorAfter = await ethers.provider.getBalance(creator.address);

      expect(mindminerAfter - mindminerBefore).to.equal(serviceFee);
      expect(creatorAfter - creatorBefore).to.equal(sellerAmount + royaltyFee);
    });

    it("sends royalty to original creator on secondary sale", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, other, marketplaceAddress } = fixture;
      await mintAndApprove(fixture, creator);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);
      await marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER });

      await marketplace.connect(buyer).approve(marketplaceAddress, 1);
      await marketplace
        .connect(buyer)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      const serviceFee = (ONE_ETHER * 1000n) / 10000n;
      const royaltyFee = (ONE_ETHER * 1000n) / 10000n;
      const sellerAmount = ONE_ETHER - serviceFee - royaltyFee;

      const creatorBefore = await ethers.provider.getBalance(creator.address);
      const buyerBefore = await ethers.provider.getBalance(buyer.address);
      const mindminerBefore = await ethers.provider.getBalance(MINDMINER_WALLET);

      await marketplace.connect(other).buyFixedPricePatentToken(1, { value: ONE_ETHER });

      expect(await marketplace.ownerOf(1)).to.equal(other.address);
      expect((await ethers.provider.getBalance(MINDMINER_WALLET)) - mindminerBefore).to.equal(
        serviceFee
      );
      expect((await ethers.provider.getBalance(creator.address)) - creatorBefore).to.equal(
        royaltyFee
      );
      expect((await ethers.provider.getBalance(buyer.address)) - buyerBefore).to.equal(
        sellerAmount
      );
    });

    it("reverts buy edge cases", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, marketplaceAddress } = fixture;
      await mintAndApprove(fixture, creator);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      await expect(
        marketplace.connect(creator).buyFixedPricePatentToken(1, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "OwnerCannotBuyOwnPatentToken");

      await expect(
        marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER - 1n })
      ).to.be.revertedWithCustomError(marketplace, "PaymentDoesNotMeetRequiredPrice");

      await marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER });

      await expect(
        marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "ItemAlreadySold");
    });

    it("cancels fixed listing and returns token", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;
      await mintAndApprove(fixture, creator);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      await expect(marketplace.connect(creator).cancelListingForFixedPrice(1))
        .to.emit(marketplace, "PatentTokenDelisted")
        .withArgs(1n, creator.address);

      expect(await marketplace.ownerOf(1)).to.equal(creator.address);
      const listing = await marketplace.fixedPrice(1);
      expect(listing.listed).to.equal(false);
    });

    it("reverts cancel when not owner or not listed or already sold", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, other, marketplaceAddress } = fixture;
      await mintAndApprove(fixture, creator);

      await expect(
        marketplace.connect(other).cancelListingForFixedPrice(1)
      ).to.be.revertedWithCustomError(marketplace, "NotOwnerOfListing");

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      await marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER });

      await expect(
        marketplace.connect(creator).cancelListingForFixedPrice(1)
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenCannotBeCancelledAsAlreadySold");
    });
  });

  describe("Auction listing & bidding", function () {
    async function setupAuction(fixture) {
      const { marketplace, creator, marketplaceAddress } = fixture;
      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_ETHER, start, end, 1, marketplaceAddress, ZERO_ADDRESS);

      await time.increaseTo(start);
      return { start, end };
    }

    it("lists token for auction with valid schedule", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 60n;
      const end = start + 3600n;

      await expect(
        marketplace
          .connect(creator)
          .listItemForAuction(ONE_ETHER, start, end, 1, marketplaceAddress, ZERO_ADDRESS)
      ).to.emit(marketplace, "PatentTokenListed");

      expect(await marketplace.ownerOf(1)).to.equal(marketplaceAddress);
    });

    it("reverts when listing auction for expired patent token", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);
      await time.increase(EXPIRY_DURATION + 1n);

      const now = await time.latest();
      const start = BigInt(now) + 60n;
      const end = start + 3600n;

      await expect(
        marketplace
          .connect(creator)
          .listItemForAuction(ONE_ETHER, start, end, 1, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });

    it("reverts invalid auction params", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 3600n;
      const end = start + 7200n;

      await expect(
        marketplace.connect(creator).listItemForAuction(0, start, end, 1, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "InitialPriceCannotBeZero");

      await expect(
        marketplace
          .connect(creator)
          .listItemForAuction(ONE_ETHER, start - 7200n, end, 1, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "StartTimeAndEndTimeMustBeGreaterThanCurrentTime");

      await expect(
        marketplace
          .connect(creator)
          .listItemForAuction(ONE_ETHER, end, start, 1, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "AuctionStartTimeMustBeLessThanEndTime");
    });

    it("accepts increasing bids and refunds previous bidder", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, bidder, buyer } = fixture;
      await setupAuction(fixture);

      const bid1 = ONE_ETHER;
      const bid2 = ethers.parseEther("2");

      await marketplace.connect(bidder).startBid(1, 0, { value: bid1 });
      const bidderBefore = await ethers.provider.getBalance(bidder.address);

      await marketplace.connect(buyer).startBid(1, 0, { value: bid2 });

      const bidderAfter = await ethers.provider.getBalance(bidder.address);
      expect(bidderAfter).to.be.gt(bidderBefore);

      const auctionData = await marketplace.auction(1);
      expect(auctionData.currentBidder).to.equal(buyer.address);
      expect(auctionData.currentBidAmount).to.equal(bid2);
    });

    it("reverts bid edge cases", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder } = fixture;
      await setupAuction(fixture);

      await expect(
        marketplace.connect(creator).startBid(1, 0, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "SellerCannotPlaceBidOnOwnPatentToken");

      await expect(
        marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER - 1n })
      ).to.be.revertedWithCustomError(marketplace, "BidMustBeHigherThanInitialPrice");

      await expect(
        marketplace.connect(bidder).startBid(1, 0)
      ).to.be.revertedWithCustomError(marketplace, "EthPaymentRequired");

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });

      await expect(
        marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "HigherOrEqualBidAlreadyExists");
    });

    it("sends 10% service fee to MINDMINER_WALLET on auction settlement", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder } = fixture;
      await setupAuction(fixture);

      const serviceFee = (ONE_ETHER * 1000n) / 10000n;
      const mindminerBefore = await ethers.provider.getBalance(MINDMINER_WALLET);

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });
      await marketplace.connect(creator).auctionEnd(1);

      const mindminerAfter = await ethers.provider.getBalance(MINDMINER_WALLET);
      expect(mindminerAfter - mindminerBefore).to.equal(serviceFee);
    });

    it("seller can end auction early and transfer to highest bidder", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, marketplaceAddress } = fixture;
      await setupAuction(fixture);

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });

      await marketplace.connect(creator).auctionEnd(1);

      expect(await marketplace.ownerOf(1)).to.equal(bidder.address);
      const auctionData = await marketplace.auction(1);
      expect(auctionData.isSold).to.equal(true);
      expect(await marketplace.ownerOf(1)).to.equal(bidder.address);
      expect(marketplaceAddress).to.not.equal(bidder.address);
    });

    it("reverts auctionEnd when there are no bids", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator } = fixture;
      await setupAuction(fixture);

      const auctionData = await marketplace.auction(1);
      expect(auctionData.currentBidder).to.equal(ZERO_ADDRESS);
      expect(auctionData.currentBidAmount).to.equal(0n);

      await expect(
        marketplace.connect(creator).auctionEnd(1)
      ).to.be.revertedWithCustomError(marketplace, "PriceOfPatentTokenCannotBeZero");
    });

    it("highest bidder claims after auction end time", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, bidder } = fixture;
      const { end } = await setupAuction(fixture);

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });
      await time.increaseTo(end + 1n);

      await marketplace.connect(bidder).claimPatentToken(1);
      expect(await marketplace.ownerOf(1)).to.equal(bidder.address);
    });

    it("reverts claim before end and double claim", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, buyer } = fixture;
      await setupAuction(fixture);

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });

      await expect(
        marketplace.connect(bidder).claimPatentToken(1)
      ).to.be.revertedWithCustomError(marketplace, "CannotClaimPatentTokenAsAuctionTimeNotEnded");

      await expect(
        marketplace.connect(buyer).claimPatentToken(1)
      ).to.be.revertedWithCustomError(marketplace, "OnlyHighestBidderCanClaimPatentToken");

      await marketplace.connect(creator).auctionEnd(1);

      await expect(
        marketplace.connect(bidder).claimPatentToken(1)
      ).to.be.revertedWithCustomError(marketplace, "AuctionEndedPatentTokenTransferredToHighestBidder");
    });

    it("cancels auction and refunds current bidder", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder } = fixture;
      await setupAuction(fixture);

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });
      const before = await ethers.provider.getBalance(bidder.address);

      await marketplace.connect(creator).cancelListingForAuction(1);

      const after = await ethers.provider.getBalance(bidder.address);
      expect(after).to.be.gt(before);
      expect(await marketplace.ownerOf(1)).to.equal(creator.address);
    });
  });

  describe("Transfer restrictions after expiry", function () {
    it("blocks transferFrom after patent token expiry", async function () {
      const { marketplace, creator, buyer } = await loadFixture(deployPatentMarketplaceFixture);

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await time.increase(EXPIRY_DURATION + 1n);

      await expect(
        marketplace.connect(creator).transferFrom(creator.address, buyer.address, 1)
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });

    it("blocks safeTransferFrom after patent token expiry", async function () {
      const { marketplace, creator, buyer } = await loadFixture(deployPatentMarketplaceFixture);

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(creator.address, 1);
      await time.increase(EXPIRY_DURATION + 1n);

      await expect(
        marketplace
          .connect(creator)
          .safeTransferFrom(creator.address, buyer.address, 1)
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });
  });

  describe("Patent token expiry", function () {
    it("returns correct expiry timestamp from getPatentTokenExpireTime", async function () {
      const { marketplace, creator } = await loadFixture(deployPatentMarketplaceFixture);

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      const info = await marketplace.patentTokenInfo(1);
      expect(await marketplace.getPatentTokenExpireTime(1)).to.equal(info.expiryTime);
      expect(info.expiryTime).to.equal(info.mintedAt + EXPIRY_DURATION);
    });

    it("allows transfer before expiry", async function () {
      const { marketplace, creator, buyer } = await loadFixture(deployPatentMarketplaceFixture);

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).transferFrom(creator.address, buyer.address, 1);
      expect(await marketplace.ownerOf(1)).to.equal(buyer.address);
    });

    it("blocks fixed-price buy after patent token expires", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);
      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      await time.increase(EXPIRY_DURATION + 1n);

      await expect(
        marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });

    it("blocks fixed-price cancel after patent token expires", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);
      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      await time.increase(EXPIRY_DURATION + 1n);

      await expect(
        marketplace.connect(creator).cancelListingForFixedPrice(1)
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });

    it("blocks bidding after patent token expires", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + EXPIRY_DURATION + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_ETHER, start, end, 1, marketplaceAddress, ZERO_ADDRESS);

      await time.increaseTo(start);
      await time.increase(EXPIRY_DURATION + 1n);

      await expect(
        marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });

    it("blocks auctionEnd after patent token expires", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + EXPIRY_DURATION + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_ETHER, start, end, 1, marketplaceAddress, ZERO_ADDRESS);

      await time.increaseTo(start);
      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });
      await time.increase(EXPIRY_DURATION + 1n);

      await expect(
        marketplace.connect(creator).auctionEnd(1)
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });

    it("blocks claim after patent token expires", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_ETHER, start, end, 1, marketplaceAddress, ZERO_ADDRESS);

      await time.increaseTo(start);
      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });
      await time.increaseTo(end + 1n);
      await time.increase(EXPIRY_DURATION + 1n);

      await expect(
        marketplace.connect(bidder).claimPatentToken(1)
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenExpired");
    });
  });

  describe("Fixed-price edge cases", function () {
    it("reverts buy with invalid fixed id zero", async function () {
      const { marketplace, buyer } = await loadFixture(deployPatentMarketplaceFixture);

      await expect(
        marketplace.connect(buyer).buyFixedPricePatentToken(0, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "InvalidFixedPatentTokenId");
    });

    it("reverts buy when token was never listed", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);

      await expect(
        marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "PatentTokenNotListedYet");
    });

    it("reverts cancel when listing does not exist", async function () {
      const { marketplace, creator } = await loadFixture(deployPatentMarketplaceFixture);

      await expect(
        marketplace.connect(creator).cancelListingForFixedPrice(99)
      ).to.be.revertedWithCustomError(marketplace, "NotOwnerOfListing");
    });

    it("reverts list when seller is not token holder", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, other, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(other.address, 1);

      await expect(
        marketplace
          .connect(other)
          .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(marketplace, "NotOwnerOfTokenId");
    });

    it("accepts overpayment on fixed-price buy", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);
      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);

      await expect(
        marketplace.connect(buyer).buyFixedPricePatentToken(1, { value: ONE_ETHER * 2n })
      ).to.emit(marketplace, "PatentTokenBought");

      expect(await marketplace.ownerOf(1)).to.equal(buyer.address);
    });
  });

  describe("Auction edge cases", function () {
    async function setupAuction(fixture, opts = {}) {
      const { marketplace, creator, marketplaceAddress } = fixture;
      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = opts.start ?? BigInt(now) + 100n;
      const end = opts.end ?? start + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_ETHER, start, end, 1, marketplaceAddress, ZERO_ADDRESS);

      if (opts.advanceToStart !== false) {
        await time.increaseTo(start);
      }

      return { start, end };
    }

    it("reverts bid before auction start time", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, bidder } = fixture;

      const now = await time.latest();
      const start = BigInt(now) + 3600n;
      const end = start + 3600n;
      await setupAuction(fixture, { start, end, advanceToStart: false });

      await expect(
        marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "CannotBidBeforeAuctionStartedOrAfterEnd");
    });

    it("reverts bid after auction end time", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, bidder } = fixture;

      const { end } = await setupAuction(fixture);
      await time.increaseTo(end + 1n);

      await expect(
        marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "CannotBidBeforeAuctionStartedOrAfterEnd");
    });

    it("reverts auctionEnd when caller is not seller", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, bidder, other } = fixture;
      await setupAuction(fixture);

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });

      await expect(
        marketplace.connect(other).auctionEnd(1)
      ).to.be.revertedWithCustomError(marketplace, "OnlySellerCanEndAuction");
    });

    it("reverts auctionEnd after scheduled end time (must use claim)", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder } = fixture;
      const { end } = await setupAuction(fixture);

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });
      await time.increaseTo(end + 1n);

      await expect(
        marketplace.connect(creator).auctionEnd(1)
      ).to.be.revertedWithCustomError(marketplace, "AuctionHasEnded");
    });

    it("reverts auctionEnd when already sold", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder } = fixture;
      await setupAuction(fixture);

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });
      await marketplace.connect(creator).auctionEnd(1);

      await expect(
        marketplace.connect(creator).auctionEnd(1)
      ).to.be.revertedWithCustomError(marketplace, "AuctionAlreadyEnded");
    });

    it("reverts cancel auction when not listed", async function () {
      const { marketplace, creator } = await loadFixture(deployPatentMarketplaceFixture);

      await expect(
        marketplace.connect(creator).cancelListingForAuction(99)
      ).to.be.revertedWithCustomError(marketplace, "NotOwnerOfListing");
    });

    it("sends royalty to creator on auction claim after end time", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder } = fixture;
      const { end } = await setupAuction(fixture);

      const serviceFee = (ONE_ETHER * 1000n) / 10000n;
      const royaltyFee = (ONE_ETHER * 1000n) / 10000n;
      const sellerAmount = ONE_ETHER - serviceFee - royaltyFee;

      await marketplace.connect(bidder).startBid(1, 0, { value: ONE_ETHER });

      const creatorBefore = await ethers.provider.getBalance(creator.address);
      const mindminerBefore = await ethers.provider.getBalance(MINDMINER_WALLET);

      await time.increaseTo(end + 1n);
      await marketplace.connect(bidder).claimPatentToken(1);

      expect(await marketplace.ownerOf(1)).to.equal(bidder.address);
      expect((await ethers.provider.getBalance(MINDMINER_WALLET)) - mindminerBefore).to.equal(
        serviceFee
      );
      expect((await ethers.provider.getBalance(creator.address)) - creatorBefore).to.equal(
        sellerAmount + royaltyFee
      );
    });

    it("reverts claim when no bids were placed", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, buyer } = fixture;
      const { end } = await setupAuction(fixture);

      await time.increaseTo(end + 1n);

      await expect(
        marketplace.connect(buyer).claimPatentToken(1)
      ).to.be.revertedWithCustomError(marketplace, "OnlyHighestBidderCanClaimPatentToken");
    });
  });

  describe("USDT payment token", function () {
    const ONE_USDT = ethers.parseUnits("1", 6);

    async function mintAndApproveUsdt(fixture, holder) {
      const { marketplace, marketplaceAddress, usdtAddress } = fixture;
      await marketplace.mintPatentToken(holder.address, TOKEN_URI);
      await marketplace.connect(holder).approve(marketplaceAddress, 1);
      return 1n;
    }

    it("buys fixed-price listing with USDT", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, other, marketplaceAddress, usdt, usdtAddress } =
        fixture;
      await mintAndApproveUsdt(fixture, creator);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_USDT, marketplaceAddress, usdtAddress);

      const serviceFee = (ONE_USDT * 1000n) / 10000n;
      const royaltyFee = (ONE_USDT * 1000n) / 10000n;
      const sellerAmount = ONE_USDT - serviceFee - royaltyFee;

      await usdt.connect(other).approve(marketplaceAddress, ONE_USDT);

      const creatorBefore = await usdt.balanceOf(creator.address);
      const mindminerBefore = await usdt.balanceOf(MINDMINER_WALLET);

      await marketplace.connect(other).buyFixedPricePatentToken(1);

      expect(await marketplace.ownerOf(1)).to.equal(other.address);
      expect(await usdt.balanceOf(MINDMINER_WALLET) - mindminerBefore).to.equal(serviceFee);
      expect(await usdt.balanceOf(creator.address) - creatorBefore).to.equal(
        sellerAmount + royaltyFee
      );
    });

    it("reverts fixed-price USDT buy when ETH is sent", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, other, marketplaceAddress, usdtAddress } = fixture;
      await mintAndApproveUsdt(fixture, creator);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_USDT, marketplaceAddress, usdtAddress);

      await expect(
        marketplace.connect(other).buyFixedPricePatentToken(1, { value: ONE_USDT })
      ).to.be.revertedWithCustomError(marketplace, "UnexpectedEth");
    });

    it("reverts listing with invalid payment token", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;
      await mintAndApproveUsdt(fixture, creator);

      await expect(
        marketplace
          .connect(creator)
          .listPatentTokenForFixedPrice(1, ONE_USDT, marketplaceAddress, creator.address)
      ).to.be.revertedWithCustomError(marketplace, "InvalidPaymentToken");
    });

    it("places USDT bids and settles on claim", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, buyer, marketplaceAddress, usdt, usdtAddress } =
        fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_USDT, start, end, 1, marketplaceAddress, usdtAddress);

      await time.increaseTo(start);

      const bid1 = ONE_USDT;
      const bid2 = ONE_USDT * 2n;
      await usdt.connect(bidder).approve(marketplaceAddress, bid2);
      await usdt.connect(buyer).approve(marketplaceAddress, bid2);

      await marketplace.connect(bidder).startBid(1, bid1);
      await marketplace.connect(buyer).startBid(1, bid2);

      expect(await usdt.balanceOf(bidder.address)).to.equal(fixture.oneUsdt);

      await time.increaseTo(end + 1n);
      await marketplace.connect(buyer).claimPatentToken(1);

      expect(await marketplace.ownerOf(1)).to.equal(buyer.address);
      expect((await marketplace.auction(1)).currentBidAmount).to.equal(bid2);
    });

    it("refunds USDT bidder when auction is cancelled", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, marketplaceAddress, usdt, usdtAddress, oneUsdt } =
        fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_USDT, start, end, 1, marketplaceAddress, usdtAddress);

      await time.increaseTo(start);
      await usdt.connect(bidder).approve(marketplaceAddress, ONE_USDT);
      await marketplace.connect(bidder).startBid(1, ONE_USDT);

      const bidderBefore = await usdt.balanceOf(bidder.address);
      await marketplace.connect(creator).cancelListingForAuction(1);

      expect(await usdt.balanceOf(bidder.address)).to.equal(bidderBefore + ONE_USDT);
      expect(await usdt.balanceOf(bidder.address)).to.equal(oneUsdt);
    });

    it("stores paymentToken on fixed-price and auction listings", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress, usdtAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_ETHER, marketplaceAddress, ZERO_ADDRESS);
      expect((await marketplace.fixedPrice(1)).paymentToken).to.equal(ZERO_ADDRESS);

      await marketplace.connect(creator).cancelListingForFixedPrice(1);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_USDT, marketplaceAddress, usdtAddress);
      expect((await marketplace.fixedPrice(1)).paymentToken).to.equal(usdtAddress);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;
      await marketplace.mintPatentToken(creator.address, "ipfs://auction-token");
      await marketplace.connect(creator).approve(marketplaceAddress, 2);
      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_USDT, start, end, 2, marketplaceAddress, usdtAddress);
      expect((await marketplace.auction(2)).paymentToken).to.equal(usdtAddress);
    });

    it("reverts USDT buy without token approval", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, other, marketplaceAddress, usdtAddress } = fixture;
      await mintAndApproveUsdt(fixture, creator);

      await marketplace
        .connect(creator)
        .listPatentTokenForFixedPrice(1, ONE_USDT, marketplaceAddress, usdtAddress);

      await expect(marketplace.connect(other).buyFixedPricePatentToken(1)).to.be.reverted;
    });

    it("reverts USDT bid when ETH is sent", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, marketplaceAddress, usdtAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_USDT, start, end, 1, marketplaceAddress, usdtAddress);

      await time.increaseTo(start);

      await expect(
        marketplace.connect(bidder).startBid(1, ONE_USDT, { value: ONE_ETHER })
      ).to.be.revertedWithCustomError(marketplace, "UnexpectedEth");
    });

    it("reverts USDT bid with zero bid amount", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, marketplaceAddress, usdtAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_USDT, start, end, 1, marketplaceAddress, usdtAddress);

      await time.increaseTo(start);

      await expect(
        marketplace.connect(bidder).startBid(1, 0)
      ).to.be.revertedWithCustomError(marketplace, "PaymentDoesNotMeetRequiredPrice");
    });

    it("reverts auction list with invalid payment token", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, marketplaceAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;

      await expect(
        marketplace
          .connect(creator)
          .listItemForAuction(ONE_USDT, start, end, 1, marketplaceAddress, creator.address)
      ).to.be.revertedWithCustomError(marketplace, "InvalidPaymentToken");
    });

    it("settles USDT auction early via auctionEnd with fees in USDT", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, bidder, marketplaceAddress, usdt, usdtAddress } = fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).approve(marketplaceAddress, 1);

      const now = await time.latest();
      const start = BigInt(now) + 100n;
      const end = start + 3600n;

      await marketplace
        .connect(creator)
        .listItemForAuction(ONE_USDT, start, end, 1, marketplaceAddress, usdtAddress);

      await time.increaseTo(start);
      await usdt.connect(bidder).approve(marketplaceAddress, ONE_USDT);
      await marketplace.connect(bidder).startBid(1, ONE_USDT);

      const serviceFee = (ONE_USDT * 1000n) / 10000n;
      const royaltyFee = (ONE_USDT * 1000n) / 10000n;
      const sellerAmount = ONE_USDT - serviceFee - royaltyFee;
      const mindminerBefore = await usdt.balanceOf(MINDMINER_WALLET);
      const creatorBefore = await usdt.balanceOf(creator.address);

      await marketplace.connect(creator).auctionEnd(1);

      expect(await marketplace.ownerOf(1)).to.equal(bidder.address);
      expect(await usdt.balanceOf(MINDMINER_WALLET) - mindminerBefore).to.equal(serviceFee);
      expect(await usdt.balanceOf(creator.address) - creatorBefore).to.equal(
        sellerAmount + royaltyFee
      );
    });

    it("pays no USDT creator royalty when non-creator listed for fixed price", async function () {
      const fixture = await loadFixture(deployPatentMarketplaceFixture);
      const { marketplace, creator, buyer, other, marketplaceAddress, usdt, usdtAddress } =
        fixture;

      await marketplace.mintPatentToken(creator.address, TOKEN_URI);
      await marketplace.connect(creator).transferFrom(creator.address, buyer.address, 1);
      await marketplace.connect(buyer).approve(marketplaceAddress, 1);
      await marketplace
        .connect(buyer)
        .listPatentTokenForFixedPrice(1, ONE_USDT, marketplaceAddress, usdtAddress);

      const serviceFee = (ONE_USDT * 1000n) / 10000n;
      const sellerAmount = ONE_USDT - serviceFee;

      await usdt.connect(other).approve(marketplaceAddress, ONE_USDT);

      const creatorBefore = await usdt.balanceOf(creator.address);
      const buyerBefore = await usdt.balanceOf(buyer.address);
      const mindminerBefore = await usdt.balanceOf(MINDMINER_WALLET);

      await marketplace.connect(other).buyFixedPricePatentToken(1);

      expect(await usdt.balanceOf(MINDMINER_WALLET) - mindminerBefore).to.equal(serviceFee);
      expect(await usdt.balanceOf(creator.address) - creatorBefore).to.equal(0n);
      expect(await usdt.balanceOf(buyer.address) - buyerBefore).to.equal(sellerAmount);
    });
  });

  describe("supportsInterface", function () {
    it("supports ERC721 interface", async function () {
      const { marketplace } = await loadFixture(deployPatentMarketplaceFixture);
      const erc721InterfaceId = "0x80ac58cd";
      expect(await marketplace.supportsInterface(erc721InterfaceId)).to.equal(true);
    });
  });
});
