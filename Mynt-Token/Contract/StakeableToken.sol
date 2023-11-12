// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./GlobalsAndUtility.sol";

contract StakeableToken is GlobalsAndUtility {
    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param newStakedHearts Number of Hearts to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external
    {
        GlobalsCache memory g; 
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot); /* Global Cache struct 11, capturing/Read the current global state into a cache for reference and potential modification in state. */

        /* Enforce the minimum stake time */
        require(newStakedDays >= MIN_STAKE_DAYS, "MYNT: newStakedDays lower than minimum");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        _stakeStart(g, newStakedHearts, newStakedDays, false);

        /* Remove staked Hearts from balanceuint256 stakeIndex, uint40 stakeIdParam of staker */
        _burn(msg.sender, newStakedHearts);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Unlocks a completed stake, distributing the proceeds of any penalty
     * immediately. The staker must still call stakeEnd() to retrieve their stake return (if any).
     * @param stakerAddr Address of staker
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */

     /*
     This function works similarly. It's used to finish a staking 
     process early, but it doesn't give you all the rewards you'd 
     get if you waited until the staking period is over. 
     Instead, it distributes any penalties right away. 
     However, you still need to do something else (call stakeEnd())
      to get the full benefits of your staking.
    */
    function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam) external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* require() is more informative than the default assert() */
        require(stakeLists[stakerAddr].length != 0, "MYNT: Empty stake list");
        require(stakeIndex < stakeLists[stakerAddr].length, "MYNT: stakeIndex invalid");

        StakeStore storage stRef = stakeLists[stakerAddr][stakeIndex];

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stRef, stakeIdParam, st);

        /* Stake must have served full term */
        require(g._currentDay >= st._lockedDay + st._stakedDays, "MYNT: Stake not fully served");

        /* Stake must still be locked */
        require(st._unlockedDay == 0, "MYNT: Stake already unlocked");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        /* Unlock the completed stake */
        _stakeUnlock(g, st);

        /* stakeReturn value is unused here */
        (, uint256 payout, uint256 penalty, uint256 cappedPenalty) = _stakePerformance(
            g,
            st,
            st._stakedDays
        );

        _emitStakeGoodAccounting(
            stakerAddr,
            stakeIdParam,
            st._stakedHearts,
            st._stakeShares,
            payout,
            penalty
        );

        if (cappedPenalty != 0) {
            _splitPenaltyProceeds(g, cappedPenalty);
        }

        /* st._unlockedDay has changed */
        _stakeUpdate(stRef, st);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
     * a stake id is used to reject stale indexes.
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        // retrieves the staker's stake list from storage. This list contains all their stakes.
        StakeStore[] storage stakeListRef = stakeLists[msg.sender];

        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "MYNT: Empty stake list");
        require(stakeIndex < stakeListRef.length, "MYNT: stakeIndex invalid");

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st); // It loads the data of the stake corresponding to the provided stakeIndex and stakeIdParam into a memory structure called st.

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        /*keep track of the number of days the stake is active or in progress*/
        uint256 servedDays = 0;

        bool prevUnlocked = (st._unlockedDay != 0); // The system to determine the stake is whether withdrawn or not
        uint256 stakeReturn;
        uint256 payout = 0;
        uint256 penalty = 0;
        uint256 cappedPenalty = 0;

            if (g._currentDay >= st._lockedDay) {
            
            /*If it was previously unlocked/Withdrawn, then the stake has finished its entire term and can be considered as completed*/
            if (prevUnlocked) {
                /* Previously unlocked in stakeGoodAccounting(), so must have served full term/considered as completed */
                servedDays = st._stakedDays;
            } else {
                _stakeUnlock(g, st);

                // it then calculates the number of days the stake has served since unlocking.     
                servedDays = g._currentDay - st._lockedDay; 

                // If this number exceeds the total staked days,
                if (servedDays > st._stakedDays) {
                    servedDays = st._stakedDays; // limited/capped to the staked days
                } 
                // else {
                //     /* Deny early-unstake before an auto-stake minimum has been served */
                //     if (servedDays < MIN_AUTO_STAKE_DAYS) { // 350 days
                //         require(!st._isAutoStake, "MYNT: Auto-stake still locked");
                //     }
                // }
            }

            (stakeReturn, payout, penalty, cappedPenalty) = _stakePerformance(g, st, servedDays);
        } else {
            /* Deny early-unstake before an auto-stake minimum has been served */
            // require(!st._isAutoStake, "MYNT: Auto-stake still locked");

            /* Stake hasn't been added to the total yet, so no penalties or rewards apply */
            g._nextStakeSharesTotal -= st._stakeShares;

            stakeReturn = st._stakedHearts;
        }

        _emitStakeEnd(
            stakeIdParam,
            st._stakedHearts,
            st._stakeShares,
            payout,
            penalty,
            servedDays,
            prevUnlocked
        );

        if (cappedPenalty != 0 && !prevUnlocked) {
            /* Split penalty proceeds only if not previously unlocked by stakeGoodAccounting() */
            _splitPenaltyProceeds(g, cappedPenalty);
        }

        /* Pay the stake return, if any, to the staker */
        if (stakeReturn != 0) {
            _mint(msg.sender, stakeReturn);

            /* Update the share rate if necessary */
            _shareRateUpdate(g, st, stakeReturn);
        }
        g._lockedHeartsTotal -= st._stakedHearts;

        _stakeRemove(stakeListRef, stakeIndex);

        _globalsSync(g, gSnapshot);
    }

    /**
     * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
    function stakeCount(address stakerAddr) external view returns (uint256)
    {
        return stakeLists[stakerAddr].length;
    }

    /**
     * @dev Open a stake.
     * @param g Cache of stored globals
     * @param newStakedHearts Number of Hearts to stake
     * @param newStakedDays Number of days to stake
     * @param newAutoStake Stake is automatic directly from a new claim
     */
    function _stakeStart( GlobalsCache memory g, uint256 newStakedHearts, uint256 newStakedDays, bool newAutoStake) internal
    {
        /* Enforce the maximum stake time */
        require(newStakedDays <= MAX_STAKE_DAYS, "MYNT: newStakedDays higher than maximum");

        uint256 bonusHearts = _stakeStartBonusHearts(newStakedHearts, newStakedDays);
        uint256 newStakeShares = (newStakedHearts + bonusHearts) * SHARE_RATE_SCALE / g._shareRate;

        /* Ensure newStakedHearts is enough for at least one stake share */
        /* It checks whether the new stake shares are greater than zero, ensuring that the stake is enough to earn at least one stake share. */ 
        require(newStakeShares != 0, "MYNT: newStakedHearts must be at least minimum shareRate");

        /*
            The stakeStart timestamp will always be part-way through the current
            day, so it needs to be rounded-up to the next day to ensure all
            stakes align with the same fixed calendar days. The current day is
            already rounded-down, so rounded-up is current day + 1.
        */
        /* 
        This code determines the day on which a new stake will be locked. 
        It checks if the current day is before a specific starting day (CLAIM_PHASE_START_DAY).
         If it is, the newLockedDay is set to that starting day plus one. 
         Otherwise, if the current day is after the starting day, 
         the newLockedDay is set to the current day plus one. 
         
         This ensures that the new stake will be locked on the next day to maintain alignment with the fixed calendar days.
        */ 
        uint256 newLockedDay = g._currentDay < CLAIM_PHASE_START_DAY
            ? CLAIM_PHASE_START_DAY + 1
            : g._currentDay + 1;

        /* Create Stake */
        uint40 newStakeId = ++g._latestStakeId; // A new stake ID is generated (newStakeId).

        /* This function adds a new stake to a list of stakes. */
        _stakeAdd(
            stakeLists[msg.sender],
            newStakeId,
            newStakedHearts,
            newStakeShares,
            newLockedDay,
            newStakedDays,
            newAutoStake
        );

        _emitStakeStart(newStakeId, newStakedHearts, newStakeShares, newStakedDays, newAutoStake);

        /* Stake is added to total in the next round, not the current round */
        /* The new stake shares are added to g._nextStakeSharesTotal to be included in the next round's total stakes.*/
        g._nextStakeSharesTotal += newStakeShares;

        /* Track total staked Hearts for inflation calculations */
        /* The total locked Hearts (g._lockedHeartsTotal) is increased by the newStakedHearts.*/
        g._lockedHeartsTotal += newStakedHearts;
    }

    /*
     * @dev Calculates total stake payout including rewards for a multi-day range
     * @param g Cache of stored globals
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param beginDay First day to calculate bonuses for
     * @param endDay Last day (non-inclusive) of range to calculate bonuses for
     * @return Payout in Hearts
     */

     /* It calculates and returns the total payout (rewards) in Hearts for a specific stake over a range of days.*/
    function _calcPayoutRewards( GlobalsCache memory g,
        uint256 stakeSharesParam, // No of stake shares for the specific stake we're calculating the bonuses for.
        uint256 beginDay, // first day of the range for which we want to calculate bonuses.
        uint256 endDay
    ) public view returns (uint256 payout)
    {
        for (uint256 day = beginDay; day < endDay; day++) {
            payout += dailyData[day].dayPayoutTotal * stakeSharesParam
                / dailyData[day].dayStakeSharesTotal;
        }

        /* Less expensive to re-read storage than to have the condition inside the loop */
        if (beginDay <= BIG_PAY_DAY && endDay > BIG_PAY_DAY) {
            uint256 bigPaySlice = g._unclaimedSatoshisTotal * HEARTS_PER_SATOSHI * stakeSharesParam
                / dailyData[BIG_PAY_DAY].dayStakeSharesTotal;

            payout += bigPaySlice + _calcAdoptionBonus(g, bigPaySlice);
        }
        return payout;
    }

    /**
     * @dev Calculate bonus Hearts for a new stake, if any
     * @param newStakedHearts Number of Hearts to stake
     * @param newStakedDays Number of days to stake
     */
    function _stakeStartBonusHearts(uint256 newStakedHearts, uint256 newStakedDays) private pure returns (uint256 bonusHearts)
    {
        /*
            LONGER PAYS BETTER:

            If longer than 1 day stake is committed to, each extra day
            gives bonus shares of approximately 0.0548%, which is approximately 20%
            extra per year of increased stake length committed to, but capped to a
            maximum of 200% extra.

            extraDays       =  stakedDays - 1

            longerBonus%    = (extraDays / 364) * 20%
                            = (extraDays / 364) / 5
                            =  extraDays / 1820
                            =  extraDays / LPB

            extraDays       =  longerBonus% * 1820
            extraDaysMax    =  longerBonusMax% * 1820
                            =  200% * 1820
                            =  3640
                            =  LPB_MAX_DAYS

            BIGGER PAYS BETTER:

            Bonus percentage scaled 0% to 10% for the first 150M MYNT of stake.

            biggerBonus%    = (cappedHearts /  BPB_MAX_HEARTS) * 10%
                            = (cappedHearts /  BPB_MAX_HEARTS) / 10
                            =  cappedHearts / (BPB_MAX_HEARTS * 10)
                            =  cappedHearts /  BPB

            COMBINED:

            combinedBonus%  =            longerBonus%  +  biggerBonus%

                                      cappedExtraDays     cappedHearts
                            =         ---------------  +  ------------
                                            LPB               BPB

                                cappedExtraDays * BPB     cappedHearts * LPB
                            =   ---------------------  +  ------------------
                                      LPB * BPB               LPB * BPB

                                cappedExtraDays * BPB  +  cappedHearts * LPB
                            =   --------------------------------------------
                                                  LPB  *  BPB

            bonusHearts     = hearts * combinedBonus%
                            = hearts * (cappedExtraDays * BPB  +  cappedHearts * LPB) / (LPB * BPB)
        */
        uint256 cappedExtraDays = 0;

        /* Must be more than 1 day for Longer-Pays-Better */
        if (newStakedDays > 1) {
            cappedExtraDays = newStakedDays <= LPB_MAX_DAYS ? newStakedDays - 1 : LPB_MAX_DAYS;
        }

        uint256 cappedStakedHearts = newStakedHearts <= BPB_MAX_HEARTS
            ? newStakedHearts
            : BPB_MAX_HEARTS;

        bonusHearts = cappedExtraDays * BPB + cappedStakedHearts * LPB;
        bonusHearts = newStakedHearts * bonusHearts / (LPB * BPB);

        return bonusHearts;
    }

    // To withdraw the funds and to update the var's
    function _stakeUnlock(GlobalsCache memory g, StakeCache memory st) private pure
    {
        g._stakeSharesTotal -= st._stakeShares;
        st._unlockedDay = g._currentDay;
    }

    function _stakePerformance(GlobalsCache memory g, StakeCache memory st, uint256 servedDays) private view returns (uint256 stakeReturn, uint256 payout, uint256 penalty, uint256 cappedPenalty)
    {
        if (servedDays < st._stakedDays) {
            (payout, penalty) = _calcPayoutAndEarlyPenalty(
                g,
                st._lockedDay,
                st._stakedDays,
                servedDays,
                st._stakeShares
            );
            stakeReturn = st._stakedHearts + payout;
        } else {
            // servedDays must == stakedDays here
            payout = _calcPayoutRewards(
               g,
                st._stakeShares,
                st._lockedDay,
                st._lockedDay + servedDays
            );
            stakeReturn = st._stakedHearts + payout;

            penalty = _calcLatePenalty(st._lockedDay, st._stakedDays, st._unlockedDay, stakeReturn);
        }
        if (penalty != 0) {
            if (penalty > stakeReturn) {
                /* Cannot have a negative stake return */
                cappedPenalty = stakeReturn;
                stakeReturn = 0;
            } else {
                /* Remove penalty from the stake return */
                cappedPenalty = penalty;
                stakeReturn -= cappedPenalty;
            }
        }
        return (stakeReturn, payout, penalty, cappedPenalty);
    }

    /*If the stake hasn't been served for the full duration, this calculates both the payout and the early penalty*/
    function _calcPayoutAndEarlyPenalty( GlobalsCache memory g, uint256 lockedDayParam, uint256 stakedDaysParam, uint256 servedDays, uint256 stakeSharesParam) private view returns (uint256 payout, uint256 penalty)
    {
        uint256 servedEndDay = lockedDayParam + servedDays;

        /* 50% of stakedDays (rounded up) with a minimum applied */
        uint256 penaltyDays = (stakedDaysParam + 1) / 2;
        if (penaltyDays < EARLY_PENALTY_MIN_DAYS) {
            penaltyDays = EARLY_PENALTY_MIN_DAYS;
        }

        // If the stake wasn't served any days:
        if (servedDays == 0) {
            /* Fill penalty days with the estimated average payout */
            /*Will return stake payout for an incomplete day*/
            uint256 expected = _estimatePayoutRewardsDay(g, stakeSharesParam, lockedDayParam);
            penalty = expected * penaltyDays;
            return (payout, penalty); // Actual payout was 0
        }

        if (penaltyDays < servedDays) {
            /*
                Simplified explanation of intervals where end-day is non-inclusive:

                penalty:    [lockedDay  ...  penaltyEndDay)
                delta:                      [penaltyEndDay  ...  servedEndDay)
                payout:     [lockedDay  .......................  servedEndDay)
            */
            //Calculate the day on which the penalty period ends
            uint256 penaltyEndDay = lockedDayParam + penaltyDays;
            penalty = _calcPayoutRewards(
                g,
                 stakeSharesParam, lockedDayParam, penaltyEndDay);

            uint256 delta = _calcPayoutRewards(g,
             stakeSharesParam, penaltyEndDay, servedEndDay);
            payout = penalty + delta;
            return (payout, penalty);
        }

        /* penaltyDays >= servedDays  */
        payout = _calcPayoutRewards(g, 
        stakeSharesParam, lockedDayParam, servedEndDay);

        if (penaltyDays == servedDays) {
            penalty = payout;
        } else {
            /*
                (penaltyDays > servedDays) means not enough days served, so fill the
                penalty days with the average payout from only the days that were served.
            */
            penalty = payout * penaltyDays / servedDays;
        }
        return (payout, penalty);
    }

    function _calcLatePenalty(uint256 lockedDayParam, uint256 stakedDaysParam, uint256 unlockedDayParam, uint256 rawStakeReturn) private pure returns (uint256)
    {
        /* Allow grace time before penalties accrue */
        uint256 maxUnlockedDay = lockedDayParam + stakedDaysParam + LATE_PENALTY_GRACE_DAYS;
        if (unlockedDayParam <= maxUnlockedDay) {
            return 0;
        }

        /* Calculate penalty as a percentage of stake return based on time */
        return rawStakeReturn * (unlockedDayParam - maxUnlockedDay) / LATE_PENALTY_SCALE_DAYS;
    }

    function _splitPenaltyProceeds(GlobalsCache memory g, uint256 penalty) private
    {
        /* Split a penalty 50:50 between Origin and stakePenaltyTotal */
        uint256 splitPenalty = penalty / 2;

        if (splitPenalty != 0) {
            _mint(ORIGIN_ADDR, splitPenalty);
        }

        /* Use the other half of the penalty to account for an odd-numbered penalty */
        splitPenalty = penalty - splitPenalty;
        g._stakePenaltyTotal += splitPenalty;
    }

    function _shareRateUpdate(GlobalsCache memory g, StakeCache memory st, uint256 stakeReturn) private
    {
        if (stakeReturn > st._stakedHearts) {
            /*
                Calculate the new shareRate that would yield the same number of shares if
                the user re-staked this stakeReturn, factoring in any bonuses they would
                receive in stakeStart().
            */
            uint256 bonusHearts = _stakeStartBonusHearts(stakeReturn, st._stakedDays);
            uint256 newShareRate = (stakeReturn + bonusHearts) * SHARE_RATE_SCALE / st._stakeShares;

            if (newShareRate > SHARE_RATE_MAX) {
                /*
                    Realistically this can't happen, but there are contrived theoretical
                    scenarios that can lead to extreme values of newShareRate, so it is
                    capped to prevent them anyway.
                */
                newShareRate = SHARE_RATE_MAX;
            }

            if (newShareRate > g._shareRate) {
                g._shareRate = newShareRate;

                _emitShareRateChange(newShareRate, st._stakeId);
            }
        }
    }

    /* An event _emitStakeStart is emitted to log the details of the new stake. */
    function _emitStakeStart( uint40 stakeId, uint256 stakedHearts, uint256 stakeShares, uint256 stakedDays, bool isAutoStake) private
    {
        emit StakeStart( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(stakedHearts)) << 40)
                | (uint256(uint72(stakeShares)) << 112)
                | (uint256(uint16(stakedDays)) << 184)
                | (isAutoStake ? (1 << 200) : 0),
            msg.sender,
            stakeId
        );
    }

    function _emitStakeGoodAccounting(address stakerAddr, uint40 stakeId, uint256 stakedHearts, uint256 stakeShares, uint256 payout, uint256 penalty) private
    {
        emit StakeGoodAccounting( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(stakedHearts)) << 40)
                | (uint256(uint72(stakeShares)) << 112)
                | (uint256(uint72(payout)) << 184),
            uint256(uint72(penalty)),
            stakerAddr,
            stakeId,
            msg.sender
        );
    }

    function _emitStakeEnd(uint40 stakeId, uint256 stakedHearts, uint256 stakeShares, uint256 payout, uint256 penalty, uint256 servedDays, bool prevUnlocked) private
    {
        emit StakeEnd( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint72(stakedHearts)) << 40)
                | (uint256(uint72(stakeShares)) << 112)
                | (uint256(uint72(payout)) << 184),
            uint256(uint72(penalty))
                | (uint256(uint16(servedDays)) << 72)
                | (prevUnlocked ? (1 << 88) : 0),
            msg.sender,
            stakeId
        );
    }

    function _emitShareRateChange(uint256 shareRate, uint40 stakeId) private
    {
        emit ShareRateChange( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint40(shareRate)) << 40),
            stakeId
        );
    }
}