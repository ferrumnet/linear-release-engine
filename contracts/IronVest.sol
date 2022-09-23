// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
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
contract VestingHarvestContarct is
    AccessControl,
    Initializable,
    ReentrancyGuardUpgradeable
{
    // Declaration of token interface with SafeErc20.
    using SafeERC20 for IERC20;
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
    mapping(uint256 => IVesting.PoolInfo) public poolInfo;
    // Pool information against specific poolid for cliff vesting.
    mapping(uint256 => IVesting.CliffPoolInfo) public cliffPoolInfo;
    // Double mapping to check user information by address and poolid for simple vesting.
    mapping(uint256 => mapping(address => IVesting.UserInfo)) public userInfo;
    // Double mapping to check user information by address and poolid for cliff vesting.
    mapping(uint256 => mapping(address => IVesting.UserClifInfo))
        public userClifInfo;
    mapping(uint256 => mapping(address => IVesting.UserNonClifInfo))
        public userNonClifInfo;

    /*
    @dev Creating events for all necessary values while adding simple vesting.
    @notice vester address and poolId are indexed.
    */
    event AddVesting(
        address indexed vester,
        uint256 indexed poolId,
        string poolName,
        uint256 startDate,
        uint256 vestingTime,
        address tokenAddress,
        uint256 totalVesting,
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
        uint256 vestingTime,
        uint256 cliffVestingTime,
        uint256 nonCliffVestingTime,
        uint256 cliffPeriod,
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

    /*
    @dev deploy the contract by upgradeable proxy by any framewrok.
    @param vesting name and signer address.
    @notice Contract is upgradeable need initilization and deployer is default admin.
    */
    function initialize(string memory _vestingName, address _signer) public {
        require(!initialized, "Contract instance has already been initialized");
        vestingContractName = _vestingName;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VESTER_ROLE, msg.sender);
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
        bytes32 _salt
    ) external onlyVester nonReentrant {
        require(
            _vestingTime > block.timestamp,
            "IVesting: Invalid IVesting Time"
        );
        require(
            signatureVerification(signature, _salt) == signer,
            "Signer: Invalid signer"
        );
        uint256 totalvesting;
        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            totalvesting += _userAlloc[i];
            userInfo[vestingPoolSize][_usersAddresses[i]] = IVesting.UserInfo(
                _userAlloc[i],
                0,
                _userAlloc[i],
                block.timestamp,
                _userAlloc[i] / _vestingTime - block.timestamp
            );
        }
        poolInfo[vestingPoolSize] = IVesting.PoolInfo(
            _poolName,
            block.timestamp,
            _vestingTime,
            _tokenAddress,
            totalvesting,
            _usersAddresses,
            _userAlloc
        );
        IERC20(_tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            totalvesting
        );
        cliff[vestingPoolSize] = false;
        emit AddVesting(
            _msgSender(),
            vestingPoolSize,
            _poolName,
            block.timestamp,
            _vestingTime,
            _tokenAddress,
            totalvesting,
            _usersAddresses,
            _userAlloc
        );
        vestingPoolSize = vestingPoolSize + 1;
    }

    /*
    @dev User must have allocation in the pool.
    @notice This is for claiming simple vesting.
    @param poolId from which pool user want to withdraw.
    @notice Secured by nonReentrant
    */
    function claim(uint256 _poolId) external nonReentrant {
        uint256 transferAble = claimable(_poolId, _msgSender());
        IERC20(poolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        IVesting.UserInfo memory info = userInfo[_poolId][_msgSender()];
        require(
            block.timestamp > poolInfo[_poolId].startDate,
            "IVesting: Lock Time Is Not Over Yet"
        );
        require(transferAble > 0, "IVesting: Invalid TransferAble");
        uint256 claimed = (info.claimedAmount + transferAble);
        uint256 remainingToBeClaimable = info.allocation - claimed;
        userInfo[_poolId][_msgSender()] = IVesting.UserInfo(
            info.allocation,
            claimed,
            remainingToBeClaimable,
            block.timestamp,
            info.releaseRatePerSec
        );
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
        uint256 _cliffPercentage,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc,
        bytes memory signature,
        bytes32 _salt
    ) external onlyVester nonReentrant {
        require(
            _vestingTime > block.timestamp,
            "IVesting: IVesting Time Must Be Greater Than Current Time"
        );
        require(
            _cliffVestingTime < _vestingTime,
            "IVesting: Cliff IVesting Time Must Be Lesser Than IVesting Time"
        );
        require(
            _cliffVestingTime > _cliffPeriod,
            "IVesting: Cliff IVesting Time Must Be Greater Than Cliff Period"
        );
        require(
            signatureVerification(signature, _salt) == signer,
            "Signer: Invalid signer"
        );
        require(
            _cliffPercentage <= 50,
            "Percentage:Percentage Should Be less Than  50%"
        );
        require(
            _cliffPercentage >= 1,
            "Percentage:Percentage Should Be More Than  1%"
        );

        uint256 nonClifVestingTime = (_vestingTime - _cliffVestingTime) +
            _cliffPeriod;
        uint256 totalVesting;
        for (uint256 i = 0; i < _usersAddresses.length; i++) {
            uint256 cliffAlloc = (_userAlloc[i] * _cliffPercentage) / 100;
            totalVesting += _userAlloc[i];
            uint256 nonCliffReaminingTobeclaimable = _userAlloc[i] - cliffAlloc;
            userClifInfo[vestingPoolSize][_usersAddresses[i]] = IVesting
                .UserClifInfo(
                    _userAlloc[i],
                    cliffAlloc,
                    0,
                    _cliffPeriod,
                    cliffAlloc,
                    (cliffAlloc) / (_cliffVestingTime - _cliffPeriod),
                    _cliffPeriod
                );
            userNonClifInfo[vestingPoolSize][_usersAddresses[i]] = IVesting
                .UserNonClifInfo(
                    _userAlloc[i],
                    nonCliffReaminingTobeclaimable,
                    0,
                    _cliffPeriod,
                    nonCliffReaminingTobeclaimable,
                    (_userAlloc[i] - (cliffAlloc)) /
                        (nonClifVestingTime - _cliffPeriod),
                    _cliffPeriod
                );
        }
        cliffPoolInfo[vestingPoolSize] = IVesting.CliffPoolInfo(
            _poolName,
            block.timestamp,
            _vestingTime,
            _cliffVestingTime,
            (_vestingTime - _cliffVestingTime) + _cliffPeriod,
            _cliffPeriod,
            _tokenAddress,
            totalVesting,
            _cliffPercentage,
            _usersAddresses,
            _userAlloc
        );
        IERC20(_tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            totalVesting
        );
        cliff[vestingPoolSize] = true;

        emit CliffAddVesting(
            _msgSender(),
            vestingPoolSize,
            _poolName,
            _vestingTime,
            _cliffVestingTime,
            nonClifVestingTime,
            _cliffPeriod,
            _tokenAddress,
            totalVesting,
            _usersAddresses,
            _userAlloc
        );

        vestingPoolSize = vestingPoolSize + 1;
    }

    /*
    @dev User must have allocation in the pool.
    @notice This is for claiming cliff vesting.
    @notice should be called if need to claim cliff amount.
    @param poolId from which pool user want to withdraw.
    @notice Secured by nonReentrant.
    */
    function claimCliff(uint256 _poolId) external nonReentrant {
        IVesting.UserClifInfo memory info = userClifInfo[_poolId][_msgSender()];
        require(
            cliffPoolInfo[_poolId].cliffPeriod < block.timestamp,
            "IVesting: Cliff Period Is Not Over Yet"
        );

        uint256 transferAble = cliffClaimable(_poolId, _msgSender());
        require(transferAble > 0, "IVesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 claimed = transferAble + info.claimedAmnt;
        uint256 remainingTobeClaimable = info.cliffAlloc - claimed;
        userClifInfo[_poolId][_msgSender()] = IVesting.UserClifInfo(
            info.allocation,
            info.cliffAlloc,
            claimed,
            info.tokensRelaseTime,
            remainingTobeClaimable,
            info.cliffRealeaseRatePerSec,
            block.timestamp
        );
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
        IVesting.UserNonClifInfo memory info = userNonClifInfo[_poolId][
            _msgSender()
        ];
        require(
            cliffPoolInfo[_poolId].cliffPeriod < block.timestamp,
            "IVesting: Cliff Period Is Not Over Yet"
        );

        uint256 transferAble = nonCliffClaimable(_poolId, _msgSender());
        uint256 claimed = transferAble + info.claimedAmnt;
        require(transferAble > 0, "IVesting: Invalid TransferAble");
        IERC20(cliffPoolInfo[_poolId].tokenAddress).safeTransfer(
            _msgSender(),
            transferAble
        );
        uint256 remainingTobeClaimable = info.nonCliffAlloc - claimed;
        userNonClifInfo[_poolId][_msgSender()] = IVesting.UserNonClifInfo(
            info.allocation,
            info.nonCliffAlloc,
            claimed,
            info.tokensRelaseTime,
            remainingTobeClaimable,
            info.nonCliffRealeaseRatePerSec,
            block.timestamp
        );
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
        uint256 releaseRate;

        IVesting.UserInfo memory info = userInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation: You Don't have allocation in this pool"
        );
        releaseRate = info.releaseRatePerSec;
        if (poolInfo[_poolId].startDate < block.timestamp) {
            if (poolInfo[_poolId].vestingTime < block.timestamp) {
                claimable = info.remainingToBeClaimable;
            } else if (poolInfo[_poolId].vestingTime > block.timestamp) {
                claimable =
                    (block.timestamp - info.lastWithdrawl) *
                    releaseRate;
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
        IVesting.UserClifInfo memory info = userClifInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation: You Don't have allocation in this pool"
        );

        if (cliffPoolInfo[_poolId].cliffPeriod < block.timestamp) {
            if (cliffPoolInfo[_poolId].cliffVestingTime > block.timestamp) {
                cliffClaimable =
                    (block.timestamp - info.cliffLastWithdrawl) *
                    info.cliffRealeaseRatePerSec;
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
        uint256 releaseRate;
        IVesting.UserNonClifInfo memory info = userNonClifInfo[_poolId][_user];
        require(
            info.allocation > 0,
            "Allocation: You Don't have allocation in this pool"
        );

        if (cliffPoolInfo[_poolId].cliffPeriod < block.timestamp) {
            if (cliffPoolInfo[_poolId].nonCliffVestingTime > block.timestamp) {
                nonCliffClaimable =
                    (block.timestamp - info.nonCliffLastWithdrawl) *
                    info.nonCliffRealeaseRatePerSec;
                releaseRate = info.nonCliffRealeaseRatePerSec;
            } else nonCliffClaimable = info.remainingToBeClaimableNonCliff;
        } else nonCliffClaimable = 0;

        return (nonCliffClaimable);
    }

    /*
    @dev Functions is called by a default admin.
    @param user address whom admin want to be a signer.
    */
    function setSigner(address _signer) public onlyAdmin {
        signer = _signer;
    }

    /*
    @dev For geting signer address from salt and sgnature.
    @param sig : signature provided signed by signer
    @return Address of signer who signed the message hash
    */
    function signatureVerification(bytes memory signature, bytes32 _salt)
        public
        view
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

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
}
