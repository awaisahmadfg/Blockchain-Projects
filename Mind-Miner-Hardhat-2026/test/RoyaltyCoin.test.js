const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const {
  deployRoyaltyCoinFixture,
  deployMultiPairRoyaltyCoinFixture,
  fundRcUser,
  impersonatePair,
} = require("./helpers/fixtures");
const {
  ZERO_ADDRESS,
  MINDMINER_WALLET,
  LIQUIDITY_TREASURY_WALLET,
  MARKET_WALLET,
  TEAM_WALLET,
  BPS,
  TRADE_FEE_BPS,
  DEFAULT_MINDMINER_FEE_BPS,
  DEFAULT_LIQUIDITY_FEE_BPS,
  MAX_REWARD_FEE_BPS,
  ONE_RC,
  MAX_SINGLE_DISTRIBUTION,
  MAX_SUPPLY,
  REWARDS_SUPPLY,
  LIQUIDITY_SUPPLY,
  MARKET_SUPPLY,
  TEAM_SUPPLY,
} = require("./helpers/constants");

function calcRewardSplit(amount, mindminerBps, liquidityBps) {
  const adjusted = amount;
  const mindminer = (adjusted * mindminerBps) / BPS;
  const liquidity = (adjusted * liquidityBps) / BPS;
  return { adjusted, mindminer, liquidity, total: adjusted + mindminer + liquidity };
}

describe("RoyaltyCoin", function () {
  describe("Initialization", function () {
    it("mints correct total supply allocation", async function () {
      const { royaltyCoinRead } = await loadFixture(deployRoyaltyCoinFixture);

      expect(await royaltyCoinRead.totalSupply()).to.equal(MAX_SUPPLY);
      expect(await royaltyCoinRead.balanceOf(await royaltyCoinRead.getAddress())).to.equal(REWARDS_SUPPLY);
      expect(await royaltyCoinRead.balanceOf(await royaltyCoinRead.LIQUIDITY_TREASURY_WALLET())).to.equal(
        LIQUIDITY_SUPPLY
      );
      expect(await royaltyCoinRead.balanceOf(await royaltyCoinRead.MARKET_WALLET())).to.equal(MARKET_SUPPLY);
      expect(await royaltyCoinRead.balanceOf(await royaltyCoinRead.TEAM_WALLET())).to.equal(TEAM_SUPPLY);
    });

    it("sets token metadata and initial reward pool state", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);

      expect(await royaltyCoin.name()).to.equal("RoyaltyCoin");
      expect(await royaltyCoin.symbol()).to.equal("RC");
      expect(await royaltyCoin.remainingSupply()).to.equal(REWARDS_SUPPLY);
      expect(await royaltyCoin.totalRewardsDistributed()).to.equal(0n);
      expect(await royaltyCoin.tradeFeeBps()).to.equal(TRADE_FEE_BPS);
    });

    it("deploys quote receiver and wires router", async function () {
      const { royaltyCoin, router } = await loadFixture(deployRoyaltyCoinFixture);

      const receiver = await royaltyCoin.liquidityQuoteReceiver();
      expect(receiver).to.not.equal(ZERO_ADDRESS);
      expect(await royaltyCoin.uniswapV2Router()).to.equal(await router.getAddress());
    });

    it("sets MINDMINER_WALLET as owner regardless of deployer", async function () {
      const { royaltyCoinRead, deployer } = await loadFixture(deployRoyaltyCoinFixture);

      expect(await royaltyCoinRead.owner()).to.equal(MINDMINER_WALLET);
      expect(deployer.address).to.not.equal(MINDMINER_WALLET);
    });

    it("reverts when deploy wallet calls reward distribution", async function () {
      const { royaltyCoinRead, deployer, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoinRead
          .connect(deployer)
          .distributeRoyaltyCoinReward(user.address, ONE_RC, 0, 0)
      ).to.be.revertedWithCustomError(royaltyCoinRead, "UnauthorizedRewardOperator");
    });

    it("sets MINDMINER_WALLET as initial rewardOperator", async function () {
      const { royaltyCoinRead } = await loadFixture(deployRoyaltyCoinFixture);

      expect(await royaltyCoinRead.rewardOperator()).to.equal(MINDMINER_WALLET);
    });

    it("reverts initialize with zero router", async function () {
      const RoyaltyCoin = await ethers.getContractFactory("RoyaltyCoin");
      await expect(
        upgrades.deployProxy(RoyaltyCoin, [ZERO_ADDRESS], { kind: "uups" })
      ).to.be.revertedWithCustomError(RoyaltyCoin, "InvalidRouterAddress");
    });

    it("marks treasury wallets fee-exempt (wallet-to-wallet untaxed)", async function () {
      const { royaltyCoin, user, user2 } = await loadFixture(deployRoyaltyCoinFixture);

      const amount = ethers.parseEther("100");
      await royaltyCoin.distributeRoyaltyCoinReward(user.address, amount, 0, 0);

      await expect(royaltyCoin.connect(user).transfer(user2.address, amount))
        .to.emit(royaltyCoin, "Transfer")
        .withArgs(user.address, user2.address, amount);
    });
  });

  describe("addQuoteToken / removeQuoteToken", function () {
    it("registers an existing pair and emits event", async function () {
      const { royaltyCoin, usdt, pair } = await loadFixture(deployRoyaltyCoinFixture);
      const usdtAddress = await usdt.getAddress();

      await expect(royaltyCoin.removeQuoteToken(usdtAddress))
        .to.emit(royaltyCoin, "QuoteTokenRemoved")
        .withArgs(usdtAddress, pair);

      await expect(royaltyCoin.addQuoteToken(usdtAddress))
        .to.emit(royaltyCoin, "QuoteTokenAdded")
        .withArgs(usdtAddress, pair);
    });

    it("reverts when pair does not exist", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);
      const fakeToken = ethers.Wallet.createRandom().address;

      await expect(royaltyCoin.addQuoteToken(fakeToken)).to.be.revertedWithCustomError(
        royaltyCoin,
        "PairDoesNotExist"
      );
    });

    it("reverts when quote token is zero address", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(royaltyCoin.addQuoteToken(ZERO_ADDRESS)).to.be.revertedWithCustomError(
        royaltyCoin,
        "InvalidQuoteTokenAddress"
      );
    });

    it("reverts when quote token already registered", async function () {
      const { royaltyCoin, usdt } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(royaltyCoin.addQuoteToken(await usdt.getAddress())).to.be.revertedWithCustomError(
        royaltyCoin,
        "QuoteTokenAlreadyRegistered"
      );
    });

    it("reverts removeQuoteToken when pair does not exist", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);
      const fakeToken = ethers.Wallet.createRandom().address;

      await expect(royaltyCoin.removeQuoteToken(fakeToken)).to.be.revertedWithCustomError(
        royaltyCoin,
        "PairDoesNotExist"
      );
    });

    it("reverts removeQuoteToken when pair exists but is not registered", async function () {
      const { royaltyCoin, factory, rcAddress } = await loadFixture(deployRoyaltyCoinFixture);
      const DummyWETH = await ethers.getContractFactory("DummyWETH");
      const weth = await DummyWETH.deploy();
      const wethAddress = await weth.getAddress();

      await factory.createPair(rcAddress, wethAddress);

      await expect(royaltyCoin.removeQuoteToken(wethAddress)).to.be.revertedWithCustomError(
        royaltyCoin,
        "QuoteTokenNotRegistered"
      );
    });

    it("registers multiple quote tokens for multi-pool testing", async function () {
      const { royaltyCoin, factory, rcAddress } = await loadFixture(deployRoyaltyCoinFixture);
      const DummyWETH = await ethers.getContractFactory("DummyWETH");
      const weth = await DummyWETH.deploy();
      const wethAddress = await weth.getAddress();

      await factory.createPair(rcAddress, wethAddress);
      const wethPair = await factory.getPair(rcAddress, wethAddress);

      await expect(royaltyCoin.addQuoteToken(wethAddress))
        .to.emit(royaltyCoin, "QuoteTokenAdded")
        .withArgs(wethAddress, wethPair);
    });

    it("reverts admin functions for non-owner", async function () {
      const { royaltyCoinRead, usdt, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoinRead.connect(user).addQuoteToken(await usdt.getAddress())
      ).to.be.revertedWithCustomError(royaltyCoinRead, "OwnableUnauthorizedAccount");

      await expect(
        royaltyCoinRead.connect(user).removeQuoteToken(await usdt.getAddress())
      ).to.be.revertedWithCustomError(royaltyCoinRead, "OwnableUnauthorizedAccount");
    });
  });

  describe("distributeRoyaltyCoinReward", function () {
    it("distributes default 500/500 split correctly", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("10000");
      const { adjusted, mindminer, liquidity, total } = calcRewardSplit(
        amount,
        DEFAULT_MINDMINER_FEE_BPS,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const contractBefore = await royaltyCoin.balanceOf(await royaltyCoin.getAddress());
      const mindminerBefore = await royaltyCoin.balanceOf(MINDMINER_WALLET);

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(
          user.address,
          amount,
          DEFAULT_MINDMINER_FEE_BPS,
          DEFAULT_LIQUIDITY_FEE_BPS
        )
      )
        .to.emit(royaltyCoin, "RoyaltyCoinRewardDistributed")
        .withArgs(user.address, adjusted)
        .and.to.emit(royaltyCoin, "MindminerFeeSent")
        .withArgs(mindminer)
        .and.to.emit(royaltyCoin, "LiquidityFeesAccumulated")
        .withArgs(liquidity, "reward");

      expect(await royaltyCoin.balanceOf(user.address)).to.equal(adjusted);
      expect(await royaltyCoin.balanceOf(MINDMINER_WALLET)).to.equal(mindminerBefore + mindminer);
      expect(await royaltyCoin.balanceOf(await royaltyCoin.getAddress())).to.equal(
        contractBefore - adjusted - mindminer
      );
      expect(await royaltyCoin.totalRewardsDistributed()).to.equal(total);
      expect(await royaltyCoin.remainingSupply()).to.equal(REWARDS_SUPPLY - total);
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(liquidity);
    });

    it("supports dynamic 1000/0 fee split", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("1000");
      const mindminerBps = 1000n;
      const liquidityBps = 0n;
      const { adjusted, mindminer, total } = calcRewardSplit(amount, mindminerBps, liquidityBps);

      await royaltyCoin.distributeRoyaltyCoinReward(user.address, amount, mindminerBps, liquidityBps);

      expect(await royaltyCoin.balanceOf(user.address)).to.equal(adjusted);
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(0n);
      expect(await royaltyCoin.totalRewardsDistributed()).to.equal(total);
    });

    it("skips zero fee transfers and events", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("500");

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(user.address, amount, 0, 0)
      )
        .to.emit(royaltyCoin, "RoyaltyCoinRewardDistributed")
        .withArgs(user.address, amount)
        .and.not.to.emit(royaltyCoin, "MindminerFeeSent")
        .and.not.to.emit(royaltyCoin, "LiquidityFeesAccumulated");
    });

    it("reverts AmountExceedsLimit above 1M per call", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(
          user.address,
          MAX_SINGLE_DISTRIBUTION + 1n,
          DEFAULT_MINDMINER_FEE_BPS,
          DEFAULT_LIQUIDITY_FEE_BPS
        )
      ).to.be.revertedWithCustomError(royaltyCoin, "AmountExceedsLimit");
    });

    it("reverts InvalidRewardFeeBps above max", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(
          user.address,
          ONE_RC,
          MAX_REWARD_FEE_BPS + 1n,
          DEFAULT_LIQUIDITY_FEE_BPS
        )
      ).to.be.revertedWithCustomError(royaltyCoin, "InvalidRewardFeeBps");
    });

    it("reverts zero amount", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(
          user.address,
          0,
          DEFAULT_MINDMINER_FEE_BPS,
          DEFAULT_LIQUIDITY_FEE_BPS
        )
      ).to.be.revertedWithCustomError(royaltyCoin, "InvalidAmount");
    });

    it("reverts zero recipient", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(
          ZERO_ADDRESS,
          ONE_RC,
          DEFAULT_MINDMINER_FEE_BPS,
          DEFAULT_LIQUIDITY_FEE_BPS
        )
      ).to.be.revertedWithCustomError(royaltyCoin, "InvalidRecipientAddress");
    });

    it("reverts for non-reward-operator", async function () {
      const { royaltyCoinRead, user, user2 } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoinRead
          .connect(user)
          .distributeRoyaltyCoinReward(
            user2.address,
            ONE_RC,
            DEFAULT_MINDMINER_FEE_BPS,
            DEFAULT_LIQUIDITY_FEE_BPS
          )
      ).to.be.revertedWithCustomError(royaltyCoinRead, "UnauthorizedRewardOperator");
    });

    it("scales distribution as rewards pool depletes", async function () {
      const { royaltyCoin, user, user2 } = await loadFixture(deployRoyaltyCoinFixture);
      const large = ethers.parseEther("1000000");

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        large,
        DEFAULT_MINDMINER_FEE_BPS,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const rewardsRemaining = await royaltyCoin.remainingSupply();
      const scaled = (large * rewardsRemaining) / REWARDS_SUPPLY;

      await royaltyCoin.distributeRoyaltyCoinReward(
        user2.address,
        large,
        DEFAULT_MINDMINER_FEE_BPS,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      expect(await royaltyCoin.balanceOf(user2.address)).to.equal(scaled);
    });
  });

  describe("distributeUsdtReward", function () {
    it("transfers USDT from rewardOperator treasury to RC holder", async function () {
      const { royaltyCoin, usdt, admin, user } = await loadFixture(deployRoyaltyCoinFixture);
      const reward = ethers.parseUnits("100", 6);

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("10"),
        0,
        0
      );

      await usdt.connect(admin).approve(await royaltyCoin.getAddress(), reward);

      await expect(royaltyCoin.distributeUsdtReward(user.address, reward, await usdt.getAddress()))
        .to.emit(royaltyCoin, "UsdtRewardDistributed")
        .withArgs(user.address, reward);

      expect(await usdt.balanceOf(user.address)).to.equal(reward);
      expect(await usdt.balanceOf(MINDMINER_WALLET)).to.equal(
        ethers.parseUnits("1000000", 6) - reward
      );
    });

    it("reverts when recipient holds no RC", async function () {
      const { royaltyCoin, usdt, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoin.distributeUsdtReward(user.address, 1, await usdt.getAddress())
      ).to.be.revertedWithCustomError(royaltyCoin, "UserHasNoRoyaltyCoins");
    });

    it("reverts invalid reward token and zero params", async function () {
      const { royaltyCoin, usdt, user } = await loadFixture(deployRoyaltyCoinFixture);
      const usdtAddress = await usdt.getAddress();

      await royaltyCoin.distributeRoyaltyCoinReward(user.address, ONE_RC, 0, 0);

      await expect(
        royaltyCoin.distributeUsdtReward(user.address, 1, ZERO_ADDRESS)
      ).to.be.revertedWithCustomError(royaltyCoin, "InvalidRewardTokenAddress");

      await expect(
        royaltyCoin.distributeUsdtReward(ZERO_ADDRESS, 1, usdtAddress)
      ).to.be.revertedWithCustomError(royaltyCoin, "InvalidRecipientAddress");

      await expect(
        royaltyCoin.distributeUsdtReward(user.address, 0, usdtAddress)
      ).to.be.revertedWithCustomError(royaltyCoin, "InvalidAmount");
    });
  });

  describe("setTradeFeeBps", function () {
    it("defaults to 5% on initialize", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);
      expect(await royaltyCoin.tradeFeeBps()).to.equal(500n);
      expect(await royaltyCoin.DEFAULT_TRADE_FEE_BPS()).to.equal(500n);
      expect(await royaltyCoin.MAX_TRADE_FEE_BPS()).to.equal(500n);
    });

    it("allows owner to update trade fee and emits event", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(royaltyCoin.setTradeFeeBps(400n))
        .to.emit(royaltyCoin, "TradeFeeBpsUpdated")
        .withArgs(400n);

      expect(await royaltyCoin.tradeFeeBps()).to.equal(400n);
    });

    it("allows owner to disable trade tax with zero bps", async function () {
      const { royaltyCoin, pair, taxedSeller } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("100");

      await royaltyCoin.setTradeFeeBps(0n);
      await fundRcUser(royaltyCoin, taxedSeller, amount);

      await royaltyCoin.connect(taxedSeller).transfer(pair, amount);
      expect(await royaltyCoin.balanceOf(pair)).to.equal(amount);
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(0n);
    });

    it("applies updated trade fee on pair transfers", async function () {
      const { royaltyCoin, pair, taxedSeller } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("1000");
      const updatedBps = 300n;
      const fee = (amount * updatedBps) / BPS;

      await royaltyCoin.setTradeFeeBps(updatedBps);
      await fundRcUser(royaltyCoin, taxedSeller, amount);

      await expect(royaltyCoin.connect(taxedSeller).transfer(pair, amount))
        .to.emit(royaltyCoin, "LiquidityFeesAccumulated")
        .withArgs(fee, "trade");

      expect(await royaltyCoin.balanceOf(pair)).to.equal(amount - fee);
    });

    it("allows owner to set maximum 5% trade fee", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);

      await royaltyCoin.setTradeFeeBps(500n);
      expect(await royaltyCoin.tradeFeeBps()).to.equal(500n);
    });

    it("reverts when bps exceeds max", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(royaltyCoin.setTradeFeeBps(501n)).to.be.revertedWithCustomError(
        royaltyCoin,
        "InvalidTradeFeeBps"
      );
    });

    it("reverts for non-owner", async function () {
      const { royaltyCoinRead, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoinRead.connect(user).setTradeFeeBps(600n)
      ).to.be.revertedWithCustomError(royaltyCoinRead, "OwnableUnauthorizedAccount");
    });
  });

  describe("Trade tax (5%)", function () {
    async function fundUser(royaltyCoin, user, amount) {
      await royaltyCoin.distributeRoyaltyCoinReward(user.address, amount, 0, 0);
    }

    it("charges 5% on transfer to pair (sell)", async function () {
      const { royaltyCoin, pair, taxedSeller } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("1000");
      const fee = (amount * TRADE_FEE_BPS) / BPS;

      await fundUser(royaltyCoin, taxedSeller, amount);

      await expect(royaltyCoin.connect(taxedSeller).transfer(pair, amount))
        .to.emit(royaltyCoin, "LiquidityFeesAccumulated")
        .withArgs(fee, "trade");

      expect(await royaltyCoin.balanceOf(pair)).to.equal(amount - fee);
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(fee);
    });

    it("charges 5% on transfer from pair (buy)", async function () {
      const { royaltyCoin, owner, pair, taxedBuyer } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("500");
      const fee = (amount * TRADE_FEE_BPS) / BPS;

      await fundUser(royaltyCoin, owner, amount);
      await royaltyCoin.connect(owner).transfer(pair, amount);

      await ethers.provider.send("hardhat_setBalance", [pair, "0x1000000000000000000"]);
      const pairSigner = await ethers.getImpersonatedSigner(pair);

      await expect(royaltyCoin.connect(pairSigner).transfer(taxedBuyer.address, amount))
        .to.emit(royaltyCoin, "LiquidityFeesAccumulated")
        .withArgs(fee, "trade");

      expect(await royaltyCoin.balanceOf(taxedBuyer.address)).to.equal(amount - fee);
    });

    it("does not tax exempt wallet transfers", async function () {
      const { royaltyCoin, user, user2 } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("100");

      await fundUser(royaltyCoin, user, amount);
      await royaltyCoin.connect(user).transfer(user2.address, amount);
      expect(await royaltyCoin.balanceOf(user2.address)).to.equal(amount);
    });
  });

  describe("accumulatedLiquidityBalance & setLiquidityAddThreshold", function () {
    it("returns zero when only reward reserve is in contract", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(0n);
    });

    it("tracks LP fees separately from unreleased rewards", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("1000");

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        amount,
        DEFAULT_MINDMINER_FEE_BPS,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const liquidity = (amount * DEFAULT_LIQUIDITY_FEE_BPS) / BPS;
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(liquidity);
    });

    it("enforces liquidity add threshold", async function () {
      const { royaltyCoin, usdt, user } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("1000");

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        amount,
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const accumulated = await royaltyCoin.accumulatedLiquidityBalance();
      await royaltyCoin.setLiquidityAddThreshold(accumulated + 1n);

      await expect(
        royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress())
      ).to.be.revertedWithCustomError(royaltyCoin, "BelowLiquidityThreshold");
    });
  });

  describe("addAccumulatedLiquidityToPool", function () {
    it("swaps and adds liquidity when accumulated balance exists", async function () {
      const { royaltyCoin, usdt, user, pair } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("10000");

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        amount,
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const accumulated = await royaltyCoin.accumulatedLiquidityBalance();
      expect(accumulated > 0n).to.equal(true);

      await expect(royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress())).to.emit(
        royaltyCoin,
        "LiquidityAddedToPool"
      );

      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(0n);
    });

    it("reverts when accumulated balance is zero", async function () {
      const { royaltyCoin, usdt } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress())
      ).to.be.revertedWithCustomError(royaltyCoin, "InvalidAmount");
    });

    it("reverts when quote token pair does not exist", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("100"),
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const fakeQuote = ethers.Wallet.createRandom().address;
      await expect(
        royaltyCoin.addAccumulatedLiquidityToPool(fakeQuote)
      ).to.be.revertedWithCustomError(royaltyCoin, "PairDoesNotExist");
    });

    it("reverts when quote token pair exists but is not registered", async function () {
      const { royaltyCoin, user, factory, rcAddress } = await loadFixture(deployRoyaltyCoinFixture);
      const DummyWETH = await ethers.getContractFactory("DummyWETH");
      const weth = await DummyWETH.deploy();
      const wethAddress = await weth.getAddress();

      await factory.createPair(rcAddress, wethAddress);
      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("100"),
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      await expect(
        royaltyCoin.addAccumulatedLiquidityToPool(wethAddress)
      ).to.be.revertedWithCustomError(royaltyCoin, "QuoteTokenNotRegistered");
    });

    it("does not apply trade tax during internal swap (_inSwap guard)", async function () {
      const { royaltyCoin, usdt, user, pair } = await loadFixture(deployRoyaltyCoinFixture);
      const amount = ethers.parseEther("10000");

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        amount,
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const accumulated = await royaltyCoin.accumulatedLiquidityBalance();
      const half = accumulated / 2n;
      const otherHalf = accumulated - half;

      const tx = await royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress());
      const receipt = await tx.wait();

      const tradeFeeEvents = receipt.logs
        .map((log) => {
          try {
            return royaltyCoin.interface.parseLog(log);
          } catch {
            return null;
          }
        })
        .filter((parsed) => parsed?.name === "LiquidityFeesAccumulated" && parsed.args[1] === "trade");

      expect(tradeFeeEvents.length).to.equal(0);

      const lpEvent = receipt.logs
        .map((log) => {
          try {
            return royaltyCoin.interface.parseLog(log);
          } catch {
            return null;
          }
        })
        .find((parsed) => parsed?.name === "LiquidityAddedToPool");

      expect(lpEvent).to.not.equal(undefined);
      expect(lpEvent.args.royaltyCoinAmount).to.equal(otherHalf);
      expect(half + otherHalf).to.equal(accumulated);
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(0n);
    });

    it("sends LP tokens to LIQUIDITY_TREASURY_WALLET via router", async function () {
      const { royaltyCoin, usdt, router, user } = await loadFixture(deployRoyaltyCoinFixture);

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("10000"),
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      await royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress());

      expect(await router.lastLiquidityRecipient()).to.equal(LIQUIDITY_TREASURY_WALLET);
      expect(await royaltyCoin.LIQUIDITY_TREASURY_WALLET()).to.equal(LIQUIDITY_TREASURY_WALLET);
    });
  });

  describe("RoyaltyCoinQuoteReceiver", function () {
    it("reverts when non-RoyaltyCoin calls forward", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);
      const receiverAddress = await royaltyCoin.liquidityQuoteReceiver();
      const receiver = await ethers.getContractAt("RoyaltyCoinQuoteReceiver", receiverAddress);

      await expect(
        receiver.connect(user).forwardQuoteToken(await royaltyCoin.getAddress())
      ).to.be.revertedWithCustomError(receiver, "Unauthorized");
    });
  });

  describe("Access control", function () {
    it("only owner can set liquidity threshold", async function () {
      const { royaltyCoin, royaltyCoinRead, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoinRead.connect(user).setLiquidityAddThreshold(1)
      ).to.be.revertedWithCustomError(royaltyCoinRead, "OwnableUnauthorizedAccount");

      await expect(royaltyCoin.setLiquidityAddThreshold(ethers.parseEther("1")))
        .to.emit(royaltyCoin, "LiquidityAddThresholdUpdated")
        .withArgs(ethers.parseEther("1"));
    });

    it("only owner can call addAccumulatedLiquidityToPool", async function () {
      const { royaltyCoin, royaltyCoinRead, usdt, user } = await loadFixture(
        deployRoyaltyCoinFixture
      );

      await fundRcUser(royaltyCoin, user, ethers.parseEther("1000"), 0n, DEFAULT_LIQUIDITY_FEE_BPS);

      await expect(
        royaltyCoinRead.connect(user).addAccumulatedLiquidityToPool(await usdt.getAddress())
      ).to.be.revertedWithCustomError(royaltyCoinRead, "OwnableUnauthorizedAccount");
    });
  });

  describe("Multi-pair trade tax (USDT / WETH / WBTC)", function () {
    it("charges 5% sell tax on each registered pair", async function () {
      const { royaltyCoin, pair, wethPair, wbtcPair, taxedSeller } = await loadFixture(
        deployMultiPairRoyaltyCoinFixture
      );
      const amount = ethers.parseEther("1000");
      const fee = (amount * TRADE_FEE_BPS) / BPS;

      await fundRcUser(royaltyCoin, taxedSeller, amount * 3n);

      for (const pairAddress of [pair, wethPair, wbtcPair]) {
        const before = await royaltyCoin.accumulatedLiquidityBalance();
        await expect(royaltyCoin.connect(taxedSeller).transfer(pairAddress, amount))
          .to.emit(royaltyCoin, "LiquidityFeesAccumulated")
          .withArgs(fee, "trade");
        expect(await royaltyCoin.balanceOf(pairAddress)).to.equal(amount - fee);
        expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(before + fee);
      }
    });

    it("charges 5% buy tax when transferring from each registered pair", async function () {
      const { royaltyCoin, owner, pair, wethPair, wbtcPair, taxedBuyer } = await loadFixture(
        deployMultiPairRoyaltyCoinFixture
      );
      const amount = ethers.parseEther("200");
      const fee = (amount * TRADE_FEE_BPS) / BPS;

      await fundRcUser(royaltyCoin, owner, amount * 3n);

      for (const pairAddress of [pair, wethPair, wbtcPair]) {
        await royaltyCoin.connect(owner).transfer(pairAddress, amount);

        const pairSigner = await impersonatePair(pairAddress);
        await expect(royaltyCoin.connect(pairSigner).transfer(taxedBuyer.address, amount))
          .to.emit(royaltyCoin, "LiquidityFeesAccumulated")
          .withArgs(fee, "trade");
      }
    });

    it("does not tax transfers involving an unregistered pair", async function () {
      const { royaltyCoin, factory, rcAddress, taxedSeller, user2 } = await loadFixture(
        deployMultiPairRoyaltyCoinFixture
      );
      const DummyWETH = await ethers.getContractFactory("DummyWETH");
      const weth = await DummyWETH.deploy();
      const wethAddress = await weth.getAddress();

      await factory.createPair(rcAddress, wethAddress);
      const unregisteredPair = await factory.getPair(rcAddress, wethAddress);

      const amount = ethers.parseEther("100");
      await fundRcUser(royaltyCoin, taxedSeller, amount);

      await royaltyCoin.connect(taxedSeller).transfer(unregisteredPair, amount);
      expect(await royaltyCoin.balanceOf(unregisteredPair)).to.equal(amount);
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(0n);
    });

    it("stops taxing a pair after removeQuoteToken", async function () {
      const { royaltyCoin, weth, wethPair, taxedSeller } = await loadFixture(
        deployMultiPairRoyaltyCoinFixture
      );
      const wethAddress = await weth.getAddress();
      const amount = ethers.parseEther("500");

      await royaltyCoin.removeQuoteToken(wethAddress);
      await fundRcUser(royaltyCoin, taxedSeller, amount);

      await royaltyCoin.connect(taxedSeller).transfer(wethPair, amount);
      expect(await royaltyCoin.balanceOf(wethPair)).to.equal(amount);
    });
  });

  describe("Multi-pair liquidity addition", function () {
    it("adds accumulated liquidity to USDT pool and clears balance", async function () {
      const { royaltyCoin, usdt, user, pair } = await loadFixture(deployMultiPairRoyaltyCoinFixture);
      const amount = ethers.parseEther("10000");

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        amount,
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const accumulated = await royaltyCoin.accumulatedLiquidityBalance();
      expect(accumulated > 0n).to.equal(true);

      await expect(royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress()))
        .to.emit(royaltyCoin, "LiquidityAddedToPool");

      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(0n);
    });

    it("adds accumulated liquidity to WETH pool separately", async function () {
      const { royaltyCoin, weth, user, wethPair } = await loadFixture(deployMultiPairRoyaltyCoinFixture);

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("10000"),
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      await expect(royaltyCoin.addAccumulatedLiquidityToPool(await weth.getAddress())).to.emit(
        royaltyCoin,
        "LiquidityAddedToPool"
      );

      const eventFilter = royaltyCoin.filters.LiquidityAddedToPool(wethPair);
      const events = await royaltyCoin.queryFilter(eventFilter);
      expect(events.length).to.equal(1);
    });

    it("adds accumulated liquidity to WBTC pool separately", async function () {
      const { royaltyCoin, wbtc, user } = await loadFixture(deployMultiPairRoyaltyCoinFixture);

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("10000"),
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      await expect(royaltyCoin.addAccumulatedLiquidityToPool(await wbtc.getAddress())).to.emit(
        royaltyCoin,
        "LiquidityAddedToPool"
      );
    });

    it("combines trade tax and reward LP fees before adding liquidity", async function () {
      const { royaltyCoin, usdt, pair, taxedSeller, user } = await loadFixture(
        deployMultiPairRoyaltyCoinFixture
      );
      const tradeAmount = ethers.parseEther("2000");

      await fundRcUser(royaltyCoin, taxedSeller, tradeAmount);
      await royaltyCoin.connect(taxedSeller).transfer(pair, tradeAmount);

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("5000"),
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const accumulated = await royaltyCoin.accumulatedLiquidityBalance();
      expect(accumulated > 0n).to.equal(true);

      await expect(royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress())).to.emit(
        royaltyCoin,
        "LiquidityAddedToPool"
      );
      expect(await royaltyCoin.accumulatedLiquidityBalance()).to.equal(0n);
    });
  });

  describe("setLiquidityAddThreshold edge cases", function () {
    it("allows liquidity add when threshold is zero (default)", async function () {
      const { royaltyCoin, usdt, user } = await loadFixture(deployRoyaltyCoinFixture);

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("100"),
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      expect(await royaltyCoin.liquidityAddThreshold()).to.equal(0n);
      await expect(royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress())).to.not.be
        .reverted;
    });

    it("allows liquidity add when accumulated equals threshold exactly", async function () {
      const { royaltyCoin, usdt, user } = await loadFixture(deployRoyaltyCoinFixture);

      await royaltyCoin.distributeRoyaltyCoinReward(
        user.address,
        ethers.parseEther("1000"),
        0,
        DEFAULT_LIQUIDITY_FEE_BPS
      );

      const accumulated = await royaltyCoin.accumulatedLiquidityBalance();
      await royaltyCoin.setLiquidityAddThreshold(accumulated);

      await expect(royaltyCoin.addAccumulatedLiquidityToPool(await usdt.getAddress())).to.emit(
        royaltyCoin,
        "LiquidityAddedToPool"
      );
    });

    it("clears threshold back to zero", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);
      const threshold = ethers.parseEther("100");

      await royaltyCoin.setLiquidityAddThreshold(threshold);
      expect(await royaltyCoin.liquidityAddThreshold()).to.equal(threshold);

      await royaltyCoin.setLiquidityAddThreshold(0);
      expect(await royaltyCoin.liquidityAddThreshold()).to.equal(0n);
    });
  });

  describe("distributeRoyaltyCoinReward edge cases", function () {
    it("reverts AdjustedAmountTooLow when scaled reward rounds to zero", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);

      let reverted = false;
      for (let i = 0; i < 900; i++) {
        try {
          await royaltyCoin.distributeRoyaltyCoinReward(
            user.address,
            MAX_SINGLE_DISTRIBUTION,
            0,
            0
          );
        } catch (error) {
          expect(error.message).to.include("AdjustedAmountTooLow");
          reverted = true;
          break;
        }
      }
      expect(reverted).to.equal(true);
    });

    it("reverts MindminerPortionTooLow when bps > 0 but fee rounds to zero", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(user.address, 1n, 1n, 0)
      ).to.be.revertedWithCustomError(royaltyCoin, "MindminerPortionTooLow");
    });

    it("reverts LiquidityPortionTooLow when liquidity bps > 0 but fee rounds to zero", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(user.address, 1n, 0, 1n)
      ).to.be.revertedWithCustomError(royaltyCoin, "LiquidityPortionTooLow");
    });
  });

  describe("rewardOperator / Safe admin split", function () {
    it("allows owner to update rewardOperator", async function () {
      const { royaltyCoin, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(royaltyCoin.setRewardOperator(user.address))
        .to.emit(royaltyCoin, "RewardOperatorUpdated")
        .withArgs(user.address);

      expect(await royaltyCoin.rewardOperator()).to.equal(user.address);
    });

    it("reverts setRewardOperator with zero address", async function () {
      const { royaltyCoin } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(royaltyCoin.setRewardOperator(ZERO_ADDRESS)).to.be.revertedWithCustomError(
        royaltyCoin,
        "InvalidOperatorAddress"
      );
    });

    it("reverts setRewardOperator for non-owner", async function () {
      const { royaltyCoinRead, user, user2 } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoinRead.connect(user).setRewardOperator(user2.address)
      ).to.be.revertedWithCustomError(royaltyCoinRead, "OwnableUnauthorizedAccount");
    });

    it("allows operator but not Safe owner to distribute after ownership transfer", async function () {
      const { royaltyCoin, royaltyCoinRead, user, user2 } = await loadFixture(
        deployRoyaltyCoinFixture
      );

      await royaltyCoin.setRewardOperator(MINDMINER_WALLET);
      await royaltyCoin.transferOwnership(user2.address);

      expect(await royaltyCoinRead.owner()).to.equal(user2.address);

      await expect(
        royaltyCoinRead
          .connect(user2)
          .distributeRoyaltyCoinReward(user.address, ONE_RC, 0, 0)
      ).to.be.revertedWithCustomError(royaltyCoinRead, "UnauthorizedRewardOperator");

      await expect(
        royaltyCoin.distributeRoyaltyCoinReward(user.address, ONE_RC, 0, 0)
      ).to.emit(royaltyCoin, "RoyaltyCoinRewardDistributed");

      expect(await royaltyCoin.balanceOf(user.address)).to.equal(ONE_RC);
    });

    it("allows Safe owner to call admin functions but not distribute", async function () {
      const { royaltyCoin, royaltyCoinRead, user, user2 } = await loadFixture(
        deployRoyaltyCoinFixture
      );

      await royaltyCoin.setRewardOperator(MINDMINER_WALLET);
      await royaltyCoin.transferOwnership(user2.address);

      await expect(royaltyCoinRead.connect(user2).setTradeFeeBps(400n))
        .to.emit(royaltyCoin, "TradeFeeBpsUpdated")
        .withArgs(400n);

      await expect(
        royaltyCoinRead
          .connect(user2)
          .distributeRoyaltyCoinReward(user.address, ONE_RC, 0, 0)
      ).to.be.revertedWithCustomError(royaltyCoinRead, "UnauthorizedRewardOperator");

      expect(await royaltyCoinRead.tradeFeeBps()).to.equal(400n);
      expect(await royaltyCoinRead.owner()).to.equal(user2.address);
      expect(await royaltyCoinRead.rewardOperator()).to.equal(MINDMINER_WALLET);
    });

    it("pulls USDT from rewardOperator after ownership transfer to Safe", async function () {
      const { royaltyCoin, royaltyCoinRead, usdt, admin, user, user2 } = await loadFixture(
        deployRoyaltyCoinFixture
      );
      const reward = ethers.parseUnits("50", 6);

      await royaltyCoin.setRewardOperator(MINDMINER_WALLET);
      await royaltyCoin.transferOwnership(user2.address);
      await fundRcUser(royaltyCoin, user, ONE_RC);

      await usdt.connect(admin).approve(await royaltyCoin.getAddress(), reward);

      await expect(royaltyCoin.distributeUsdtReward(user.address, reward, await usdt.getAddress()))
        .to.emit(royaltyCoin, "UsdtRewardDistributed")
        .withArgs(user.address, reward);

      expect(await usdt.balanceOf(user.address)).to.equal(reward);
      expect(await royaltyCoinRead.owner()).to.equal(user2.address);
    });
  });

  describe("distributeUsdtReward edge cases", function () {
    it("reverts for non-reward-operator", async function () {
      const { royaltyCoinRead, usdt, user } = await loadFixture(deployRoyaltyCoinFixture);

      await expect(
        royaltyCoinRead
          .connect(user)
          .distributeUsdtReward(user.address, 1, await usdt.getAddress())
      ).to.be.revertedWithCustomError(royaltyCoinRead, "UnauthorizedRewardOperator");
    });

    it("reverts when rewardOperator has insufficient USDT balance", async function () {
      const { royaltyCoin, usdt, admin, user } = await loadFixture(deployRoyaltyCoinFixture);
      const reward = ethers.parseUnits("100", 6);

      await fundRcUser(royaltyCoin, user, ONE_RC);

      const adminBalance = await usdt.balanceOf(admin.address);
      await usdt.connect(admin).transfer(user.address, adminBalance);

      await expect(
        royaltyCoin.distributeUsdtReward(user.address, reward, await usdt.getAddress())
      ).to.be.reverted;
    });

    it("reverts when rewardOperator has not approved USDT allowance", async function () {
      const { royaltyCoin, usdt, user } = await loadFixture(deployRoyaltyCoinFixture);
      const reward = ethers.parseUnits("10", 6);

      await fundRcUser(royaltyCoin, user, ONE_RC);

      await expect(
        royaltyCoin.distributeUsdtReward(user.address, reward, await usdt.getAddress())
      ).to.be.reverted;
    });
  });
});
