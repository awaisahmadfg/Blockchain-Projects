require("dotenv").config();
const { ethers, upgrades } = require("hardhat");
const { verifyUupsProxy, getDeployerInfo } = require("./helpers/uupsDeploy");
const { explorerLink } = require("./helpers/networkConfig");

/**
 * Upgrade RoyaltyCoin UUPS proxy and verify on Etherscan (proxy + implementation link).
 *
 * Usage:
 *   ROYALTYCOIN_PROXY_ADDRESS=0x... npx hardhat run deployments/upgrade_RoyaltyCoin_UUPS.js --network sepolia
 *   ROYALTYCOIN_PROXY_ADDRESS=0x... npx hardhat run deployments/upgrade_RoyaltyCoin_UUPS.js --network mainnet
 *
 * Requires ETHERSCAN_API_KEY (or MAINNET_ETHERSCAN_API_KEY) for auto-verify.
 * After upgrade, run configure_RoyaltyCoin_roles.js (setRewardOperator → transferOwnership Safe).
 */
async function main() {
  const PROXY = process.env.ROYALTYCOIN_PROXY_ADDRESS;
  if (!PROXY) throw new Error("Set ROYALTYCOIN_PROXY_ADDRESS in .env");

  const { netConfig } = await getDeployerInfo();

  if (!process.env.ETHERSCAN_API_KEY && !process.env.MAINNET_ETHERSCAN_API_KEY) {
    console.warn(
      "\n⚠️  ETHERSCAN_API_KEY not set — upgrade will succeed but Etherscan verify will fail."
    );
    console.warn("   Set the key in .env or run verify manually after upgrade.\n");
  }

  const RoyaltyCoin = await ethers.getContractFactory("RoyaltyCoin");
  console.log("Upgrading RoyaltyCoin proxy:", PROXY);

  const upgraded = await upgrades.upgradeProxy(PROXY, RoyaltyCoin, { kind: "uups" });
  await upgraded.waitForDeployment();

  const impl = await upgrades.erc1967.getImplementationAddress(PROXY);
  console.log("✅ Upgraded. New implementation:", impl);
  console.log("Proxy unchanged (use same address in app):", PROXY);

  if (netConfig.explorer) {
    console.log("Proxy Etherscan:  ", explorerLink(netConfig.explorer, PROXY));
    console.log("Impl Etherscan:   ", explorerLink(netConfig.explorer, impl));
  }

  const verification = await verifyUupsProxy(PROXY, "RoyaltyCoin");

  if (!verification.verified) {
    console.warn(
      `\n⚠️  Etherscan verify failed — retry manually:\n` +
        `   npx hardhat verify --network ${netConfig.networkName} ${PROXY}\n`
    );
    process.exitCode = 1;
  } else {
    console.log("\n✅ Etherscan verify + proxy↔implementation link complete.");
    console.log("Next: npx hardhat run deployments/configure_RoyaltyCoin_roles.js --network " + netConfig.networkName);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
