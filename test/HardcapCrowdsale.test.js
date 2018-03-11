const BigNumber = web3.BigNumber;

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

const HardcapToken = artifacts.require("./HardcapToken")
const HardcapCrowdsale = artifacts.require("./HardcapCrowdsaleMock");

contract('HardcapCrowdsaleTest', function (accounts) {
  let investor = accounts[0];
  let wallet = accounts[1];
  let purchaser = accounts[2];
  let platform = accounts[3];

  beforeEach(async function () {
    this.token = await HardcapToken.new();
    this.crowdsale = await HardcapCrowdsale.new(wallet, platform, this.token.address);
    await this.token.transferOwnership(this.crowdsale.address);
  });

  describe('accepting payments', function () {
   it('should not accept payments before start date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-05').getTime());
      try {
          await this.crowdsale.send(ether(10));
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should not accept payments after end date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-09-05').getTime());
      try {
          await this.crowdsale.send(ether(10));
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should accept payments during ico time', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.send(ether(1)).should.be.fulfilled;
    });
    it('should fail when sending 0 ethers', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      try {
          await this.crowdsale.send(ether(0));
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    it('should not allow buy less than 100 tokens', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
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
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1340e18);
    });
    it('should reveive correct amount (1290) of tokens when sending 1 ether for the 2\'nd phase', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(wallet, { value: ether(10000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1290e18);
    });
    it('should reveive correct amount (1240) of tokens when sending 1 ether for the 3\'rd phase', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(wallet, { value: ether(15000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1240e18);
    });
    it('should reveive correct amount (1190) of tokens when sending 1 ether for the 4\'th phase', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(wallet, { value: ether(21000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1190e18);
    });
    it('should reveive correct amount (1140) of tokens when sending 1 ether for the 5\'th phase', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(wallet, { value: ether(26000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1140e18);
    });
    it('should reveive correct amount (1090) of tokens when sending 1 ether for the 6\'th phase', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(wallet, { value: ether(31000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1090e18);
    });
    it('should reveive correct amount (1050) of tokens when sending 1 ether for the 7\'th phase', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(wallet, { value: ether(40000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1050e18);
    });
    it('should reveive correct amount (1000) of tokens when sending 1 ether for the 8\'th phase', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(wallet, { value: ether(50000) });
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1000e18);
    });
    it('should reject purchase when phase 8 exceeded tokens', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(wallet, { value: ether(60000) });
      try {
          await this.crowdsale.buyTokens(investor, { value: ether(1) });
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
    //TODO: add check if date changes
  });

  describe('changing phases on date exceed in phase', function () {
    it('should reveive correct amount (1340) of tokens when sending 1 ether for the 1\'st phase date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-03-28').getTime());
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1340e18);
    });
    it('should reveive correct amount (1290) of tokens when sending 1 ether for the 2\'nd phase date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-04-06').getTime());
      /*
      let oTime = await this.crowdsale.openingTime();
      let cTime = await this.crowdsale.closingTime();
      let nTime = await this.crowdsale._getTime();

      console.log(new Date(oTime.toNumber()));
      console.log(new Date(cTime.toNumber()));
      console.log(new Date(nTime.toNumber()));
      */
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1290e18);
    });
    it('should reveive correct amount (1240) of tokens when sending 1 ether for the 3\'rd phase date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-04-20').getTime());
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1240e18);
    });
    it('should reveive correct amount (1190) of tokens when sending 1 ether for the 4\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-04-30').getTime());
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1190e18);
    });
    it('should reveive correct amount (1140) of tokens when sending 1 ether for the 5\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-05-10').getTime());
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1140e18);
    });
    it('should reveive correct amount (1090) of tokens when sending 1 ether for the 6\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-05-20').getTime());
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1090e18);
    });
    it('should reveive correct amount (1050) of tokens when sending 1 ether for the 7\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-06-01').getTime());
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1050e18);
    });
    it('should reveive correct amount (1000) of tokens when sending 1 ether for the 8\'th phase date', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-06-10').getTime());
      await this.crowdsale.buyTokens(investor, { value: ether(1) });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(1000e18);
    });
    it('should reject purchase after the 8\'th phase date expired', async function () {
      await this.crowdsale.setCurrentTime(new Date('2018-06-20').getTime());
      try {
          await this.crowdsale.buyTokens(investor, { value: ether(1) });
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
  });
/*

  describe('receive funds', function () {
    it('should forward funds to wallet', async function () {
      this.crowdsale.should.exist;
      await this.crowdsale.unpause();
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens(investor, { value: ether(10) });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(ether(10));
    });
    it('should not set oveflow if not oveflowed', async function () {
      this.crowdsale.should.exist;
      await this.crowdsale.unpause();
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens(investor, { value: ether(15000) });

      const overflowOwner = await this.crowdsale.overflowOwner();
      overflowOwner.should.be.equal('0x0000000000000000000000000000000000000000');

      const overflowAmount = await this.crowdsale.overflowAmount();
      overflowAmount.should.be.bignumber.equal(0);
    });
    it('should set overflow data if oweflowed', async function () {
      this.crowdsale.should.exist;
      await this.crowdsale.unpause();
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens(investor, { value: ether(25000) });

      const overflowOwner = await this.crowdsale.overflowOwner();
      overflowOwner.should.be.equal(investor);

      const overflowAmount = await this.crowdsale.overflowAmount();
      overflowAmount.should.be.bignumber.at.most(1.34481460568418e21);
      overflowAmount.should.be.bignumber.at.least(1.34481460568417e21);
    });
    it('should not change weiRaised if not overflowed', async function() {
      this.crowdsale.should.exist;
      await this.crowdsale.unpause();
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens(investor, { value: ether(15000) });
      const weiRaised = await this.crowdsale.weiRaised();
      weiRaised.should.be.bignumber.equal(ether(15000));
    });
    it('should correct weiRaised when overflowed', async function() {
      this.crowdsale.should.exist;
      await this.crowdsale.unpause();
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens(investor, { value: ether(25000) });
      const weiRaised = await this.crowdsale.weiRaised();
      const overflowAmount = await this.crowdsale.overflowAmount();
      const totalAmount = weiRaised.plus(overflowAmount);
      totalAmount.should.be.bignumber.equal(ether(25000));
    });
  });

  describe('finalize', function () {
    it('should allow finalize when paused', async function () {
      this.crowdsale.should.exist;
      await this.crowdsale.finalize();
    });

    it('should transfer all tokens to wallet when finalized', async function () {
      this.crowdsale.should.exist;
      await this.crowdsale.finalize();
      const balance = await this.token.balanceOf(wallet);
      balance.should.be.bignumber.equal(450e24);
    });

    it('should transfer all left tokens to wallet when finalized', async function () {
      this.crowdsale.should.exist;
      await this.crowdsale.unpause();
      await this.crowdsale.buyTokens(investor, { value: ether(5) });
      await this.crowdsale.pause();
      await this.crowdsale.finalize();
      const balance = await this.token.balanceOf(wallet);
      balance.should.be.bignumber.equal(449.9425e24);
    });


    it('should reassign ownership to wallet when finalized', async function () {
      this.crowdsale.should.exist;
      await this.crowdsale.finalize();
      let owner = await this.token.owner();
      owner.should.be.equal(wallet);
    });

    it('should finish minting when finalized', async function() {
      this.crowdsale.should.exist;
      await this.crowdsale.finalize();
      let mintingFinished = await this.token.mintingFinished();
      mintingFinished.should.be.equal(true);
    });

    it('should not allow finalize when not paused', async function () {
      this.crowdsale.should.exist;
      await this.crowdsale.unpause();
      try {
          await this.crowdsale.finalize();
          assert.fail('Expected reject not received');
      } catch (error) {
        assert(error.message.search('revert') > 0, 'Wrong error message received: ' + error.message);
      }
    });
  });*/
});

function ether (n) {
  return new web3.BigNumber(web3.toWei(n, 'ether'));
}
