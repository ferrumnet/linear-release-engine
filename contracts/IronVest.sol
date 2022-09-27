// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Libraries/IIronVest.sol";

   /* 
    @author The ferrum network.
    @title This is a vesting contract named as VestingHarvestContarct.
    @dev This contract is upgradeable please use a framework i.e truffle or hardhat for deploying it.
    @notice This contract contains the power of accesscontrol.    
    Have fun reading it. Hopefully it's bug-free. God Bless.
    */
contract IronVest is  Initializable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    // Declaration of token interface with SafeErc20.
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // Public variable to strore contract name.
    string public vestingContractName;
    // Unique identity of contract.
    uint256 public vestingPoolSize;
    // Signer address. Transaction supposed to be sign be this address.
    address public signer;
    // For upgradeable initializer to check if the contract is initilized.
    bool private initialized;
    // Vester role initilization.
    bytes32 public constant VESTER_ROLE = keccak256("VESTER_ROLE");

    // Mappingg
    // Cliff mapping with the check if the specific pool relate to the cliff vesting or not.
    mapping(uint256 => bool) public cliff;
    // Pool information against specific poolid for simple vesting.
    mapping(uint256 => IIronVest.PoolInfo) poolInfo;
    // Pool information against specific poolid for cliff vesting.
    mapping(uint256 => IIronVest.CliffPoolInfo) cliffPoolInfo;
    // Double mapping to check user information by address and poolid for simple vesting.
    mapping(uint256 => mapping(address => IIronVest.UserInfo)) public userInfo;
    // Double mapping to check user information by address and poolid for cliff vesting.
    mapping(uint256 => mapping(address => IIronVest.UserCliffInfo))
        public UserCliffInfo;
    mapping(uint256 => mapping(address => IIronVest.UserNonCliffInfo))
        public userNonCliffInfo;
    mapping(bytes32 => bool) public usedHashes;

    /*
    @dev Creating events for all necessary values while adding simple vesting.
    @notice vester address and poolId are indexed.
    */
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

    /*
    @dev Creating events for all necessary values while adding cliff vesting.
    @notice vester address and poolId are indexed.
    */
    event CliffAddVesting(
        address indexed vester,
        uint256 indexed poolId,
        string poolName,
        uint256 vestingEndTime,
        uint256 cliffVestingEndTime,
        uint256 nonCliffVestingEndTime,
        uint256 cliffPeriodEndTime,
        address tokenAddress,
        uint256 totalVestedTokens,
        address[] usersAddresses,
        uint256[] usersAlloc
    );

    /*
    @dev Whenever user claim their amount from simple vesting.
    @notice beneficiary address and poolId are indexed.
    */
    event Claim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    /*
    @dev Whenever user claim their cliff amount from cliff vesting.
    @notice beneficiary address and poolId are indexed.
    */
    event CliffClaim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    /*
    @dev Whenever user claim their non cliff amount from cliff vesting.
    @notice beneficiary address and poolId are indexed.
    */
    event NonCliffClaim(
        uint256 indexed poolId,
        uint256 claimed,
        address indexed beneficiary,
        uint256 remaining
    );

    // Modifier to check if vester.
    modifier onlyVester() {
        require(
            hasRole(VESTER_ROLE, _msgSender()),
            "AccessDenied: Only Vester Call This Function"
        );
        _;
    }

    // Modifier to check if default admin.
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AccessDenied: Only Admin Call This Function"
        );
        _;
    }

    // constructor () EIP712('NAME', '0.0001') { }

    /*
    @dev deploy the contract by upgradeable proxy by any framewrok.
    @param vesting name and signer address.
    @notice Contract is upgradeable need initilization and deployer is default admin.
    */
    function initialize(string memory _vestingName, address _signer) public initializer {
        require(!initialized, "Contract instance has already been initialized");
        __ReentrancyGuard_init();
        __AccessControl_init();
        vestingContractName = _vestingName;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(VESTER_ROLE, _msgSender());
        signer = _signer;
        initialized = true;
    }

    /*
    @dev Only callable by vester.
    @param Pool name is supposed to be any string.
    @param Vesting time is tenure in which token will be released.
    @param Token address related to the vested token.
    @param Users addresses whom the vester want to allocate tokens and it is an array.
    @param Users allocation of tokens with respect to address.
    @param Signature of the signed by signer.
    @param Specific salt value.
    @notice Create a new vesting.
    */
    function addVesting(
        string memory _poolName,
        uint256 _vestingTime,
        address _tokenAddress,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc,
        bytes memory signature,
        bytes memory _keyHash
    ) public onlyVester nonReentrant {
        require(
            _vestingTime > block.timestamp,
            "IIronVest: Invalid Vesting Time"
        );
        require(
            signatureVerification(signature, _poolName, _tokenAddress, _keyHash) ==
                signer,
            "Signer: Invalid signer"
        );
        uint256 totalVesting;
        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            totalVesting += _userAlloc[i];
            userInfo[vestingPoolSize][_usersAddresses[i]] = IIronVest.UserInfo(
                _userAlloc[i],
                0,
                _userAlloc[i],
                block.timestamp,
                _userAlloc[i] / (_vestingTime - block.timestamp)
            );
        }
        poolInfo[vestingPoolSize] = IIronVest.PoolInfo(
            _poolName,
            block.timestamp,
            _vestingTime,
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
        cliff[vestingPoolSize] = false;
        vestingPoolSize = vestingPoolSize + 1;
        emit AddVesting(
            _msgSender(),
            vestingPoolSize,
            _poolName,
            block.timestamp,
            _vestingTime,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );
        bytes32 _salt = messageHash(_poolName, _tokenAddress, _keyHash);
        usedHashes[_salt] = true;

    }

    /*
    @dev User must have allocation in the pool.
    @notice This is for claiming simple vesting.
    @param poolId from which pool user want to withdraw.
    @notice Secured by nonReentrant
    */
    function claim(uint256 _poolId) external nonReentrant {
        uint256 transferAble = claimable(_poolId, _msgSender());
        require(transferAble > 0, "IIronVest: Invalid TransferAble");
        IERC20Upgradeable(poolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        IIronVest.UserInfo memory info = userInfo[_poolId][_msgSender()];
        uint256 claimed = (info.claimedAmount + transferAble);
        uint256 remainingToBeClaimable = info.allocation - claimed;
        userInfo[_poolId][_msgSender()].claimedAmount = claimed;
        userInfo[_poolId][_msgSender()]
            .remainingToBeClaimable = remainingToBeClaimable;
        userInfo[_poolId][_msgSender()].lastWithdrawal = block.timestamp;

        emit Claim(_poolId, transferAble, _msgSender(), remainingToBeClaimable);
    }

    /*
    @dev Only callable by vester.
    @param Pool name is supposed to be any string.
    @param Vesting time is tenure in which token will be released.
    @param cliff vesting time is the end time for releasing cliff tokens.
    @param cliff period is a period in which token will be locked.
    @param Token address related to the vested token.
    @param cliff percentage defines how may percentage should be allocated to cliff tokens.
    @param Users addresses whom the vester want to allocate tokens and it is an array.
    @param Users allocation of tokens with respect to address.
    @param Signature of the signed by signer.
    @param Specific salt value.
    @notice Create a new vesting with cliff.
    */
    function addCliffVesting(
        string memory _poolName,
        uint256 _vestingTime,
        uint256 _cliffVestingTime,
        uint256 _cliffPeriod,
        address _tokenAddress,
        uint256 _cliffPercentage10000,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc,
        bytes memory signature,
        bytes memory _keyHash
    ) external onlyVester nonReentrant {
        require(
            _vestingTime > block.timestamp,
            "IIronVest: IIronVest Time Must Be Greater Than Current Time"
        );
        require(
            _cliffVestingTime < _vestingTime,
            "IIronVest: Cliff Vesting Time Must Be Lesser Than IIronVest Time"
        );
        require(
            _cliffVestingTime > _cliffPeriod,
            "IIronVest: Cliff Vesting Time Must Be Greater Than Cliff Period"
        );
        require(
            _cliffPeriod > block.timestamp,
            "IIronVest: Cliff Period Time Must Be Greater Than Current Time"
        );
        require(
            signatureVerification(signature, _poolName, _tokenAddress, _keyHash) ==
                signer,
            "Signer: Invalid signer"
        );
        require(
            _cliffPercentage10000 <= 5000,
            "Percentage:Percentage Should Be less Than  50%"
        );
        require(
            _cliffPercentage10000 >= 50,
            "Percentage:Percentage Should Be More Than  0.5%"
        );

        uint256 nonCliffVestingEndTime = (_vestingTime - _cliffVestingTime) +
            _cliffPeriod;
        uint256 totalVesting;
        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            uint256 cliffAlloc = (_userAlloc[i] * _cliffPercentage10000) / 10000;
            totalVesting += _userAlloc[i];
            uint256 nonCliffReaminingTobeclaimable = _userAlloc[i] - cliffAlloc;
            UserCliffInfo[vestingPoolSize][_usersAddresses[i]] = IIronVest
                .UserCliffInfo(
                    _userAlloc[i],
                    cliffAlloc,
                    0,
                    _cliffPeriod,
                    cliffAlloc,
                    (cliffAlloc) / (_cliffVestingTime - _cliffPeriod),
                    _cliffPeriod
                );
            userNonCliffInfo[vestingPoolSize][_usersAddresses[i]] = IIronVest
                .UserNonCliffInfo(
                    _userAlloc[i],
                    nonCliffReaminingTobeclaimable,
                    0,
                    _cliffPeriod,
                    nonCliffReaminingTobeclaimable,
                    (_userAlloc[i] - (cliffAlloc)) /
                        (nonCliffVestingEndTime - _cliffPeriod),
                    _cliffPeriod
                );
        }
        cliffPoolInfo[vestingPoolSize] = IIronVest.CliffPoolInfo(
            _poolName,
            block.timestamp,
            _vestingTime,
            _cliffVestingTime,
            (_vestingTime - _cliffVestingTime) + _cliffPeriod,
            _cliffPeriod,
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
        cliff[vestingPoolSize] = true;
        vestingPoolSize = vestingPoolSize + 1;
        emit CliffAddVesting(
            _msgSender(),
            vestingPoolSize,
            _poolName,
            _vestingTime,
            _cliffVestingTime,
            nonCliffVestingEndTime,
            _cliffPeriod,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );
        bytes32 _salt = messageHash(_poolName, _tokenAddress, _keyHash);
        usedHashes[_salt] = true;
    }

    /*
    @dev User must have allocation in the pool.
    @notice This is for claiming cliff vesting.
    @notice should be called if need to claim cliff amount.
    @param poolId from which pool user want to withdraw.
    @notice Secured by nonReentrant.
    */
    function claimCliff(uint256 _poolId) external nonReentrant {
        IIronVest.UserCliffInfo memory info = UserCliffInfo[_poolId][
            _msgSender()
        ];
        require(
            cliffPoolInfo[_poolId].cliffPeriodEndTime < block.timestamp,
            "IIronVest: Cliff Period Is Not Over Yet"
        );

        uint256 transferAble = cliffClaimable(_poolId, _msgSender());
        require(transferAble > 0, "IIronVest: Invalid TransferAble");
        IERC20Upgradeable(cliffPoolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 claimed = transferAble + info.claimedAmnt;
        uint256 remainingTobeClaimable = info.cliffAlloc - claimed;
        UserCliffInfo[_poolId][_msgSender()].claimedAmnt = claimed;
        UserCliffInfo[_poolId][_msgSender()]
            .remainingToBeClaimableCliff = remainingTobeClaimable;
        UserCliffInfo[_poolId][_msgSender()].cliffLastWithdrawal = block
            .timestamp;

        emit CliffClaim(
            _poolId,
            transferAble,
            _msgSender(),
            remainingTobeClaimable
        );
    }

    /*
    @dev User must have allocation in the pool.
    @notice This is for claiming cliff vesting.
    @notice should be called if need to claim non cliff amount.
    @param poolId from which pool user want to withdraw.
    @notice Secured by nonReentrant.
    */
    function claimNonCliff(uint256 _poolId) external nonReentrant {
        IIronVest.UserNonCliffInfo memory info = userNonCliffInfo[_poolId][
            _msgSender()
        ];
        require(
            cliffPoolInfo[_poolId].cliffPeriodEndTime < block.timestamp,
            "IIronVest: Cliff Period Is Not Over Yet"
        );

        uint256 transferAble = nonCliffClaimable(_poolId, _msgSender());
        uint256 claimed = transferAble + info.claimedAmnt;
        require(transferAble > 0, "IIronVest: Invalid TransferAble");
        IERC20Upgradeable(cliffPoolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 remainingTobeClaimable = info.nonCliffAlloc - claimed;
        userNonCliffInfo[_poolId][_msgSender()].claimedAmnt = claimed;
        userNonCliffInfo[_poolId][_msgSender()]
            .remainingToBeClaimableNonCliff = remainingTobeClaimable;
        userNonCliffInfo[_poolId][_msgSender()].nonCliffLastWithdrawal = block
            .timestamp;
        emit NonCliffClaim(
            _poolId,
            transferAble,
            _msgSender(),
            remainingTobeClaimable
        );
    }

    /*
    @dev This is check claimable for simple vesting.
    @param poolId from which pool user want to check.
    @param user address for which user want to check claimables.
    @return returning the claimable amount of the user
    */
    function claimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 claimable;
        IIronVest.UserInfo memory info = userInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation: You Don't have allocation in this pool"
        );
        if (poolInfo[_poolId].startTime < block.timestamp) {
            if (poolInfo[_poolId].vestingEndTime < block.timestamp) {
                claimable = info.remainingToBeClaimable;
            } else if (poolInfo[_poolId].vestingEndTime > block.timestamp) {
                claimable =
                    (block.timestamp - info.lastWithdrawal) *
                    info.releaseRatePerSec;
            }
        } else {
            claimable = 0;
        }
        return (claimable);
    }

    /*
    @dev This is check claimable for cliff vesting.
    @param poolId from which pool user want to check.
    @param user address for which user want to check claimables.
    @return returning the claimable amount of the user from cliff vesting.
    */
    function cliffClaimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 cliffClaimable;
        IIronVest.UserCliffInfo memory info = UserCliffInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation: You Don't have allocation in this pool"
        );

        if (cliffPoolInfo[_poolId].cliffPeriodEndTime < block.timestamp) {
            if (cliffPoolInfo[_poolId].cliffVestingEndTime > block.timestamp) {
                cliffClaimable =
                    (block.timestamp - info.cliffLastWithdrawal) *
                    info.cliffReleaseRatePerSec;
            } else cliffClaimable = info.remainingToBeClaimableCliff;
        } else cliffClaimable = 0;

        return (cliffClaimable);
    }

    /*
    @dev This is check claimable for non cliff vesting.
    @param poolId from which pool user want to check.
    @param user address for which user want to check claimables.
    @return returning the claimable amount of the user from non cliff vesting.
    */
    function nonCliffClaimable(uint256 _poolId, address _user)
        public
        view
        returns (uint256)
    {
        uint256 nonCliffClaimable;
        IIronVest.UserNonCliffInfo memory info = userNonCliffInfo[_poolId][
            _user
        ];
        require(
            info.allocation > 0,
            "Allocation: You Don't have allocation in this pool"
        );

        if (cliffPoolInfo[_poolId].cliffPeriodEndTime < block.timestamp) {
            if (
                cliffPoolInfo[_poolId].nonCliffVestingEndTime > block.timestamp
            ) {
                nonCliffClaimable =
                    (block.timestamp - info.nonCliffLastWithdrawal) *
                    info.nonCliffReleaseRatePerSec;
            } else nonCliffClaimable = info.remainingToBeClaimableNonCliff;
        } else nonCliffClaimable = 0;

        return (nonCliffClaimable);
    }

    /*
    @dev As we are using poolId as unique ID which is supposed to return pool info i.e
    poolInfo and cliffPoolInfo but it unique for the contract level this function will 
    return the values from where this poolId relate to.
    @param _piilId : poolId
    @return bool : if this Id relate to the cliffPool or note?
    @return poolName : poolName If exist.
    @return vestingEndTime : vestingEndTime of this Pool.
    @return cliffVestingEndTime : cliffVestingEndTime If exist and if also a cliffPool.
    @return nonCliffVestingEndTime : nonCliffVestingEndTime If exist and also a cliffPool.
    @return cliffPeriodEndTime : cliffPeriodEndTime If exist and also a cliffPool.
    @return tokenAddress :  Vested token address If exist.
    @return totalVestedTokens : totalVestedTokens If exist.
    @return cliffLockPercentage : cliffLockPercentage If exist and also a cliffPool.
    */
    function poolInformation(uint256 _poolId)
        public
        view
        returns (
            bool isCliff,
            string memory poolName,
            uint256 startTime,
            uint256 vestingEndTime,
            uint256 cliffVestingEndTime,
            uint256 nonCliffVestingEndTime,
            uint256 cliffPeriodEndTime,
            address tokenAddress,
            uint256 totalVestedTokens,
            uint256 cliffLockPercentage
        )
    {
        // bool isCliff = cliff[_poolId];
        if (cliff[_poolId]) {
            IIronVest.CliffPoolInfo memory info = cliffPoolInfo[_poolId];
            return (
                isCliff,
                info.poolName,
                info.startTime,
                info.vestingEndTime,
                info.cliffVestingEndTime,
                info.nonCliffVestingEndTime,
                info.cliffPeriodEndTime,
                info.tokenAddress,
                info.totalVestedTokens,
                info.cliffLockPercentage10000
            );
        } else {
            IIronVest.PoolInfo memory info = poolInfo[_poolId];
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

    /*
    @dev Functions is called by a default admin.
    @param user address whom admin want to be a signer.
    */
    function setSigner(address _signer) public onlyAdmin {
        require(_signer != address(0x00), "Invalid: Signer Address Is Invalid");
        signer = _signer;
    }

    /*
    @dev For geting signer address from salt and sgnature.
    @param sig : signature provided signed by signer
    @return Address of signer who signed the message hash
    */
    function signatureVerification(
        bytes memory signature,
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) public view returns (address) {
        bytes32 _salt = messageHash(_poolName, _tokenAddress, _keyHash);
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        require(!usedHashes[_salt], "Message already used");

        address _user = verifyMessage(_salt, v, r, s);
        return _user;
    }

    /*
    @dev For splititng signature.
    @param sig : signature provided signed by signer
    @return r: First 32 bytes stores the length of the signature.
    @return s: add(sig, 32) = pointer of sig + 32
    effectively, skips first 32 bytes of signature.
    @return v: mload(p) loads next 32 bytes starting
    at the memory address p into memory.
    */
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

    /*
    @dev Verify and recover signer from salt and signature.
    @param r: First 32 bytes stores the length of the signature.
    @param s: add(sig, 32) = pointer of sig + 32
    effectively, skips first 32 bytes of signature.
    @param v: mload(p) loads next 32 bytes starting
    at the memory address p into memory.
    @return returning the address of signer.
    */
    function verifyMessage(
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _salt)
        );
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function messageHash(
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) public view returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        bytes32 hash = keccak256(
            abi.encodePacked(_poolName, _tokenAddress, _keyHash, block.chainid)
        );
        return hash;
    }

    function getsalt(
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) public view returns (bytes memory) {
        return abi.encodePacked(_poolName, _tokenAddress, _keyHash, block.chainid);
    }
}
