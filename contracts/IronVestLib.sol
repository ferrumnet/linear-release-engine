// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @author The ferrum network.
/// @title This is a vesting contract named as IronVest.
/// @dev This contract is upgradeable please use a framework i.e truffle or hardhat for deploying it.
/// @notice This contract contains the power of accesscontrol.
/// There are two different vesting defined in the contract with different functionalities.
/// Have fun reading it. Hopefully it's bug-free. God Bless.
contract IronVestLib is Initializable, AccessControlUpgradeable {
    /// @notice This struct will save all the pool information about simple vesting i.e addVesting().
    struct PoolInfo {
        string poolName;
        uint256 startTime; /// block.timestamp while creating new pool.
        uint256 vestingEndTime; /// time stamp when to end the vesting.
        address tokenAddress; /// token which we want to vest in the contract.
        uint256 totalVestedTokens; /// total amount of tokens.
        address[] usersAddresses; /// addresses of users an array.
        uint256[] usersAlloc; /// allocation to user with respect to usersAddresses.
    }

    /// @notice Used to store information about the user in simple vesting.
    struct UserInfo {
        uint256 allocation; /// total allocation to a user.
        uint256 claimedAmount; /// claimedAmnt + claimed.
        uint256 remainingToBeClaimable; /// remaining claimable fully claimable once time ended.
        uint256 lastWithdrawal; /// block.timestamp used for internal claimable calculation
        uint256 releaseRatePerSec; /// calculated as vestingTime/(vestingTime-starttime)
        bool deprecated; /// The allocated address is deprecated and new address allocated.
        address updatedAddress; /// If (deprecated = true) otherwise it will denote address(0x00)
    }

    /// @notice This struct will save all the pool information about simple vesting i.e addCliffVesting().
    struct CliffPoolInfo {
        string poolName;
        uint256 startTime; /// block.timestamp while creating new pool.
        uint256 vestingEndTime; /// total time to end cliff vesting.
        uint256 cliffVestingEndTime; /// time in which user can vest cliff tokens should be less than vestingendtime.
        uint256 nonCliffVestingPeriod; /// calculated as cliffPeriod-vestingEndTime. in seconds
        uint256 cliffPeriodEndTime; ///in this time tenure the tokens keep locked in contract. a timestamp
        address tokenAddress; /// token which we want to vest in the contract.
        uint256 totalVestedTokens; /// total amount of tokens.
        uint256 cliffLockPercentage10000; /// for percentage calculation using 10000 instead 100.
        address[] usersAddresses; /// addresses of users an array.
        uint256[] usersAlloc; /// allocation to user with respect to usersAddresses.
    }

    /// @notice Used to store information about the user in cliff vesting.
    struct UserCliffInfo {
        uint256 allocation; /// total allocation cliff+noncliff
        uint256 cliffAlloc; /// (totalallocation*cliffPercentage)/10000
        uint256 claimedAmnt; /// claimedAmnt-claimableClaimed.
        uint256 tokensReleaseTime; /// the time we used to start vesting tokens.
        uint256 remainingToBeClaimableCliff; /// remaining claimable fully claimable once time ended.
        uint256 cliffReleaseRatePerSec; /// calculated as cliffAlloc/(cliffendtime -cliffPeriodendtime).
        uint256 cliffLastWithdrawal; /// block.timestamp used for internal claimable calculation.
        bool deprecated; /// The allocated address is deprecated and new address allocated.
        address updatedAddress; /// If (deprecated = true) otherwise it will denote address(0x00)
    }

    /// @notice Used to store information about the user of non cliff in cliff vesting.
    struct UserNonCliffInfo {
        uint256 allocation; /// total allocation cliff+noncliff
        uint256 nonCliffAlloc; /// (totalallocation-cliffalloc)
        uint256 claimedAmnt; /// claimedAmnt-claimableClaimed
        uint256 tokensReleaseTime; /// the time we used to start vesting tokens.
        uint256 remainingToBeClaimableNonCliff; /// remaining claimable fully claimable once time ended.
        uint256 nonCliffReleaseRatePerSec; /// calculated as nonCliffAlloc/(cliffVestingEndTime-vestingEndTime).
        uint256 nonCliffLastWithdrawal; /// used for internal claimable calculation.
        bool deprecated; /// The allocated address is deprecated and new address allocated.
        address updatedAddress; /// If (deprecated = true) otherwise it will denote address(0x00)
    }

    /// @notice Signer address. Transaction supposed to be sign be this address.
    address public signer;

    /// Hash Information to avoid the replay from same _messageHash
    mapping(bytes32 => bool) internal _usedHashes;

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
    function initialize(address _signer) external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        signer = _signer;
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
    function preAddVesting(
        string memory _poolName,
        uint256 _vestingEndTime,
        address _tokenAddress,
        address[] memory _usersAddresses,
        uint256[] memory _userAlloc,
        bytes memory _signature,
        bytes memory _keyHash
    ) external view {
        require(
            _usersAddresses.length == _userAlloc.length,
            "IIronVest Array : Length of _usersAddresses And _userAlloc Must Be Equal"
        );
        require(
            _vestingEndTime > block.timestamp,
            "IIronVest : Vesting End Time Should Be Greater Than Current Time"
        );
        require(
            signatureVerification(
                _signature,
                _poolName,
                _tokenAddress,
                _keyHash
            ) == signer,
            "Signer : Invalid signer"
        );
    }

    function usedHash(
        bool _boolean,
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) external onlyOwner {
        _usedHashes[messageHash(_poolName, _tokenAddress, _keyHash)] = _boolean;
    }

    /// @dev Only callable by vester.
    /// @param _poolName : Pool name is supposed to be any string.
    /// @param _vestingEndTime : Vesting time is tenure in which token will be released.
    /// @param _cliffVestingEndTime : cliff vesting time is the end time for releasing cliff tokens.
    /// @param _cliffPeriodEndTime : cliff period is a period in which token will be locked.
    /// @param _tokenAddress : Token address related to the vested token.
    /// @param _cliffPercentage10000 : cliff percentage defines how may percentage should be allocated to cliff tokens.
    /// @param _usersAddresses : Users addresses whom the vester want to allocate tokens and it is an array.
    /// @param _usersAlloc : Users allocation of tokens with respect to address.
    /// @param _signature : Signature of the signed by signer.
    /// @param _keyHash : Specific keyhash value formed to stop replay.
    /// @notice Create a new vesting with cliff.
    function preAddCliffVesting(
        string memory _poolName,
        uint256 _vestingEndTime,
        uint256 _cliffVestingEndTime,
        uint256 _cliffPeriodEndTime,
        address _tokenAddress,
        uint256 _cliffPercentage10000,
        address[] memory _usersAddresses,
        uint256[] memory _usersAlloc,
        bytes memory _signature,
        bytes memory _keyHash
    ) external view onlyOwner {
        require(
            _usersAddresses.length == _usersAlloc.length,
            "IIronVest Array : Length of _usersAddresses And _userAlloc Must Be Equal"
        );
        require(
            _cliffVestingEndTime < _vestingEndTime,
            "IIronVest : Cliff Vesting End Time Must Be Lesser Than Vesting Time"
        );
        require(
            _cliffVestingEndTime > _cliffPeriodEndTime,
            "IIronVest : Cliff Vesting Time Must Be Greater Than Cliff Period"
        );
        require(
            _cliffPeriodEndTime > block.timestamp,
            "IIronVest : Cliff Vesting Time Must Be Lesser Than Vesting Time"
        );
        require(
            signatureVerification(
                _signature,
                _poolName,
                _tokenAddress,
                _keyHash
            ) == signer,
            "Signer : Invalid signer"
        );
        require(
            _cliffPercentage10000 <= 5000,
            "Percentage : Percentage Should Be less Than 50%"
        );
    }

    /// @dev Only callable by owner.
    /// @param _poolId : On which pool admin want to update user address.
    /// @param _deprecatedAddress : Old address that need to be updated.
    /// @param _updatedAddress : New address that gonna replace old address.
    /// @notice This function is useful whenever a person lose their address which has pool allocation.
    /// @notice If else block will specify if the pool ID is related to cliff vesting or simple vesting.
    function preUpdateBeneficiaryAddress(
        uint256 _poolId,
        address _deprecatedAddress,
        address _updatedAddress,
        uint256 _vestingPoolsize
    ) external view onlyOwner {
        require(_vestingPoolsize > _poolId, "Pool Id : Invalid _poolId");
        require(
            _updatedAddress == _deprecatedAddress,
            "Addresses : Deprecated Address and Updated Address Souldn't be equeal"
        );
        require(
            _updatedAddress == address(0x00) &&
                _deprecatedAddress == address(0x00),
            "Invalid Address"
        );
    }

    /// @dev Functions is called by a default admin.
    /// @param _signer : An address whom admin want to be a signer.
    function setSigner(address _signer) external onlyOwner {
        require(
            _signer != address(0x00),
            "Invalid : Signer Address Is Invalid"
        );
        signer = _signer;
    }

    /// @dev For geting signer address from salt and sgnature.
    /// @param _signature : signature provided signed by signer.
    /// @param _poolName : Pool Name to name a pool.
    /// @param _tokenAddress : tokenAddess of our vested tokesn.
    /// @param _keyHash : keyhash value to stop replay.
    /// @return Address of signer who signed the message hash.
    function signatureVerification(
        bytes memory _signature,
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) public view returns (address) {
        bytes32 _salt = messageHash(_poolName, _tokenAddress, _keyHash);
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        require(!_usedHashes[_salt], "Message already used");

        address _user = _verifyMessage(_salt, v, r, s);
        return _user;
    }

    /// @dev For splititng signature.
    /// @param _sig : signature provided signed by signer
    /// @return r : First 32 bytes stores the length of the signature.
    /// @return s : add(sig, 32) = pointer of sig + 32
    /// effectively, skips first 32 bytes of signature.
    /// @return v : mload(p) loads next 32 bytes starting
    /// at the memory address p into memory.
    function _splitSignature(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            /// First 32 bytes stores the length of the signature

            /// add(_sig, 32) = pointer of _sig + 32
            /// effectively, skips first 32 bytes of signature

            /// mload(p) loads next 32 bytes starting at the memory address p into memory

            /// first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            /// second 32 bytes
            s := mload(add(_sig, 64))
            /// final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }

        /// implicitly return (r, s, v)
    }

    /// @dev Verify and recover signer from salt and signature.
    /// @param _salt : A hash value which contains concatened hash of different values.
    /// @param _v : mload(p) loads next 32 bytes starting at the memory address p into memory.
    /// @param _r : First 32 bytes stores the length of the signature.
    /// @param _s : add(sig, 32) = pointer of sig + 32 effectively, skips first 32 bytes of signature.
    /// @return signerAddress : Return the address of signer.
    function _verifyMessage(
        bytes32 _salt,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (address signerAddress) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _salt)
        );
        address _signerAddress = ecrecover(prefixedHashMessage, _v, _r, _s);
        return _signerAddress;
    }

    /// @dev create a message hash by concatincating the values.
    /// @param _poolName : Pool name.
    /// @param _tokenAddress : Vesting token address .
    /// @param _keyHash : key hash value generated by our backend to stop replay attack.
    /// also a chain Id so that a user can't replay the hash any other chain.
    /// @return returning keccak hash of concate values.
    function messageHash(
        string memory _poolName,
        address _tokenAddress,
        bytes memory _keyHash
    ) public view returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(_poolName, _tokenAddress, _keyHash, block.chainid)
        );
        return hash;
    }

    function usedHash(bytes32 _hash) external view returns (bool isHashUsed) {
        return _usedHashes[_hash];
    }
}
