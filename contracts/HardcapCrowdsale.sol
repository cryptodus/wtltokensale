pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";
import './HardcapToken.sol';

contract HardcapCrowdsale is MintedCrowdsale, FinalizableCrowdsale {
  using SafeMath for uint256;

  struct Phase {
    uint256 capTo;
    uint256 rate;
  }

  uint256 private constant TEAM_PERCENTAGE = 10;
  uint256 private constant PLATFORM_PERCENTAGE = 25;
  uint256 private constant CROWDSALE_PERCENTAGE = 65;

  uint256 private constant MIN_TOKENS_TO_PURCHASE = 100 * 10**18;

  uint256 private constant ICO_TOKENS_CAP = 65 * 10**24;

  uint256 public phaseEndDate = 1522936800000;

  address public overflowOwner;
  uint256 public overflowAmount;

  address public platform;

  mapping (uint8 => Phase) private phases;

  modifier onlyWhileOpen {
    require(getBlockTimestamp() >= openingTime && getBlockTimestamp() <= closingTime);
    _;
  }

  function HardcapCrowdsale(address _wallet, address _platform, HardcapToken _token) public
    Crowdsale(1340, _wallet, _token)
    TimedCrowdsale(1522072800000, 1528984800000) {
      platform = _platform;
      // 0 - 10
      phases[1] = Phase(10 * 10**24, 1340);
      // 10 - 17
      phases[2] = Phase(17 * 10**24, 1290);
      // 17 - 24
      phases[3] = Phase(24 * 10**24, 1240);
      // 24 - 31
      phases[4] = Phase(31 * 10**24, 1190);
      // 31 - 38
      phases[5] = Phase(38 * 10**24, 1140);
      // 38 - 47
      phases[6] = Phase(47 * 10**24, 1090);
      // 47 - 56
      phases[7] = Phase(56 * 10**24, 1050);
      // 56 - 65
      phases[8] = Phase(65 * 10**24, 1000);
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

  function _getCurrentPhase(uint256 _currentSupply) internal view returns (Phase) {
      uint8 phase = 1;
      while (_currentSupply <= phases[phase].capTo && phase < 8) {
        phase = phase + 1;
      }
      return phases[phase];
   }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(token.totalSupply() < ICO_TOKENS_CAP);
    require(!isFinalized);

    while (phaseEndDate < getBlockTimestamp() && phaseEndDate < closingTime) {
      phaseEndDate = getBlockTimestamp() + 10 days;
      //closingTime = phaseEndDate + (8 - phase) * 10 days;
    }
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 _leftowers = 0;
    uint256 _weiReq = 0;
    uint256 _tokens = 0;
    uint256 _currentSupply = token.totalSupply();
    Phase memory _phase = _getCurrentPhase(_currentSupply);

    while (_weiAmount > 0 && _currentSupply < ICO_TOKENS_CAP) {
      _leftowers = _phase.capTo.sub(_currentSupply);
      _weiReq = _leftowers.div(_phase.rate);
      if (_weiReq < _weiAmount) {
         _tokens = _tokens.add(_leftowers);
         _weiAmount = _weiAmount.sub(_weiReq);
      } else {
         _tokens = _tokens.add(_weiAmount.mul(_phase.rate));
         _weiAmount = 0;
      }

      _currentSupply = token.totalSupply().add(_tokens);
      _phase = _getCurrentPhase(_currentSupply);
    }

    require(_tokens >= MIN_TOKENS_TO_PURCHASE);
    return _tokens;
  }

  /*
    If the last tokens where sold and buyer send more ethers than required
    we save the overflow data. Than it is up to ico raiser to return the oveflowed
    invested amount to the buyer.
  */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    uint256 _currentSupply = token.totalSupply();
    Phase memory _phase = _getCurrentPhase(_currentSupply);
    uint256 _tokens = _tokenAmount;
    uint256 _weiAmount = 0;
    uint256 _leftowers = 0;
    bool _phaseChanged = false;

    while (_tokens > 0) {
      _leftowers = _phase.capTo.sub(_currentSupply);
      if (_leftowers <= _tokens) {
        _weiAmount = _weiAmount.add(_tokens.div(_phase.rate));
        _tokens = 0;
      } else {
        _weiAmount = _weiAmount.add(_leftowers.div(_phase.rate));
        _tokens = _tokens.sub(_leftowers);
        _phaseChanged = true;
      }

      _currentSupply = token.totalSupply().sub(_tokens);
      _phase = _getCurrentPhase(_currentSupply);
    }

    if (_phaseChanged) {
      phaseEndDate = getBlockTimestamp() + 10 days;
    }

    if (msg.value > _weiAmount) {
      overflowOwner = msg.sender;
      overflowAmount = msg.value.sub(_weiAmount);
    }

    super._processPurchase(_beneficiary, _tokenAmount);
  }

  /*
    If overflow happened we dicrease the weiRaised because, those will be returned
    to investor and it is not weiRaised.
  */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._postValidatePurchase(_beneficiary, _weiAmount);
    require(token.totalSupply() < ICO_TOKENS_CAP);
    if (overflowAmount > 0) {
      weiRaised = weiRaised.sub(overflowAmount);
    }
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
