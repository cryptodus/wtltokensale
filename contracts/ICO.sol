pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol';
import 'zeppelin-solidity/contracts/crowdsale/FinalizableCrowdsale.sol';
import './Token.sol';

contract ICO is CappedCrowdsale, FinalizableCrowdsale {

  function ICO(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap, address _wallet) public
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
  }

  function createTokenContract() internal returns (MintableToken) {
    return new Token();
  }

  function finalization() internal {
    uint256 leftOvers = cap - token.totalSupply();
    if (leftOvers > 0) {
      token.mint(wallet, leftOvers);
    }
  }
}
