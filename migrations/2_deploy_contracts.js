var Ico = artifacts.require("./Ico.sol");

module.exports = function (deployer, network, accounts) {
  const tokenCap = 10000;
  const startTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 1 // one second in the future
  const endTime = startTime + (86400 * 20) // 20 days
  const rateChangeStep = 1000;
  const wallet = accounts[0]

  deployer.deploy(Ico, tokenCap, startTime, endTime, wallet, rateChangeStep);
};
