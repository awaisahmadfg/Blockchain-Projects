// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./UTXORedeemableToken.sol";
import "hardhat/console.sol";

contract TransformableToken is UTXORedeemableToken {
    /**
     * @dev PUBLIC FACING: Enter the tranform lobby for the current round
     * @param referrerAddr Eth address of referring user (optional; 0x0 for no referrer)
     */
    function xfLobbyEnter(address referrerAddr) external payable
    {
        uint256 enterDay = _currentDay();
        // 1 < 351
        require(enterDay < CLAIM_PHASE_END_DAY, "MYNT: Lobbies have ended");

        uint256 rawAmount = msg.value;
        require(rawAmount != 0, "MYNT: Amount required");

        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender]; // This is where information about the user's lobby entry will be stored.

        uint256 entryIndex = qRef.tailIndex++; // It adds the user's entry.

        qRef.entries[entryIndex] = XfLobbyEntryStore(uint96(rawAmount), referrerAddr); // stroing amount and address on that tail index

        xfLobby[enterDay] += rawAmount; //  It keeps track of the total ETH entered into the lobby on that day.

        _emitXfLobbyEnter(enterDay, entryIndex, rawAmount, referrerAddr);
    }

    /**
     * @dev PUBLIC FACING: Leave the transform lobby after the round is complete
     * @param enterDay Day number when the member entered
     * @param count Number of queued-enters to exit (optional; 0 for all)
     */
    function xfLobbyExit(uint256 enterDay, uint256 count) external
    {
        require(enterDay < _currentDay(), "MYNT: Round is not complete");

        XfLobbyQueueStore storage qRef = xfLobbyMembers[enterDay][msg.sender];

        uint256 headIndex = qRef.headIndex;
        uint256 endIndex;

        if (count != 0) {
            require(count <= qRef.tailIndex - headIndex, "MYNT: count invalid");
            endIndex = headIndex + count;
        } else {
            endIndex = qRef.tailIndex;
            require(headIndex < endIndex, "MYNT: count invalid");
        }

        uint256 waasLobby = _waasLobby(enterDay); // Returns Amount of MYNT that is available for distribution in the Transform Lobbies on a specific day
        uint256 _xfLobby = xfLobby[enterDay]; // The _xfLobby variable is the total amount of ETH that has been entered into the Transform Lobbies on the day that the user entered.
        console.log("enterDay _xfLobby: ", _xfLobby);
        uint256 totalXfAmount = 0;
        uint256 originBonusGeos = 0;

        do {
            uint256 rawAmount = qRef.entries[headIndex].rawAmount;
            address referrerAddr = qRef.entries[headIndex].referrerAddr;

            delete qRef.entries[headIndex];

            /* 1. The formula for calculating the share of MYNT 
               2. rawAmount: It is the amount of ETH that the user entered with.
               3. waasLobby: The amount of MYNT that is available for distribution in the Transform Lobbies on the day that the user entered. 
               4. _xfLobby: It is the total amount of ETH that has been entered into the Transform Lobbies on the day that the user entered.
            */
            uint256 xfAmount = waasLobby * rawAmount / _xfLobby;

            if (referrerAddr == address(0)) {
                /* No referrer */
                _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
            } else {
                /* Referral bonus of 10% of xfAmount to member */
                uint256 referralBonusGeos = xfAmount / 10;

                xfAmount += referralBonusGeos;

                /* Then a cumulative referrer bonus of 20% to referrer */
                uint256 referrerBonusGeos = xfAmount / 5;

                if (referrerAddr == msg.sender) {
                    /* Self-referred */
                    xfAmount += referrerBonusGeos;
                    _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
                } else {
                    /* Referred by different address */
                    _emitXfLobbyExit(enterDay, headIndex, xfAmount, referrerAddr);
                    _mint(referrerAddr, referrerBonusGeos);
                }
                originBonusGeos += referralBonusGeos + referrerBonusGeos;
            }

            totalXfAmount += xfAmount;
        } while (++headIndex < endIndex);

        qRef.headIndex = uint40(headIndex);

        if (originBonusGeos != 0) {
            _mint(ORIGIN_ADDR, originBonusGeos);
        }
        if (totalXfAmount != 0) {
            _mint(msg.sender, totalXfAmount);
        }
    }

    /**
     * @dev PUBLIC FACING: Release any value that has been sent to the contract
     */
    // function xfLobbyFlush() external
    // {
    //     require(address(this).balance != 0, "MYNT: No value");

    //     FLUSH_ADDR.transfer(address(this).balance);
    // }

    /*
     * @dev PUBLIC FACING: External helper to return multiple values of xfLobby[] with
     * a single call
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return Fixed array of values
     */
    function xfLobbyRange(uint256 beginDay, uint256 endDay) external view returns (uint256[] memory list)
    {
        require(
            beginDay < endDay && endDay <= CLAIM_PHASE_END_DAY && endDay <= _currentDay(),
            "MYNT: invalid range"
        );

        list = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        do {
            list[dst++] = uint256(xfLobby[src++]);
        } while (src < endDay);

        return list;
    }

    /*
     * @dev PUBLIC FACING: Return a current lobby member queue entry.
     * Only needed due to limitations of the standard ABI encoder.
     * @param memberAddr Eth address of the lobby member
     * @param entryId 49 bit compound value. Top 9 bits: enterDay, Bottom 40 bits: entryIndex
     * @return 1: Raw amount that was entered with; 2: Referring Eth addr (optional; 0x0 for no referrer)
     */

    /* This function is used to return the details of a specific entry in the xfLobbyMembers mapping.*/
    function xfLobbyEntry(address memberAddr, uint256 entryId) external view returns (uint256 rawAmount, address referrerAddr)
    {
        uint256 enterDay = entryId >> XF_LOBBY_ENTRY_INDEX_SIZE;
        uint256 entryIndex = entryId & XF_LOBBY_ENTRY_INDEX_MASK;

        XfLobbyEntryStore storage entry = xfLobbyMembers[enterDay][memberAddr].entries[entryIndex];

        require(entry.rawAmount != 0, "MYNT: Param invalid");

        return (entry.rawAmount, entry.referrerAddr);
    }

    // function calculateEntryIndex(uint256 enterDay, uint256 entryIndex) external pure returns (uint256) {
    //     // Combine enterDay and entryIndex to create the 49-bit entryId
    //     uint256 entryId = (enterDay << 40) | entryIndex;
    //     return entryId;
    // }

    function calculateEntryId(uint256 enterDay, uint256 entryIndex) public pure returns (uint256 entryId) {
        require(enterDay < (1 << 128), "enterDay exceeds 128 bits");
        require(entryIndex < (1 << 40), "entryIndex exceeds 40 bits");
        
        entryId = (enterDay << 40) | entryIndex;
        return entryId;
    }


    /*
     * @dev PUBLIC FACING: Return the lobby days that a user is in with a single call
     * @param memberAddr Eth address of the user
     * @return Bit vector of lobby day numbers
     */
    /*This function is used to return a bit vector of the days that a user is in the Transform Lobbies.
      It allows users to see which days they are actively participating in the Transform Lobbies.*/ 
    function xfLobbyPendingDays(address memberAddr) external view returns (uint256[XF_LOBBY_DAY_WORDS] memory words)
    {
        uint256 day = _currentDay() + 1; // counting from the next day
        // console.log("1");
        // This step ensures that the function doesn't attempt to access lobby data beyond the end of the claim phase.
        if (day > CLAIM_PHASE_END_DAY) {
            day = CLAIM_PHASE_END_DAY;
        }

        // console.log("2");


        /* This line starts a while loop that iterates as long as day is not equal to zero. 
           The day-- expression decrements the day variable by one in each iteration. */

        // while (day-- != 0) {
        //     /*This line checks if the tailIndex of the xfLobbyMembers storage for the specific day
        //      and memberAddr is greater than the headIndex. 
        //      This condition checks if the user has made any entries in the lobby on that day. 
        //      If this condition is met, it means the user has pending lobby entries for that day.*/
        //     if (xfLobbyMembers[day][memberAddr].tailIndex > xfLobbyMembers[day][memberAddr].headIndex) {
        //         words[day >> 8] |= 1 << (day & 255);
        //     }
        // }

        while (day > 0) {
        
            if (xfLobbyMembers[day][memberAddr].tailIndex > xfLobbyMembers[day][memberAddr].headIndex) {
            words[day >> 8] |= 1 << (day & 255);
            }
            day--;
        }
        // console.log("3");
        return words;
    }

    /* This function is used to calculate the amount of MYNT that is available for distribution in the Transform Lobbies on a specific day.*/
    function _waasLobby(uint256 enterDay) public returns (uint256 waasLobby)
    {
        if (enterDay >= CLAIM_PHASE_START_DAY) {
            GlobalsCache memory g;
            GlobalsCache memory gSnapshot;
            _globalsLoad(g, gSnapshot);

            _dailyDataUpdateAuto(g);

            uint256 unclaimed = dailyData[enterDay].dayUnclaimedSatoshisTotal;
            console.log("unclaimed: ", unclaimed);
            waasLobby = unclaimed * GEOS_PER_SATOSHI / CLAIM_PHASE_DAYS;
            console.log("waasLobby: ", waasLobby);

            _globalsSync(g, gSnapshot);
        } else {
            waasLobby = WAAS_LOBBY_SEED_GEOS; // 1e17
        }
        return waasLobby;
    }

    function _emitXfLobbyEnter(uint256 enterDay, uint256 entryIndex, uint256 rawAmount, address referrerAddr) private
    {
        emit XfLobbyEnter( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint96(rawAmount)) << 40),
            msg.sender,
            (enterDay << XF_LOBBY_ENTRY_INDEX_SIZE) | entryIndex,
            referrerAddr
        );
    }

    function _emitXfLobbyExit( uint256 enterDay, uint256 entryIndex, uint256 xfAmount, address referrerAddr) private
    {
        emit XfLobbyExit( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(xfAmount)) << 40),
            msg.sender,
            (enterDay << XF_LOBBY_ENTRY_INDEX_SIZE) | entryIndex,
            referrerAddr
        );
    }

}
