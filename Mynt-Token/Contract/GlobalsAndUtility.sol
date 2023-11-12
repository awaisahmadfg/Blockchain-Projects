// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GlobalsAndUtility is ERC20 {

    /*  DailyDataUpdate   (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        uint16            beginDay        -->  data0 [ 55: 40]
        uint16            endDay          -->  data0 [ 71: 56]
        bool              isAutoUpdate    -->  data0 [ 79: 72]
        address  indexed  updaterAddr
    */
    event DailyDataUpdate(uint256 data0,address indexed updaterAddr);

    /*  Claim             (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        bytes20  indexed  btcAddr
        uint56            rawSatoshis     -->  data0 [ 95: 40]
        uint56            adjSatoshis     -->  data0 [151: 96]
        address  indexed  claimToAddr
        uint8             claimFlags      -->  data0 [159:152]
        uint72            claimedHearts   -->  data0 [231:160]
        address  indexed  referrerAddr
        address           senderAddr      -->  data1 [159:  0]
    */
    event Claim(uint256 data0,uint256 data1,bytes20 indexed btcAddr,address indexed claimToAddr,address indexed referrerAddr);

    /*  StakeStart        (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  stakerAddr
        uint40   indexed  stakeId
        uint72            stakedHearts    -->  data0 [111: 40]
        uint72            stakeShares     -->  data0 [183:112]
        uint16            stakedDays      -->  data0 [199:184]
        bool              isAutoStake     -->  data0 [207:200]
    */
    event StakeStart(uint256 data0,address indexed stakerAddr,uint40 indexed stakeId);

    /*  StakeGoodAccounting(auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  stakerAddr
        uint40   indexed  stakeId
        uint72            stakedHearts    -->  data0 [111: 40]
        uint72            stakeShares     -->  data0 [183:112]
        uint72            payout          -->  data0 [255:184]
        uint72            penalty         -->  data1 [ 71:  0]
        address  indexed  senderAddr
    */
    event StakeGoodAccounting(uint256 data0,uint256 data1,address indexed stakerAddr,uint40 indexed stakeId,address indexed senderAddr);

    /*  StakeEnd          (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        address  indexed  stakerAddr
        uint40   indexed  stakeId
        uint72            stakedHearts    -->  data0 [111: 40]
        uint72            stakeShares     -->  data0 [183:112]
        uint72            payout          -->  data0 [255:184]
        uint72            penalty         -->  data1 [ 71:  0]
        uint16            servedDays      -->  data1 [ 87: 72]
        bool              prevUnlocked    -->  data1 [ 95: 88]
    */
    event StakeEnd(uint256 data0,uint256 data1,address indexed stakerAddr,uint40 indexed stakeId);

    /*  ShareRateChange   (auto-generated event)

        uint40            timestamp       -->  data0 [ 39:  0]
        uint40            shareRate       -->  data0 [ 79: 40]
        uint40   indexed  stakeId
    */
    event ShareRateChange(uint256 data0,uint40 indexed stakeId);

    /* Origin address */
    address internal constant ORIGIN_ADDR = 0x9A6a414D6F3497c05E3b1De90520765fA1E07c03;

    /* Flush address */
    // Owner of the contract recieve ETH 
    address payable internal constant FLUSH_ADDR = payable(0xDEC9f2793e3c17cd26eeFb21C4762fA5128E0399);

    uint8 public constant decimal = 8;
    uint256 private constant HEARTS_PER_MYNT = 10 ** uint256(decimal); // 1e8
 
    /* ERC20 Constructor */
    constructor() ERC20("MYNT", "MYNT") {}

    uint256 private constant MYNT_PER_BTC = 1e4; // TBD
    uint256 private constant SATOSHIS_PER_BTC = 1e8; // TBD
    uint256 internal constant HEARTS_PER_SATOSHI = HEARTS_PER_MYNT / SATOSHIS_PER_BTC * MYNT_PER_BTC;  // 1e4 = 10,000 // TBD

    /* Time of contract launch (2023-12-03T00:00:00Z) */
    uint256 internal constant LAUNCH_TIME = 1694676807; // e.g Frid, 20 Dec 2023 20:00:00 GMT+0000

    /* Size of a Hearts or Shares uint */
    uint256 internal constant HEART_UINT_SIZE = 72; 

    /* Start of claim phase */
    uint256 internal constant PRE_CLAIM_DAYS = 1;
    uint256 internal constant CLAIM_PHASE_START_DAY = PRE_CLAIM_DAYS ;

    /* Length of claim phase */
    uint256 private constant CLAIM_PHASE_WEEKS = 50;
    uint256 internal constant CLAIM_PHASE_DAYS = CLAIM_PHASE_WEEKS * 7; // 11.5068 months
    // uint256 internal constant CLAIM_PHASE_DAYS = CLAIM_PHASE_WEEKS * 7 * 24 * 60; // Weeks * Days * Hours * Minutes

    /* End of claim phase */
    uint256 internal constant CLAIM_PHASE_END_DAY = CLAIM_PHASE_START_DAY + CLAIM_PHASE_DAYS; // 351 days= 11.5397 months

    /* Number of words to hold 1 bit for each transform lobby day */
    uint256 internal constant XF_LOBBY_DAY_WORDS = (CLAIM_PHASE_END_DAY + 255) >> 8; // 606 >> 8
        
    /* BigPayDay */
    uint256 internal constant BIG_PAY_DAY = CLAIM_PHASE_END_DAY + 1; // 352

    /* Root hash of the UTXO Merkle tree */
    // bytes32 internal constant MERKLE_TREE_ROOT = 0x4e831acb4223b66de3b3d2e54a2edeefb0de3d7916e2886a4b134d9764d41bec;

    /* Size of a Satoshi claim uint in a Merkle leaf */
    // uint256 internal constant MERKLE_LEAF_SATOSHI_SIZE = 45;

    /* Zero-fill between BTC address and Satoshis in a Merkle leaf */
    // uint256 internal constant MERKLE_LEAF_FILL_SIZE = 256 - 160 - MERKLE_LEAF_SATOSHI_SIZE;
    // uint256 internal constant MERKLE_LEAF_FILL_BASE = (1 << MERKLE_LEAF_FILL_SIZE) - 1;
    // uint256 internal constant MERKLE_LEAF_FILL_MASK = MERKLE_LEAF_FILL_BASE << MERKLE_LEAF_SATOSHI_SIZE;

    /* Size of a Satoshi total uint */
    uint256 internal constant SATOSHI_UINT_SIZE = 51;
    uint256 internal constant SATOSHI_UINT_MASK = (1 << SATOSHI_UINT_SIZE) - 1;

    /* Total Satoshis from all BTC addresses in UTXO snapshot */
    uint256 internal constant FULL_SATOSHIS_TOTAL = 1807766732160668;

    /* Total Satoshis from supported BTC addresses in UTXO snapshot after applying Silly Whale */
    uint256 internal constant CLAIMABLE_SATOSHIS_TOTAL = 910087996911001;

    /* Number of claimable BTC addresses in UTXO snapshot */
    uint256 internal constant CLAIMABLE_BTC_ADDR_COUNT = 27997742;

    /* Largest BTC address Satoshis balance in UTXO snapshot (sanity check) */
    // uint256 internal constant MAX_BTC_ADDR_BALANCE_SATOSHIS = 25550214098481;

    /* Percentage of total claimed Hearts that will be auto-staked from a claim */
    // uint256 internal constant AUTO_STAKE_CLAIM_PERCENT = 90;

    /* Stake timing parameters */
    uint256 internal constant MIN_STAKE_DAYS = 1;
    // uint256 internal constant MIN_AUTO_STAKE_DAYS = 350;

    uint256 internal constant MAX_STAKE_DAYS = 5555; // Approx 15 years

    uint256 internal constant EARLY_PENALTY_MIN_DAYS = 90;

    uint256 private constant LATE_PENALTY_GRACE_WEEKS = 2;
    uint256 internal constant LATE_PENALTY_GRACE_DAYS = LATE_PENALTY_GRACE_WEEKS * 7; // 14

    uint256 private constant LATE_PENALTY_SCALE_WEEKS = 100;
    uint256 internal constant LATE_PENALTY_SCALE_DAYS = LATE_PENALTY_SCALE_WEEKS * 7; // 700 days = 1.91781 year

    /* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusHearts() */
    uint256 private constant LPB_BONUS_PERCENT = 20;
    uint256 private constant LPB_BONUS_MAX_PERCENT = 200;
    uint256 internal constant LPB = 364 * 100 / LPB_BONUS_PERCENT; // = 1820
    uint256 internal constant LPB_MAX_DAYS = LPB * LPB_BONUS_MAX_PERCENT / 100; // = 3640 days = 119.6711 months = 9.972603 years

    /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusHearts() */
    uint256 private constant BPB_BONUS_PERCENT = 10;
    uint256 private constant BPB_MAX_MYNT = 150 * 1e6; 
    uint256 internal constant BPB_MAX_HEARTS = BPB_MAX_MYNT * HEARTS_PER_MYNT; // = 1e15
    uint256 internal constant BPB = BPB_MAX_HEARTS * 100 / BPB_BONUS_PERCENT; // = 1e16

    /* Share rate is scaled to increase precision */
    uint256 internal constant SHARE_RATE_SCALE = 1e5;

    /* Share rate max (after scaling) */
    uint256 internal constant SHARE_RATE_UINT_SIZE = 40;
    uint256 internal constant SHARE_RATE_MAX = (1 << SHARE_RATE_UINT_SIZE) - 1;

    /* Constants for preparing the claim message text */
    // uint8 internal constant ETH_ADDRESS_BYTE_LEN = 20;
    // uint8 internal constant ETH_ADDRESS_MYNT_LEN = ETH_ADDRESS_BYTE_LEN * 2;

    // uint8 internal constant CLAIM_PARAM_HASH_BYTE_LEN = 12;
    // uint8 internal constant CLAIM_PARAM_HASH_MYNT_LEN = CLAIM_PARAM_HASH_BYTE_LEN * 2;

    // uint8 internal constant BITCOIN_SIG_PREFIX_LEN = 24;
    // bytes24 internal constant BITCOIN_SIG_PREFIX_STR = "Bitcoin Signed Message:\n";

    // bytes internal constant STD_CLAIM_PREFIX_STR = "Claim_MYNT_to_0x";
    // bytes internal constant OLD_CLAIM_PREFIX_STR = "Claim_BitcoinMYNT_to_0x";

    // bytes16 internal constant MYNT_DIGITS = "0123456789abcdef";

    /* Claim flags passed to btcAddressClaim()  */
    // uint8 internal constant CLAIM_FLAG_MSG_PREFIX_OLD = 1 << 0;
    // uint8 internal constant CLAIM_FLAG_BTC_ADDR_COMPRESSED = 1 << 1;
    // uint8 internal constant CLAIM_FLAG_BTC_ADDR_P2WPKH_IN_P2SH = 1 << 2;
    // uint8 internal constant CLAIM_FLAG_BTC_ADDR_BECH32 = 1 << 3;
    // uint8 internal constant CLAIM_FLAG_ETH_ADDR_LOWERCASE = 1 << 4;


    /* Globals expanded for memory (except _latestStakeId) and compact for storage */
    struct GlobalsCache {
        // 1
        uint256 _lockedHeartsTotal;
        uint256 _nextStakeSharesTotal;
        uint256 _shareRate;
        uint256 _stakePenaltyTotal;
        // 2
        uint256 _dailyDataCount;
        uint256 _stakeSharesTotal;
        uint40 _latestStakeId;

        uint256 _unclaimedSatoshisTotal;
        uint256 _claimedSatoshisTotal;
        uint256 _claimedBtcAddrCount;

        uint256 _currentDay;
    }


    struct GlobalsStore {
        // 1
        uint72 lockedHeartsTotal;
        uint72 nextStakeSharesTotal;
        uint40 shareRate;
        uint72 stakePenaltyTotal;
        // 2
        uint16 dailyDataCount;
        uint72 stakeSharesTotal;
        uint40 latestStakeId;
        uint128 claimStats;
    }

    GlobalsStore public globals;

    /* Claimed BTC addresses */
    // mapping(bytes20 => bool) public btcAddressClaims;

    /* Daily data */
    struct DailyDataStore {
        uint72 dayPayoutTotal;
        uint72 dayStakeSharesTotal;
        uint56 dayUnclaimedSatoshisTotal;
    }

    mapping(uint256 => DailyDataStore) public dailyData;

    /* Stake expanded for memory (except _stakeId) and compact for storage */
    struct StakeCache {
        uint40 _stakeId;
        uint256 _stakedHearts;
        uint256 _stakeShares;
        uint256 _lockedDay;
        uint256 _stakedDays;
        uint256 _unlockedDay;

        // bool _isAutoStake;
    }

    struct StakeStore {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }

    mapping(address => StakeStore[]) public stakeLists;

    /* Temporary state for calculating daily rounds */
    struct DailyRoundState {
        uint256 _allocSupplyCached;
        uint256 _mintOriginBatch;
        uint256 _payoutTotal;
    }

    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }

    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }

    mapping(uint256 => uint256) public xfLobby;
    mapping(uint256 => mapping(address => XfLobbyQueueStore)) public xfLobbyMembers;

    /**
     * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param beforeDay Only update days before this day number (optional; 0 for current day)
     */
    function dailyDataUpdate(uint256 beforeDay) external
    {
        GlobalsCache memory g;
        GlobalsCache memory gSnapshot;
        _globalsLoad(g, gSnapshot);

        /* Skip pre-claim period */
        require(g._currentDay > CLAIM_PHASE_START_DAY, "MYNT: Too early");

        if (beforeDay != 0) {
            require(beforeDay <= g._currentDay, "MYNT: beforeDay cannot be in the future");

            _dailyDataUpdate(g, beforeDay, false);
        } else {
            /* Default to updating before current day */
            _dailyDataUpdate(g, g._currentDay, false);
        }

        _globalsSync(g, gSnapshot);
    }

    /*
     * @dev PUBLIC FACING: External helper to return multiple values of daily data with
     * a single call. Ugly implementation due to limitations of the standard ABI encoder.
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return Fixed array of packed values
     */

     /* This function is calculating the daily payout of just one day and all the days within range.
        Depends on the Begin Day(E.g Launch day or Staking day) & End Day (very next day of begin day) 
        
        It returns the packed value of array data.
        The data includes the number of unclaimed satoshis, 
        the number of stake shares, and the number of payouts. */
    function dailyDataRange(uint256 beginDay, uint256 endDay)external view returns (uint256[] memory list)
    {
        require(beginDay < endDay && endDay <= globals.dailyDataCount, "MYNT: range invalid");

        list = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        uint256 v;
        do {
            v = uint256(dailyData[src].dayUnclaimedSatoshisTotal) << (HEART_UINT_SIZE * 2); // TBD
            v |= uint256(dailyData[src].dayStakeSharesTotal) << HEART_UINT_SIZE;
            v |= uint256(dailyData[src].dayPayoutTotal);

            list[dst++] = v;
        } while (++src < endDay);

        return list;
    }

    /**
     * @dev PUBLIC FACING: External helper to return most global info with a single call.
     * Ugly implementation due to limitations of the standard ABI encoder.
     * @return Fixed array of values
     */
    function globalInfo() external view returns (uint256[13] memory)
    {
        uint256 _claimedBtcAddrCount;
        uint256 _claimedSatoshisTotal;
        uint256 _unclaimedSatoshisTotal;

        (_claimedBtcAddrCount, _claimedSatoshisTotal, _unclaimedSatoshisTotal) = _claimStatsDecode(
            globals.claimStats
        );

        return [
            // 1
            globals.lockedHeartsTotal,
            globals.nextStakeSharesTotal,
            globals.shareRate,
            globals.stakePenaltyTotal,
            // 2
            globals.dailyDataCount,
            globals.stakeSharesTotal,
            globals.latestStakeId,
            _unclaimedSatoshisTotal,
            _claimedSatoshisTotal,
            _claimedBtcAddrCount,
            //
            block.timestamp,
            totalSupply(),
            xfLobby[_currentDay()]
        ];
    }


    /**
     * @dev PUBLIC FACING: ERC20 totalSupply() is the circulating supply and does not include any
     * staked Hearts. allocatedSupply() includes both.
     * @return Allocated Supply in Hearts
     */
    function allocatedSupply() external view returns (uint256)
    {
        return totalSupply() + globals.lockedHeartsTotal;
    }

    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zebool _isAutoStake;ro-based)
     */
    function currentDay() external view returns (uint256)
    {
        return _currentDay();
    }

    /* It means that approximately 1094 minutes have passed since the contract's launch. */
    function _currentDay() internal view returns (uint256)
    {
        return (block.timestamp - LAUNCH_TIME) / 1 minutes;
    }

    function _dailyDataUpdateAuto(GlobalsCache memory g) internal
    {
        _dailyDataUpdate(g, g._currentDay, true);
    }

    /* Function is used to read the global state variables. */
    function _globalsLoad(GlobalsCache memory g, GlobalsCache memory gSnapshot) internal view
    {
        // 1
        g._lockedHeartsTotal = globals.lockedHeartsTotal;
        g._nextStakeSharesTotal = globals.nextStakeSharesTotal;
        g._shareRate = globals.shareRate;
        g._stakePenaltyTotal = globals.stakePenaltyTotal;
        // 2
        g._dailyDataCount = globals.dailyDataCount;
        g._stakeSharesTotal = globals.stakeSharesTotal;
        g._latestStakeId = globals.latestStakeId;
        (g._claimedBtcAddrCount, g._claimedSatoshisTotal, g._unclaimedSatoshisTotal) = _claimStatsDecode(
            globals.claimStats
        );
        
        g._currentDay = _currentDay();

        _globalsCacheSnapshot(g, gSnapshot);
    }


    /* Function is used to update the global state variables by restoring the values from a cache (GlobalsCache structure). */
    function _globalsCacheSnapshot(GlobalsCache memory g, GlobalsCache memory gSnapshot) internal pure
    {
        // 1
        gSnapshot._lockedHeartsTotal = g._lockedHeartsTotal;
        gSnapshot._nextStakeSharesTotal = g._nextStakeSharesTotal;
        gSnapshot._shareRate = g._shareRate;
        gSnapshot._stakePenaltyTotal = g._stakePenaltyTotal;
        // 2
        gSnapshot._dailyDataCount = g._dailyDataCount;
        gSnapshot._stakeSharesTotal = g._stakeSharesTotal;
        gSnapshot._latestStakeId = g._latestStakeId;
        gSnapshot._unclaimedSatoshisTotal = g._unclaimedSatoshisTotal;
        gSnapshot._claimedSatoshisTotal = g._claimedSatoshisTotal;
        gSnapshot._claimedBtcAddrCount = g._claimedBtcAddrCount;
    }

    /*
    This function compares the current state of certain global variables with their snapshot (previous) state.
    If there are any differences detected in specific variables related to locked hearts, stake shares,
    share rate, and stake penalties, the function updates these variables in the main contract state.

    Similarly, if differences are found in variables related to daily data count, stake shares total,
    latest stake ID, and various statistics related to claimed and unclaimed satoshis and BTC addresses,
    the function updates these variables in the main contract state.

    In summary, this function keeps the main contract's global variables synchronized with their corresponding 
    snapshot values, ensuring that changes in these variables are accurately reflected in the contract's state.
    */

    function _globalsSync(GlobalsCache memory g, GlobalsCache memory gSnapshot) internal
    {
        if (g._lockedHeartsTotal != gSnapshot._lockedHeartsTotal
            || g._nextStakeSharesTotal != gSnapshot._nextStakeSharesTotal
            || g._shareRate != gSnapshot._shareRate
            || g._stakePenaltyTotal != gSnapshot._stakePenaltyTotal) {
            // 1
            globals.lockedHeartsTotal = uint72(g._lockedHeartsTotal);
            globals.nextStakeSharesTotal = uint72(g._nextStakeSharesTotal);
            globals.shareRate = uint40(g._shareRate);
            globals.stakePenaltyTotal = uint72(g._stakePenaltyTotal);
        }
        if (g._dailyDataCount != gSnapshot._dailyDataCount
            || g._stakeSharesTotal != gSnapshot._stakeSharesTotal
            || g._latestStakeId != gSnapshot._latestStakeId
            || g._unclaimedSatoshisTotal != gSnapshot._unclaimedSatoshisTotal
            || g._claimedSatoshisTotal != gSnapshot._claimedSatoshisTotal
            || g._claimedBtcAddrCount != gSnapshot._claimedBtcAddrCount
            ) {
            // 2
            globals.dailyDataCount = uint16(g._dailyDataCount);
            globals.stakeSharesTotal = uint72(g._stakeSharesTotal);
            globals.latestStakeId = g._latestStakeId;
            globals.claimStats = _claimStatsEncode(
                g._claimedBtcAddrCount,
                g._claimedSatoshisTotal,
                g._unclaimedSatoshisTotal
            );
        }
    }

    /*This function is used to load data from a stake in storage into a memory structure. It's used in the stakeEnd function*/
    function _stakeLoad(StakeStore storage stRef, uint40 stakeIdParam, StakeCache memory st) internal view
    {
        /* Ensure caller's stakeIndex is still current */
        require(stakeIdParam == stRef.stakeId, "MYNT: stakeIdParam not in stake");

        st._stakeId = stRef.stakeId;
        st._stakedHearts = stRef.stakedHearts;
        st._stakeShares = stRef.stakeShares;
        st._lockedDay = stRef.lockedDay;
        st._stakedDays = stRef.stakedDays;
        st._unlockedDay = stRef.unlockedDay;
        // st._isAutoStake = stRef.isAutoStake;
    }

    function _stakeUpdate(StakeStore storage stRef, StakeCache memory st) internal
    {
        stRef.stakeId = st._stakeId;
        stRef.stakedHearts = uint72(st._stakedHearts);
        stRef.stakeShares = uint72(st._stakeShares);
        stRef.lockedDay = uint16(st._lockedDay);
        stRef.stakedDays = uint16(st._stakedDays);
        stRef.unlockedDay = uint16(st._unlockedDay);
        // stRef.isAutoStake = st._isAutoStake;
    }

    /* This function adds a new stake to a list of stakes. */
    function _stakeAdd(StakeStore[] storage stakeListRef,uint40 newStakeId,uint256 newStakedHearts,uint256 newStakeShares,uint256 newLockedDay,uint256 newStakedDays,bool newAutoStake) internal
    {
        stakeListRef.push(
            StakeStore(
                newStakeId,
                uint72(newStakedHearts),
                uint72(newStakeShares),
                uint16(newLockedDay),
                uint16(newStakedDays),
                uint16(0), // unlockedDay
                newAutoStake
            )
        );
    }

    /**
     * @dev Efficiently delete from an unordered array by moving the last element
     * to the "hole" and reducing the array length. Can change the order of the list
     * and invalidate previously held indexes.
     * @notice stakeListRef length and stakeIndex are already ensured valid in stakeEnd()
     * @param stakeListRef Reference to stakeLists[stakerAddr] array in storage
     * @param stakeIndex Index of the element to delete
     */
    function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex) internal
    {
        uint256 lastIndex = stakeListRef.length - 1;

        /* Skip the copy if element to be removed is already the last element */
        if (stakeIndex != lastIndex) {
            /* Copy last element to the requested element's "hole" */
            stakeListRef[stakeIndex] = stakeListRef[lastIndex];
        }

        /*
            Reduce the array length now that the array is contiguous.
            Surprisingly, 'pop()' uses less gas than 'stakeListRef.length = lastIndex'
        */
        stakeListRef.pop();
    }

    function _claimStatsEncode(uint256 _claimedBtcAddrCount, uint256 _claimedSatoshisTotal, uint256 _unclaimedSatoshisTotal) internal pure returns (uint128)
    {
        uint256 v = _claimedBtcAddrCount << (SATOSHI_UINT_SIZE * 2);
        v |= _claimedSatoshisTotal << SATOSHI_UINT_SIZE;
        v |= _unclaimedSatoshisTotal;

        return uint128(v);
    }

    function _claimStatsDecode(uint128 v) internal pure returns (uint256 _claimedBtcAddrCount, uint256 _claimedSatoshisTotal, uint256 _unclaimedSatoshisTotal)
    {
        _claimedBtcAddrCount = v >> (SATOSHI_UINT_SIZE * 2);
        _claimedSatoshisTotal = (v >> SATOSHI_UINT_SIZE) & SATOSHI_UINT_MASK;
        _unclaimedSatoshisTotal = v & SATOSHI_UINT_MASK;

        return (_claimedBtcAddrCount, _claimedSatoshisTotal, _unclaimedSatoshisTotal);
    }

    /*
     * @dev Estimate the stake payout for an incomplete day
     * @param g Cache of stored globals
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param day Day to calculate bonuses for
     * @return Payout in Hearts
     */

     /*
      It calculates the total payout based on the cached daily round data,
       the stake shares, and any applicable bonuses or rewards for the 
       given day. If it's the "BigPayDay," additional rewards are added 
       based on unclaimed satoshis and adoption bonuses.
       The final calculated payout is returned as the result.
     */
    function _estimatePayoutRewardsDay(GlobalsCache memory g, uint256 stakeSharesParam, uint256 day) internal view returns (uint256 payout)
    {
        /* Prevent updating state for this estimation */
        GlobalsCache memory gTmp;
        _globalsCacheSnapshot(g, gTmp);

        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply() + g._lockedHeartsTotal;

        _dailyRoundCalc(gTmp, rs, day);

        /* Stake is no longer locked so it must be added to total as if it were */
        gTmp._stakeSharesTotal += stakeSharesParam;

        payout = rs._payoutTotal * stakeSharesParam / gTmp._stakeSharesTotal;

        if (day == BIG_PAY_DAY) {
            uint256 bigPaySlice = gTmp._unclaimedSatoshisTotal * HEARTS_PER_SATOSHI * stakeSharesParam
                / gTmp._stakeSharesTotal;
            payout += bigPaySlice + _calcAdoptionBonus(gTmp, bigPaySlice);
        }

        return payout;
    }

    function _calcAdoptionBonus(GlobalsCache memory g, uint256 payout) internal pure returns (uint256)
    {
        /*
            VIRAL REWARDS: Add adoption percentage bonus to payout

            viral = payout * (claimedBtcAddrCount / CLAIMABLE_BTC_ADDR_COUNT)
        */
        uint256 viral = payout * g._claimedBtcAddrCount / CLAIMABLE_BTC_ADDR_COUNT;

        /*
            CRIT MASS REWARDS: Add adoption percentage bonus to payout

            crit  = payout * (claimedSatoshisTotal / CLAIMABLE_SATOSHIS_TOTAL)
        */
        uint256 crit = payout * g._claimedSatoshisTotal / CLAIMABLE_SATOSHIS_TOTAL;

        return viral + crit;
    }

    /* The calculation involves estimating the daily interest rate based on an inflation rate
     of 3.69% per year AND to calculate the daily payout based on the total supply. */

     /* handles the core calculations, including estimating the daily payout, 
     calculating adoption bonuses, and considering stake penalties. */
    function _dailyRoundCalc(GlobalsCache memory g, DailyRoundState memory rs, uint256 day) private pure
    {
        /*
            Calculate payout round

            Inflation of 3.69% inflation per 364 days             (approx 1 year)
            dailyInterestRate   = exp(log(1 + 3.69%)  / 364) - 1
                                = exp(log(1 + 0.0369) / 364) - 1
                                = exp(log(1.0369) / 364) - 1
                                = 0.000099553011616349            (approx)

            payout  = allocSupply * dailyInterestRate
                    = allocSupply / (1 / dailyInterestRate)
                    = allocSupply / (1 / 0.000099553011616349)
                    = allocSupply / 10044.899534066692            (approx)
                    = allocSupply * 10000 / 100448995             (* 10000/10000 for int precision)
        */
        rs._payoutTotal = rs._allocSupplyCached * 10000 / 100448995;

        if (day < CLAIM_PHASE_END_DAY) { // 351
            uint256 bigPaySlice = g._unclaimedSatoshisTotal * HEARTS_PER_SATOSHI / CLAIM_PHASE_DAYS; // A portion of unclaimed satoshis is allocated to the day's payout (bigPaySlice).

            uint256 originBonus = bigPaySlice + _calcAdoptionBonus(g, rs._payoutTotal + bigPaySlice);
            rs._mintOriginBatch += originBonus;
            rs._allocSupplyCached += originBonus;

            rs._payoutTotal += _calcAdoptionBonus(g, rs._payoutTotal);
        }

        // If there's a stake penalty (g._stakePenaltyTotal), it's added to the rs._payoutTotal, and the global _stakePenaltyTotal is reset to zero.
        if (g._stakePenaltyTotal != 0) {
            rs._payoutTotal += g._stakePenaltyTotal;
            g._stakePenaltyTotal = 0;
        }
    }

    function _dailyRoundCalcAndStore(GlobalsCache memory g, DailyRoundState memory rs, uint256 day) private
    {
        _dailyRoundCalc(g, rs, day);

        dailyData[day].dayPayoutTotal = uint72(rs._payoutTotal);
        dailyData[day].dayStakeSharesTotal = uint72(g._stakeSharesTotal);
        dailyData[day].dayUnclaimedSatoshisTotal = uint56(g._unclaimedSatoshisTotal);
    }

    function _dailyDataUpdate(GlobalsCache memory g, uint256 beforeDay, bool isAutoUpdate) private
    {
        if (g._dailyDataCount >= beforeDay) {
            /* Already up-to-date */
            return; // so Returns Early means no update is needed.
        }

        /* If the daily data is not up-to-date, a new DailyRoundState memory variable rs is created to store the updated state for the day. */
        DailyRoundState memory rs;
        rs._allocSupplyCached = totalSupply() + g._lockedHeartsTotal;

        uint256 day = g._dailyDataCount;

        _dailyRoundCalcAndStore(g, rs, day);

        /* Stakes started during this day are added to the total the next day */
        /*It's checked whether any stakes were started on the current day (g._nextStakeSharesTotal != 0).
         If so, the stake shares from the current day are added to the total stake shares, and the current
          day's stake shares are reset to zero.*/ 
        if (g._nextStakeSharesTotal != 0) {
            g._stakeSharesTotal += g._nextStakeSharesTotal;
            g._nextStakeSharesTotal = 0;
        }

        // A loop is initiated using a while statement, where current day is incremented in each iteration until it reaches the beforeDay(target day).
        // _dailyRoundCalcAndStore is called again to calculate and store the daily round's data for each day between the current day and the beforeDay.
        while (++day < beforeDay) {
            _dailyRoundCalcAndStore(g, rs, day);
        }

        _emitDailyDataUpdate(g._dailyDataCount, day, isAutoUpdate);
        g._dailyDataCount = day; // The global state variable g._dailyDataCount is updated to match the day, marking the data as updated.

        /*
        Finally, it's checked if there was a non-zero value for rs._mintOriginBatch. If so, it means that 
        there were some tokens to be minted for the origin address. 
        The _mint function is then called to mint these tokens and allocate them to the origin address
        */
        if (rs._mintOriginBatch != 0) {
            _mint(ORIGIN_ADDR, rs._mintOriginBatch);
        }
    }

    // emit an event indicating that the daily data has been updated. 
    function _emitDailyDataUpdate(uint256 beginDay, uint256 endDay, bool isAutoUpdate) private
    {
        emit DailyDataUpdate( // (auto-generated event)
            uint256(uint40(block.timestamp))
                | (uint256(uint16(beginDay)) << 40)
                | (uint256(uint16(endDay)) << 56)
                | (isAutoUpdate ? (1 << 72) : 0),
            msg.sender
        );
    }
}