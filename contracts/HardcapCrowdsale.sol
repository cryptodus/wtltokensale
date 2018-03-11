pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import './HardcapToken.sol';

contract HardcapCrowdsale is Ownable {
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

  uint256 private constant FINAL_CLOSING_TIME = 1528984800000;

  uint256 public phase = 1;

  ERC20 public token;

  address public wallet;
  address public platform;
  address public teamTokenHolder;

  uint256 public weiRaised;

  bool public isFinalized = false;

  uint256 public openingTime = 1522072800000;
  uint256 public closingTime = 1522936800000;
  uint256 public finalizedTime;

  mapping (uint256 => Phase) private phases;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event Finalized();

  function HardcapCrowdsale(address _wallet, address _platform, HardcapToken _token) public {
      require(_wallet != address(0));
      require(_platform != address(0));
      require(_token != address(0));

      wallet = _wallet;
      platform = _platform;
      token = _token;

      phases[1] = Phase(10 * 10**24, 1340);
      phases[2] = Phase(17 * 10**24, 1290);
      phases[3] = Phase(24 * 10**24, 1240);
      phases[4] = Phase(31 * 10**24, 1190);
      phases[5] = Phase(38 * 10**24, 1140);
      phases[6] = Phase(47 * 10**24, 1090);
      phases[7] = Phase(56 * 10**24, 1050);
      phases[8] = Phase(65 * 10**24, 1000);
  }

  function setTeamTokenHolder(address _teamTokenHolder) public {
    require(_teamTokenHolder != address(0));
    teamTokenHolder = _teamTokenHolder;
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {
    _processTokensPurchase(_beneficiary, msg.value);
  }

  /*
    If investmend was made in bitcoins etc. owner can assign apropriate amount of
    tokens to the investor.
  */
  function assignTokens(address _beneficiary, uint256 _weiAmount) onlyOwner public {
    _processTokensPurchase(_beneficiary, _weiAmount);
  }

  function finalize() onlyOwner public {
    require(teamTokenHolder != address(0));
    require(!isFinalized);
    require(_hasClosed());
    require(finalizedTime == 0);

    HardcapToken _token = HardcapToken(token);

    // mint and burn all leftovers
    uint256 _tokenCap = _token.totalSupply().mul(100).div(CROWDSALE_PERCENTAGE);

    require(_token.mint(teamTokenHolder, _tokenCap.mul(TEAM_PERCENTAGE).div(100)));
    require(_token.mint(platform, _tokenCap.mul(PLATFORM_PERCENTAGE).div(100)));
    _token.burn(_token.cap().sub(_token.totalSupply()));

    require(_token.finishMinting());
    _token.transferOwnership(wallet);

    Finalized();

    finalizedTime = _getTime();
    isFinalized = true;
  }

  function _hasClosed() internal view returns (bool) {
    return _getTime() > FINAL_CLOSING_TIME || token.totalSupply() >= ICO_TOKENS_CAP;
  }

  function _processTokensPurchase(address _beneficiary, uint256 _weiAmount) internal {
    _preValidatePurchase(_beneficiary, _weiAmount);

    // calculate token amount to be created
    uint256 _leftowers = 0;
    uint256 _weiReq = 0;
    uint256 _tokens = 0;
    uint256 _currentSupply = token.totalSupply();
    bool _phaseChanged = false;
    Phase memory _phase = phases[phase];

    while (_weiAmount > 0 && _currentSupply < ICO_TOKENS_CAP) {
      _leftowers = _phase.capTo.sub(_currentSupply);
      _weiReq = _leftowers.div(_phase.rate);
      if (_weiReq < _weiAmount) {
         _tokens = _tokens.add(_leftowers);
         _weiAmount = _weiAmount.sub(_weiReq);
         phase = phase + 1;
         _phaseChanged = true;
      } else {
         _tokens = _tokens.add(_weiAmount.mul(_phase.rate));
         _weiAmount = 0;
      }

      _currentSupply = token.totalSupply().add(_tokens);
      _phase = phases[phase];
    }

    require(_tokens >= MIN_TOKENS_TO_PURCHASE);

    if (_phaseChanged) {
      _changeClosingTime();
    }

    if (msg.value > _weiAmount) {
      uint256 _overflowAmount = msg.value.sub(_weiAmount);
      _beneficiary.transfer(_overflowAmount);
    }

    weiRaised = weiRaised.add(_weiAmount);

    require(HardcapToken(token).mint(_beneficiary, _tokens));
    TokenPurchase(msg.sender, _beneficiary, _weiAmount, _tokens);

    // You can access this method either buying tokens or assigning tokens to
    // someone. In the previous case you won't be sending any ehter to contract
    // so no need to forward any funds to wallet.
    if (msg.value > 0) {
      wallet.transfer(_weiAmount);
    }
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    if (closingTime < _getTime() && closingTime < FINAL_CLOSING_TIME && phase < 8) {
      phase = phase.add(_calcPhasesPassed());
      _changeClosingTime();

    }
    require(_getTime() >= openingTime && _getTime() <= closingTime);
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(phase <= 8);

    require(token.totalSupply() < ICO_TOKENS_CAP);
    require(!isFinalized);
  }

  function _changeClosingTime() internal {
    closingTime = _getTime() + 10 days;
    if (closingTime > FINAL_CLOSING_TIME) {
      closingTime = FINAL_CLOSING_TIME;
    }
  }

  function _calcPhasesPassed() internal view returns(uint256) {
    return  _getTime().sub(closingTime).div(10 days * 1000).add(1);
  }

 function _getTime() public view returns (uint256) {
   return now;
 }

}
