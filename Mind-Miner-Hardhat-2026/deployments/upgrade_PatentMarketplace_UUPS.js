require("dotenv").config();
const { ethers, upgrades } = require("hardhat");

async function main() {
  const PROXY = process.env.PATENTMARKETPLACE_PROXY_ADDRESS;
  if (!PROXY) throw new Error("Set PATENTMARKETPLACE_PROXY_ADDRESS in .env");

  const PatentMarketplace = await ethers.getContractFactory("PatentMarketplace");
  console.log("Upgrading PatentMarketplace proxy:", PROXY);

  const upgraded = await upgrades.upgradeProxy(PROXY, PatentMarketplace, { kind: "uups" });
  await upgraded.waitForDeployment();

  const impl = await upgrades.erc1967.getImplementationAddress(PROXY);
  console.log("✅ Upgraded. New implementation:", impl);
  console.log("Proxy unchanged:", PROXY);
}

main().catch(console.error);