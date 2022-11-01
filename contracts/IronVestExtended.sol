// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IronVestLib.sol";

/// @author The ferrum network.
/// @title This is a vesting contract named as IronVest.
/// @dev This contract is upgradeable please use a framework i.e truffle or hardhat for deploying it.
/// @notice This contract contains the power of accesscontrol.
/// There are two different vesting defined in the contract with different functionalities.
/// Have fun reading it. Hopefully it's bug-free. God Bless.
contract IronVestExtended is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    /// @notice Declaration of token interface with SafeErc20.
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Vester role initilization.
    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");
    /// @notice Unique identity of contract.
    uint256 public vestingPoolSize;
    IronVestLib public Lib;

    /// Cliff mapping with the check if the specific pool relate to the cliff vesting or not.
    mapping(uint256 => bool) public cliff;
    /// Double mapping to check user information by address and poolid for cliff vesting.
    mapping(uint256 => mapping(address => IronVestLib.UserInfo))
        public userInfo;
    /// Double mapping to check user information by address and poolid for cliff vesting.
    mapping(uint256 => mapping(address => IronVestLib.UserCliffInfo))
        public userCliffInfo;
    /// Double mapping to check user information by address and poolid for cliff vesting.
    mapping(uint256 => mapping(address => IronVestLib.UserNonCliffInfo))
        public userNonCliffInfo;
    // Get updated address from outdated address
    mapping(address => address) public deprecatedAddressOf;
    /// Pool information against specific poolid for simple vesting.
    mapping(uint256 => IronVestLib.PoolInfo) internal _poolInfo;
    /// Pool information against specific poolid for cliff vesting.
    mapping(uint256 => IronVestLib.CliffPoolInfo) internal _cliffPoolInfo;

    /// @dev Creating events for all necessary values while adding simple vesting.
    /// @notice vester address and poolId are indexed.
    event AddVesting(
        address indexed vester,
        uint256 indexed poolId,
        string poolName,
        uint256 startTime,
        uint256 vestingEndTime,
        address tokenAddress,
        uint256 totalVestedTokens,
        address[] usersAddresses,
        uint256[] usersAlloc
    );

    /// @dev Creating events for all necessary values while adding cliff vesting.
    /// @notice vester address and poolId are indexed.
    event CliffAddVesting(
        address indexed vester,
        uint256 indexed poolId,
        string poolName,
        uint256 vestingEndTime,
        uint256 cliffVestingEndTime,
        uint256 cliffPeriodEndTime,
        address tokenAddress,
        uint256 totalVestedTokens,
        address[] usersAddresses,
        uint256[] usersAlloc
    );

    /// @dev Whenever user claim their amount from simple vesting.
    /// @notice beneficiary address and poolId are indexed.
    event Claim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    /// @dev Whenever user claim their cliff amount from cliff vesting.
    /// @notice beneficiary address and poolId are indexed.
    event CliffClaim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    /// @dev Whenever user claim their non cliff amount from cliff vesting.
    /// @notice beneficiary address and poolId are indexed.
    event NonCliffClaim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    /// @dev This event will emit if there is a need to update allocation to new address.
    /// @notice Deprecated, updated address and poolId indexed
    event UpdateBeneficiaryWithdrawlAddress(
        uint256 indexed poolId,
        address indexed deprecatedAddress,
        address indexed newAddress,
        bool isCliff
    );

    /// @notice Modifier to check if vester.
    modifier onlyVester() {
        require(
            hasRole(VESTER_ROLE, _msgSender()),
            "AccessDenied : Only Vester Call This Function"
        );
        _;
    }

    /// @notice Modifier to check if DEFAULT_ADMIN and Deployer of contract.
    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AccessDenied : Only Admin Call This Function"
        );
        _;
    }

    /// @dev deploy the contract by upgradeable proxy by any framewrok.
    /// @param _signer : An address verification for facing the replay attack issues.
    /// @notice Contract is upgradeable need initilization and deployer is default admin.
    function initialize(address _signer, IronVestLib _lib)
        external
        initializer
    {
        __ReentrancyGuard_init();
        __AccessControl_init();
        Lib = _lib;
        Lib.initialize(_signer);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(VESTER_ROLE, _msgSender());
    }

    /// @dev Only callable by vester.
    /// @param _poolName : Pool name is supposed to be any string.
    /// @param _vestingEndTime : Vesting time is tenure in which token will be released.
    /// @param _tokenAddress : Token address related to the vested token.
    /// @param _usersAddresses : Users addresses whom the vester want to allocate tokens and it is an array.
    /// @param _userAlloc : Users allocation of tokens with respect to address.
    /// @param _signature : Signature of the signed by signer.
    /// @param _keyHash : Specific keyhash value formed to stop replay.
    /// @notice Create a new vesting.
    function addVesting(
        string memory _poolName,
        uint256 _vestingEndTime,
        address _tokenAddress,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc,
        bytes memory _signature,
        bytes memory _keyHash
    ) external onlyVester nonReentrant {
        uint256 totalVesting;
        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            totalVesting += _userAlloc[i];
            userInfo[vestingPoolSize][_usersAddresses[i]] = IronVestLib
                .UserInfo(
                    _userAlloc[i],
                    0,
                    _userAlloc[i],
                    block.timestamp,
                    _userAlloc[i] / (_vestingEndTime - block.timestamp),
                    false,
                    address(0x00)
                );
        }
        _poolInfo[vestingPoolSize] = IronVestLib.PoolInfo(
            _poolName,
            block.timestamp,
            _vestingEndTime,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            totalVesting
        );
        Lib.preAddVesting(
            _poolName,
            _vestingEndTime,
            _tokenAddress,
            _usersAddresses,
            _userAlloc,
            _signature,
            _keyHash
        );
        Lib.usedHash(true, _poolName, _tokenAddress, _keyHash);
        emit AddVesting(
            _msgSender(),
            vestingPoolSize,
            _poolName,
            block.timestamp,
            _vestingEndTime,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );
        vestingPoolSize = vestingPoolSize + 1;
    }

    /// @dev User must have allocation in the pool.
    /// @notice This is for claiming simple vesting.
    /// @param _poolId : poolId from which pool user want to withdraw.
    /// @notice Secured by nonReentrant
    function claim(uint256 _poolId) external nonReentrant {
        uint256 transferAble = claimable(_poolId, _msgSender());
        IronVestLib.UserInfo storage info = userInfo[_poolId][_msgSender()];
        require(transferAble > 0, "IIronVest : Invalid TransferAble");
        IERC20Upgradeable(_poolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 claimed = (info.claimedAmount + transferAble);
        uint256 remainingToBeClaimable = info.allocation - claimed;
        info.claimedAmount = claimed;
        info.remainingToBeClaimable = remainingToBeClaimable;
        info.lastWithdrawal = block.timestamp;
        emit Claim(
            _poolId,
            transferAble,
            _msgSender(),
            info.remainingToBeClaimable
        );
    }

    /// @dev Only callable by vester.
    /// @param _poolName : Pool name is supposed to be any string.
    /// @param _vestingEndTime : Vesting time is tenure in which token will be released.
    /// @param _cliffVestingEndTime : cliff vesting time is the end time for releasing cliff tokens.
    /// @param _cliffPeriodEndTime : cliff period is a period in which token will be locked.
    /// @param _tokenAddress : Token address related to the vested token.
    /// @param _cliffPercentage10000 : cliff percentage defines how may percentage should be allocated to cliff tokens.
    /// @param _usersAddresses : Users addresses whom the vester want to allocate tokens and it is an array.
    /// @param _userAlloc : Users allocation of tokens with respect to address.
    /// @param _signature : Signature of the signed by signer.
    /// @param _keyHash : Specific keyhash value formed to stop replay.
    /// @notice Create a new vesting with cliff.
    function addCliffVesting(
        string memory _poolName,
        uint256 _vestingEndTime,
        uint256 _cliffVestingEndTime,
        uint256 _cliffPeriodEndTime,
        address _tokenAddress,
        uint256 _cliffPercentage10000,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc,
        bytes memory _signature,
        bytes memory _keyHash
    ) external onlyVester nonReentrant {
        uint256 totalVesting;
        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            uint256 cliffAlloc = (_userAlloc[i] * _cliffPercentage10000) /
                10000;
            totalVesting += _userAlloc[i];
            uint256 nonCliffReaminingTobeclaimable = _userAlloc[i] - cliffAlloc;
            userCliffInfo[vestingPoolSize][_usersAddresses[i]] = IronVestLib
                .UserCliffInfo(
                    _userAlloc[i],
                    cliffAlloc,
                    0,
                    _cliffPeriodEndTime,
                    cliffAlloc,
                    (cliffAlloc) / (_cliffVestingEndTime - _cliffPeriodEndTime),
                    _cliffPeriodEndTime,
                    false,
                    address(0x00)
                );
            userNonCliffInfo[vestingPoolSize][_usersAddresses[i]] = IronVestLib
                .UserNonCliffInfo(
                    _userAlloc[i],
                    nonCliffReaminingTobeclaimable,
                    0,
                    _cliffPeriodEndTime,
                    nonCliffReaminingTobeclaimable,
                    (_userAlloc[i] - (cliffAlloc)) /
                        (_vestingEndTime - _cliffPeriodEndTime),
                    _cliffPeriodEndTime,
                    false,
                    address(0x00)
                );
        }
        uint256 nonCliffVestingPeriod = _vestingEndTime - _cliffPeriodEndTime;
        _cliffPoolInfo[vestingPoolSize] = IronVestLib.CliffPoolInfo(
            _poolName,
            block.timestamp,
            _vestingEndTime,
            _cliffVestingEndTime,
            nonCliffVestingPeriod,
            _cliffPeriodEndTime,
            _tokenAddress,
            totalVesting,
            _cliffPercentage10000,
            _usersAddresses,
            _userAlloc
        );
        IERC20Upgradeable(_tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            totalVesting
        );
        Lib.preAddCliffVesting(
            _poolName,
            _vestingEndTime,
            _cliffVestingEndTime,
            _cliffPeriodEndTime,
            _tokenAddress,
            _cliffPercentage10000,
            _usersAddresses,
            _userAlloc,
            _signature,
            _keyHash
        );
        Lib.usedHash(true, _poolName, _tokenAddress, _keyHash);
        cliff[vestingPoolSize] = true;
        emit CliffAddVesting(
            _msgSender(),
            vestingPoolSize,
            _poolName,
            _vestingEndTime,
            _cliffVestingEndTime,
            _cliffPeriodEndTime,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );
        vestingPoolSize = vestingPoolSize + 1;
    }

    /// @dev Only callable by owner.
    /// @param _poolId : On which pool admin want to update user address.
    /// @param _deprecatedAddress : Old address that need to be updated.
    /// @param _updatedAddress : New address that gonna replace old address.
    /// @notice This function is useful whenever a person lose their address which has pool allocation.
    /// @notice If else block will specify if the pool ID is related to cliff vesting or simple vesting.
    function updateBeneficiaryAddress(
        uint256 _poolId,
        address _deprecatedAddress,
        address _updatedAddress
    ) external virtual onlyOwner nonReentrant {
        bool isCliff = cliff[_poolId];
        if (isCliff) {
            IronVestLib.CliffPoolInfo storage pool = _cliffPoolInfo[_poolId];
            IronVestLib.UserCliffInfo storage cliffInfo = userCliffInfo[
                _poolId
            ][_deprecatedAddress];
            IronVestLib.UserNonCliffInfo
                storage nonCliffInfo = userNonCliffInfo[_poolId][
                    _deprecatedAddress
                ];
            require(
                nonCliffInfo.allocation > 0,
                "Allocation : This address doesn't have allocation in this pool"
            );
            userNonCliffInfo[_poolId][_updatedAddress] = IronVestLib
                .UserNonCliffInfo(
                    nonCliffInfo.allocation,
                    nonCliffInfo.nonCliffAlloc,
                    nonCliffInfo.claimedAmnt,
                    nonCliffInfo.tokensReleaseTime,
                    nonCliffInfo.remainingToBeClaimableNonCliff,
                    nonCliffInfo.nonCliffReleaseRatePerSec,
                    nonCliffInfo.nonCliffLastWithdrawal,
                    false,
                    address(0x00)
                );
            userCliffInfo[_poolId][_updatedAddress] = IronVestLib.UserCliffInfo(
                cliffInfo.allocation,
                cliffInfo.cliffAlloc,
                cliffInfo.claimedAmnt,
                cliffInfo.tokensReleaseTime,
                cliffInfo.remainingToBeClaimableCliff,
                cliffInfo.cliffReleaseRatePerSec,
                cliffInfo.cliffLastWithdrawal,
                false,
                address(0x00)
            );
            cliffInfo.allocation = 0;
            cliffInfo.updatedAddress = _updatedAddress;
            cliffInfo.deprecated = true;
            nonCliffInfo.allocation = 0;
            nonCliffInfo.updatedAddress = _updatedAddress;
            nonCliffInfo.deprecated = true;
            pool.usersAddresses.push(_updatedAddress);
            pool.usersAlloc.push(cliffInfo.allocation);
        } else {
            IronVestLib.PoolInfo storage pool = _poolInfo[_poolId];
            IronVestLib.UserInfo storage info = userInfo[_poolId][
                _deprecatedAddress
            ];
            require(
                info.allocation > 0,
                "Allocation : This address doesn't have allocation in this pool"
            );
            userInfo[_poolId][_updatedAddress] = IronVestLib.UserInfo(
                info.allocation,
                info.claimedAmount,
                info.remainingToBeClaimable,
                info.lastWithdrawal,
                info.releaseRatePerSec,
                false,
                address(0x00)
            );
            info.allocation = 0;
            info.updatedAddress = _updatedAddress;
            info.deprecated = true;
            pool.usersAddresses.push(_updatedAddress);
            pool.usersAlloc.push(info.allocation);
        }
        Lib.preUpdateBeneficiaryAddress(
            _poolId,
            _deprecatedAddress,
            _updatedAddress,
            vestingPoolSize
        );
        deprecatedAddressOf[_updatedAddress] = _deprecatedAddress;
        emit UpdateBeneficiaryWithdrawlAddress(
            _poolId,
            _deprecatedAddress,
            _updatedAddress,
            isCliff
        );
    }

    /// @dev Functions is called by a default admin.
    /// @param _signer : An address whom admin want to be a signer.
    function setSigner(address _signer) external onlyOwner {
        Lib.setSigner(_signer);
    }

    /// @dev User must have allocation in the pool.
    /// @notice This is for claiming cliff vesting.
    /// @notice should be called if need to claim cliff amount.
    /// @param _poolId : Pool Id from which pool user want to withdraw.
    /// @notice Secured by nonReentrant.
    function claimCliff(uint256 _poolId) external nonReentrant {
        IronVestLib.UserCliffInfo storage info = userCliffInfo[_poolId][
            _msgSender()
        ];
        require(
            _cliffPoolInfo[_poolId].cliffPeriodEndTime < block.timestamp,
            "IIronVest : Cliff Period Is Not Over Yet"
        );

        uint256 transferAble = cliffClaimable(_poolId, _msgSender());
        require(transferAble > 0, "IIronVest : Invalid TransferAble");
        IERC20Upgradeable(_cliffPoolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 claimed = transferAble + info.claimedAmnt;
        uint256 remainingTobeClaimable = info.cliffAlloc - claimed;
        info.claimedAmnt = claimed;
        info.remainingToBeClaimableCliff = remainingTobeClaimable;
        info.cliffLastWithdrawal = block.timestamp;

        emit CliffClaim(
            _poolId,
            transferAble,
            _msgSender(),
            remainingTobeClaimable
        );
    }

    /// @dev User must have allocation in the pool.
    /// @notice This is for claiming cliff vesting.
    /// @notice should be called if need to claim non cliff amount.
    /// @param _poolId : Pool Id from which pool user want to withdraw.
    /// @notice Secured by nonReentrant.
    function claimNonCliff(uint256 _poolId) external nonReentrant {
        IronVestLib.UserNonCliffInfo storage info = userNonCliffInfo[_poolId][
            _msgSender()
        ];
        require(
            _cliffPoolInfo[_poolId].cliffPeriodEndTime < block.timestamp,
            "IIronVest : Cliff Period Is Not Over Yet"
        );

        uint256 transferAble = nonCliffClaimable(_poolId, _msgSender());
        uint256 claimed = transferAble + info.claimedAmnt;
        require(transferAble > 0, "IIronVest : Invalid TransferAble");
        IERC20Upgradeable(_cliffPoolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 remainingTobeClaimable = info.nonCliffAlloc - claimed;
        info.claimedAmnt = claimed;
        info.remainingToBeClaimableNonCliff = remainingTobeClaimable;
        info.nonCliffLastWithdrawal = block.timestamp;
        emit NonCliffClaim(
            _poolId,
            transferAble,
            _msgSender(),
            remainingTobeClaimable
        );
    }

    /// @dev this function use to withdraw tokens that send to the contract mistakenly
    /// @param _token : Token address that is required to withdraw from contract.
    /// @param _amount : How much tokens need to withdraw.
    function emergencyWithdraw(IERC20Upgradeable _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
    }

    /// @dev As we are using poolId as unique ID which is supposed to return pool info i.e
    /// _poolInfo and _cliffPoolInfo but it unique for the contract level this function will
    /// return the values from where this poolId relate to.
    /// @param _poolId : Every Pool has a unique Id.
    /// @return isCliff : If this Id relate to the cliffPool or note?
    /// @return poolName : PoolName If exist.
    /// @return startTime : When does this pool initialized .
    /// @return vestingEndTime : Vesting End Time of this Pool.
    /// @return cliffVestingEndTime : CliffVestingEndTime If exist and if also a cliffPool.
    /// @return nonCliffVestingPeriod : Non CliffVesting Period If exist and also a cliffPool.
    /// @return cliffPeriodEndTime : Cliff Period End Time If exist and also a cliffPool.
    /// @return tokenAddress :  Vested token address If exist.
    /// @return totalVestedTokens : total Vested Tokens If exist.
    /// @return cliffLockPercentage : CliffLockPercentage If exist and also a cliffPool.
    function poolInformation(uint256 _poolId)
        external
        view
        returns (
            bool isCliff,
            string memory poolName,
            uint256 startTime,
            uint256 vestingEndTime,
            uint256 cliffVestingEndTime,
            uint256 nonCliffVestingPeriod,
            uint256 cliffPeriodEndTime,
            address tokenAddress,
            uint256 totalVestedTokens,
            uint256 cliffLockPercentage
        )
    {
        bool isCliff = cliff[_poolId];
        if (isCliff) {
            IronVestLib.CliffPoolInfo memory info = _cliffPoolInfo[_poolId];
            return (
                isCliff,
                info.poolName,
                info.startTime,
                info.vestingEndTime,
                info.cliffVestingEndTime,
                info.nonCliffVestingPeriod,
                info.cliffPeriodEndTime,
                info.tokenAddress,
                info.totalVestedTokens,
                info.cliffLockPercentage10000
            );
        } else {
            IronVestLib.PoolInfo memory info = _poolInfo[_poolId];
            return (
                isCliff,
                info.poolName,
                info.startTime,
                info.vestingEndTime,
                0,
                0,
                0,
                info.tokenAddress,
                info.totalVestedTokens,
                0
            );
        }
    }

    /// @dev This is check claimable for simple vesting.
    /// @param _poolId : Pool Id from which pool user want to check.
    /// @param _user : User address for which user want to check claimables.
    /// @return returning the claimable amount of the user
    function claimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 claimable;
        IronVestLib.UserInfo memory info = userInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation : You Don't have allocation in this pool"
        );
        if (_poolInfo[_poolId].vestingEndTime <= block.timestamp) {
            claimable = info.remainingToBeClaimable;
        } else
            claimable =
                (block.timestamp - info.lastWithdrawal) *
                info.releaseRatePerSec;

        return (claimable);
    }

    /// @dev This is check claimable for non cliff vesting.
    /// @param _poolId : Pool Id from which pool user want to check.
    /// @param _user : User address for which user want to check claimables.
    /// @return returning the claimable amount of the user from non cliff vesting.
    function nonCliffClaimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 nonCliffClaimable;
        IronVestLib.UserNonCliffInfo memory info = userNonCliffInfo[_poolId][
            _user
        ];
        require(
            info.allocation > 0,
            "Allocation : You Don't have allocation in this pool"
        );

        if (_cliffPoolInfo[_poolId].cliffPeriodEndTime <= block.timestamp) {
            if (_cliffPoolInfo[_poolId].vestingEndTime >= block.timestamp) {
                nonCliffClaimable =
                    (block.timestamp - info.nonCliffLastWithdrawal) *
                    info.nonCliffReleaseRatePerSec;
            } else nonCliffClaimable = info.remainingToBeClaimableNonCliff;
        }

        return (nonCliffClaimable);
    }

    /// @dev This is check claimable for cliff vesting.
    /// @param _poolId : Pool Id from which pool user want to check.
    /// @param _user : User address for which user want to check claimables.
    /// @return returning the claimable amount of the user from cliff vesting.
    function cliffClaimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 cliffClaimable;
        IronVestLib.UserCliffInfo memory info = userCliffInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation : You Don't have allocation in this pool"
        );

        if (_cliffPoolInfo[_poolId].cliffPeriodEndTime <= block.timestamp) {
            if (
                _cliffPoolInfo[_poolId].cliffVestingEndTime >= block.timestamp
            ) {
                cliffClaimable =
                    (block.timestamp - info.cliffLastWithdrawal) *
                    info.cliffReleaseRatePerSec;
            } else cliffClaimable = info.remainingToBeClaimableCliff;
        }

        return (cliffClaimable);
    }

     function usedHashes(bytes32 _hash) external view returns (bool usedHashes) {
        return Lib.usedHash(_hash);
    }
}
