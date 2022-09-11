pragma solidity ^0.8.12;
 
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Libraries/Library.sol";

contract VestingHarvestContarct is Ownable, AccessControl{

    
    uint256 public vestingPoolSize = 0;
    string public vestingContractName;
    address public ownerAddress;

    constructor(string memory _vestingName){
     vestingContractName = _vestingName;
    //  require(_adminAddress != _msgSender() ,"admin cannot be deployer");
     ownerAddress =  _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VESTER_ROLE, msg.sender);

    }

    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");


        modifier onlyVester() {
        require(hasRole(VESTER_ROLE, _msgSender()), "Not a manager role");
        _;
    }   

    // Mappings
    mapping(address => bool) public cliff;
    mapping(uint256 => Vesting.PoolInfo) public poolInfo;
    mapping(uint256 => Vesting.CliffPoolInfo) public cliffPoolInfo;
    mapping(uint256 => mapping(address =>Vesting.UserInfo)) public userInfo;
    mapping(uint256 => mapping(address =>Vesting.UserClifInfo)) public userClifInfo;


    // events
    event AddVesting(
        string  poolName,
        uint256 startDate,
        uint256 vestingTime, 
        uint256 lockTime, 
        uint256 releaseRate, 
        address tokenAddress,
        uint256 totalVesting,
        address[]  usersAddresses,
        uint256[]  usersAlloc);

    event VestingUserInfo(  
        uint256 allocation,    // VestingAllocation
        uint256 claimableAmount, //calimableAmnt   
        uint256 tokensRelaseTime,                      //tokensRelaseToDate    
        uint256 remaining,  // VestingAllocationCalculated
        uint256 lastWithdrawl);

    event Claim(uint256 poolId, uint256 claimed);

    event CliffAddVesting(
        string  poolName,
        uint256 startDate,  //
        uint256 vestingTime,
        uint256 cliffVestingTime,
        uint256 nonCliffVestingTime, // 
        uint256 nonCliffReleaseRate,     //noncliff
        uint256 cliffReleaseRate,
        uint256 cliffPeriod,
        address tokenAddress,
        uint256 totalVestedTokens,  //
        uint256 cliffPercentage,
        address[]  usersAddresses,
        uint256[]  usersAlloc);

    event CliffuserInfo(uint256 allocation,    // VestingAllocation
        uint256 cliffAlloc,
        uint256 nonCliffAlloc,
        uint256 claimableAmnt, //calimableAmnt   
        uint256 tokensRelaseTime,                      //tokensRelaseToDate    
        uint256 remainingClaimableCliff, 
        uint256 remainingClaimableNonCliff, 
        uint256 cliffLastWithdrawl,
        uint256 nonCliffLastWithdrawl);

    event CliffClaim(uint256 poolId, uint256 Claimed);
    event NonCliffClaim(uint256 poolId, uint256 Claimed);




    //function type payable
    // This function is used to register vesting which is without cliff
    function addVesting(string memory _poolName, uint256 _vestingTime, uint256 _cliffPeriod,address _tokenAddress,uint256 _totalVesting, address[] memory _usersAddresses,uint[] memory _userAlloc) public onlyVester {
         require(_vestingTime > block.timestamp,"Vesting: Invalid Vesting Time");
         require(_vestingTime >= _cliffPeriod,"Vesting: Lock time must be lesser than vesting time");
          for(uint i=0; i<_usersAddresses.length;i++)
         { 
             

        require(_totalVesting == _userAlloc[i],"Vesting: Total Vesting is Invalid");
        uint256 releaseRate =SafeMath.div(_totalVesting ,(SafeMath.sub(_vestingTime,_cliffPeriod)));
        poolInfo[vestingPoolSize] = Vesting.PoolInfo(_poolName, block.timestamp,_vestingTime,_cliffPeriod,releaseRate,_tokenAddress,_totalVesting, _usersAddresses,_userAlloc);
        userInfo[vestingPoolSize][_usersAddresses[i]] = Vesting.UserInfo(_userAlloc[i],0,_cliffPeriod,_userAlloc[i],0);
         } 
        IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),_totalVesting);
        vestingPoolSize = vestingPoolSize + 1;
        cliff[_tokenAddress] = false;

     } 

    //  for internal use to get the registerd users and their allocated tokens
    function poolInfoArrays(uint256 poolIndex) internal view returns (uint256[] memory,address[] memory) {
        Vesting.PoolInfo memory Info = poolInfo[poolIndex];
        return (Info.usersAlloc,Info.usersAddresses);
    }

    // read only no gas required
    // to check how many tokens are claimable for the specific individual in a specifc pool
    function claimable(uint256 _poolId, address _user) public view returns(uint256){
        uint256 claimable;
        Vesting.UserInfo memory info = userInfo[_poolId][_user];
        require(info.allocation > 0,"Allocation: You Don't have allocation in this pool");
        require(poolInfo[_poolId].lockTime < block.timestamp,"Invalid Withdrarl: You can't withdraw before release date");

       uint256 releaseRate =  poolInfo[_poolId].releaseRate;
       if(info.remaining>0){

        if(info.lastWithdrawl == 0 ){
           
           claimable = SafeMath.mul((SafeMath.sub( block.timestamp,poolInfo[_poolId].lockTime )) , releaseRate);
           if(claimable > info.allocation){
               claimable = info.allocation;
           }

       }
         else if(info.lastWithdrawl != 0){
               claimable = SafeMath.mul(SafeMath.sub(block.timestamp , info.lastWithdrawl ) , releaseRate);

            if(claimable > info.allocation){
               claimable = info.allocation;
            }
           }
        
       }
           
      else{
               claimable = 0;
           }
         return claimable;
    }

    // to claim the claimables 
    // funciton type payable
    function claim(uint256 _poolId) public {
       
        uint256 transferable = claimable(_poolId,_msgSender());
        // require(transferable > 0 , "transferable must not be 0");
        IERC20(poolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferable);
        // IERC20(poolInfo[_poolId].tokenAddress).transfer(_msgSender(),10000000000);
         Vesting.UserInfo memory info = userInfo[_poolId][_msgSender()];
        userInfo[_poolId][_msgSender()] = Vesting.UserInfo(info.allocation, claimable(_poolId,_msgSender()), info.tokensRelaseTime,SafeMath.sub(info.allocation,claimable(_poolId,_msgSender()) ) , block.timestamp );

    }

    // function type payable
    // use to register vesting
    function addCliffVesting(string memory _poolName,uint256 _vestingTime, uint256 _cliffVestingTime,uint256 _cliffPeriod,address _tokenAddress,uint256 _totalVesting, uint256 _cliffPercentage,address[] memory _usersAddresses,uint[] memory _userAlloc) public onlyVester{
         require(_vestingTime > block.timestamp && _vestingTime > _cliffPeriod && _cliffPeriod > block.timestamp,"Vesting: Invalid Vesting or Cliff Time");
        //  require(_cliffVestingTime >= _cliffPeriod,"Vesting: Lock time must be lesser than vesting time");
        uint256 nonClifVestingTime = SafeMath.add(SafeMath.sub(_vestingTime , _cliffVestingTime),_cliffPeriod);
        
        uint256 cliffToken =SafeMath.div(SafeMath.mul(_totalVesting,_cliffPercentage),100);
        for(uint i=0; i<_usersAddresses.length;i++)
         { 

        require(_totalVesting >= _userAlloc[i],"Cliff Vesting: Total Vesting is Invalid");
        cliffPoolInfo[vestingPoolSize] = Vesting.CliffPoolInfo(_poolName, block.timestamp,_vestingTime,_cliffVestingTime,nonClifVestingTime,_cliffPeriod,_tokenAddress,_totalVesting,_cliffPercentage,_usersAddresses,_userAlloc);
        // uint256 usrcliffAlloc = SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100);
        // uint256 nonCliffAlloc = SafeMath.sub(_userAlloc[i],usrcliffAlloc);
        // uint256 userNCRR = SafeMath.div(nonCliffAlloc,SafeMath.sub(_vestingTime , nonClifVestingTime));
        userClifInfo[vestingPoolSize][_usersAddresses[i]] = Vesting.UserClifInfo(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100),SafeMath.sub(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),0,_cliffPeriod,SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100),SafeMath.sub(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),SafeMath.div(SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100) ,SafeMath.sub(_cliffVestingTime,_cliffPeriod)),SafeMath.div(SafeMath.sub(_userAlloc[i],SafeMath.div( (SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),SafeMath.sub(nonClifVestingTime, _cliffPeriod)),0,0);
         }
        IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),_totalVesting);

        vestingPoolSize = vestingPoolSize + 1;
        cliff[_tokenAddress] = true;    

    }


    // function type readOnly
    // This function is used to return cliffclaimables for the vesting tokens
    function cliffClaimable(uint256 _poolId,  address _user) public view returns(uint256){
        uint256 cliffClaimable;
        Vesting.UserClifInfo memory info = userClifInfo[_poolId][_user];
     if(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp ){

       if(cliffPoolInfo[_poolId].cliffVestingTime < block.timestamp ){
           cliffClaimable = info.remainingClaimableCliff;

       }  else if(info.cliffLastWithdrawl == 0 && cliffPoolInfo[_poolId].cliffVestingTime > block.timestamp ){
          cliffClaimable = SafeMath.mul(SafeMath.sub(block.timestamp , cliffPoolInfo[_poolId].cliffPeriod ) , info.cliffRealeaseRatePerSec);

       }
         else if(info.cliffLastWithdrawl != 0){
               cliffClaimable = SafeMath.mul(SafeMath.sub( block.timestamp , info.cliffLastWithdrawl ) , info.cliffRealeaseRatePerSec);

         }
         else if(block.timestamp > cliffPoolInfo[_poolId].cliffVestingTime ){
             cliffClaimable = info.remainingClaimableCliff;
             cliffClaimable = 3;
         }
           
        }
           else cliffClaimable = 0;

         return cliffClaimable;
    }


     // function type readOnly
    // This function is used to return nonCliffclaimables for the vesting tokens
    function nonCliffClaimable(uint256 _poolId, address _user) public view returns(uint256){
        uint256 nonCliffClaimable;
        Vesting.UserClifInfo memory info = userClifInfo[_poolId][_user];
       if(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp ){

          if(cliffPoolInfo[_poolId].nonCliffVestingTime < block.timestamp ){
              nonCliffClaimable = info.remainingClaimableNonCliff;

          }
          else if(info.nonCliffLastWithdrawl == 0 && cliffPoolInfo[_poolId].nonCliffVestingTime > block.timestamp){
            nonCliffClaimable = SafeMath.mul(SafeMath.sub(block.timestamp , cliffPoolInfo[_poolId].cliffPeriod ) , info.nonCliffRealeaseRatePerSec);


        }
         else if(info.nonCliffLastWithdrawl != 0 && cliffPoolInfo[_poolId].nonCliffVestingTime > block.timestamp){
               nonCliffClaimable = SafeMath.mul(SafeMath.sub( block.timestamp , info.nonCliffLastWithdrawl ) , info.nonCliffRealeaseRatePerSec);

         
        }
        else if(block.timestamp > cliffPoolInfo[_poolId].nonCliffVestingTime  ){
             nonCliffClaimable = info.remainingClaimableNonCliff;
              nonCliffClaimable  = 3;
         }
           
           }
  
           else nonCliffClaimable = 0;

         return nonCliffClaimable;
    }

    // function type payable
    // Claim the cliff amount of the token
    function claimCliff(uint256 _poolId) public {
        Vesting.UserClifInfo memory info = userClifInfo[_poolId][_msgSender()];
        require(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp, "Vesting: Cliff Period Is Not Over Yet");
        uint256 transferAble = cliffClaimable(_poolId,_msgSender());
        require(transferAble> 0 ,"Vesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferAble);
        userClifInfo[_poolId][_msgSender()] = Vesting.UserClifInfo(info.allocation, info.cliffAlloc,info.nonCliffAlloc,SafeMath.add(transferAble,info.claimedAmnt ),info.tokensRelaseTime,SafeMath.sub(info.cliffAlloc,transferAble),info.remainingClaimableNonCliff,info.cliffRealeaseRatePerSec,info.nonCliffRealeaseRatePerSec, block.timestamp,info.nonCliffLastWithdrawl );
            emit CliffClaim( _poolId,  transferAble);

        }

    // function type payable
    // Claim the nonCliff amount of the token
    function claimNonCliff(uint256 _poolId) public {
        Vesting.UserClifInfo memory info = userClifInfo[_poolId][_msgSender()];
        require(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp, "Vesting: Cliff Period Is Not Over Yet");

        uint256 transferAble = nonCliffClaimable(_poolId,_msgSender());
        require(transferAble> 0 ,"Vesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferAble);
        userClifInfo[_poolId][_msgSender()] = Vesting.UserClifInfo(info.allocation, info.cliffAlloc,info.nonCliffAlloc,SafeMath.add(transferAble,info.claimedAmnt ) ,info.tokensRelaseTime,info.remainingClaimableCliff,SafeMath.sub(info.nonCliffAlloc,transferAble),info.cliffRealeaseRatePerSec,info.nonCliffRealeaseRatePerSec,info.cliffLastWithdrawl, block.timestamp );
        emit NonCliffClaim( _poolId, transferAble);

    }

}