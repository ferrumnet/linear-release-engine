// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with a custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with a custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with a custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}














/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
pragma solidity ^0.8.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: Vesting.sol
pragma solidity ^0.8.12;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
contract VestingHarvestContarct is Ownable {
    /*
     * Vesting Information
     */

    uint256 public vestingSize;
    uint256[] public allVestingIdentifiers;
    mapping(address => uint256[]) public vestingsByWithdrawalAddress;
    mapping(address => mapping(address => uint256))
    public walletVestedTokenBalance;
  
    event VestingExecution(address SentToAddress, uint256 AmountTransferred);
    event WithdrawalExecution(address SentToAddress, uint256 AmountTransferred);
    event RewardWithdrawalExecution(string poolName, address SentToAddress, uint256 AmountTransferred);



    uint256 public vestingPoolSize = 0;
    string public vestingContractName;
    address public adminAddress;
    address public ownerAddress;


   
    
    struct PoolItems {
        
          string  poolName;
          uint256 startDate;
          uint256  vestingDays;
          string  releaseRate;
          uint256 releasePartialValue;
          uint256  lockPeriod;
          uint256 unlockDate;
          address tokenAddress;
          uint256 poolTotalVestings;
          bool cliffing ;
          uint256 cliffPercentage;

    }

   struct SingleVesting {
        PoolItems pool;
        address withdrawalAddress;
        uint256 VestingAllocation;    // VestingAllocation
        uint256 claimableAmnt; //calimableAmnt   
        uint256 tokensRelaseToDate;                      //tokensRelaseToDate    
        uint256 VestingAllocationCalculated;  // VestingAllocationCalculated
        uint256 lastWithdrawlTime;
        bool withdrawn;   //Vested tokens
        bool tokenWithdrawn;    // only rewards
    }  



  struct CliffPoolItems {
        
          string  poolName;
          uint256 startDate;  //
        
          uint256  vestingDays;
        
          uint256  cliffVestingDays;
          uint256 NonCliffVestingDays; // 

          string  vestingReleaseRate;     //noncliff
          string  cliffVestingReleaseRate;

          uint256 releaseVestingPartialValue;  // helper for calculation
          uint256 releaseCliffPartialValue;  // helper for calculation

          uint256  cliffLockDays;

          uint256 cliffUnlockDate; // helper for unlcok date
          address tokenAddress;
          uint256 poolTotalVestings;  //
          bool cliffing ;
          uint256 cliffPercentage;

    }





   struct SingleCliffVesting {
        CliffPoolItems pool;
        address withdrawalAddress;
        uint256 VestingAllocation;    // VestingAllocation
       
        uint256 CliffVestedtokens;
        uint256 NonCliffVestedTokens;
       
        uint256 claimableAmnt; //calimableAmnt   
        uint256 tokensRelaseToDate;                      //tokensRelaseToDate    
       
       // uint256 VestingAllocationCalculated;  // VestingAllocationCalculated
      
        uint256 PerCliffCalculation;  
        uint256  PerNonCliffCalculation;
      
        uint256 claimablCliffAmnt; 
        uint256 claimablNonCliffAmnt; 
      
        uint256 lastWithdrawlTime;
      
        bool withdrawn;   //Vested tokens
        bool tokenWithdrawn;    // only rewards
    }  



      mapping (string  => mapping(uint256 => SingleVesting)) public vestedPool;

      mapping (string  => mapping(uint256 => SingleCliffVesting)) public vestedCliffPool;

   //mapping(uint256 => SingleVesting) public vestedPool1;


    constructor(string memory _vestingName, address _adminAddress){
     vestingContractName = _vestingName;
     require(_adminAddress != msg.sender ,"admin cannot be deployer");
     adminAddress = _adminAddress;
     ownerAddress =  msg.sender;

    }

      modifier onlyAdmin() {
        require(adminAddress == _msgSender(), "Ownable: caller is not the admin");
        _;
    }

     modifier onlyAdminOwner() {
        require(adminAddress == _msgSender() ||  ownerAddress == _msgSender() , "Ownable: caller is not the admin/owner");
        _;
    }

    //  modifier onlyOwner() {
    //     require(ownerAddress == _msgSender(), "Ownable: caller is not the Owner");
    //     _;
    // }




    function changeAdmin(address _newAdminAddress)public onlyAdminOwner {
        require(_newAdminAddress != address(0), 'Zero address');
        require(_newAdminAddress != adminAddress, 'Provide different Address');

        adminAddress = _newAdminAddress;
    } 
       


    function changeOwner(address _newOwnerAddress)public onlyOwner {
        require(_newOwnerAddress != address(0), 'Zero address');
        require(_newOwnerAddress != ownerAddress, 'Provide different Address');

        ownerAddress = _newOwnerAddress;
    } 



   struct CliffPoolArgsItem {
     string  _poolName;
     uint256 _vestingDays;
     string   _vestingReleaseRate;
     uint256 _cliffPercentage;
     uint256 _cliffVestingDays;
     string   _cliffReleaseRate;
     uint256 _cliffLockDays;
     address _tokenAddress;
     address[]  _withdrawalAddress;
     uint[]  _amount;
}





    /**
    *setup cliff/NonCliff(Vesting) Pool
    */
     function setupCliffVestingPool(CliffPoolArgsItem memory _args
       //string memory _poolName, uint256 _vestingDays, string memory  _vestingReleaseRate,uint256 _cliffPercentage, uint256 _cliffVestingDays,  string memory  _cliffReleaseRate,  uint256 _cliffLockDays ,address _tokenAddress, address[] memory _withdrawalAddress,uint[] memory _amount
       ) public onlyAdmin{
         require(_args._withdrawalAddress.length == _args._amount.length, "withdrawlAddress[]!=Amount[]" );
         require(_args._vestingDays>0,"Days invalid");
         require(_args._cliffVestingDays>0,"Cliff Days invalid");
         require(_args._cliffPercentage>0,"Cliff % invalid");
         string memory releaseDate;
         uint256 _releasePartialValue;
         string memory cliffReleaseDate;
         uint256 _cliffReleasePartialValue;

         for(uint i=0; i<_args._withdrawalAddress.length;i++)
         {          
            // SingleVesting storage single_vesting =vestedPool[i];
            SingleCliffVesting storage single_vesting =vestedCliffPool[_args._poolName][i];
            require(_args._amount[i]>0,"invalid Amount");
          
            single_vesting.pool.poolName = _args._poolName;
            single_vesting.pool.startDate = block.timestamp;
            // single_vesting.lastWithdrawlTime= block.timestamp;
            single_vesting.pool.vestingDays = _args._vestingDays;
            single_vesting.pool.cliffVestingDays = _args._cliffVestingDays;

            single_vesting.pool.vestingReleaseRate = _args._vestingReleaseRate;
            single_vesting.pool.cliffVestingReleaseRate = _args._cliffReleaseRate;
          
            single_vesting.pool.cliffLockDays = _args._cliffLockDays;

            single_vesting.pool.cliffPercentage = _args._cliffPercentage;

            single_vesting.CliffVestedtokens = SafeMath.mul(_args._amount[i] , _args._cliffPercentage);

            single_vesting.NonCliffVestedTokens =   SafeMath.sub( _args._amount[i], single_vesting.CliffVestedtokens);

            single_vesting.pool.NonCliffVestingDays = SafeMath.sub(_args._vestingDays ,_args._cliffLockDays);




          // for non cliff vesting
         if(keccak256(abi.encodePacked(_args._vestingReleaseRate))== keccak256(abi.encodePacked("second")) ){
          releaseDate =   string.concat("1",_args._vestingReleaseRate);
          releaseDate =   string.concat(releaseDate,"s");
          single_vesting.pool.vestingReleaseRate = releaseDate;
         _releasePartialValue =  SafeMath.mul(_args._vestingDays, 24*60*60); 
        //   uint256 cliffTokenReleasePerSeocnd = SafeMath.div(single_vesting.pool.NonCliffVestedTokens ,SafeMath.mul(86400 , single_vesting.NonCliffVestingDays));
         }else if(keccak256(abi.encodePacked(_args._vestingReleaseRate))== keccak256(abi.encodePacked("minute")) ){
          releaseDate =   string.concat("1",_args._vestingReleaseRate);
          releaseDate =   string.concat(releaseDate,"s");
          single_vesting.pool.vestingReleaseRate = releaseDate;
          _releasePartialValue =   SafeMath.mul(_args._vestingDays, 24*60);

         }else if(keccak256(abi.encodePacked(_args._vestingReleaseRate))== keccak256(abi.encodePacked("hour")) ){
          releaseDate =   string.concat("1",_args._vestingReleaseRate);
          releaseDate =   string.concat(releaseDate,"s");
          single_vesting.pool.vestingReleaseRate = releaseDate;
          _releasePartialValue =   SafeMath.mul(_args._vestingDays, 24);

         }else if(keccak256(abi.encodePacked(_args._vestingReleaseRate))== keccak256(abi.encodePacked("day")) ){
          releaseDate =   string.concat("1",_args._vestingReleaseRate);
          releaseDate =   string.concat(releaseDate,"s");
          single_vesting.pool.vestingReleaseRate = releaseDate;

          _releasePartialValue =   SafeMath.mul(_args._vestingDays, 1);

         }else if(keccak256(abi.encodePacked(_args._vestingReleaseRate))== keccak256(abi.encodePacked("week")) ){
          releaseDate =   string.concat("1",_args._vestingReleaseRate);
          releaseDate =   string.concat(releaseDate,"s");
          single_vesting.pool.vestingReleaseRate = releaseDate;
          _releasePartialValue =    SafeMath.div(_args._vestingDays,  7);  //vestingDays / 7; 

         }else if(keccak256(abi.encodePacked(_args._vestingReleaseRate))== keccak256(abi.encodePacked("month")) ){
          releaseDate =   string.concat("1",_args._vestingReleaseRate);
          releaseDate =   string.concat(releaseDate,"s");
          single_vesting.pool.vestingReleaseRate = releaseDate;
          _releasePartialValue =   SafeMath.div(_args._vestingDays, 30);  //vestingDays / 30 

         }else if(keccak256(abi.encodePacked(_args._vestingReleaseRate))== keccak256(abi.encodePacked("year")) ){
          releaseDate =   string.concat("1",_args._vestingReleaseRate);
          releaseDate =   string.concat(releaseDate,"s");
          single_vesting.pool.vestingReleaseRate = releaseDate;
         _releasePartialValue =    SafeMath.div(_args._vestingDays,  365);    //vestingDays / 365; 

         }




        // for cliff

         if(keccak256(abi.encodePacked(_args._cliffReleaseRate))== keccak256(abi.encodePacked("second")) ){
          cliffReleaseDate =   string.concat("1",_args._cliffReleaseRate);
          cliffReleaseDate =   string.concat(cliffReleaseDate,"s");
         _cliffReleasePartialValue =  SafeMath.mul(_args._cliffVestingDays, 24*60*60); 
        //   uint256 cliffTokenReleasePerSeocnd = SafeMath.div(single_vesting.pool.NonCliffVestedTokens ,SafeMath.mul(86400 , single_vesting.NonCliffVestingDays));
         }else if(keccak256(abi.encodePacked(_args._cliffReleaseRate))== keccak256(abi.encodePacked("minute")) ){
          cliffReleaseDate =   string.concat("1",_args._cliffReleaseRate);
          cliffReleaseDate =   string.concat(cliffReleaseDate,"s");
          _cliffReleasePartialValue =   SafeMath.mul(_args._cliffVestingDays, 24*60);

         }else if(keccak256(abi.encodePacked(_args._cliffReleaseRate))== keccak256(abi.encodePacked("hour")) ){
          cliffReleaseDate =   string.concat("1",_args._cliffReleaseRate);
          cliffReleaseDate =   string.concat(cliffReleaseDate,"s");
          _cliffReleasePartialValue =   SafeMath.mul(_args._cliffVestingDays, 24);

         }else if(keccak256(abi.encodePacked(_args._cliffReleaseRate))== keccak256(abi.encodePacked("day")) ){
          cliffReleaseDate =   string.concat("1",_args._cliffReleaseRate);
          cliffReleaseDate =   string.concat(cliffReleaseDate,"s");

          _cliffReleasePartialValue =   SafeMath.mul(_args._cliffVestingDays, 1);

         }else if(keccak256(abi.encodePacked(_args._cliffReleaseRate))== keccak256(abi.encodePacked("week")) ){
          cliffReleaseDate =   string.concat("1",_args._cliffReleaseRate);
          cliffReleaseDate =   string.concat(cliffReleaseDate,"s");
          _cliffReleasePartialValue =    SafeMath.div(_args._cliffVestingDays,  7);  //vestingDays / 7; 

         }else if(keccak256(abi.encodePacked(_args._cliffReleaseRate))== keccak256(abi.encodePacked("month")) ){
          cliffReleaseDate =   string.concat("1",_args._cliffReleaseRate);
          cliffReleaseDate =   string.concat(cliffReleaseDate,"s");
          _cliffReleasePartialValue =   SafeMath.div(_args._cliffVestingDays, 30);  //vestingDays / 30 

         }else if(keccak256(abi.encodePacked(_args._cliffReleaseRate))== keccak256(abi.encodePacked("year")) ){
          cliffReleaseDate =   string.concat("1",_args._cliffReleaseRate);
          cliffReleaseDate =   string.concat(cliffReleaseDate,"s");
         _cliffReleasePartialValue =    SafeMath.div(_args._cliffVestingDays,  365);    //vestingDays / 365; 

        }




             single_vesting.pool.vestingReleaseRate = releaseDate;
             single_vesting.pool.cliffVestingReleaseRate = cliffReleaseDate;
             single_vesting.pool.releaseVestingPartialValue = _releasePartialValue;
             single_vesting.pool.releaseCliffPartialValue = _cliffReleasePartialValue;




            single_vesting.pool.tokenAddress = _args._tokenAddress;
            single_vesting.pool.poolTotalVestings =   single_vesting.pool.poolTotalVestings + 1;
            single_vesting.withdrawn = false;
           
            single_vesting.tokenWithdrawn = false;
            single_vesting.pool.cliffUnlockDate = block.timestamp + (_args._cliffLockDays * 1 days) ;

            
            
            single_vesting.withdrawalAddress = _args._withdrawalAddress[i];
            single_vesting.VestingAllocation = _args._amount[i];

                  
                   // Transfer tokens into contract
            require(
                IERC20(_args._tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _args._amount[i]
                )
            );
          //  emit VestingExecution(_args._withdrawalAddress[i], _args._amount[i]);
         }


         vestingPoolSize = vestingPoolSize + 1;
         

    }


   








    /**
    *setup Vesting Pool
    */
     function setupVestingPool(string memory _poolName, uint256 _vestingDays, string memory  _releaseRate, uint256 _lockPeriod,address _tokenAddress, address[] memory _withdrawalAddress,uint[] memory _amount) public onlyAdmin{
         require(_withdrawalAddress.length == _amount.length, "withdrawlAddress[]!=Amount[]" );
         require(_vestingDays>0,"Days invalid");
         string memory releaseDate;
         uint256 _releasePartialValue;
         if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("second")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =  SafeMath.mul(_vestingDays, 24*60*60);

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("minute")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =   SafeMath.mul(_vestingDays, 24*60);

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("hour")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =   SafeMath.mul(_vestingDays, 24);

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("day")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =   SafeMath.mul(_vestingDays, 1);

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("week")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =    SafeMath.div(_vestingDays,  7);  //vestingDays / 7; 

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("month")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =   SafeMath.div(_vestingDays, 30);  //vestingDays / 30 

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("year")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =    SafeMath.div(_vestingDays,  365);    //vestingDays / 365; 

        }



   

         for(uint i=0; i<_withdrawalAddress.length;i++)
         {         
            // SingleVesting storage single_vesting =vestedPool[i];
            SingleVesting storage single_vesting =vestedPool[_poolName][i];
            require(_amount[i]>0,"invalid Amount");
            single_vesting.pool.poolName = _poolName;
            single_vesting.pool.startDate = block.timestamp;
            single_vesting.lastWithdrawlTime= block.timestamp;
            single_vesting.pool.vestingDays = _vestingDays;
            single_vesting.pool.releaseRate = releaseDate;
            single_vesting.pool.releasePartialValue = _releasePartialValue;
            single_vesting.pool.lockPeriod = _lockPeriod;


            // single_vesting.pool.cliffing = _cliffing;
            // if( _cliffing == false ){
            //     single_vesting.pool.cliffPercentage = 0;
            // }else{
            //     single_vesting.pool.cliffPercentage = _cliffPercentage;

            // }
            single_vesting.pool.tokenAddress = _tokenAddress;
            single_vesting.pool.poolTotalVestings =   single_vesting.pool.poolTotalVestings + 1;
            single_vesting.withdrawn = false;
           
            single_vesting.tokenWithdrawn = false;
            single_vesting.pool.unlockDate = block.timestamp + (_lockPeriod * 1 days) ;

            
            
            single_vesting.withdrawalAddress = _withdrawalAddress[i];
            single_vesting.VestingAllocation = _amount[i];

                  
                   // Transfer tokens into contract
            require(
                IERC20(_tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _amount[i]
                )
            );
            emit VestingExecution(_withdrawalAddress[i], _amount[i]);
         }


         vestingPoolSize = vestingPoolSize + 1;
         

    }



    /**
    *Update withdrwal address
    */
    function updateWithdrawlAddress(string memory _poolName,uint _id,address _updatedAddress)onlyOwner public{
                    SingleVesting storage single_vesting =vestedPool[_poolName][_id];
                    single_vesting.withdrawalAddress = _updatedAddress;


    }



       /**
    *Check Vest tokens count to withdrawl without Cliff    --Just Public
    */
    
    function checkWithdrawlTokensCount(string memory _poolName,uint _id)  public  returns(uint256) {
            SingleVesting storage single_vesting =vestedPool[_poolName][_id];
            // require(block.timestamp - single_vesting.pool.startDate >= single_vesting.pool.unlockDate,"still locked");
            // require(!single_vesting.withdrawn,"Already withdraw");
           


           
            uint256 rewardCalculationPer =    SafeMath.div( single_vesting.VestingAllocation , single_vesting.pool.releasePartialValue);   //500/172800=0.00289351851      500/86400=0.005787037
            uint256 elaspedSeconds=  SafeMath.sub(block.timestamp , single_vesting.lastWithdrawlTime);

            // uint256 elaspedSeconds =  SafeMath.sub(block.timestamp , single_vesting.pool.startDate);  //5, 10
            // uint256 currentSeconds = elaspedSeconds -  single_vesting.elaspedUtilizedSeconds;      //5-0   , 10-5
            // single_vesting.elaspedUtilizedSeconds += currentSeconds;                               //5      ,5+5                 //  calculating the principle(total) Reward as well as the reward upto this function calling time
                 // please verify this as well
            if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1seconds")) ){
                     single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.mul(single_vesting.pool.vestingDays , 86400))  ;    //principle total reward  
                     single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , elaspedSeconds);               // By the time calculated reward

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1minutes")) ){
                     single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.mul(single_vesting.pool.vestingDays , 1440))  ;    //principle total reward  
                     single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,60)); 
                    //  single_vesting.VestingAllocationCalculated = rewardCalculationPer * (single_vesting.pool.vestingDays * 1440);
                    //  single_vesting.claimableAmnt =  rewardCalculationPer *  (elaspedSeconds / 60);

             }
            else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1hours")) ){
                  single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.mul(single_vesting.pool.vestingDays , 24))  ;
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,3600)); 

                    //  single_vesting.VestingAllocationCalculated = rewardCalculationPer * (single_vesting.pool.vestingDays * 24);
                    //  single_vesting.claimableAmnt =  rewardCalculationPer * ( elaspedSeconds / 3600);   // seconds in an hour

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1days")) ){
                  single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, single_vesting.pool.vestingDays)  ;
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,86400)); 
                    //  single_vesting.VestingAllocationCalculated = rewardCalculationPer * single_vesting.pool.vestingDays;
                    //  single_vesting.claimableAmnt =  rewardCalculationPer * (elaspedSeconds / 86400);   // seconds in a day

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1weeks")) ){
                   single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.div(single_vesting.pool.vestingDays,7));
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,604800)); 


                    //  single_vesting.VestingAllocationCalculated = rewardCalculationPer * (single_vesting.pool.vestingDays / 7);
                    //  single_vesting.claimableAmnt =  rewardCalculationPer *  ( elaspedSeconds / 604800);  // seconds in a week

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1months")) ){
                     single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.div(single_vesting.pool.vestingDays,30))  ;
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,2592000)); 

                    //  single_vesting.VestingAllocationCalculated = rewardCalculationPer * ( single_vesting.pool.vestingDays / 30);
                    //  single_vesting.claimableAmnt =  rewardCalculationPer * (elaspedSeconds / 2592000); // seconds in a month

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1years")) ){
                     single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.div(single_vesting.pool.vestingDays,365))  ;
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,31540000)); 

                    //  single_vesting.VestingAllocationCalculated = rewardCalculationPer * (single_vesting.pool.vestingDays / 365);
                    //  single_vesting.claimableAmnt =  rewardCalculationPer * ( elaspedSeconds / 31540000);   // seconds in a year
            }

            return   single_vesting.VestingAllocationCalculated ;

    }








      /**
    *Check tokens count to withdrawl     --core helper function
    */
    
    function checkWithdrawlTokenCount(string memory _poolName,uint _id)  internal {
            SingleVesting storage single_vesting =vestedPool[_poolName][_id];
            uint256 elaspedSeconds=  SafeMath.sub(block.timestamp , single_vesting.lastWithdrawlTime);
            
            uint256 cliff_release_rate = SafeMath.div(SafeMath.mul(single_vesting.VestingAllocation,SafeMath.mul(single_vesting.pool.cliffPercentage , 10)),1000);

             require(block.timestamp - single_vesting.pool.startDate >= single_vesting.pool.unlockDate,"still locked");
                uint256 rewardCalculationPer =    SafeMath.div( single_vesting.VestingAllocation , single_vesting.pool.releasePartialValue);   //500/172800=0.00289351851      500/86400=0.005787037
                if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1seconds")) ){
                     single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.mul(single_vesting.pool.vestingDays , 86400))  ;    //principle total reward  
                     single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , elaspedSeconds);               // By the time calculated reward
                }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1minutes")) ){
                     single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.mul(single_vesting.pool.vestingDays , 1440))  ;    //principle total reward  
                     single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,60)); 
                }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1hours")) ){
                  single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.mul(single_vesting.pool.vestingDays , 24))  ;
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,3600)); 
                }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1days")) ){
                  single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, single_vesting.pool.vestingDays)  ;
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,86400)); 
                }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1weeks")) ){
                   single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.div(single_vesting.pool.vestingDays,7));
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,604800)); 

                }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1months")) ){
                     single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.div(single_vesting.pool.vestingDays,30))  ;
                     single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,2592000)); 
           
                }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1years")) ){
                     single_vesting.VestingAllocationCalculated = SafeMath.mul(rewardCalculationPer, SafeMath.div(single_vesting.pool.vestingDays,365))  ;
                  single_vesting.claimableAmnt =  SafeMath.mul(rewardCalculationPer , SafeMath.div(elaspedSeconds,31540000)); 
                  }

       
    }





   /**
    *Calculate  cliff/NonCliff(Vested) related tokens  ---- Just public use
    */
    
    function calculateCliffVestingTokensCount(string memory _poolName,uint _id)  public  {
            SingleCliffVesting storage single_vesting =vestedCliffPool[_poolName][_id];
            uint256 elaspedSeconds=  SafeMath.sub(block.timestamp , single_vesting.lastWithdrawlTime);       
           
            //old
           // uint256 cliff_release_rate = SafeMath.div(SafeMath.mul(single_vesting.VestingAllocation,SafeMath.mul(single_vesting.pool.cliffPercentage , 10)),1000);
            //cliff_release_rate ===  NonCliffTokenReleasePerSeocnd
          
              //new logic
            uint256 NonCliffTokenReleasePer = SafeMath.div(single_vesting.NonCliffVestedTokens , single_vesting.pool.releaseVestingPartialValue);
            uint256 CliffTokenReleasePer = SafeMath.div(single_vesting.CliffVestedtokens , single_vesting.pool.releaseCliffPartialValue);

             



                      //Non Cliff(Vesting) per --- calculation
                  single_vesting.PerNonCliffCalculation  = NonCliffTokenReleasePer;

                if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1seconds")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer , elaspedSeconds);
                }
               else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1minutes")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,60));
                }
                else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1hours")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,3600));
                } 
                else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1days")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,86400));
                } 
               else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1weeks")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,604800));
                } 
               else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1months")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,2592000));
                } 
                else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1years")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,31540000));
                } 


                      //Cliff per --- calculation

                single_vesting.PerCliffCalculation  = CliffTokenReleasePer;

                 if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1seconds")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer , elaspedSeconds);
                }
               else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1minutes")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,60));
                }
                else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1hours")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer,  SafeMath.div(elaspedSeconds,3600));
                } 
                else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1days")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer,  SafeMath.div(elaspedSeconds,86400));
                } 
               else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1weeks")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,604800));
                } 
               else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1months")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,2592000));
                } 
                else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1years")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,31540000));
                } 



    }



    /**
    *Calculate cliff/NonCliff(Vested) related tokens  ---- Just INTERNAL use
    */
    
    function calculateCliffVestingTokensCountInternal(string memory _poolName,uint _id)  internal  {
             SingleCliffVesting storage single_vesting =vestedCliffPool[_poolName][_id];
            uint256 elaspedSeconds=  SafeMath.sub(block.timestamp , single_vesting.lastWithdrawlTime);       
           
            //old
           // uint256 cliff_release_rate = SafeMath.div(SafeMath.mul(single_vesting.VestingAllocation,SafeMath.mul(single_vesting.pool.cliffPercentage , 10)),1000);
            //cliff_release_rate ===  NonCliffTokenReleasePerSeocnd
          
              //new logic
            uint256 NonCliffTokenReleasePer = SafeMath.div(single_vesting.NonCliffVestedTokens , single_vesting.pool.releaseVestingPartialValue);
            uint256 CliffTokenReleasePer = SafeMath.div(single_vesting.CliffVestedtokens , single_vesting.pool.releaseCliffPartialValue);
           
            //require(block.timestamp - single_vesting.pool.startDate >= single_vesting.pool.cliffUnlockDate,"cliff lock day period has not been finish");
             




                      //Non Cliff(Vesting) per --- calculation
                  single_vesting.PerNonCliffCalculation  = NonCliffTokenReleasePer;

                if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1seconds")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer , elaspedSeconds);
                }
               else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1minutes")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,60));
                }
                else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1hours")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,3600));
                } 
                else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1days")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,86400));
                } 
               else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1weeks")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,604800));
                } 
               else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1months")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,2592000));
                } 
                else if(keccak256(abi.encodePacked(single_vesting.pool.vestingReleaseRate))== keccak256(abi.encodePacked("1years")) ){
               single_vesting.claimablNonCliffAmnt = SafeMath.mul(NonCliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,31540000));
                } 


                      //Cliff per --- calculation

                single_vesting.PerCliffCalculation  = CliffTokenReleasePer;

                 if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1seconds")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer , elaspedSeconds);
                }
               else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1minutes")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,60));
                }
                else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1hours")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer,  SafeMath.div(elaspedSeconds,3600));
                } 
                else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1days")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer,  SafeMath.div(elaspedSeconds,86400));
                } 
               else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1weeks")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,604800));
                } 
               else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1months")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,2592000));
                } 
                else if(keccak256(abi.encodePacked(single_vesting.pool.cliffVestingReleaseRate))== keccak256(abi.encodePacked("1years")) ){
               single_vesting.claimablCliffAmnt = SafeMath.mul(CliffTokenReleasePer ,  SafeMath.div(elaspedSeconds,31540000));
                } 

    }




 /**
     * Withdraw only vested tokens, not reward   ----Invalid function
     */
    function withdrawVestedTokens(string memory _poolName, uint256 _id) public {
        SingleVesting storage single_vesting =vestedPool[_poolName][_id];

        require(block.timestamp - single_vesting.pool.startDate >= single_vesting.pool.unlockDate,"still locked");
        require(msg.sender == single_vesting.withdrawalAddress,"Invalid member");
        require(!single_vesting.withdrawn,"Already withdraw");

        single_vesting.withdrawn = true;
        // single_vesting.tokensRelaseToDate += single_vesting.VestingAllocation;
        // single_vesting.VestingAllocation = 0;

                 // Transfer tokens into contract
             require(
            IERC20(single_vesting.pool.tokenAddress).transfer(
                msg.sender,
                single_vesting.VestingAllocation
            )
            );

        emit WithdrawalExecution(msg.sender, single_vesting.VestingAllocation);

    

        // uint256 rewardCalculation = single_vesting.VestingAllocation /  single_vesting.pool.releasePartialValue;
        // single_vesting.claimableAmnt =  single_vesting.claimableAmnt + rewardCalculation;
    }




     /**
     * Withdraw claimable amount for vesting, calculated so far
     */
    function withdrawClaims(string memory _poolName, uint256 _id) public {
        checkWithdrawlTokenCount(  _poolName,_id); 
        SingleVesting storage single_vesting =vestedPool[_poolName][_id];
        require(msg.sender == single_vesting.withdrawalAddress,"Invalid member");
       
        // if(single_vesting.pool.cliffing== true){
        //    require(single_vesting.claimablCliffAmnt>0,"0 Reward!");
        //    single_vesting.tokenWithdrawn = true;

        //    uint256 AmntToWithdraw = single_vesting.claimablCliffAmnt;
        //    single_vesting.tokensRelaseToDate += single_vesting.claimablCliffAmnt;
        //    single_vesting.claimablCliffAmnt = 0;
        //    single_vesting.lastWithdrawlTime = block.timestamp;

        //          // Transfer tokens into contract
        //    require(
        //     IERC20(single_vesting.pool.tokenAddress).transfer(
        //         msg.sender,
        //         AmntToWithdraw
        //     )
        //     );
        //    emit RewardWithdrawalExecution(single_vesting.pool.poolName, msg.sender, AmntToWithdraw);

        // } else{

          require(block.timestamp - single_vesting.pool.startDate >= single_vesting.pool.unlockDate,"still locked");
          require(single_vesting.claimableAmnt>0,"0 Reward!");
          require(!single_vesting.withdrawn,"Funds withdrawn already");
          single_vesting.tokenWithdrawn = true;
          uint256 AmntToWithdraw = single_vesting.claimableAmnt;
          single_vesting.tokensRelaseToDate += single_vesting.claimableAmnt;
          single_vesting.claimableAmnt = 0;

                 // Transfer tokens into contract
          require(
            IERC20(single_vesting.pool.tokenAddress).transfer(
                msg.sender,
                AmntToWithdraw
            )
            );
          emit RewardWithdrawalExecution(single_vesting.pool.poolName, msg.sender, AmntToWithdraw);

       // }


 
    

        // uint256 rewardCalculation = single_vesting.VestingAllocation /  single_vesting.pool.releasePartialValue;
        // single_vesting.claimableAmnt =  single_vesting.claimableAmnt + rewardCalculation;
    }










      /**
     * Withdraw claimable amount for cliff , calculated so far
     */
    function withdrawCliffVestingClaims(string memory _poolName, uint256 _id) public {
        checkWithdrawlTokenCount(  _poolName,_id); 
        SingleCliffVesting storage single_vesting =vestedCliffPool[_poolName][_id];
        require(msg.sender == single_vesting.withdrawalAddress,"Invalid member");
      
       
        if(single_vesting.pool.cliffing== true){
            require(block.timestamp - single_vesting.pool.startDate >= single_vesting.pool.cliffUnlockDate,"cliff lock day period has not been finish");
            require(single_vesting.claimablCliffAmnt>0,"0 Cliff amount!");
           single_vesting.tokenWithdrawn = true;

           uint256 AmntToWithdraw = single_vesting.claimablCliffAmnt;
           single_vesting.tokensRelaseToDate += single_vesting.claimablCliffAmnt;
           single_vesting.claimablCliffAmnt = 0;
           single_vesting.lastWithdrawlTime = block.timestamp;

                 // Transfer tokens into contract
           require(
            IERC20(single_vesting.pool.tokenAddress).transfer(
                msg.sender,
                AmntToWithdraw
            )
            );
           emit RewardWithdrawalExecution(single_vesting.pool.poolName, msg.sender, AmntToWithdraw);

         }
        
    }







   /**
     * Withdraw claimable amount for  Non cliff(Vesting), calculated so far
     */
    function withdrawNonCliffVestingClaims(string memory _poolName, uint256 _id) public {
        checkWithdrawlTokenCount(  _poolName,_id); 
        SingleCliffVesting storage single_vesting =vestedCliffPool[_poolName][_id];
        require(msg.sender == single_vesting.withdrawalAddress,"Invalid member");
       
        if(single_vesting.pool.cliffing== true){
      require(block.timestamp - single_vesting.pool.startDate >= single_vesting.pool.cliffUnlockDate,"Non cliff period not yet started");

           require(single_vesting.claimablNonCliffAmnt>0,"0 Reward!");
           single_vesting.tokenWithdrawn = true;

           uint256 AmntToWithdraw = single_vesting.claimablNonCliffAmnt;
           single_vesting.tokensRelaseToDate += single_vesting.claimablNonCliffAmnt;
           single_vesting.claimablNonCliffAmnt = 0;
           single_vesting.lastWithdrawlTime = block.timestamp;

                 // Transfer tokens into contract
           require(
            IERC20(single_vesting.pool.tokenAddress).transfer(
                msg.sender,
                AmntToWithdraw
            )
            );
           emit RewardWithdrawalExecution(single_vesting.pool.poolName, msg.sender, AmntToWithdraw);

         }
        
    }




    /**
    *Get Vestings detail using Pool number
    */
    // function checkVestings(uint256 _vestedPool) public returns(address[] memory,uint256[] memory){
    //    return (vestedPool[_vestedPool].withdrawalAddress,vestedPool[_vestedPool].amount);
    // }



  
}
