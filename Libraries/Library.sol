pragma solidity ^0.8.12;

interface Vesting {
    struct PoolInfo {
        string poolName;
        uint256 startDate;
        uint256 vestingTime; //in seconds
        address tokenAddress;
        uint256 totalVesting;
        address[] usersAddresses;
        uint256[] usersAlloc;
    }

    struct UserInfo {
        uint256 allocation; // VestingAllocation
        uint256 claimedAmount; //calimableAmnt
        uint256 remainingToBeClaimable; // VestingAllocationCalculated
        uint256 lastWithdrawal;
        uint256 releaseRatePerSec;
    }

    struct CliffPoolInfo {
        string poolName;
        uint256 startDate; //
        uint256 vestingTime;
        uint256 cliffVestingTime;
        uint256 nonCliffVestingTime; //
        uint256 cliffPeriod;
        address tokenAddress;
        uint256 totalVestedTokens; //
        uint256 cliffPercentage;
        address[] usersAddresses;
        uint256[] usersAlloc;
    }

    struct UserCliffInfo {
        uint256 allocation; // VestingAllocation
        uint256 cliffAlloc;
        uint256 claimedAmnt; //calimableAmnt
        uint256 tokensReleaseTime; //tokensRelaseToDate
        uint256 remainingToBeClaimableCliff;
        uint256 cliffReleaseRatePerSec;
        uint256 cliffLastWithdrawal;
    }
    struct UserNonCliffInfo {
        uint256 allocation; // VestingAllocation
        uint256 nonCliffAlloc;
        uint256 claimedAmnt; //calimableAmnt
        uint256 tokensReleaseTime; //tokensRelaseToDate
        uint256 remainingToBeClaimableNonCliff;
        uint256 nonCliffReleaseRatePerSec;
        uint256 nonCliffLastWithdrawal;
    }
}
