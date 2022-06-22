// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
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
    struct VestingItems {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }
    uint256 public vestingSize;
    uint256[] public allVestingIdentifiers;
    mapping(address => uint256[]) public vestingsByWithdrawalAddress;
    mapping(uint256 => VestingItems) public vestedToken;
    mapping(address => mapping(address => uint256))
    public walletVestedTokenBalance;
  
    event VestingExecution(address SentToAddress, uint256 AmountTransferred);
    event WithdrawalExecution(address SentToAddress, uint256 AmountTransferred);
    event RewardWithdrawalExecution(string poolName, address SentToAddress, uint256 AmountTransferred);



    uint256 public vestingPoolSize = 0;
    string public vestingContractName;
    address public adminAddress;

   
    
    struct PoolItems {
        
          string  poolName;
          uint256 startDate;
          uint256  vestingDays;
          string  releaseRate;
          uint256 releasePartialValue;
          uint256  lockPeriod;
          address tokenAddress;
          uint256 poolTotalVestings;
          //SingleVesting singleUser;
          //address[]  withdrawalAddress;
          //uint[]  amount;
    }

   struct SingleVesting {
        PoolItems pool;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 rewardAmnt;
        uint256 principleEstimatedReward;
        bool withdrawn;   //Vested tokens
        bool tokenWithdrawn;    // only rewards
    }  

   mapping (string  => mapping(uint256 => SingleVesting)) public vestedPool;
   //mapping(uint256 => SingleVesting) public vestedPool1;


    constructor(string memory _vestingName, address _adminAddress){
     vestingContractName = _vestingName;
     require(_adminAddress != msg.sender ,"admin cannot be deployer");
     adminAddress = _adminAddress;

    }

      modifier onlyAdmin() {
        require(adminAddress == _msgSender(), "Ownable: caller is not the admin");
        _;
    }







    /**
    *setup Vesting Pool
    */
     function setupVestingPool(string memory _poolName, uint256 _vestingDays, string memory  _releaseRate, uint256 _lockPeriod, address _tokenAddress, address[] memory _withdrawalAddress,uint[] memory _amount) public onlyAdmin{
         require(_withdrawalAddress.length == _amount.length, "withdrawlAddress[]!=Amount[]" );
         require(_vestingDays>0,"Days invalid");
         //require(keccak256(abi.encodePacked(_releaseRate))== "second" || keccak256(abi.encodePacked(_releaseRate))== "minute" ||
         //          keccak256(abi.encodePacked(_releaseRate))== "hour"   || keccak256(abi.encodePacked(_releaseRate))== "day"    ||
         //          keccak256(abi.encodePacked(_releaseRate))== "week"   || keccak256(abi.encodePacked(_releaseRate))== "month"  ||
         //          keccak256(abi.encodePacked(_releaseRate))== "year" ,"Invalid Release Rate");
         string memory releaseDate;
         uint256 _releasePartialValue;
        // uint256  
        
        //formula=>  TotalVestingAllocationPerAddress /(TotalVestingTermPerAddressInDays*24)
        // so here i am calculating value after divide operator which is _releasePartialValue
        // PLease verify 
         if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("second")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =  _vestingDays *24*60*60;

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("minute")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =  _vestingDays *24*60;

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("hour")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =  _vestingDays *24;

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("day")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =  _vestingDays *1;

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("week")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =  _vestingDays *7;

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("month")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =  _vestingDays *30;

        }else if(keccak256(abi.encodePacked(_releaseRate))== keccak256(abi.encodePacked("year")) ){
          releaseDate =   string.concat("1",_releaseRate);
          releaseDate =   string.concat(releaseDate,"s");
         _releasePartialValue =  _vestingDays *365;

        }



   

         for(uint i=0; i<_withdrawalAddress.length;i++)
         {         
            // SingleVesting storage single_vesting =vestedPool[i];
            SingleVesting storage single_vesting =vestedPool[_poolName][i];
            require(_amount[i]>0,"invalid Amount");
            single_vesting.pool.poolName = _poolName;
            single_vesting.pool.startDate = block.timestamp;
            single_vesting.pool.vestingDays = _vestingDays;
            single_vesting.pool.releaseRate = releaseDate;
            single_vesting.pool.releasePartialValue = _releasePartialValue;
            single_vesting.pool.lockPeriod = _lockPeriod;
            single_vesting.pool.tokenAddress = _tokenAddress;
            single_vesting.pool.poolTotalVestings =   single_vesting.pool.poolTotalVestings + 1;
            single_vesting.withdrawn = false;
            single_vesting.tokenWithdrawn = false;
            
            single_vesting.withdrawalAddress = _withdrawalAddress[i];
            single_vesting.tokenAmount = _amount[i];

                  
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
    *Check tokens count to withdrawl
    */
    
    function checkWithdrawlTokensCount(string memory _poolName,uint _id)  public  returns(uint256) {
            SingleVesting storage single_vesting =vestedPool[_poolName][_id];
            uint256 rewardCalculationPer = single_vesting.tokenAmount /  single_vesting.pool.releasePartialValue;   //500/172800=0.00289351851
            uint256 elaspedSeconds = block.timestamp - single_vesting.pool.startDate;
      
                 //  calculating the principle(total) Reward as well as the reward upto this function calling time
                 // please verify this as well
            if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1seconds")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays * 86400);    //principle total reward  
                     single_vesting.rewardAmnt =  rewardCalculationPer *  elaspedSeconds;               // By the time calculated reward

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1minutes")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays * 1440);
                     single_vesting.rewardAmnt =  rewardCalculationPer *  (elaspedSeconds / 60);

             }
            else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1hours")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays * 24);
                     single_vesting.rewardAmnt =  rewardCalculationPer * ( elaspedSeconds / 3600);   // seconds in an hour

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1days")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * single_vesting.pool.vestingDays;
                     single_vesting.rewardAmnt =  rewardCalculationPer * (elaspedSeconds / 86400);   // seconds in a day

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1weeks")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays / 7);
                     single_vesting.rewardAmnt =  rewardCalculationPer *  ( elaspedSeconds / 604800);  // seconds in a week

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1months")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * ( single_vesting.pool.vestingDays / 30);
                     single_vesting.rewardAmnt =  rewardCalculationPer * (elaspedSeconds / 2592000); // seconds in a month

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1years")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays / 365);
                     single_vesting.rewardAmnt =  rewardCalculationPer * ( elaspedSeconds / 31540000);   // seconds in a year
            }

            return   single_vesting.principleEstimatedReward ;

    }



      /**
    *Check tokens count to withdrawl-- helper
    */
    
    function checkWithdrawlTokenCount(string memory _poolName,uint _id)  internal {
            SingleVesting storage single_vesting =vestedPool[_poolName][_id];
            uint256 rewardCalculationPer = single_vesting.tokenAmount /  single_vesting.pool.releasePartialValue;   //500/172800=0.00289351851
            uint256 elaspedSeconds = block.timestamp - single_vesting.pool.startDate;
      
                 //  calculating the principle(total) Reward as well as the reward upto this function calling time
                 // please verify this as well
            if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1seconds")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays * 86400);    //principle total reward  
                     single_vesting.rewardAmnt =  rewardCalculationPer *  elaspedSeconds;               // By the time calculated reward

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1minutes")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays * 1440);
                     single_vesting.rewardAmnt =  rewardCalculationPer *  (elaspedSeconds / 60);

             }
            else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1hours")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays * 24);
                     single_vesting.rewardAmnt =  rewardCalculationPer * ( elaspedSeconds / 3600);   // seconds in an hour

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1days")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * single_vesting.pool.vestingDays;
                     single_vesting.rewardAmnt =  rewardCalculationPer * (elaspedSeconds / 86400);   // seconds in a day

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1weeks")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays / 7);
                     single_vesting.rewardAmnt =  rewardCalculationPer *  ( elaspedSeconds / 604800);  // seconds in a week

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1months")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * ( single_vesting.pool.vestingDays / 30);
                     single_vesting.rewardAmnt =  rewardCalculationPer * (elaspedSeconds / 2592000); // seconds in a month

            }else if(keccak256(abi.encodePacked(single_vesting.pool.releaseRate))== keccak256(abi.encodePacked("1years")) ){
                     single_vesting.principleEstimatedReward = rewardCalculationPer * (single_vesting.pool.vestingDays / 365);
                     single_vesting.rewardAmnt =  rewardCalculationPer * ( elaspedSeconds / 31540000);   // seconds in a year
            }


    }


 /**
     * Withdraw only vested tokens, not reward
     */
    function withdrawVestedTokens(string memory _poolName, uint256 _id) public {
        SingleVesting storage single_vesting =vestedPool[_poolName][_id];

        require(block.timestamp - single_vesting.pool.startDate <= single_vesting.pool.lockPeriod,"still locked");
        require(msg.sender == single_vesting.withdrawalAddress,"Invalid member");
        require(!single_vesting.withdrawn,"Already withdraw");

        single_vesting.withdrawn = true;

                 // Transfer tokens into contract
             require(
            IERC20(single_vesting.pool.tokenAddress).transfer(
                msg.sender,
                single_vesting.tokenAmount
            )
            );

        emit WithdrawalExecution(msg.sender, single_vesting.tokenAmount);

    

        // uint256 rewardCalculation = single_vesting.tokenAmount /  single_vesting.pool.releasePartialValue;
        // single_vesting.rewardAmnt =  single_vesting.rewardAmnt + rewardCalculation;
    }




     /**
     * Withdraw only the rewards, calculated so far
     */
    function withdrawRewards(string memory _poolName, uint256 _id) public {
        checkWithdrawlTokenCount(  _poolName,_id); 
        SingleVesting storage single_vesting =vestedPool[_poolName][_id];

        require(block.timestamp - single_vesting.pool.startDate <= single_vesting.pool.lockPeriod,"still locked");
        require(msg.sender == single_vesting.withdrawalAddress,"Invalid member");
        require(single_vesting.rewardAmnt>0,"0 Reward!");
        require(!single_vesting.tokenWithdrawn,"Already withdraw");

        single_vesting.tokenWithdrawn = true;
       

                 // Transfer tokens into contract
        require(
            IERC20(single_vesting.pool.tokenAddress).transfer(
                msg.sender,
                single_vesting.rewardAmnt
            )
            );
        emit RewardWithdrawalExecution(single_vesting.pool.poolName, msg.sender, single_vesting.rewardAmnt);

    

        // uint256 rewardCalculation = single_vesting.tokenAmount /  single_vesting.pool.releasePartialValue;
        // single_vesting.rewardAmnt =  single_vesting.rewardAmnt + rewardCalculation;
    }

    /**
    *Get Vestings detail using Pool number
    */
    // function checkVestings(uint256 _vestedPool) public returns(address[] memory,uint256[] memory){
    //    return (vestedPool[_vestedPool].withdrawalAddress,vestedPool[_vestedPool].amount);
    // }



  
}
