pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";
import './HardcapToken.sol';

contract HardcapCrowdsale is MintedCrowdsale, FinalizableCrowdsale {
  using SafeMath for uint256;

  struct Phase {
    uint256 cap;
    uint256 rate;
  }

  uint256 private constant TEAM_PERCENTAGE = 10;
  uint256 private constant PLATFORM_PERCENTAGE = 25;
  uint256 private constant CROWDSALE_PERCENTAGE = 65;

  uint256 private constant MIN_TOKENS_TO_PURCHASE = 100 * 10**18;

  uint256 private leftovers = 65 * 10**24;

  uint256 public currentCap = 10 * 10**24;
  uint256 public phaseEndDate = 1522936800000;

  address public overflowOwner;
  uint256 public overflowAmount;

  address public platform;
  uint256 public phase = 1;

  mapping (uint => Phase) private phases;

  modifier notFinished() {
    require(leftovers > 0);
    require(!isFinalized);
    _;
  }

  modifier onlyWhileOpen {
    require(getBlockTimestamp() >= openingTime && getBlockTimestamp() <= closingTime);
    _;
  }

  function HardcapCrowdsale(address _wallet, address _platform, HardcapToken _token) public
    Crowdsale(1340, _wallet, _token)
    TimedCrowdsale(1522072800000, 1528984800000) {
      platform = _platform;
      phases[1] = Phase(10 * 10**24, 1340);
      phases[2] = Phase(7 * 10**24, 1290);
      phases[3] = Phase(7 * 10**24, 1240);
      phases[4] = Phase(7 * 10**24, 1190);
      phases[5] = Phase(7 * 10**24, 1140);
      phases[6] = Phase(9 * 10**24, 1090);
      phases[7] = Phase(9 * 10**24, 1050);
      phases[8] = Phase(9 * 10**24, 1000);
      /*phases[1] = Phase(1522072800, 1522936800, 10 * 10**24, 1340);
      phases[2] = Phase(1522936800, 1523800800, 7 * 10**24, 1290);
      phases[3] = Phase(1523800800, 1524664800, 7 * 10**24, 1240);
      phases[4] = Phase(1524664800, 1525528800, 7 * 10**24, 1190);
      phases[5] = Phase(1525528800, 1526392800, 7 * 10**24, 1140);
      phases[6] = Phase(1526392800, 1527256800, 9 * 10**24, 1090);
      phases[7] = Phase(1527256800, 1528120800, 9 * 10**24, 1050);
      phases[8] = Phase(1528120800, 1528984800, 9 * 10**24, 1000);*/
  }

  /*
    If investmend was made in bitcoins etc. owner can assign apropriate amount of
    tokens to the investor.
  */
  function assignTokens(address _beneficiary, uint256 weiAmount) onlyOwner public {
    _preValidatePurchase(_beneficiary, weiAmount);
    uint256 tokens = _getTokenAmount(weiAmount);
    _processPurchase(_beneficiary, tokens);
    _updatePurchasingState(_beneficiary, weiAmount);
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) notFinished internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);

    if (phaseEndDate < getBlockTimestamp()) {
      _changePhase();
    }
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 _tokens = _weiAmount.mul(rate);
    if (currentCap > _tokens && leftovers > _tokens) {
      currentCap = currentCap.sub(_tokens);
      leftovers = leftovers.sub(_tokens);
      require(_tokens >= MIN_TOKENS_TO_PURCHASE);
      return _tokens;
    }

    uint256 _weiReq = 0;
    uint256 _tokensToSend = 0;

    while (leftovers > 0 && _weiAmount > 0) {
      uint256 _stepTokens = 0;

      if (currentCap < _tokens) {
          _stepTokens = currentCap;
          currentCap = 0;
          _weiReq = _stepTokens.div(rate);
          _weiAmount = _weiAmount.sub(_weiReq);
          _changePhase();
      } else {
          _stepTokens = leftovers;
          if (leftovers > _tokens) {
            _stepTokens = _tokens;
          }
          currentCap = currentCap.sub(_stepTokens);
          _weiReq = _stepTokens.div(rate);
          _weiAmount = _weiAmount.sub(_weiReq);
      }
      _tokensToSend = _tokensToSend.add(_stepTokens);
      leftovers = leftovers.sub(_stepTokens);

      _tokens = _weiAmount.mul(rate);
    }

    if (_weiAmount > 0) {
      _assignOverlfowData(_weiAmount);
    }

    require(_tokensToSend >= MIN_TOKENS_TO_PURCHASE);
    return _tokensToSend;
  }

  /*
    If overflow happened we dicrease the weiRaised because, those will be returned
    to investor and it is not weiRaised.
  */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._postValidatePurchase(_beneficiary, _weiAmount);
    if (overflowAmount > 0) {
      weiRaised = weiRaised.sub(overflowAmount);
    }
  }

  function _changePhase() {
    require(phase < 8);
    phase = phase.add(1);
    phaseEndDate = getBlockTimestamp() + 10 days;
    closingTime = phaseEndDate + (8 - phase) * 10 days;
    currentCap = currentCap.add(phases[phase].cap);
    rate = phases[phase].rate;
  }

  /*
    If the last tokens where sold and buyer send more ethers than required
    we save the overflow data. Than it is up to ico raiser to return the oveflowed
    invested amount to the buyer.
  */
  function _assignOverlfowData(uint256 _weiAmount) internal {
      require(leftovers <= 0);
      overflowOwner = msg.sender;
      overflowAmount = _weiAmount;
  }

  function finalization() internal {
    HardcapToken token = HardcapToken(token);

    // mint and burn all leftovers
    uint256 tokenCap = token.totalSupply().mul(100).div(CROWDSALE_PERCENTAGE);

    require(token.mint(wallet, tokenCap.mul(TEAM_PERCENTAGE).div(100)));
    require(token.mint(platform, tokenCap.mul(PLATFORM_PERCENTAGE).div(100)));
    token.burn(token.cap().sub(token.totalSupply()));

    require(token.finishMinting());
    token.transferOwnership(wallet);
  }

  function getBlockTimestamp() internal constant returns (uint256) {
    return block.timestamp;
  }
}
