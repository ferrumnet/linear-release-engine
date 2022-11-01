const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const IronVest = artifacts.require("IronVest");


// production script
module.exports = async function (deployer) {
  const instance = await deployProxy(IronVest, ["Iron Vest", "0xf97E03bc3498170D8195512A33E44602ed1A4D34"], { deployer });
  console.log('Deployed', instance.address);
};

// module.exports = async function (deployer) {
//   const instance = await deployProxy(IronVest, ["Iron Vest", "0xE9b2b574A87056cF8aa917f736cADE7136aB811C"], { deployer });
//   console.log('Deployed', instance.address);
// };