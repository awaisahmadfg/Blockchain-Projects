require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");
const { getNetworkConfig, explorerLink } = require("./helpers/networkConfig");
const { verifyContractAddress } = require("./helpers/verifyContract");

/**
 * Deploy DummyWETH for testnets only (Sepolia).
 * 18 decimals — RC/WETH multi-pool testing on Uniswap V2.
 *
 * Usage:
 *   npx hardhat run deployments/deploy_DummyWETH.js --network sepolia
 *
 * After deploy, add to .env:
 *   SEPOLIA_WETH_ADDRESS=<deployed address>
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const netConfig = getNetworkConfig(network.chainId);

  if (!netConfig.isTestnet) {
    throw new Error(
      "DummyWETH is for testnets only. On mainnet use real WETH:\n" +
        "  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    );
  }

  console.log("\n=== Deploying DummyWETH (testnet) ===");
  console.log(`Network:  ${network.name} (chainId ${network.chainId})`);
  console.log(`Deployer: ${deployer.address}`);

  const DummyWETH = await ethers.getContractFactory("DummyWETH");
  const token = await DummyWETH.deploy();
  await token.waitForDeployment();

  const address = await token.getAddress();
  const tx = token.deploymentTransaction();
  if (tx) {
    console.log(`Deploy tx: ${tx.hash}`);
    await tx.wait(5);
  }

  console.log(`DummyWETH: ${address}`);

  const verification = await verifyContractAddress(address, "DummyWETH");

  const record = {
    contractName: "DummyWETH",
    networkName: netConfig.networkName,
    chainId: network.chainId.toString(),
    address,
    deployer: deployer.address,
    verified: verification.verified,
    verification,
    timestamp: new Date().toISOString(),
    explorerUrl: explorerLink(netConfig.explorer, address),
    envHint: `Add to .env: SEPOLIA_WETH_ADDRESS=${address}`,
  };

  const outDir = path.join(__dirname, "..", "deployments-output");
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  const savedTo = path.join(
    outDir,
    `${netConfig.networkName}-DummyWETH-${Date.now()}.json`
  );
  fs.writeFileSync(savedTo, JSON.stringify(record, null, 2));

  console.log("\n=== Done ===");
  console.log(JSON.stringify(record, null, 2));
  console.log(`\n👉 ${record.envHint}`);
  console.log(`Saved to: ${savedTo}`);

  if (!verification.verified) {
    console.log(
      `\nManual retry:\n  npx hardhat verify --network ${netConfig.networkName} ${address}`
    );
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
