const { ethers, upgrades } = require("hardhat");
const { LIQUIDITY_TREASURY_WALLET, MINDMINER_WALLET } = require("./constants");

async function impersonateMindminer() {
  await ethers.provider.send("hardhat_setBalance", [
    MINDMINER_WALLET,
    ethers.toBeHex(ethers.parseEther("1000")),
  ]);
  return ethers.getImpersonatedSigner(MINDMINER_WALLET);
}

async function impersonatePair(pairAddress) {
  await ethers.provider.send("hardhat_setBalance", [
    pairAddress,
    ethers.toBeHex(ethers.parseEther("1")),
  ]);
  return ethers.getImpersonatedSigner(pairAddress);
}

async function fundRcUser(royaltyCoin, user, amount, mindminerBps = 0n, liquidityBps = 0n) {
  await royaltyCoin.distributeRoyaltyCoinReward(user.address, amount, mindminerBps, liquidityBps);
}

async function mintQuoteToRouter(quoteToken, router, amount) {
  await quoteToken.mint(await router.getAddress(), amount);
}

async function registerQuotePair(factory, royaltyCoinAdmin, rcAddress, quoteToken, router) {
  const quoteAddress = await quoteToken.getAddress();
  await factory.createPair(rcAddress, quoteAddress);
  const pairAddress = await factory.getPair(rcAddress, quoteAddress);
  await royaltyCoinAdmin.addQuoteToken(quoteAddress);
  return { quoteAddress, pairAddress };
}

async function deployRoyaltyCoinFixture() {
  const signers = await ethers.getSigners();
  const [deployer, user, user2, taxedBuyer, taxedSeller] = signers;
  const admin = await impersonateMindminer();

  const Factory = await ethers.getContractFactory("MockUniswapV2Factory");
  const factory = await Factory.deploy();

  const Router = await ethers.getContractFactory("MockUniswapV2Router");
  const router = await Router.deploy(await factory.getAddress());

  const DummyUSDT = await ethers.getContractFactory("DummyUSDT");
  const usdt = await DummyUSDT.deploy();

  const RoyaltyCoin = await ethers.getContractFactory("RoyaltyCoin");
  const royaltyCoin = await upgrades.deployProxy(
    RoyaltyCoin,
    [await router.getAddress()],
    { kind: "uups" }
  );
  await royaltyCoin.waitForDeployment();

  const royaltyCoinAdmin = royaltyCoin.connect(admin);
  const rcAddress = await royaltyCoin.getAddress();
  const usdtAddress = await usdt.getAddress();

  const { pairAddress: pair } = await registerQuotePair(
    factory,
    royaltyCoinAdmin,
    rcAddress,
    usdt,
    router
  );

  await mintQuoteToRouter(usdt, router, ethers.parseUnits("10000000", 6));
  await usdt.mint(LIQUIDITY_TREASURY_WALLET, ethers.parseUnits("1000000", 6));
  await usdt.mint(MINDMINER_WALLET, ethers.parseUnits("1000000", 6));

  return {
    royaltyCoin: royaltyCoinAdmin,
    royaltyCoinRead: royaltyCoin,
    usdt,
    router,
    factory,
    pair,
    deployer,
    admin,
    owner: admin,
    user,
    user2,
    taxedBuyer,
    taxedSeller,
    rcAddress,
    usdtAddress,
  };
}

async function deployMultiPairRoyaltyCoinFixture() {
  const base = await deployRoyaltyCoinFixture();
  const { royaltyCoin, factory, rcAddress, router } = base;

  const DummyWETH = await ethers.getContractFactory("DummyWETH");
  const weth = await DummyWETH.deploy();
  const DummyWBTC = await ethers.getContractFactory("DummyWBTC");
  const wbtc = await DummyWBTC.deploy();

  const { pairAddress: wethPair } = await registerQuotePair(
    factory,
    royaltyCoin,
    rcAddress,
    weth,
    router
  );
  const { pairAddress: wbtcPair } = await registerQuotePair(
    factory,
    royaltyCoin,
    rcAddress,
    wbtc,
    router
  );

  await mintQuoteToRouter(weth, router, ethers.parseEther("1000000"));
  await mintQuoteToRouter(wbtc, router, ethers.parseUnits("1000000", 8));

  return {
    ...base,
    weth,
    wethPair,
    wbtc,
    wbtcPair,
  };
}

async function deployPatentMarketplaceFixture() {
  const signers = await ethers.getSigners();
  const [deployer, creator, buyer, bidder, other] = signers;
  const admin = await impersonateMindminer();

  const DummyUSDT = await ethers.getContractFactory("DummyUSDT");
  const usdt = await DummyUSDT.deploy();
  await usdt.waitForDeployment();
  const usdtAddress = await usdt.getAddress();

  const PatentMarketplace = await ethers.getContractFactory("PatentMarketplace");
  const marketplace = await upgrades.deployProxy(PatentMarketplace, [usdtAddress], {
    kind: "uups",
  });
  await marketplace.waitForDeployment();

  const marketplaceAdmin = marketplace.connect(admin);

  const oneUsdt = ethers.parseUnits("1000", 6);
  await usdt.mint(creator.address, oneUsdt);
  await usdt.mint(buyer.address, oneUsdt);
  await usdt.mint(bidder.address, oneUsdt);
  await usdt.mint(other.address, oneUsdt);

  return {
    marketplace: marketplaceAdmin,
    marketplaceRead: marketplace,
    usdt,
    usdtAddress,
    oneUsdt,
    deployer,
    admin,
    owner: admin,
    creator,
    buyer,
    bidder,
    other,
    marketplaceAddress: await marketplace.getAddress(),
  };
}

module.exports = {
  deployRoyaltyCoinFixture,
  deployMultiPairRoyaltyCoinFixture,
  deployPatentMarketplaceFixture,
  impersonateMindminer,
  impersonatePair,
  fundRcUser,
  mintQuoteToRouter,
  registerQuotePair,
};
