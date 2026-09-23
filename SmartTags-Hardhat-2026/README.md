# SmartTags Hardhat

UUPS upgradeable **ERC-721** property registration for real-estate deed/metadata on **Polygon**.

## Production

- Proxy (verified): [Polygonscan](https://polygonscan.com/address/0x3696b294693944380A2d0991Dc1F161A07Cc9D87#code)
- Product: [SmartTag Analytics](https://smarttaganalytics.com/)

## Contract

- `registerLand(cid)` — registrar mints property token with IPFS metadata
- `updateProperty(tokenId, newCid)` — metadata update with CID uniqueness rules
- `getProperty`, `isCIDUsed`, `getNextTokenId`

## Tests

Run on local Hardhat network (no `.env` required for tests):

```shell
npm install
npm test
```

Coverage: initialization, register/update flows, custom errors, access control, CID bookkeeping.

## Deploy / verify (Polygon)

Requires `.env` (never commit):

- `POLYGON_API_URL`
- `POLYGON_PRIVATE_KEY`
- `POLYGONSCAN_API_KEY`

```shell
npx hardhat run deployments/deploy_SmartTags.js --network polygon
node scripts/verify-proxy.js
```
