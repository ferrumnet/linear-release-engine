pragma solidity ^0.8.12;


interface Vesting {


        struct PoolInfo {
          string  poolName;
          uint256 startDate;
          uint256 vestingTime; //in seconds
          uint256 lockTime; //time stamp
          uint256 releaseRate; 
        //   uint256 unlockDate; //onward in seconds
          address tokenAddress;
          uint256 totalVesting;
          address[]  usersAddresses;
          uint256[]  usersAlloc;
    }

    
        struct UserInfo{
        uint256 allocation;    // VestingAllocation
        uint256 claimableAmount; //calimableAmnt   
        uint256 tokensRelaseTime;                      //tokensRelaseToDate    
        uint256 remaining;  // VestingAllocationCalculated
        uint256 lastWithdrawl;
        // bool withdrawn;   //Vested tokens
        // bool tokenWithdrawn;    // only rewards
    }
        
struct CliffPoolInfo {
        
          string  poolName;
          uint256 startDate;  //
          uint256 vestingTime;
          uint256 cliffVestingTime;
          uint256 nonCliffVestingTime; // 
          uint256 cliffPeriod;
          address tokenAddress;
          uint256 totalVestedTokens;  //
          uint256 cliffPercentage;
          address[]  usersAddresses;
          uint256[]  usersAlloc;

    }

      struct UserClifInfo {
        uint256 allocation;    // VestingAllocation
        uint256 cliffAlloc;
        uint256 nonCliffAlloc;
        uint256 claimedAmnt; //calimableAmnt   
        uint256 tokensRelaseTime;                      //tokensRelaseToDate    
        uint256 remainingClaimableCliff; 
        uint256 remainingClaimableNonCliff;
        uint256 cliffRealeaseRatePerSec;
        uint256 nonCliffRealeaseRatePerSec;  
        uint256 cliffLastWithdrawl;
        uint256 nonCliffLastWithdrawl;

    }  

}

    