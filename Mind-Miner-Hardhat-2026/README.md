# Mind-Miner Hardhat

UUPS upgradeable smart contracts for Mind-Miner.

## Contracts

- **RoyaltyCoin (RC)** — ERC20 with reward distribution, 5% Uniswap V2 trade tax, multi-pair auto-LP (USDT/WETH/WBTC)
- **PatentMarketplace (PT)** — ERC721 patent tokens, fixed-price and auction listings, 10% service fee + 5% creator royalty

## Tests

114 tests on Hardhat network (`npm test`).

**RoyaltyCoin:** distribute rewards, USDT rewards, trade tax, multi-pair LP, `_inSwap` double-tax guard, LP to treasury wallet

**PatentMarketplace:** mint, fixed/auction flows, expiry, fees, no-bid auction revert, secondary sale royalty behavior

```shell
npm test
npm run test:royalty
npm run test:marketplace
```

Use `--network hardhat` (default in scripts). Plain `npx hardhat test` may fail if config defaults to Sepolia.

## Deploy / Upgrade

```shell
npx hardhat run deployments/deploy_PatentMarketplace_UUPS.js --network sepolia
npx hardhat run deployments/deploy_RoyaltyCoin_UUPS.js --network sepolia
npx hardhat run deployments/upgrade_RoyaltyCoin_UUPS.js --network sepolia
npx hardhat run deployments/configure_RoyaltyCoin_roles.js --network sepolia
npx hardhat run deployments/upgrade_PatentMarketplace_UUPS.js --network sepolia
```

`upgrade_RoyaltyCoin_UUPS.js` upgrades the proxy and auto-verifies on Etherscan (proxy +
implementation link). Requires `ETHERSCAN_API_KEY` in `.env`. Works when `owner()` is an EOA.

If `owner()` is a Gnosis Safe, run `prepare_RoyaltyCoin_upgrade.js` instead (deploys impl + prints
Safe `upgradeTo` calldata), execute via Safe UI, then verify the proxy.

`distributeUsdtReward` pulls USDT from `rewardOperator` (not `owner()`). Operator must approve the
RC proxy once; daily USDT rewards stay instant from the backend wallet.

After upgrading RoyaltyCoin with `rewardOperator` support, run `configure_RoyaltyCoin_roles.js` to
`setRewardOperator` (backend hot wallet) then `transferOwnership` (Gnosis Safe). Requires
`SEPOLIA_SAFE` / `SAFE_ADDRESS` and owner `PRIVATE_KEY` in `.env`.

Requires `.env` with deployer `PRIVATE_KEY` and RPC URL.
