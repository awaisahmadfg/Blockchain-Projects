require("dotenv").config();
const { runUupsDeployment, getDeployerInfo } = require("./helpers/uupsDeploy");

/**
 * Deploy + verify RoyaltyCoin (UUPS) on any configured network.
 *
 * Usage:
 *   npx hardhat run deployments/deploy_RoyaltyCoin_UUPS.js --network sepolia
 *   npx hardhat run deployments/deploy_RoyaltyCoin_UUPS.js --network mainnet
 *
 * initialize(router) — router from networkConfig / .env
 */
async function main() {
  const { netConfig } = await getDeployerInfo();

  const router = netConfig.uniswapV2Router;
  if (!router) {
    throw new Error(
      "Uniswap V2 router not configured. Set SEPOLIA_UNISWAP_ROUTER or MAINNET_UNISWAP_ROUTER in .env"
    );
  }

  console.log(`\nInitialize args: router = ${router}`);

  await runUupsDeployment({
    contractName: "RoyaltyCoin",
    initArgs: [router],
    postDeployLog(record, cfg) {
      console.log(`\n--- RoyaltyCoin post-deploy notes ---`);
      console.log(`Uniswap V2 router: ${cfg.uniswapV2Router}`);
      if (cfg.uniswapV2Factory) {
        console.log(`Uniswap V2 factory: ${cfg.uniswapV2Factory}`);
      }

      if (cfg.isTestnet) {
        console.log(
          "\nTestnet: deploy dummy quote tokens if needed:\n" +
            "  npx hardhat run deployments/deploy_USDTToken.js --network sepolia\n" +
            "  npx hardhat run deployments/deploy_DummyWBTC.js --network sepolia\n" +
            "  npx hardhat run deployments/deploy_DummyWETH.js --network sepolia"
        );
        if (!cfg.usdtAddress) {
          console.warn(
            "⚠️  SEPOLIA_USDT_ADDRESS not set — set quote token addresses before addQuoteToken()."
          );
        } else {
          console.log(`Test USDT (.env): ${cfg.usdtAddress}`);
        }
      } else {
        console.log(`Mainnet USDT: ${cfg.usdtAddress}`);
      }

      console.log(
        "\nNext steps (owner wallet):\n" +
          "  1. Create RC/quote-token pools on Uniswap V2\n" +
          "  2. royaltyCoin.addQuoteToken(quoteTokenAddress)\n" +
          "  3. Optional: setLiquidityAddThreshold(minRcAmount)\n" +
          "  4. addAccumulatedLiquidityToPool(quoteTokenAddress) when fees accumulate"
      );

      record.nextSteps = {
        router: cfg.uniswapV2Router,
        addQuoteToken: cfg.usdtAddress || "<set quote token addresses in .env>",
      };
    },
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
