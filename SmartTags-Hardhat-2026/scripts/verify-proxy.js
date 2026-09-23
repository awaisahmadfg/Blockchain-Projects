/**
 * Verify SmartTags proxy on Polygonscan (Polygon mainnet)
 * Run: npx hardhat run scripts/verify-proxy.js --network polygon
 *
 * ERC1967Proxy constructor: (address _logic, bytes memory _data)
 * _data = encoded initialize() call = 0x8129fc1c
 */
import "dotenv/config";
import hre from "hardhat";

const IMPLEMENTATION_ADDRESS = "0x70Fea43Fe4000DBaac1eA97bF18cc2C92415DFfe";
const PROXY_ADDRESS = "0x3696b294693944380A2d0991Dc1F161A07Cc9D87";
const INITIALIZE_CALLDATA = "0x8129fc1c"; // SmartTags.initialize()

async function main() {
  const args = [IMPLEMENTATION_ADDRESS, INITIALIZE_CALLDATA];

  console.log("Constructor arguments for ERC1967Proxy:");
  console.log("  1. implementation:", args[0]);
  console.log("  2. _data (initialize):", args[1]);

  console.log("\n--- Option 1: Verify proxy source via Hardhat ---");
  console.log(
    'npx hardhat verify --network polygon',
    PROXY_ADDRESS,
    IMPLEMENTATION_ADDRESS,
    `"${INITIALIZE_CALLDATA}"`
  );

  console.log("\n--- Option 2: Link proxy to implementation on Polygonscan (recommended) ---");
  console.log("1. Open: https://polygonscan.com/address/" + PROXY_ADDRESS + "#code");
  console.log("2. Contract tab -> 'Is this a proxy?' -> Verify");
  console.log("3. Enter implementation address:", IMPLEMENTATION_ADDRESS);
  console.log("4. Save. Read/Write Contract will then use SmartTags ABI.\n");

  console.log("Attempting verification...");
  try {
    await hre.run("verify:verify", {
      address: PROXY_ADDRESS,
      constructorArguments: args,
    });
    console.log("Proxy verified successfully.");
  } catch (e) {
    if (e.message.includes("Already Verified") || e.message.includes("already verified")) {
      console.log("Proxy is already verified.");
    } else {
      console.error("Verification failed:", e.message);
      console.log("\nUse Option 1 command above or Option 2 on Polygonscan.");
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
