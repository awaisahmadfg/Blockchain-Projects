require("dotenv").config();
const { runUupsDeployment } = require("./helpers/uupsDeploy");
const { getNetworkConfig } = require("./helpers/networkConfig");
const { ethers } = require("hardhat");

/**
 * Deploy + verify PatentMarketplace (UUPS) — PatentToken + Marketplace merged.
 *
 * Usage:
 *   npx hardhat run deployments/deploy_PatentMarketplace_UUPS.js --network sepolia
 *   npx hardhat run deployments/deploy_PatentMarketplace_UUPS.js --network mainnet
 *
 * Mainnet USDT is set automatically in initialize():
 *   0xdAC17F958D2ee523a2206206994597C13D831ec7
 * Sepolia: set SEPOLIA_USDT_ADDRESS (DummyUSDT) in .env first.
 */
async function main() {
  const network = await ethers.provider.getNetwork();
  const netConfig = getNetworkConfig(network.chainId);

  if (!netConfig.usdtAddress) {
    throw new Error(
      "USDT address required for initialize().\n" +
        "  mainnet: uses 0xdAC17F958D2ee523a2206206994597C13D831ec7 by default\n" +
        "  sepolia: set SEPOLIA_USDT_ADDRESS in .env (deploy DummyUSDT first)"
    );
  }

  await runUupsDeployment({
    contractName: "PatentMarketplace",
    initArgs: [netConfig.usdtAddress],
    postDeployLog(record) {
      console.log(`\n--- PatentMarketplace post-deploy notes ---`);
      console.log(`USDT token (initialize): ${netConfig.usdtAddress}`);
      console.log("This proxy is both the PatentToken (ERC721) contract and the marketplace.");
      console.log("Use proxy address for:");
      console.log("  - mintPatentToken()              (owner only)");
      console.log("  - listPatentTokenForFixedPrice() / buyFixedPricePatentToken()");
      console.log("  - auction functions");

      record.nextSteps = {
        mintPatentToken: "Call mintPatentToken(recipient, tokenURI) as contract owner",
        frontend: "Use proxyAddress as both PatentToken and marketplace contract",
      };
    },
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
