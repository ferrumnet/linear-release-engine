pragma solidity ^0.8.12;
 
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Libraries/Library.sol";

contract VestingHarvestContarct is AccessControl, ReentrancyGuard {

    
    uint256 public vestingPoolSize = 0;
    string public vestingContractName;

    constructor(string memory _vestingName){
     vestingContractName = _vestingName;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VESTER_ROLE, msg.sender);

    }

    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");


        modifier onlyVester() {
        require(hasRole(VESTER_ROLE, _msgSender()), "Not a manager role");
        _;
    }   

    // Mappings
    mapping(uint256 => bool) public cliff;
    mapping(uint256 => Vesting.PoolInfo) public poolInfo;
    mapping(uint256 => Vesting.CliffPoolInfo) public cliffPoolInfo;
    mapping(uint256 => mapping(address =>Vesting.UserInfo)) public userInfo;
    mapping(uint256 => mapping(address =>Vesting.UserClifInfo)) public userClifInfo;
    mapping(uint256 => mapping(address =>Vesting.UserNonClifInfo)) public userNonClifInfo;


    // events
    event AddVesting(
        uint256 poolId,
        string  poolName,
        uint256 startDate,
        uint256 vestingTime, 
        uint256 lockTime, 
        uint256 releaseRate, 
        address tokenAddress,
        uint256 totalVesting,
        address[]  usersAddresses,
        uint256[]  usersAlloc);

    event CliffAddVesting(
        uint256 poolId,
        string  poolName,
        uint256 startDate, 
        uint256 vestingTime,
        uint256 cliffVestingTime,
        uint256 nonCliffVestingTime, 
        uint256 cliffPeriod,
        address tokenAddress,
        uint256 totalVestedTokens,  
        uint256 cliffPercentage,
        address[]  usersAddresses,
        uint256[]  usersAlloc);

    event Claim(uint256 poolId, uint256 claimed, address beneficiary, uint256 remaining);
    event CliffClaim(uint256 poolId, uint256 claimed, address beneficiary, uint256 remaining);
    event NonCliffClaim(uint256 poolId, uint256 claimed, address beneficiary, uint256 remaining);




    //function type payable
    // This function is used to register vesting which is without cliff
    function addVesting(string memory _poolName, uint256 _vestingTime, uint256 _lockTime,address _tokenAddress,uint256 _totalVesting, address[] memory _usersAddresses,uint256[] memory _userAlloc) public onlyVester nonReentrant()  {
         require(_vestingTime > block.timestamp,"Vesting: Invalid Vesting Time");
         require(_vestingTime >= _lockTime,"Vesting: Lock time must be lesser than vesting time");
         uint256 releaseRate;
         uint256 totalvesting;                                                                                                                                                                                                                                                                          
          for(uint256 i=0; i<_usersAddresses.length;i++)
         {  
             totalvesting = totalvesting + _userAlloc[i];

        require(_totalVesting >= _userAlloc[i],"Vesting: Total Vesting is Invalid");
        uint256 releaseRate = SafeMath.div(_userAlloc[i] ,(SafeMath.sub(_vestingTime,_lockTime)));
        poolInfo[vestingPoolSize] = Vesting.PoolInfo(_poolName, block.timestamp,_vestingTime,_lockTime,_tokenAddress,_totalVesting, _usersAddresses,_userAlloc);
        userInfo[vestingPoolSize][_usersAddresses[i]] = Vesting.UserInfo(_userAlloc[i],0,_lockTime,_userAlloc[i],_lockTime,SafeMath.div(_userAlloc[i],(SafeMath.sub(_vestingTime,_lockTime))));
         } 
        require(_totalVesting == totalvesting,"Vesting: Total Vesting is Invalid");

        IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),_totalVesting);
        cliff[vestingPoolSize] = false;
        emit AddVesting(vestingPoolSize,_poolName,block.timestamp,_vestingTime, _lockTime, releaseRate, _tokenAddress,_totalVesting,_usersAddresses,_userAlloc);
        vestingPoolSize = vestingPoolSize + 1;
  
        

     } 

    //  for internal use to get the registerd users and their allocated tokens
    function poolInfoArrays(uint256 poolIndex) internal view returns (uint256[] memory,address[] memory) {
        Vesting.PoolInfo memory Info = poolInfo[poolIndex];
        return (Info.usersAlloc,Info.usersAddresses);
    }

    // read only no gas required
    // to check how many tokens are claimable for the specific individual in a specifc pool
    function claimable(uint256 _poolId, address _user) public view returns(uint256,uint256,uint256){
        uint256 claimable;
        uint256 secondDiff;
        uint256 releaseRate;
        
        Vesting.UserInfo memory info = userInfo[_poolId][_user];
        require(info.allocation > 0,"Allocation: You Don't have allocation in this pool");
        // require(poolInfo[_poolId].lockTime < block.timestamp,"Invalid Withdrarl: You can't withdraw before release date");

        releaseRate =  info.releaseRatePerSec;
       if (poolInfo[_poolId].lockTime < block.timestamp){
       
        if(poolInfo[_poolId].vestingTime < block.timestamp ){

        claimable = info.remainingToBeClaimable;
         }

         else if(poolInfo[_poolId].vestingTime > block.timestamp){
         claimable = SafeMath.mul(SafeMath.sub(block.timestamp , info.lastWithdrawl ) , releaseRate);

       }}
      else{
               claimable = 0;
           }
         return (claimable,secondDiff,releaseRate);
    }

    // to claim the claimables 
    // funciton type payable
    function claim(uint256 _poolId) public nonReentrant() {
       
        (uint256 transferAble,uint256 secDiff, uint256 releaseRate) = claimable(_poolId,_msgSender());
        IERC20(poolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferAble);
         Vesting.UserInfo memory info = userInfo[_poolId][_msgSender()];
        require(block.timestamp > poolInfo[_poolId].lockTime ,"Vesting: Lock Time Is Not Over Yet");
        require(transferAble > 0 ,"Vesting: Invalid TransferAble");
        uint256 claimed = SafeMath.add(info.claimedAmount , transferAble);
        userInfo[_poolId][_msgSender()] = Vesting.UserInfo(info.allocation, claimed, info.tokensRelaseTime,SafeMath.sub(info.allocation,claimed),block.timestamp, info.releaseRatePerSec );
        emit Claim(_poolId,transferAble,_msgSender(),SafeMath.sub(info.allocation,claimed));
        

    }

    // function type payable
    // use to register vesting
    function addCliffVesting(string memory _poolName,uint256 _vestingTime, uint256 _cliffVestingTime,uint256 _cliffPeriod,address _tokenAddress,uint256 _totalVesting, uint256 _cliffPercentage,address[] memory _usersAddresses,uint256[] memory _userAlloc) public onlyVester nonReentrant(){
        require(_vestingTime > block.timestamp ,"Vesting: Vesting Time Must Be Greater Than Current Time");
        require(_vestingTime > _cliffPeriod ,"Vesting: Vesting Time Time Must Be Greater Than Cliff Period");
        require(_cliffVestingTime < _vestingTime,"Vesting: Cliff Vesting Time Must Be Lesser Than Vesting Time");
        require(_cliffVestingTime > _cliffPeriod,"Vesting: Cliff Vesting Time Must Be Greater Than Cliff Period");
        require(_cliffPercentage < 50,"Percentage:Percentage Should Be less Than  50%");

        uint256 nonClifVestingTime = SafeMath.add(SafeMath.sub(_vestingTime , _cliffVestingTime),_cliffPeriod);
        uint256 cliffToken =SafeMath.div(SafeMath.mul(_totalVesting,_cliffPercentage),100);
        uint256 totalVesting;
        for(uint256 i=0; i<_usersAddresses.length;i++)
         { 
            totalVesting = SafeMath.add(totalVesting,_userAlloc[i]);

            cliffPoolInfo[vestingPoolSize] = Vesting.CliffPoolInfo(_poolName, block.timestamp,_vestingTime,_cliffVestingTime,nonClifVestingTime,_cliffPeriod,_tokenAddress,_totalVesting,_cliffPercentage,_usersAddresses,_userAlloc);

            userClifInfo[vestingPoolSize][_usersAddresses[i]] = Vesting.UserClifInfo(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100),0,_cliffPeriod,SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100),SafeMath.div(SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100) ,SafeMath.sub(_cliffVestingTime,_cliffPeriod)),_cliffPeriod);
            userNonClifInfo[vestingPoolSize][_usersAddresses[i]] = Vesting.UserNonClifInfo(_userAlloc[i],SafeMath.sub(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),0,_cliffPeriod,SafeMath.sub(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),SafeMath.div(SafeMath.sub(_userAlloc[i],SafeMath.div( (SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),SafeMath.sub(nonClifVestingTime, _cliffPeriod)),_cliffPeriod);

        }
        require(_totalVesting == totalVesting,"Cliff Vesting: Total Vesting is Invalid");
        IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),_totalVesting);
        cliff[vestingPoolSize] = true;  
        
    emit  CliffAddVesting(vestingPoolSize,_poolName,block.timestamp,_vestingTime,_cliffVestingTime, nonClifVestingTime, _cliffPeriod,_tokenAddress,_totalVesting, _cliffPercentage,_usersAddresses,_userAlloc);

        vestingPoolSize = vestingPoolSize + 1;
          

    }


    // function type readOnly
    // This function is used to return cliffclaimables for the vesting tokens
    function cliffClaimable(uint256 _poolId,  address _user) public view returns(uint256,uint256,uint256){
        uint256 cliffClaimable;
        uint256 secondDiff;
        uint256 releaseRate;
        Vesting.UserClifInfo memory info = userClifInfo[_poolId][_user];
        require(info.allocation > 0,"Allocation: You Don't have allocation in this pool");

     if(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp ){

       if(cliffPoolInfo[_poolId].cliffVestingTime < block.timestamp ){
           cliffClaimable = info.remainingToBeClaimableCliff;

       }  
        else if( cliffPoolInfo[_poolId].cliffVestingTime > block.timestamp ){
               cliffClaimable = SafeMath.mul(SafeMath.sub( block.timestamp , info.cliffLastWithdrawl ) , info.cliffRealeaseRatePerSec);
              secondDiff =  SafeMath.sub( block.timestamp , info.cliffLastWithdrawl );
              releaseRate = info.cliffRealeaseRatePerSec;

         }
           
        }
           else cliffClaimable = 0;

         return (cliffClaimable,secondDiff,releaseRate);
    }


     // function type readOnly
    // This function is used to return nonCliffclaimables for the vesting tokens
    function nonCliffClaimable(uint256 _poolId, address _user) public view returns(uint256,uint256,uint256){
        uint256 nonCliffClaimable;
        uint256 secondDiff;
        uint256 releaseRate;
        Vesting.UserNonClifInfo memory info = userNonClifInfo[_poolId][_user];
        require(info.allocation > 0,"Allocation: You Don't have allocation in this pool");

       if(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp ){

          if(cliffPoolInfo[_poolId].nonCliffVestingTime < block.timestamp ){
              nonCliffClaimable = info.remainingToBeClaimableNonCliff;

          }
         else if(cliffPoolInfo[_poolId].nonCliffVestingTime > block.timestamp){
               nonCliffClaimable = SafeMath.mul(SafeMath.sub( block.timestamp , info.nonCliffLastWithdrawl ) , info.nonCliffRealeaseRatePerSec);
               secondDiff = SafeMath.sub( block.timestamp , info.nonCliffLastWithdrawl );
               releaseRate = info.nonCliffRealeaseRatePerSec;

        }
           
           }
  
           else nonCliffClaimable = 0;


         return (nonCliffClaimable,secondDiff,releaseRate);
    }

    // function type payable
    // Claim the cliff amount of the token
    function claimCliff(uint256 _poolId) public nonReentrant(){
        Vesting.UserClifInfo memory info = userClifInfo[_poolId][_msgSender()];
        require(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp, "Vesting: Cliff Period Is Not Over Yet");

         (uint256 transferAble,uint256 secondDiff, uint256 releaseRate) = cliffClaimable(_poolId,_msgSender());
        require(transferAble> 0 ,"Vesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferAble);
        uint256 claimed = SafeMath.add(transferAble,info.claimedAmnt );
        userClifInfo[_poolId][_msgSender()] = Vesting.UserClifInfo(info.allocation, info.cliffAlloc,claimed,info.tokensRelaseTime,SafeMath.sub(info.cliffAlloc,claimed),info.cliffRealeaseRatePerSec, block.timestamp );
           emit CliffClaim(_poolId,transferAble,_msgSender(),SafeMath.sub(info.cliffAlloc,claimed));

        }

    // function type payable
    // Claim the nonCliff amount of the token
    function claimNonCliff(uint256 _poolId) public nonReentrant() {
        Vesting.UserNonClifInfo memory info = userNonClifInfo[_poolId][_msgSender()];
        require(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp, "Vesting: Cliff Period Is Not Over Yet");

         (uint256 transferAble,uint256 secondDiff, uint256 releaseRate) = nonCliffClaimable(_poolId,_msgSender());
         uint256 claimed = SafeMath.add(transferAble,info.claimedAmnt );
        require(transferAble> 0 ,"Vesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferAble);
        userNonClifInfo[_poolId][_msgSender()] = Vesting.UserNonClifInfo(info.allocation, info.nonCliffAlloc,claimed ,info.tokensRelaseTime,SafeMath.sub(info.nonCliffAlloc,claimed),info.nonCliffRealeaseRatePerSec, block.timestamp );
        emit NonCliffClaim(_poolId,transferAble,_msgSender(),SafeMath.sub(info.nonCliffAlloc,claimed));

    }

}