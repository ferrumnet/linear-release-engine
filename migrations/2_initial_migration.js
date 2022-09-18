const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const IronVest = artifacts.require("VestingHarvestContarct");

module.exports = async function (deployer) {
  const instance = await deployProxy(IronVest,["sibghat","0x611B7aB25dcD075535495296bB4F4496d6F120Df"], { deployer });
  console.log('Deployed', instance.address);
};