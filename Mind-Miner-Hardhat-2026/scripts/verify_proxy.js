require('dotenv').config();
const { ethers, upgrades } = require("hardhat");

/**
 * Script to verify UUPS proxy contracts
 * Usage: npx hardhat run scripts/verify_proxy.js --network <network>
 * 
 * Set PROXY_ADDRESS in .env or pass as argument
 */
async function main() {
  const proxyAddress = process.env.PROXY_ADDRESS || process.argv[2];
  
  if (!proxyAddress) {
    throw new Error("Please provide PROXY_ADDRESS in .env or as first argument");
  }

  console.log("Verifying proxy at:", proxyAddress);
  
  const network = await ethers.provider.getNetwork();
  console.log("Network:", network.name, "Chain ID:", network.chainId);

  try {
    // Get implementation address
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("Implementation Address:", implementationAddress);
    
    // Get admin address (if any)
    try {
      const adminAddress = await upgrades.erc1967.getAdminAddress(proxyAddress);
      console.log("Admin Address:", adminAddress);
    } catch (e) {
      console.log("Admin Address: Not available (UUPS proxy)");
    }

    console.log("\n✅ Proxy verification successful!");
    console.log("\nTo verify on Etherscan:");
    console.log(`npx hardhat verify --network ${network.name} ${proxyAddress}`);
    console.log(`npx hardhat verify --network ${network.name} ${implementationAddress}`);
    
  } catch (error) {
    console.error("Error verifying proxy:", error.message);
    throw error;
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });























