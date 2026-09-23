require("dotenv").config();
const { ethers } = require("hardhat");

const MINDMINER_WALLET = "0xd7b7cafF029f863050A5D9e05B9b2Ce659fdDA92";

/**
 * Post-upgrade role setup for RoyaltyCoin (Sepolia / mainnet).
 *
 * Order matters:
 *   1. setRewardOperator (while caller is still owner)
 *   2. transferOwnership(Safe)
 *
 * Usage:
 *   ROYALTYCOIN_PROXY_ADDRESS=0x... SEPOLIA_SAFE=0x... \
 *   SEPOLIA_REWARD_OPERATOR=0xd7b7... (optional, defaults to MINDMINER_WALLET) \
 *   npx hardhat run deployments/configure_RoyaltyCoin_roles.js --network sepolia
 */
async function main() {
  const proxy = process.env.ROYALTYCOIN_PROXY_ADDRESS;
  if (!proxy) throw new Error("Set ROYALTYCOIN_PROXY_ADDRESS in .env");

  const safe = process.env.SEPOLIA_SAFE || process.env.MAINNET_SAFE || process.env.SAFE_ADDRESS;
  if (!safe) throw new Error("Set SEPOLIA_SAFE, MAINNET_SAFE, or SAFE_ADDRESS in .env");

  const operator =
    process.env.SEPOLIA_REWARD_OPERATOR ||
    process.env.MAINNET_REWARD_OPERATOR ||
    process.env.REWARD_OPERATOR ||
    MINDMINER_WALLET;

  const [signer] = await ethers.getSigners();
  console.log("Caller:", signer.address);
  console.log("Proxy:", proxy);
  console.log("Safe (new owner):", safe);
  console.log("Reward operator:", operator);

  const RoyaltyCoin = await ethers.getContractFactory("RoyaltyCoin");
  const rc = RoyaltyCoin.attach(proxy);

  const ownerBefore = await rc.owner();
  const operatorBefore = await rc.rewardOperator();
  console.log("\nBefore:");
  console.log("  owner():", ownerBefore);
  console.log("  rewardOperator():", operatorBefore);

  if (ownerBefore.toLowerCase() !== signer.address.toLowerCase()) {
    throw new Error(
      `Connected signer ${signer.address} is not contract owner ${ownerBefore}. Use owner PRIVATE_KEY.`
    );
  }

  if (operatorBefore === ethers.ZeroAddress || operatorBefore.toLowerCase() !== operator.toLowerCase()) {
    console.log("\n1/2 setRewardOperator...");
    const tx1 = await rc.setRewardOperator(operator);
    await tx1.wait();
    console.log("   tx:", tx1.hash);
  } else {
    console.log("\n1/2 rewardOperator already set — skip");
  }

  if (ownerBefore.toLowerCase() !== safe.toLowerCase()) {
    console.log("\n2/2 transferOwnership(Safe)...");
    const tx2 = await rc.transferOwnership(safe);
    await tx2.wait();
    console.log("   tx:", tx2.hash);
  } else {
    console.log("\n2/2 owner already Safe — skip");
  }

  console.log("\nAfter:");
  console.log("  owner():", await rc.owner());
  console.log("  rewardOperator():", await rc.rewardOperator());
  console.log("\n✅ Role configuration complete.");
  console.log("Next: verify distributeRoyaltyCoinReward from operator wallet and admin txs via Safe.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
