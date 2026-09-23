const hre = require("hardhat");

const DEFAULT_DELAY_MS = 10000;
const DEFAULT_RETRIES = 3;
const RETRY_GAP_MS = 5000;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isBenignVerifyMessage(message) {
  const lower = message.toLowerCase();
  return (
    lower.includes("already verified") ||
    lower.includes("successfully verified")
  );
}

function isTransientExplorerError(message) {
  const lower = message.toLowerCase();
  return (
    lower.includes("network request failed") ||
    lower.includes("not valid json") ||
    lower.includes("<!doctype") ||
    lower.includes("econnreset") ||
    lower.includes("etimedout") ||
    lower.includes("429") ||
    lower.includes("rate limit") ||
    lower.includes("timeout")
  );
}

async function fetchEtherscanVerificationStatus(address, chainId) {
  const apiKey =
    process.env.ETHERSCAN_API_KEY || process.env.MAINNET_ETHERSCAN_API_KEY;
  if (!apiKey) return null;

  const url = new URL("https://api.etherscan.io/v2/api");
  url.searchParams.set("chainid", String(chainId));
  url.searchParams.set("module", "contract");
  url.searchParams.set("action", "getsourcecode");
  url.searchParams.set("address", address);
  url.searchParams.set("apikey", apiKey);

  try {
    const response = await fetch(url);
    const data = await response.json();

    if (data.status !== "1" || !Array.isArray(data.result) || !data.result[0]) {
      return { verified: false, source: "etherscan-api", raw: data.message };
    }

    const sourceCode = data.result[0].SourceCode || "";
    const contractName = data.result[0].ContractName || "";
    const verified =
      sourceCode.length > 0 && contractName !== "" && contractName !== "Unknown";

    return { verified, source: "etherscan-api", contractName };
  } catch {
    return null;
  }
}

/**
 * Verify a contract on Etherscan with short delay, retries, and fallback status check.
 */
async function verifyContractAddress(address, label, options = {}) {
  const delayMs = Number(process.env.VERIFY_DELAY_MS || DEFAULT_DELAY_MS);
  const maxRetries = Number(process.env.VERIFY_RETRIES || DEFAULT_RETRIES);
  const network = await hre.ethers.provider.getNetwork();
  const chainId = Number(network.chainId);

  console.log(`\n${"=".repeat(60)}`);
  console.log(`Verifying ${label} on Etherscan`);
  console.log("=".repeat(60));
  console.log(
    `Waiting ${delayMs / 1000}s before verify (override: VERIFY_DELAY_MS)...`
  );
  await sleep(delayMs);

  let lastError = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await hre.run("verify:verify", { address });
      console.log(`✅ ${label} verified`);
      return { verified: true, error: null, attempts: attempt };
    } catch (error) {
      lastError = error.message || String(error);

      if (isBenignVerifyMessage(lastError)) {
        console.log(`✅ ${label} verified (Etherscan confirmed)`);
        return { verified: true, error: null, attempts: attempt };
      }

      if (attempt < maxRetries && isTransientExplorerError(lastError)) {
        console.warn(
          `⚠️  Attempt ${attempt}/${maxRetries} — explorer hiccup, retrying in ${RETRY_GAP_MS / 1000}s...`
        );
        await sleep(RETRY_GAP_MS);
        continue;
      }

      break;
    }
  }

  // Verify may have succeeded even if the final poll returned HTML/502.
  console.log("Checking Etherscan contract status...");
  const explorerStatus = await fetchEtherscanVerificationStatus(address, chainId);

  if (explorerStatus?.verified) {
    console.log(
      `✅ ${label} is verified on Etherscan` +
        (explorerStatus.contractName
          ? ` (${explorerStatus.contractName})`
          : "")
    );
    console.log(
      "ℹ️  Hardhat reported a network glitch, but the contract is verified — all good."
    );
    return {
      verified: true,
      error: null,
      attempts: maxRetries,
      note: "confirmed-via-etherscan-api",
    };
  }

  console.error(`❌ ${label} verification failed:\n`, lastError);
  return { verified: false, error: lastError, attempts: maxRetries };
}

module.exports = {
  verifyContractAddress,
  fetchEtherscanVerificationStatus,
  DEFAULT_DELAY_MS,
};
