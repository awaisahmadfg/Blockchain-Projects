# Blockchain-Projects

Public portfolio of **Awais Ahmad** ([@awaisahmadfg](https://github.com/awaisahmadfg)) — smart contracts and Web3 work in **Solidity**, **Hardhat**, **Node.js**, **React**, and **Ethers.js**.

## Production highlights

| Project | Network | Links |
|--------|---------|--------|
| **Mind-Miner** | Ethereum mainnet | [Hardhat](./Mind-Miner-Hardhat-2026) · [114 tests](./Mind-Miner-Hardhat-2026#tests) · [Etherscan proxy](https://etherscan.io/address/0xaEbcEA4f3B18a1445eF25e7B22DC11181407b664) · [dev.mindminer.ai](https://dev.mindminer.ai) |
| **SmartTags** | Polygon | [Hardhat](./SmartTags-Hardhat-2026) · [16 tests](./SmartTags-Hardhat-2026#tests) · [Polygonscan](https://polygonscan.com/address/0x3696b294693944380A2d0991Dc1F161A07Cc9D87#code) · [SmartTag Analytics](https://smarttaganalytics.com/) |

## Hardhat workspaces (2026)

| Folder | Summary |
|--------|---------|
| [Mind-Miner-Hardhat-2026](./Mind-Miner-Hardhat-2026/) | UUPS **RoyaltyCoin** (ERC-20, 5% Uniswap V2 trade tax) + **PatentMarketplace** (ERC-721); deploy/upgrade scripts; **114** tests. |
| [SmartTags-Hardhat-2026](./SmartTags-Hardhat-2026/) | UUPS **ERC-721** property registration; Polygon deploy/verify; **16** tests. |

## R&D & tokenomics (not production-deployed)

| Folder | Summary |
|--------|---------|
| [Mynt-Token](./Mynt-Token/) | **Myntist (MYNT)** — HEX-inspired staking, Bitcoin UTXO snapshot/claim scripts, ERC-721 treasure box, 5% buy/sell module; Hardhat-tested. |
| [BTC Claim Script](./BTC%20Claim%20Script/) | ECDSA / snapshot helpers supporting UTXO-claim flows used with Mynt-Token work. |
| [FMYNT_Token](./FMYNT_Token/) | Related MYNT / FMYN token contract experiments. |
| [xelora-contract](./xelora-contract/) | **XeloraCoin**, multi-owner patterns, token vault, upgrade-agent flow (Solidity 0.4.x sample). |

## NFT marketplaces & minting

| Folder | Summary |
|--------|---------|
| [ERC-721_NFT_MarketPlace](./ERC-721_NFT_MarketPlace/) | ERC-721 marketplace patterns (listings, royalties). |
| [ERC-1155_NFT_MarketPlace](./ERC-1155_NFT_MarketPlace/) | ERC-1155 multi-token marketplace sample. |
| [NFT Minter Dapp](./NFT%20Minter%20Dapp/) | React minting UI + minting contract (legacy portfolio demo). |
| [Mind-Miner](./Mind-Miner/) | Earlier Mind-Miner snippets (contracts, Web3 UI, IdeaCoin-era files); see **Hardhat 2026** for current mainnet code. |
| [SmartTags](./SmartTags/) | Earlier SmartTags single-contract snapshot; see **SmartTags-Hardhat-2026** for production-aligned repo. |

## Staking & ERC-20 samples

| Folder | Summary |
|--------|---------|
| [Wolverinu Staking Dapp](./Wolverinu%20Staking%20Dapp/) | Multi-token ERC-20 staking (Wolverinu, Adamantium-style rewards). |
| [ERC-721_NFT_Staking](./ERC-721_NFT_Staking/) | NFT staking contract sample. |
| [ERC-1155_NFT_Staking](./ERC-1155_NFT_Staking/) | ERC-1155 staking sample. |
| [ERC-20_SafeMoon_Token](./ERC-20_SafeMoon_Token/) | Tax/reflection-style ERC-20 experiment. |
| [ERC-20_UUPS Contract](./ERC-20_UUPS%20Contract/) | Upgradeable ERC-20 (UUPS) template. |
| [Sell_And_Buy](./Sell_And_Buy/) | Buy/sell tax or swap-related contract samples. |
| [TokenPresaleDapp](./TokenPresaleDapp/) | Token presale flow with front-end tests (Jest). |

## Oracles, events & Web3 utilities

| Folder | Summary |
|--------|---------|
| [Oracle Chain-link](./Oracle%20Chain-link/) | Chainlink price feeds, dynamic NFTs, event → IPFS storage samples. |
| [Solidity_Event_Listning _with_Append](./Solidity_Event_Listning%20_with_Append/) | Event listeners + Pinata/IPFS append patterns (Node.js). |
| [Ether JS](./Ether%20JS/) | Ethers.js integration examples. |

## Real estate & misc contracts

| Folder | Summary |
|--------|---------|
| [Real_Estate](./Real_Estate/) | Early real-estate Solidity prototypes (pre–SmartTags production). |
| [Charity_Donation_Contract](./Charity_Donation_Contract/) | Donation routing smart contract sample. |

## Security & audit notes

| Folder | Summary |
|--------|---------|
| [Smart Contract Audit](./Smart%20Contract%20Audit/) | Third-party style review notes / sample audited contracts. |
| [Smart_Contract_Audit](./Smart_Contract_Audit/) | Additional audit write-ups (e.g. staking pool review). |

## Learning & experiments

| Folder | Summary |
|--------|---------|
| [Learning Rust](./Learning%20Rust/) | Rust / Solana experiments (local setup, SPL burning, sample dApps). |
| [Learning-Go](./Learning-Go/) | Go language basics (non-blockchain practice). |

## Stack

Solidity (0.4.x–0.8.x), OpenZeppelin (including upgradeable), Hardhat, Ethers v6, Web3.js, React/TypeScript, IPFS, Chainlink oracles, Ethereum & Polygon.

## Maintainer

**Awais Ahmad** — [GitHub @awaisahmadfg](https://github.com/awaisahmadfg) · [LinkedIn](https://www.linkedin.com/in/awaisahmadfg/)

This repository is maintained solely by the account above.

## License

Unless a subdirectory specifies otherwise, code is provided for portfolio and reference purposes.
