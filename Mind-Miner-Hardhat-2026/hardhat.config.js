require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require("@openzeppelin/hardhat-upgrades");

const { 
  SEPOLIA_API_URL, 
  MAINNET_API_URL,
  PRIVATE_KEY, 
  ETHERSCAN_API_KEY,
  MAINNET_ETHERSCAN_API_KEY 
} = process.env;

// Validate required environment variables
if (!PRIVATE_KEY) {
  throw new Error("Please set PRIVATE_KEY in your .env file");
}

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.36",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          evmVersion: "paris"
        },
      },
    ],
  },
  defaultNetwork: "sepolia",
  networks: {
    hardhat: {
      chainId: 1337
    },
    sepolia: {
      url: SEPOLIA_API_URL || process.env.API_URL || "https://rpc.sepolia.org", // Fallback to public RPC
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 11155111,
      gasPrice: "auto"
    },
    // Only include mainnet if MAINNET_API_URL is provided
    ...(MAINNET_API_URL && {
      mainnet: {
        url: MAINNET_API_URL,
        accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        chainId: 1,
        gasPrice: "auto"
      }
    })
  },
  etherscan: {
    // Etherscan API V2 - single API key for all networks
    apiKey: MAINNET_ETHERSCAN_API_KEY || ETHERSCAN_API_KEY,
    // Custom chains configuration for better compatibility
    customChains: []
  },
  sourcify: {
    enabled: true
  },
  // OpenZeppelin Upgrades Plugin Settings
  upgrades: {
    // Timeout in milliseconds (e.g., 5 minutes)
    timeout: 300000,
    // Polling interval in milliseconds
    pollingInterval: 5000
  }
};
