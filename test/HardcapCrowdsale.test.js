const BigNumber = web3.BigNumber;

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const HardcapToken = artifacts.require("./HardcapToken")
const HardcapCrowdsale = artifacts.require("./HardcapCrowdsaleMock");
const TeamTokenHolder = artifacts.require("./TeamTokenHolder");

contract('HardcapCrowdsaleTest', function (accounts) {
  let investor = accounts[0];
  let wallet = accounts[1];
  let purchaser = accounts[2];
  let platform = accounts[3];

  beforeEach(async function () {
    this.token = await HardcapToken.new();
    this.crowdsale = await HardcapCrowdsale.new(wallet, platform, this.token.address);
    this.teamTokenHolder = await TeamTokenHolder.new(wallet, this.crowdsale.address, this.token.address);
    await this.token.transferOwnership(this.crowdsale.address);
  });

  describe('accepting payments', function () {
   it('should not accept payments before start date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-05').getTime() / 1000));
      try {
          await this.crowdsale.send(ether(10));
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should not accept payments after end date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-09-05').getTime() / 1000));
      try {
          await this.crowdsale.send(ether(10));
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should accept payments during ico time', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.send(ether(1)).should.be.fulfilled;
    });
    it('should fail when sending 0 ethers', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      try {
          await this.crowdsale.send(ether(0));
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should not allow buy less than 100 tokens', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      try {
          await this.crowdsale.buyTokens(investor, { value: ether(0.01) });
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
  });

  describe('changing phases on tokens exceed in phase', function () {
    it('should reveive correct amount (1340) of tokens when sending 1 ether for the 1\'st phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1340e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(1);
    });
    it('should reveive correct amount (1290) of tokens when sending 1 ether for the 2\'nd phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(10000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1290e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(2);
    });
    it('should reveive correct amount (1240) of tokens when sending 1 ether for the 3\'rd phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(15000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1240e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(3);
    });
    it('should reveive correct amount (1190) of tokens when sending 1 ether for the 4\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(21000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1190e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(4);
    });
    it('should reveive correct amount (1140) of tokens when sending 1 ether for the 5\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(26000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1140e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(5);
    });
    it('should reveive correct amount (1090) of tokens when sending 1 ether for the 6\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(31000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1090e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(6);
    });
    it('should reveive correct amount (1050) of tokens when sending 1 ether for the 7\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(40000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1050e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(7);
    });
    it('should reveive correct amount (1000) of tokens when sending 1 ether for the 8\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(50000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1000e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(8);
    });
    it('should reject purchase when phase 8 exceeded tokens', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(60000) });
      try {
          await this.crowdsale.buyTokens(investor, { value: ether(1) });
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should forward the colsing time by 10 days', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(10000) });
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(2);
      const closingTime = await this.crowdsale.closingTime();
      closingTime.should.be.bignumber.equal(Math.round(new Date('2018-04-07').getTime() / 1000));
    });
    it('should set colsing time to the end of crowdsale', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-06-10').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(10000) });
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(8);
      const closingTime = await this.crowdsale.closingTime();
      closingTime.should.be.bignumber.equal(1528984800);
    });
  });

  describe('changing phases on date exceed in phase', function () {
    it('should reveive correct amount (1340) of tokens when sending 1 ether for the 1\'st phase date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1340e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(1);
    });
    it('should reveive correct amount (1290) of tokens when sending 1 ether for the 2\'nd phase date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-04-06').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1290e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(2);
    });
    it('should reveive correct amount (1240) of tokens when sending 1 ether for the 3\'rd phase date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-04-20').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1240e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(3);
    });
    it('should reveive correct amount (1190) of tokens when sending 1 ether for the 4\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-04-30').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1190e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(4);
    });
    it('should reveive correct amount (1140) of tokens when sending 1 ether for the 5\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-05-10').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1140e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(5);
    });
    it('should reveive correct amount (1090) of tokens when sending 1 ether for the 6\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-05-20').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1090e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(6);
    });
    it('should reveive correct amount (1050) of tokens when sending 1 ether for the 7\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-06-01').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1050e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(7);
    });
    it('should reveive correct amount (1000) of tokens when sending 1 ether for the 8\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-06-10').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1000e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(8);
    });
    it('should reject purchase after the 8\'th phase date expired', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-06-20').getTime() / 1000));
      try {
          await this.crowdsale.buyTokens(investor, { value: ether(1) });
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
  });

  describe('assigning tokens', function () {
    it('should reveive correct amount (1340) of tokens when assigning 1 ether for the 1\'st phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.assignTokens(investor, ether(1));
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1340e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(1);
    });
    it('should reveive correct amount (1290) of tokens when assigning 1 ether for the 2\'nd phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(10000) });
      await this.crowdsale.assignTokens(investor, ether(1));
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1290e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(2);
    });
    it('should reveive correct amount (1240) of tokens when assigning 1 ether for the 3\'rd phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(15000) });
      await this.crowdsale.assignTokens(investor, ether(1));
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1240e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(3);
    });
    it('should reveive correct amount (1190) of tokens when assigning 1 ether for the 4\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(21000) });
      await this.crowdsale.assignTokens(investor, ether(1));
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1190e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(4);
    });
    it('should reveive correct amount (1140) of tokens when assigning 1 ether for the 5\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(26000) });
      await this.crowdsale.assignTokens(investor, ether(1));
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1140e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(5);
    });
    it('should reveive correct amount (1090) of tokens when assigning 1 ether for the 6\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(31000) });
      await this.crowdsale.assignTokens(investor, ether(1));
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1090e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(6);
    });
    it('should reveive correct amount (1050) of tokens when assigning 1 ether for the 7\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(40000) });
      await this.crowdsale.assignTokens(investor, ether(1));
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1050e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(7);
    });
    it('should reveive correct amount (1000) of tokens when assigning 1 ether for the 8\'th phase', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(50000) });
      await this.crowdsale.assignTokens(investor, ether(1));
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1000e18);
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(8);
    });
    it('should reject assigning when phase 8 exceeded tokens', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(wallet, { value: ether(60000) });
      try {
          await this.crowdsale.assignTokens(investor, ether(1));
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should forward the colsing time by 10 days', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.assignTokens(investor, ether(10000));
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(2);
      const closingTime = await this.crowdsale.closingTime();
      closingTime.should.be.bignumber.equal(Math.round(new Date('2018-04-07').getTime() / 1000));
    });
    it('should set colsing time to the end of crowdsale', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-06-10').getTime() / 1000));
      await this.crowdsale.assignTokens(investor, ether(10000));
      const phase = await this.crowdsale.phase();
      phase.should.be.bignumber.equal(8);
      const closingTime = await this.crowdsale.closingTime();
      closingTime.should.be.bignumber.equal(1528984800);
    });
  });

  describe('receive funds', function () {
    it('should forward funds to wallet when purchasing tokens', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      const pre = await web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens(investor, { value: ether(10) });
      const post = await web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(ether(10));
    });
    it('should not forward any funds to wallet when assigng tokens', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      const pre = await web3.eth.getBalance(wallet);
      await this.crowdsale.assignTokens(investor, ether(10));
      const post = await web3.eth.getBalance(wallet);
      post.should.be.bignumber.equal(pre.toNumber());
    });
    it('should not return if sent too much and tokens are over', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      const walletPre = await web3.eth.getBalance(wallet);
      const investorPre = await web3.eth.getBalance(investor);
      await this.crowdsale.buyTokens(investor, { value: ether(70000) });
      const walletPost = await web3.eth.getBalance(wallet);
      const investorPost = await web3.eth.getBalance(investor);
      const walletDiff = walletPost.minus(walletPre);
      const investorDiff = investorPre.minus(investorPost);
      // minor diff apears because of gas, so ranges should be used
      investorDiff.should.be.bignumber.gt(walletDiff.minus(ether(0.5)));
      investorDiff.should.be.bignumber.lt(walletDiff.plus(ether(0.5)));
    });
    it('should add wei to weiRaised when tokens are purchased', async function() {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      const pre = await web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens(investor, { value: ether(15000) });
      const weiRaised = await this.crowdsale.weiRaised();
      weiRaised.should.be.bignumber.equal(ether(15000));
    });
   it('should add wei to weiRaised when tokens are assigned', async function() {
     await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
     const pre = await web3.eth.getBalance(wallet);
     await this.crowdsale.assignTokens(investor, ether(15000));
     const weiRaised = await this.crowdsale.weiRaised();
     weiRaised.should.be.bignumber.equal(ether(15000));
   });
  });

  describe('finalize', function () {
    it('should not allow finalize when team token holder not set', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-07-01').getTime() / 1000));
      try {
          await this.crowdsale.finalize();
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should not allow finalize when not final dated reached or all tokens sold', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-06-01').getTime() / 1000));
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      try {
          await this.crowdsale.finalize();
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should allow finalize when final date is expired', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-07-01').getTime() / 1000));
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      await this.crowdsale.finalize().should.be.fulfilled;
    });
    it('should allow finalize when all tokens are sold', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(70000) });
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      await this.crowdsale.finalize().should.be.fulfilled;
    });
    it('should assign correct amount of tokens to team and platform when all tokens are sold', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(70000) });
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      await this.crowdsale.finalize().should.be.fulfilled;
      const walletBalance = await this.token.balanceOf(wallet);
      walletBalance.should.be.bignumber.equal(0);
      const teamTokenHolderBalance = await this.token.balanceOf(this.teamTokenHolder.address);
      teamTokenHolderBalance.should.be.bignumber.equal(10e24);
      const platformBalance = await this.token.balanceOf(platform);
      platformBalance.should.be.bignumber.equal(25e24);
    });
    it('should transfer ownership when finallized', async function () {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(70000) });
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      await this.crowdsale.finalize().should.be.fulfilled;
      const owner = await this.token.owner();
      owner.should.be.equal(wallet);
    });
    it('should finish minting when finalized', async function() {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(70000) });
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      await this.crowdsale.finalize().should.be.fulfilled;
      let mintingFinished = await this.token.mintingFinished();
      mintingFinished.should.be.equal(true);
    });
    it('should burn all leftovers when finallized', async function() {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-07-01').getTime() / 1000));
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      await this.crowdsale.finalize().should.be.fulfilled;
      // nothing sold - everything gets burned
      let totalSupply = await this.token.totalSupply();
      totalSupply.should.be.bignumber.equal(0);
    });
    it('should set finalized time when finalized', async function() {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(70000) });
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      await this.crowdsale.finalize().should.be.fulfilled;
      let finalizedTime = await this.crowdsale.finalizedTime();
      finalizedTime.should.be.bignumber.equal(Math.round(new Date('2018-03-28').getTime() / 1000));
    });
    it('should not allow finalize when finalized', async function() {
      await this.crowdsale.setCurrentTime(Math.round(new Date('2018-03-28').getTime() / 1000));
      await this.crowdsale.buyTokens(investor, { value: ether(70000) });
      await this.crowdsale.setTeamTokenHolder(this.teamTokenHolder.address);
      await this.crowdsale.finalize().should.be.fulfilled;
      try {
          await this.crowdsale.finalize();
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
  });
});

function ether (n) {
  return new web3.BigNumber(web3.toWei(n, 'ether'));
}
