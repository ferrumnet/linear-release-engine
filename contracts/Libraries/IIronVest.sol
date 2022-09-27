// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library IIronVest {
    struct PoolInfo {
        string poolName;
        uint256 startTime;
        uint256 vestingEndTime; //in seconds
        address tokenAddress;
        uint256 totalVestedTokens;
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
        uint256 startTime; //
        uint256 vestingEndTime;
        uint256 cliffVestingEndTime;
        uint256 nonCliffVestingEndTime; //
        uint256 cliffPeriodEndTime;
        address tokenAddress;
        uint256 totalVestedTokens; //
        uint256 cliffLockPercentage10000;
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
