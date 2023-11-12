// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MyntistTreasureBox.sol"; // testing

contract MYNT is MyntistTreasureBox { // testing

  constructor(address _MYTNFTAddress, address _myntistPlatformAddress)
    {
        /* Initialize global shareRate to 1 */
        globals.shareRate = uint40(1 * SHARE_RATE_SCALE);

        /* Initialize dailyDataCount to skip pre-claim period */
        globals.dailyDataCount = uint16(PRE_CLAIM_DAYS);

        /* Add all Satoshis from UTXO snapshot to contract */
        globals.claimStats = _claimStatsEncode(
            0, // _claimedBtcAddrCount
            0, // _claimedSatoshisTotal
            FULL_SATOSHIS_TOTAL // _unclaimedSatoshisTotal
        );

        NFTAddress = IERC721(_MYTNFTAddress);
        myntistPlatformAddress = _myntistPlatformAddress;  
    }

    // Added For testing purpose
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    receive() external payable {
        emit TreasureBoxFunded(msg.sender, msg.value, block.timestamp);
    }

    // Testing purpose
    function transferEth(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(address(this).balance >= amount, "Insufficient contract balance");
    
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

}

// 1698982892
// [[1,2],[2,4],[3,6]]   [[4,2],[5,4],[6,6]]  [[7,2],[8,4],[9,6]]
// 500000000000000000