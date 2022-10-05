const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const IronVest = artifacts.require("IronVest");

module.exports = async function (deployer) {
  const instance = await deployProxy(IronVest, ["sibghat", "0xE9b2b574A87056cF8aa917f736cADE7136aB811C"], { deployer });
  console.log('Deployed', instance.address);
};