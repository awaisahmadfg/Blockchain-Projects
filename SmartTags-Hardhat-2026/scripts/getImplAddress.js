const { ethers } = require("hardhat");

async function main() {
  const proxyAddress = "0x4dbdAF42e0e96Ed6Dc72462E69B5BE450bb11a85";
  const implementationSlot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";
  const implementationAddress = await ethers.provider.getStorageAt(proxyAddress, implementationSlot);
  const implAddress = "0x" + implementationAddress.slice(-40);
  console.log("Implementation Address:", implAddress);
}

main().then(() => process.exit(0)).catch(console.error);





