/**
 * Network-specific addresses and settings.
 * Override any value via .env — scripts work on sepolia and mainnet with --network flag.
 */

const KNOWN = {
  mainnet: {
    chainId: 1,
    explorer: "https://etherscan.io",
    usdtAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // Tether USDT (Ethereum)
    uniswapV2Router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
  },
  sepolia: {
    chainId: 11155111,
    explorer: "https://sepolia.etherscan.io",
    usdtAddress: null, // set via SEPOLIA_USDT_ADDRESS (e.g. your DummyUSDT)
    // Uniswap V2 Router02 on Sepolia (https://docs.uniswap.org/contracts/v2/deployments)
    // Override via SEPOLIA_UNISWAP_ROUTER if you deploy your own fork
    uniswapV2Router: "0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3",
    uniswapV2Factory: "0xF62c03E08ada871A0bEb309762E260a7a6a880E6",
  },
};

function getNetworkConfig(chainId) {
  const id = Number(chainId);

  if (id === KNOWN.mainnet.chainId) {
    return {
      networkName: "mainnet",
      chainId: id,
      explorer: KNOWN.mainnet.explorer,
      usdtAddress:
        process.env.MAINNET_USDT_ADDRESS || KNOWN.mainnet.usdtAddress,
      uniswapV2Router:
        process.env.MAINNET_UNISWAP_ROUTER || KNOWN.mainnet.uniswapV2Router,
      uniswapV2Factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f",
      isTestnet: false,
    };
  }

  if (id === KNOWN.sepolia.chainId) {
    const usdtAddress =
      process.env.SEPOLIA_USDT_ADDRESS ||
      process.env.DUMMY_USDT_ADDRESS ||
      null;
    const uniswapV2Router = process.env.SEPOLIA_UNISWAP_ROUTER || null;

    return {
      networkName: "sepolia",
      chainId: id,
      explorer: KNOWN.sepolia.explorer,
      usdtAddress,
      uniswapV2Router: uniswapV2Router || KNOWN.sepolia.uniswapV2Router,
      uniswapV2Factory: KNOWN.sepolia.uniswapV2Factory,
      isTestnet: true,
    };
  }

  return {
    networkName: `chain-${id}`,
    chainId: id,
    explorer: null,
    usdtAddress:
      process.env.USDT_ADDRESS ||
      process.env.MAINNET_USDT_ADDRESS ||
      process.env.SEPOLIA_USDT_ADDRESS ||
      null,
    uniswapV2Router:
      process.env.UNISWAP_ROUTER ||
      process.env.MAINNET_UNISWAP_ROUTER ||
      process.env.SEPOLIA_UNISWAP_ROUTER ||
      null,
    isTestnet: id !== 1,
  };
}

function explorerLink(explorer, address, type = "address") {
  if (!explorer || !address) return null;
  return `${explorer}/${type}/${address}`;
}

module.exports = { getNetworkConfig, explorerLink, KNOWN };
