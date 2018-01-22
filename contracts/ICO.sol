pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol';
import 'zeppelin-solidity/contracts/crowdsale/FinalizableCrowdsale.sol';
import './Token.sol';

contract ICO is FinalizableCrowdsale {
/*

2. Tokenų kainos dinamiškos - priklausys nuo parduoto kiekio. Token Sale pradžioje Smart
Contract’e turėtų būti fiksuojami laiptai: pirmam X kiekiui token’ų kursas 1 ETH = 1000 Token;
vėliau 1 ETH = 900 Token ir t.t. Prie EUR rištis būtų sudėtinga, kadangi Ethereum Smart
Contract’ui reiktų paduoti kursą. Taigi Token Sale metu reikės prisiimti volatilumo riziką.
3. Teoriškai pirkti galės visi. Web’e bus rodomas ETH wallet’o adresas tiems, kas praėjo KYC. Taip
būtų paprasčiau. - čia dar nėra apibrėžta ar reikės whitelisted adresus idėti ar ne. Bet jei reikės, prisidės tik papildomas mappingas, funkcijos ideti, isimti bei kai contributina require.

*/
  uint256 public tokenCap;
  uint256 public rateChangeStep;
  uint256 public rateChangeCountdown;

  uint256 private constant INITIAL_RATE = 10**15;

  function ICO(uint256 _tokenCap, uint256 _startTime, uint256 _endTime,
      address _wallet, uint256 _rateChangeStep) public
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, INITIAL_RATE, _wallet)
  {
    tokenCap = _tokenCap;
    rateChangeStep = _rateChangeStep;
    rateChangeCountdown = _rateChangeStep;
  }

  function createTokenContract() internal returns (MintableToken) {
    return new Token();
  }

  function validPurchase() internal view returns (bool) {
    uint256 tokens = msg.value.mul(rate);
    bool withinTokenCap = token.totalSupply().add(tokens) <= tokenCap;
    return withinTokenCap && super.validPurchase();
  }

  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));

    uint256 weiAmount = msg.value;

    while (weiAmount > 0) {
      uint256 tokens = weiAmount.mul(rate);
      if (rateChangeCountdown - tokens > 0) {
        rateChangeCountdown -= tokens;
        weiAmount = 0;
        buyTokens(beneficiary, tokens, weiAmount);
      } else {
        uint256 weiReq = rateChangeCountdown.div(rate);
        weiAmount -= weiReq;
        buyTokens(beneficiary, tokens, weiReq);
        //TODO: new rate calc
      }
    }
  }

  function buyTokens(address beneficiary, uint256 tokens, uint256 weiAmount) private {
    require(validPurchase());
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function hasEnded() public view returns (bool) {
    bool tokensSold = token.totalSupply() >= tokenCap;
    return tokensSold || super.hasEnded();
  }

  function finalization() internal {
    uint256 leftOvers = tokenCap - token.totalSupply();
    if (leftOvers > 0) {
      token.mint(wallet, leftOvers);
    }
  }
}
