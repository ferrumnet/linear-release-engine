// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
 
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Libraries/Library.sol";

contract VestingHarvestContarct is AccessControl ,Initializable, ReentrancyGuardUpgradeable {

    
    string public vestingContractName;
    uint256 public vestingPoolSize;
    address public signer;
    bool private initialized;
    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");


    constructor(){}


        modifier onlyVester() {
        require(hasRole(VESTER_ROLE, _msgSender()), "AccessDenied: Only Vester Call This Function");
        _;
    }  

           modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "AccessDenied: Only Admin Call This Function");
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
        uint256 releaseRate, 
        address tokenAddress,
        uint256 totalVesting,
        address[]  usersAddresses,
        uint256[]  usersAlloc);

    event CliffAddVesting(
        uint256 poolId,
        string  poolName,
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


    // contract initialization with constructor values
    function initialize(string memory _vestingName,address _signer) public {
        require(!initialized, "Contract instance has already been initialized");
        vestingContractName = _vestingName;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VESTER_ROLE, msg.sender);
        signer = _signer;
                initialized = true;
                uint256 vestingPoolSize = 0;

    }


    //function type payable
    // This function is used to register vesting which is without cliff
    function addVesting(string memory _poolName, uint256 _vestingTime,address _tokenAddress , address[] memory _usersAddresses,uint256[] memory _userAlloc, bytes memory signature,bytes32 _salt) public onlyVester  nonReentrant() {
         require(_vestingTime > block.timestamp,"Vesting: Invalid Vesting Time");
         require(signatureVerification(signature, _salt) == signer,"Signer: Invalid signer");
         uint256 releaseRate;
         uint256 totalvesting;                                                                                                                                                                                                                                                                          
          for(uint256 i=0; i<_usersAddresses.length;i++)
         {  
             totalvesting  += _userAlloc[i];

        uint256 releaseRate = SafeMath.div(_userAlloc[i] ,(SafeMath.sub(_vestingTime,block.timestamp)));
        poolInfo[vestingPoolSize] = Vesting.PoolInfo(_poolName, block.timestamp,_vestingTime,_tokenAddress,totalvesting, _usersAddresses,_userAlloc);
        userInfo[vestingPoolSize][_usersAddresses[i]] = Vesting.UserInfo(_userAlloc[i],0,_userAlloc[i],block.timestamp,SafeMath.div(_userAlloc[i],(SafeMath.sub(_vestingTime,block.timestamp))));
         } 
        IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),totalvesting);
        cliff[vestingPoolSize] = false;
        emit AddVesting(vestingPoolSize,_poolName,block.timestamp,_vestingTime, releaseRate, _tokenAddress,totalvesting,_usersAddresses,_userAlloc);
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
       if (poolInfo[_poolId].startDate < block.timestamp){
       
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
        require(block.timestamp > poolInfo[_poolId].startDate ,"Vesting: Lock Time Is Not Over Yet");
        require(transferAble > 0 ,"Vesting: Invalid TransferAble");
        uint256 claimed = SafeMath.add(info.claimedAmount , transferAble);
        userInfo[_poolId][_msgSender()] = Vesting.UserInfo(info.allocation, claimed,SafeMath.sub(info.allocation,claimed),block.timestamp, info.releaseRatePerSec );
        emit Claim(_poolId,transferAble,_msgSender(),SafeMath.sub(info.allocation,claimed));
        

    }

    // function type payable
    // use to register vesting
    function addCliffVesting(string memory _poolName,uint256 _vestingTime, uint256 _cliffVestingTime,uint256 _cliffPeriod,address _tokenAddress, uint256 _cliffPercentage,address[] memory _usersAddresses,uint256[] memory _userAlloc, bytes memory signature,bytes32 _salt ) public onlyVester nonReentrant() {
        require(_vestingTime > block.timestamp ,"Vesting: Vesting Time Must Be Greater Than Current Time");
        require(_vestingTime > _cliffPeriod ,"Vesting: Vesting Time Time Must Be Greater Than Cliff Period");
        require(_cliffVestingTime < _vestingTime,"Vesting: Cliff Vesting Time Must Be Lesser Than Vesting Time");
        require(_cliffVestingTime > _cliffPeriod,"Vesting: Cliff Vesting Time Must Be Greater Than Cliff Period");
        require(signatureVerification(signature, _salt) == signer,"Signer: Invalid signer");
        require(_cliffPercentage <= 50,"Percentage:Percentage Should Be less Than  50%");
        
        uint256 nonClifVestingTime = SafeMath.add(SafeMath.sub(_vestingTime , _cliffVestingTime),_cliffPeriod);
        uint256 totalVesting;
        for(uint256 i=0; i<_usersAddresses.length;i++)
         {
            totalVesting += _userAlloc[i];

            cliffPoolInfo[vestingPoolSize] = Vesting.CliffPoolInfo(_poolName, block.timestamp,_vestingTime,_cliffVestingTime,SafeMath.add(SafeMath.sub(_vestingTime , _cliffVestingTime),_cliffPeriod),_cliffPeriod,_tokenAddress,totalVesting,_cliffPercentage,_usersAddresses,_userAlloc);

            userClifInfo[vestingPoolSize][_usersAddresses[i]] = Vesting.UserClifInfo(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100),0,_cliffPeriod,SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100),SafeMath.div(SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100) ,SafeMath.sub(_cliffVestingTime,_cliffPeriod)),_cliffPeriod);
            userNonClifInfo[vestingPoolSize][_usersAddresses[i]] = Vesting.UserNonClifInfo(_userAlloc[i],SafeMath.sub(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),0,_cliffPeriod,SafeMath.sub(_userAlloc[i],SafeMath.div((SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),SafeMath.div(SafeMath.sub(_userAlloc[i],SafeMath.div( (SafeMath.mul(_userAlloc[i],_cliffPercentage)),100)),SafeMath.sub(nonClifVestingTime, _cliffPeriod)),_cliffPeriod);

        }
        IERC20(_tokenAddress).transferFrom(_msgSender(),address(this),totalVesting);
        cliff[vestingPoolSize] = true;  
        
    emit  CliffAddVesting(vestingPoolSize,_poolName,_vestingTime,_cliffVestingTime, nonClifVestingTime, _cliffPeriod,_tokenAddress,totalVesting, _cliffPercentage,_usersAddresses,_userAlloc);

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
    function claimNonCliff(uint256 _poolId) public nonReentrant()  {
        Vesting.UserNonClifInfo memory info = userNonClifInfo[_poolId][_msgSender()];
        require(cliffPoolInfo[_poolId].cliffPeriod < block.timestamp, "Vesting: Cliff Period Is Not Over Yet");

         (uint256 transferAble,uint256 secondDiff, uint256 releaseRate) = nonCliffClaimable(_poolId,_msgSender());
         uint256 claimed = SafeMath.add(transferAble,info.claimedAmnt );
        require(transferAble> 0 ,"Vesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).transfer(_msgSender(),transferAble);
        userNonClifInfo[_poolId][_msgSender()] = Vesting.UserNonClifInfo(info.allocation, info.nonCliffAlloc,claimed ,info.tokensRelaseTime,SafeMath.sub(info.nonCliffAlloc,claimed),info.nonCliffRealeaseRatePerSec, block.timestamp );
        emit NonCliffClaim(_poolId,transferAble,_msgSender(),SafeMath.sub(info.nonCliffAlloc,claimed));

    }


    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }


    // verify message for the internal usage
    function VerifyMessage(bytes32 _salt, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _salt));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    // verify signature  
    function signatureVerification(
        bytes memory signature,
        bytes32 _salt )public view returns(address){
        ( bytes32 r,bytes32 s,uint8 v)=splitSignature(signature);
        
        address _user =  VerifyMessage(_salt,v,r,s);
       return _user;
       
    }


    // set new signer
    function setSigner(address _signer) public onlyAdmin(){
        signer = _signer;

    }

}
