require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");
const { getNetworkConfig, explorerLink } = require("./helpers/networkConfig");
const { verifyContractAddress } = require("./helpers/verifyContract");

/**
 * Deploy DummyUSDT for testnets only (Sepolia).
 * Mainnet uses real USDT — do NOT run this on mainnet.
 *
 * Usage:
 *   npx hardhat run deployments/deploy_USDTToken.js --network sepolia
 *
 * After deploy, add to .env:
 *   SEPOLIA_USDT_ADDRESS=<deployed address>
 */
async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const netConfig = getNetworkConfig(network.chainId);

  if (!netConfig.isTestnet) {
    throw new Error(
      "DummyUSDT is for testnets only. On mainnet use real USDT:\n" +
        "  MAINNET_USDT_ADDRESS=0xdAC17F958D2ee523a2206206994597C13D831ec7"
    );
  }

  console.log("\n=== Deploying DummyUSDT (testnet) ===");
  console.log(`Network:  ${network.name} (chainId ${network.chainId})`);
  console.log(`Deployer: ${deployer.address}`);

  const DummyUSDT = await ethers.getContractFactory("DummyUSDT");
  const usdt = await DummyUSDT.deploy();
  await usdt.waitForDeployment();

  const address = await usdt.getAddress();
  const tx = usdt.deploymentTransaction();
  if (tx) {
    console.log(`Deploy tx: ${tx.hash}`);
    await tx.wait(5);
  }

  console.log(`DummyUSDT: ${address}`);

  const verification = await verifyContractAddress(address, "DummyUSDT");

  const record = {
    contractName: "DummyUSDT",
    networkName: netConfig.networkName,
    chainId: network.chainId.toString(),
    address,
    deployer: deployer.address,
    verified: verification.verified,
    verification,
    timestamp: new Date().toISOString(),
    explorerUrl: explorerLink(netConfig.explorer, address),
    envHint: `Add to .env: SEPOLIA_USDT_ADDRESS=${address}`,
  };

  const outDir = path.join(__dirname, "..", "deployments-output");
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  const savedTo = path.join(
    outDir,
    `${netConfig.networkName}-DummyUSDT-${Date.now()}.json`
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
