const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");
const { getNetworkConfig, explorerLink } = require("./networkConfig");
const { verifyContractAddress } = require("./verifyContract");

const OUTPUT_DIR = path.join(__dirname, "..", "..", "deployments-output");

function formatEth(wei) {
  return ethers.formatEther(wei);
}

async function getDeployerInfo() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const balance = await ethers.provider.getBalance(deployer.address);
  const netConfig = getNetworkConfig(network.chainId);

  return { deployer, network, balance, netConfig };
}

async function deployUupsProxy(contractName, initArgs = [], options = {}) {
  const confirmations = options.confirmations ?? 5;

  console.log(`\n${"=".repeat(60)}`);
  console.log(`Deploying ${contractName} (UUPS)`);
  console.log("=".repeat(60));

  const Factory = await ethers.getContractFactory(contractName);
  const proxy = await upgrades.deployProxy(Factory, initArgs, {
    initializer: "initialize",
    kind: "uups",
  });

  await proxy.waitForDeployment();

  const proxyAddress = await proxy.getAddress();
  const implementationAddress =
    await upgrades.erc1967.getImplementationAddress(proxyAddress);

  const deploymentTx = proxy.deploymentTransaction();
  let txHash = null;
  if (deploymentTx) {
    txHash = deploymentTx.hash;
    console.log(`Deployment tx: ${txHash}`);
    console.log(`Waiting for ${confirmations} confirmations...`);
    await deploymentTx.wait(confirmations);
  }

  console.log(`Proxy:           ${proxyAddress}`);
  console.log(`Implementation:  ${implementationAddress}`);

  return { proxy, proxyAddress, implementationAddress, txHash };
}

async function verifyUupsProxy(proxyAddress, contractLabel) {
  // hardhat-upgrades intercepts verify:verify on proxy addresses and
  // verifies both the proxy and implementation automatically.
  return verifyContractAddress(proxyAddress, `${contractLabel} (proxy + implementation)`);
}

function saveDeploymentRecord(contractName, record) {
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  const fileName = `${record.networkName}-${contractName}-${Date.now()}.json`;
  const filePath = path.join(OUTPUT_DIR, fileName);
  fs.writeFileSync(filePath, JSON.stringify(record, null, 2));
  return filePath;
}

function printFinalSummary(record) {
  const { contractName, netConfig } = record;

  console.log(`\n${"=".repeat(60)}`);
  console.log(`${contractName} — DEPLOYMENT COMPLETE`);
  console.log("=".repeat(60));

  console.log(`Network:          ${record.networkName} (chainId ${record.chainId})`);
  console.log(`Deployer:         ${record.deployer}`);
  console.log(`Deployer balance: ${record.deployerBalanceEth} ETH`);
  console.log(`Proxy (USE THIS): ${record.proxyAddress}`);
  console.log(`Implementation:   ${record.implementationAddress}`);
  if (record.deploymentTxHash) {
    console.log(`Deploy tx:        ${record.deploymentTxHash}`);
  }
  console.log(`Verified:         ${record.verification.verified ? "Yes" : "No"}`);

  if (record.proxyExplorerUrl) {
    console.log(`Proxy Etherscan:  ${record.proxyExplorerUrl}`);
  }
  if (record.implementationExplorerUrl) {
    console.log(`Impl Etherscan:   ${record.implementationExplorerUrl}`);
  }
  if (record.savedTo) {
    console.log(`Saved to:         ${record.savedTo}`);
  }

  console.log(`\n--- Full record (JSON) ---`);
  console.log(JSON.stringify(record, null, 2));
}

async function runUupsDeployment({
  contractName,
  initArgs = [],
  extraRecord = {},
  postDeployLog,
}) {
  const { deployer, network, balance, netConfig } = await getDeployerInfo();

  console.log(`\n${"#".repeat(60)}`);
  console.log(`${contractName} — UUPS Deploy + Verify`);
  console.log(`${"#".repeat(60)}`);
  console.log(`Network:  ${network.name} (chainId ${network.chainId})`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Balance:  ${formatEth(balance)} ETH`);
  console.log(`Testnet:  ${netConfig.isTestnet ? "yes" : "no (mainnet)"}`);

  if (!process.env.ETHERSCAN_API_KEY && !process.env.MAINNET_ETHERSCAN_API_KEY) {
    console.warn(
      "\n⚠️  ETHERSCAN_API_KEY not set — deploy will succeed but verify will fail."
    );
  }

  const { proxyAddress, implementationAddress, txHash } =
    await deployUupsProxy(contractName, initArgs);

  const verification = await verifyUupsProxy(proxyAddress, contractName);

  const record = {
    contractName,
    networkName: netConfig.networkName,
    chainId: network.chainId.toString(),
    deployer: deployer.address,
    deployerBalanceEth: formatEth(balance),
    proxyAddress,
    implementationAddress,
    deploymentTxHash: txHash,
    verification,
    timestamp: new Date().toISOString(),
    netConfig: {
      usdtAddress: netConfig.usdtAddress,
      uniswapV2Router: netConfig.uniswapV2Router,
      explorer: netConfig.explorer,
    },
    proxyExplorerUrl: explorerLink(netConfig.explorer, proxyAddress),
    implementationExplorerUrl: explorerLink(
      netConfig.explorer,
      implementationAddress
    ),
    ...extraRecord,
  };

  record.savedTo = saveDeploymentRecord(contractName, record);

  if (postDeployLog) {
    postDeployLog(record, netConfig);
  }

  printFinalSummary(record);

  if (!verification.verified) {
    console.log(
      `\nManual verify retry:\n  npx hardhat verify --network ${netConfig.networkName} ${proxyAddress}`
    );
    process.exitCode = 1;
  }

  return record;
}

module.exports = {
  runUupsDeployment,
  deployUupsProxy,
  verifyUupsProxy,
  getDeployerInfo,
  saveDeploymentRecord,
  formatEth,
};
