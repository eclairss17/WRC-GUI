const SampleWRC = artifacts.require("SampleWRC.sol");
module.exports = function(deployer) {
  deployer.deploy(SampleWRC);
};
