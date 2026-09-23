require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

const { POLYGON_API_URL, POLYGON_PRIVATE_KEY, POLYGONSCAN_API_KEY } = process.env;

module.exports = {
  solidity: {
    version: "0.8.33",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      evmVersion: "paris",
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: { chainId: 1337 },
    ...(POLYGON_API_URL &&
      POLYGON_PRIVATE_KEY && {
        polygon: {
          url: POLYGON_API_URL,
          accounts: [POLYGON_PRIVATE_KEY],
          chainId: 137,
        },
      }),
  },
  etherscan: {
    apiKey: {
      polygon: POLYGONSCAN_API_KEY || "",
    },
  },
};
