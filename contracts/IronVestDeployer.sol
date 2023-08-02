// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IIronVest {
    function initialize(
        string memory _vestingName,
        address _signer,
        address _defaultAdmin
    ) external;
}

interface IIronVestExtended {
    function initialize(
        string memory _vestingName,
        address _signer,
        address _defaultAdmin,
        address _preCheckAddress
    ) external;
}

contract IronVestProxyDeployer {
    event VestingDeployed(address ironVest, bytes data);
    event ExtendedVestingDeployed(address ironVest, bytes data);
    event ProxyContsuctorArgs(bytes args);

    function deployIronVest(
        address logic,
        string memory _vestingName,
        address _signer,
        address _defaultAdmin,
        address admin
    ) external returns (address) {
        bytes memory data = abi.encodeWithSelector(
            IIronVest.initialize.selector,
            _vestingName,
            _signer,
            _defaultAdmin
        );

        address ironVest = address(
            new TransparentUpgradeableProxy(logic, admin, data)
        );
        emit VestingDeployed(ironVest, data);
        bytes memory args = abi.encode(logic, admin, data);
        emit ProxyContsuctorArgs(args);
        return ironVest;
    }

      function deployIronVestExtended(
        address logic,
        string memory _vestingName,
        address _signer,
        address _defaultAdmin,
        address _preCheckAddress,
        address admin
    ) external returns (address) {
        bytes memory data = abi.encodeWithSelector(
            IIronVestExtended.initialize.selector,
            _vestingName,
            _signer,
            _defaultAdmin,
            _preCheckAddress
        );

        address ironVestExtended = address(
            new TransparentUpgradeableProxy(logic, admin, data)
        );
        emit ExtendedVestingDeployed(ironVestExtended, data);
        bytes memory args = abi.encode(logic, admin, data);
        emit ProxyContsuctorArgs(args);
        return ironVestExtended;
    }

    function ironVestData(
        string memory _vestingName,
        address _signer,
        address _defaultAdmin
    ) public pure returns (bytes memory _data) {
        bytes memory data = abi.encodeWithSelector(
            IIronVest.initialize.selector,
            _vestingName,
            _signer,
            _defaultAdmin
        );
        return data;
    }

    function ironVestExtendedData(
        string memory _vestingName,
        address _signer,
        address _defaultAdmin,
        address _preCheckAddress
    ) public pure returns (bytes memory _data) {
      bytes memory data = abi.encodeWithSelector(
            IIronVestExtended.initialize.selector,
            _vestingName,
            _signer,
            _defaultAdmin,
            _preCheckAddress
        );
        return data;
    }
}
