// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract PriceConsumerV3 {


   AggregatorV3Interface internal priceFeed;


   /**
    * Network: Sepolia
    * Aggregator: ETH/USD
    * Address: 0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910


    */
   constructor() {
       priceFeed = AggregatorV3Interface(0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910);
   }


   /**
    * Returns the latest price
    */
   function getLatestPrice() public view returns (int) {
       (
           /*uint80 roundID*/,
           int price,
           /*uint startedAt*/,
           /*uint timeStamp*/,
           /*uint80 answeredInRound*/
       ) = priceFeed.latestRoundData();
       return price;
   }
}
