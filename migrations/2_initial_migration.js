const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const IronVest = artifacts.require("IronVest");

module.exports = async function (deployer) {
  const instance = await deployProxy(IronVest, ["sibghat", "0xE63d424631bdACa918DC96D67c4Be12Bfd771CF6"], { deployer });
  console.log('Deployed', instance.address);
};