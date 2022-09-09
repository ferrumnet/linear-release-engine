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

    // modifier onlyAdmin() {
    //     require(adminAddress == _msgSender(), "Ownable: caller is not the admin");
    //     _;
    // }

    // Mappings
    mapping(address => bool) public cliff;
    mapping(uint256 => Vesting.PoolInfo) public poolInfo;
    mapping(uint256 => Vesting.CliffPoolInfo) public cliffPoolInfo;
    mapping(address => mapping(address =>Vesting.UserInfo)) public userInfo;
    mapping(address => mapping(address =>Vesting.UserClifInfo)) public userClifInfo;


    //add vesting 
    // This function is used to register vesting which is without cliff
    function addVesting(string memory _poolName, uint256 _vestingTime, uint256 _cliffPeriod,address _tokenAddress,uint256 _totalVesting, address[] memory _usersAddresses,uint[] memory _userAlloc) public onlyVester {
         require(_vestingTime > block.timestamp,"Vesting: Invalid Vesting Time");
         require(_vestingTime >= _cliffPeriod,"Vesting: Lock time must be lesser than vesting time");
          for(uint i=0; i<_usersAddresses.length;i++)
         { 

        require(_totalVesting >= _userAlloc[i],"Vesting: Total Vesting is Invalid");
        uint256 releaseRate =SafeMath.div(_totalVesting ,(SafeMath.sub(_vestingTime,_cliffPeriod)));
        poolInfo[vestingPoolSize] = Vesting.PoolInfo(_poolName, block.timestamp,_vestingTime,_cliffPeriod,releaseRate,_tokenAddress,_totalVesting, _usersAddresses,_userAlloc);
        userInfo[_tokenAddress][_usersAddresses[i]] = Vesting.UserInfo(_userAlloc[i],0,_cliffPeriod,_userAlloc[i],0);
         }

         
        IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),_totalVesting);
        // IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),1000000000000);


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
        Vesting.UserInfo memory info = userInfo[poolInfo[_poolId].tokenAddress][_user];
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
         Vesting.UserInfo memory info = userInfo[poolInfo[_poolId].tokenAddress][_msgSender()];
        userInfo[poolInfo[_poolId].tokenAddress][_msgSender()] = Vesting.UserInfo(info.allocation, claimable(_poolId,_msgSender()), info.tokensRelaseTime,SafeMath.sub(info.allocation,claimable(_poolId,_msgSender()) ) , block.timestamp );

    }

    // function type payable
    // use to register vesting
    function addCliffVesting(string memory _poolName,uint256 _vestingTime, uint256 _cliffVestingTime,uint256 _cliffPeriod,address _tokenAddress,uint256 _totalVesting, uint256 _cliffPercentage,address[] memory _usersAddresses,uint[] memory _userAlloc) public onlyVester{
         require(_vestingTime > block.timestamp && _vestingTime > _cliffPeriod,"Vesting: Invalid Vesting Time");
        //  require(_cliffVestingTime >= _cliffPeriod,"Vesting: Lock time must be lesser than vesting time");
         uint256 cliffToken =SafeMath.div(SafeMath.mul(_totalVesting,_cliffPercentage),100);
        for(uint i=0; i<_usersAddresses.length;i++)
         { 

        require(_totalVesting >= _userAlloc[i],"Cliff Vesting: Total Vesting is Invalid");
        cliffPoolInfo[vestingPoolSize] = Vesting.CliffPoolInfo(_poolName, block.timestamp,_vestingTime,_cliffVestingTime,SafeMath.sub(_vestingTime , _cliffVestingTime),SafeMath.div(SafeMath.sub(_totalVesting , cliffToken) ,SafeMath.sub(_vestingTime , _cliffVestingTime)),SafeMath.div(cliffToken ,SafeMath.sub(_vestingTime , _cliffVestingTime)),_cliffPeriod,_tokenAddress,_totalVesting,_cliffPercentage,_usersAddresses,_userAlloc);
        uint256 cliffAlloc = SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100);
        uint256 nonCliffAlloc = SafeMath.sub(_userAlloc[i],cliffAlloc);
        userClifInfo[_tokenAddress][_usersAddresses[i]] = Vesting.UserClifInfo(_userAlloc[i],cliffAlloc,nonCliffAlloc,0,_cliffPeriod,cliffAlloc,nonCliffAlloc,0,0);
         }
        IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),_totalVesting);

        vestingPoolSize = vestingPoolSize + 1;
        cliff[_tokenAddress] = true;      
    }


    // function type readOnly
    // This function is used to return cliffclaimables for the vesting tokens
    function cliffClaimable(uint256 _poolId,  address _user) public view returns(uint256){
        uint256 cliffClaimable;
        Vesting.UserClifInfo memory info = userClifInfo[cliffPoolInfo[_poolId].tokenAddress][_user];
        // require(info.cliffAlloc > 0,"Cliff Allocation: You Don't have allocation in this pool");
        // require(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp,"Invalid Withdrarl: You can't withdraw before release date");

    //    uint256 cliffPoolInfo[_poolId].cliffReleaseRate =  cliffPoolInfo[_poolId].cliffPoolInfo[_poolId].cliffReleaseRate;
       if(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp && info.remainingClaimableCliff > 0 ){

       if(info.cliffLastWithdrawl == 0 ){
          cliffClaimable = SafeMath.mul(SafeMath.sub(block.timestamp , cliffPoolInfo[_poolId].cliffPeriod ) , cliffPoolInfo[_poolId].cliffReleaseRate);

            if(cliffClaimable > info.cliffAlloc){
               cliffClaimable = info.cliffAlloc;
           }

       }
         else if(info.cliffLastWithdrawl != 0 && cliffPoolInfo[_poolId].nonCliffVestingTime > block.timestamp){
               cliffClaimable = SafeMath.mul(SafeMath.sub( block.timestamp , info.cliffLastWithdrawl ) , cliffPoolInfo[_poolId].cliffReleaseRate);
                 if(cliffClaimable > info.cliffAlloc){
                        cliffClaimable = info.cliffAlloc;
           }
           }
           
           }
           else cliffClaimable = 0;

         return cliffClaimable;
    }


     // function type readOnly
    // This function is used to return nonCliffclaimables for the vesting tokens
    function nonCliffClaimable(uint256 _poolId, address _user) public view returns(uint256){
        uint256 nonCliffClaimable;
        Vesting.UserClifInfo memory info = userClifInfo[cliffPoolInfo[_poolId].tokenAddress][_user];
        // require(info.nonCliffAlloc > 0,"Non Cliff Allocation: You Don't have allocation in this pool");
        // require(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp,"Invalid Withdrarl: You can't withdraw before release date");

    //    uint256 cliffPoolInfo[_poolId].cliffReleaseRate =  cliffPoolInfo[_poolId].cliffPoolInfo[_poolId].cliffReleaseRate;
       if(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp && info.remainingClaimableNonCliff > 0){

         if(info.nonCliffLastWithdrawl == 0 && cliffPoolInfo[_poolId].nonCliffVestingTime < block.timestamp){
            nonCliffClaimable = SafeMath.mul(SafeMath.sub(block.timestamp , cliffPoolInfo[_poolId].nonCliffVestingTime ) , cliffPoolInfo[_poolId].nonCliffReleaseRate);
                    if(nonCliffClaimable > info.nonCliffAlloc){
               nonCliffClaimable = info.nonCliffAlloc;
           }

        }
         else if(info.cliffLastWithdrawl != 0 && cliffPoolInfo[_poolId].nonCliffVestingTime > block.timestamp){
               nonCliffClaimable = SafeMath.mul(SafeMath.sub( block.timestamp , info.nonCliffLastWithdrawl ) , cliffPoolInfo[_poolId].nonCliffReleaseRate);
                    if(nonCliffClaimable > info.nonCliffAlloc){
               nonCliffClaimable = info.nonCliffAlloc;
           }
         
        }
           
           }
  
           else nonCliffClaimable = 0;

         return (nonCliffClaimable);
    }

    // function type payable
    // Claim the cliff amount of the token
    function claimCliff(uint256 _poolId) public {
        Vesting.UserClifInfo memory info = userClifInfo[cliffPoolInfo[_poolId].tokenAddress][_msgSender()];
        require(cliffPoolInfo[_poolId].cliffPeriod > block.timestamp, "Vesting: Cliff Period Is Not Over Yet");
        uint256 transferAble = cliffClaimable(_poolId,_msgSender());
        require(transferAble<= 0 ,"Vesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferAble);
        // IERC20(cliffPoolInfo[_poolId].tokenAddress).transfer(_msgSender(),10000000);
        userClifInfo[cliffPoolInfo[_poolId].tokenAddress][_msgSender()] = Vesting.UserClifInfo(info.allocation, info.cliffAlloc,info.nonCliffAlloc,SafeMath.add(nonCliffClaimable(_poolId,_msgSender()),cliffClaimable(_poolId,_msgSender())),info.tokensRelaseTime,SafeMath.sub(info.cliffAlloc,cliffClaimable(_poolId,_msgSender())),info.remainingClaimableNonCliff, block.timestamp,info.nonCliffLastWithdrawl );
    }

    // function type payable
    // Claim the nonCliff amount of the token
    function claimNonCliff(uint256 _poolId) public {
        Vesting.UserClifInfo memory info = userClifInfo[cliffPoolInfo[_poolId].tokenAddress][_msgSender()];
        require(cliffPoolInfo[_poolId].cliffPeriod > block.timestamp, "Vesting: Cliff Period Is Not Over Yet");

        uint256 transferAble = nonCliffClaimable(_poolId,_msgSender());
        require(transferAble<= 0 ,"Vesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferAble);
        userClifInfo[cliffPoolInfo[_poolId].tokenAddress][_msgSender()] = Vesting.UserClifInfo(info.allocation, info.cliffAlloc,info.nonCliffAlloc,SafeMath.sub(SafeMath.add(nonCliffClaimable(_poolId,_msgSender()),cliffClaimable(_poolId,_msgSender())),transferAble ),info.tokensRelaseTime,info.remainingClaimableCliff,SafeMath.sub(info.nonCliffAlloc,nonCliffClaimable(_poolId,_msgSender())),info.cliffLastWithdrawl, block.timestamp );
    }

}