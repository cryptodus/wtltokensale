pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import 'zeppelin-solidity/contracts/lifecycle/Pausable.sol';
import './HardcapToken.sol';

/*
  Taxi crowdsale is Pausable contract it is paused on init
  and may be paused any time in the process. While it is paused
  it can finalized meaning all left tokens will be assigned to owner wallet
*/
contract HardcapCrowdsale is MintedCrowdsale, Pausable {
  using SafeMath for uint256;

  uint256 private constant TOKENS_RATE_CHANGE_STEP = 65 * 10**24;
  uint256 private constant INIT_RATE = 11500;
  uint256 private constant MIN_RATE = 10000;
  uint256 private constant RATE_STEP = 500;

  uint256 private leftovers = 65 * 10**24;
  uint256 private toSellTillNextStep = TOKENS_RATE_CHANGE_STEP;

  bool public isFinalized = false;

  address public overflowOwner;
  uint256 public overflowAmount;

  address public platform;

  event Finalized();

  modifier notFinished() {
    require(leftovers > 0);
    require(!isFinalized);
    _;
  }

  function HardcapCrowdsale(address _wallet, address _platform, HardcapToken _token) public
    Crowdsale(INIT_RATE, _wallet, _token) {
      paused = true;
      platform = _platform;
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) notFinished whenNotPaused internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(_weiAmount > 0);
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 _tokens = _weiAmount.mul(rate);
    if (toSellTillNextStep > _tokens && leftovers > _tokens) {
      toSellTillNextStep = toSellTillNextStep.sub(_tokens);
      leftovers = leftovers.sub(_tokens);
      return _tokens;
    }

    uint256 _weiReq = 0;
    uint256 _tokensToSend = 0;

    while (leftovers > 0 && _weiAmount > 0) {
      uint256 _stepTokens = 0;

      if (toSellTillNextStep < _tokens) {
          _stepTokens = toSellTillNextStep;
          toSellTillNextStep = TOKENS_RATE_CHANGE_STEP;
          _weiReq = _stepTokens.div(rate);
          _weiAmount = _weiAmount.sub(_weiReq);
          _calcNextRate();
      } else {
          _stepTokens = leftovers;
          if (leftovers > _tokens) {
            _stepTokens = _tokens;
          }
          toSellTillNextStep = toSellTillNextStep.sub(_stepTokens);
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

  function _calcNextRate() internal {
      rate = rate.sub(RATE_STEP);
      if (rate < MIN_RATE) {
        rate = MIN_RATE;
      }
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

  /*
    This is ripped of from zeppelin contracts, because zeppelin FinalzableCrowdsale
    contract extends TimedCrowdsale contract and here it is not the case
  */
  function finalize() onlyOwner whenPaused public {
    require(!isFinalized);

    finalization();
    Finalized();

    isFinalized = true;
  }

  function finalization() internal {
    HardcapToken token = HardcapToken(token);
    // mint and burn all leftovers
    require(token.mint(wallet, leftovers));
    token.burn(leftovers);

    // mint all the dedicated tokens to wallet
    require(token.mint(wallet, 10 * 10**24));

    // mint all the dedicated tokens to platfrom
    require(token.mint(wallet, 25 * 10**24));


    require(token.finishMinting());
    token.transferOwnership(wallet);
  }
}
