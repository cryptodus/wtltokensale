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

  uint256 private constant FINAL_CLOSING_TIME = 1529884800;

  uint256 private constant INITIAL_START_DATE = 1525046400;

  uint256 public phase = 0;

  HardcapToken public token;

  address public wallet;
  address public platform;
  address public assigner;
  address public teamTokenHolder;

  uint256 public weiRaised;

  bool public isFinalized = false;

  uint256 public openingTime = 1524441600;
  uint256 public closingTime = 1525046400;
  uint256 public finalizedTime;

  mapping (uint256 => Phase) private phases;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenAssigned(address indexed purchaser, address indexed beneficiary, uint256 amount);


  event Finalized();

  modifier onlyAssginer() {
    require(msg.sender == assigner);
    _;
  }

  function HardcapCrowdsale(address _wallet, address _platform, address _assigner, HardcapToken _token) public {
      require(_wallet != address(0));
      require(_assigner != address(0));
      require(_platform != address(0));
      require(_token != address(0));

      wallet = _wallet;
      platform = _platform;
      assigner = _assigner;
      token = _token;

      // phases capTo means that totalSupply must reach it to change the phase
      phases[0] = Phase(15 * 10**23, 1250);
      phases[1] = Phase(10 * 10**24, 1200);
      phases[2] = Phase(17 * 10**24, 1150);
      phases[3] = Phase(24 * 10**24, 1100);
      phases[4] = Phase(31 * 10**24, 1070);
      phases[5] = Phase(38 * 10**24, 1050);
      phases[6] = Phase(47 * 10**24, 1030);
      phases[7] = Phase(56 * 10**24, 1000);
      phases[8] = Phase(65 * 10**24, 1000);
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  /*
    contract for teams tokens lockup
  */
  function setTeamTokenHolder(address _teamTokenHolder) onlyOwner public {
    require(_teamTokenHolder != address(0));
    // should allow set only once
    require(teamTokenHolder == address(0));
    teamTokenHolder = _teamTokenHolder;
  }

  function buyTokens(address _beneficiary) public payable {
    _processTokensPurchase(_beneficiary, msg.value);
  }

  /*
    It may be needed to assign tokens in batches if multiple clients invested
    in any other crypto currency.
    NOTE: this will fail if there are not enough tokens left for at least one investor.
        for this to work all investors must get all their tokens.
  */
  function assignTokensToMultipleInvestors(address[] _beneficiaries, uint256[] _tokensAmount) onlyAssginer public {
    require(_beneficiaries.length == _tokensAmount.length);
    for (uint i = 0; i < _tokensAmount.length; i++) {
      _processTokensAssgin(_beneficiaries[i], _tokensAmount[i]);
    }
  }

  /*
    If investmend was made in bitcoins etc. owner can assign apropriate amount of
    tokens to the investor.
  */
  function assignTokens(address _beneficiary, uint256 _tokensAmount) onlyAssginer public {
    _processTokensAssgin(_beneficiary, _tokensAmount);
  }

  function finalize() onlyOwner public {
    require(teamTokenHolder != address(0));
    require(!isFinalized);
    require(_hasClosed());
    require(finalizedTime == 0);

    HardcapToken _token = HardcapToken(token);

    // assign each counterparty their share
    uint256 _tokenCap = _token.totalSupply().mul(100).div(CROWDSALE_PERCENTAGE);
    require(_token.mint(teamTokenHolder, _tokenCap.mul(TEAM_PERCENTAGE).div(100)));
    require(_token.mint(platform, _tokenCap.mul(PLATFORM_PERCENTAGE).div(100)));

    // mint and burn all leftovers
    uint256 _tokensToBurn = _token.cap().sub(_token.totalSupply());
    require(_token.mint(address(this), _tokensToBurn));
    _token.burn(_tokensToBurn);

    require(_token.finishMinting());
    _token.transferOwnership(wallet);

    Finalized();

    finalizedTime = _getTime();
    isFinalized = true;
  }

  function _hasClosed() internal view returns (bool) {
    return _getTime() > FINAL_CLOSING_TIME || token.totalSupply() >= ICO_TOKENS_CAP;
  }

  function _processTokensAssgin(address _beneficiary, uint256 _tokenAmount) internal {
    _preValidateAssign(_beneficiary, _tokenAmount);

    // calculate token amount to be created
    uint256 _leftowers = 0;
    uint256 _tokens = 0;
    uint256 _currentSupply = token.totalSupply();
    bool _phaseChanged = false;
    Phase memory _phase = phases[phase];

    while (_tokenAmount > 0 && _currentSupply < ICO_TOKENS_CAP) {
      _leftowers = _phase.capTo.sub(_currentSupply);
      // check if it is possible to assign more than there is available in this phase
      if (_leftowers < _tokenAmount) {
         _tokens = _tokens.add(_leftowers);
         _tokenAmount = _tokenAmount.sub(_leftowers);
         phase = phase + 1;
         _phaseChanged = true;
      } else {
         _tokens = _tokens.add(_tokenAmount);
         _tokenAmount = 0;
      }

      _currentSupply = token.totalSupply().add(_tokens);
      _phase = phases[phase];
    }

    require(_tokens >= MIN_TOKENS_TO_PURCHASE || _currentSupply == ICO_TOKENS_CAP);

    // if phase changes forward the date of the next phase change by 7 days
    if (_phaseChanged) {
      _changeClosingTime();
    }

    require(HardcapToken(token).mint(_beneficiary, _tokens));
    TokenAssigned(msg.sender, _beneficiary, _tokens);
  }

  function _processTokensPurchase(address _beneficiary, uint256 _weiAmount) internal {
    _preValidatePurchase(_beneficiary, _weiAmount);

    // calculate token amount to be created
    uint256 _leftowers = 0;
    uint256 _weiReq = 0;
    uint256 _weiSpent = 0;
    uint256 _tokens = 0;
    uint256 _currentSupply = token.totalSupply();
    bool _phaseChanged = false;
    Phase memory _phase = phases[phase];

    while (_weiAmount > 0 && _currentSupply < ICO_TOKENS_CAP) {
      _leftowers = _phase.capTo.sub(_currentSupply);
      _weiReq = _leftowers.div(_phase.rate);
      // check if it is possible to purchase more than there is available in this phase
      if (_weiReq < _weiAmount) {
         _tokens = _tokens.add(_leftowers);
         _weiAmount = _weiAmount.sub(_weiReq);
         _weiSpent = _weiSpent.add(_weiReq);
         phase = phase + 1;
         _phaseChanged = true;
      } else {
         _tokens = _tokens.add(_weiAmount.mul(_phase.rate));
         _weiSpent = _weiSpent.add(_weiAmount);
         _weiAmount = 0;
      }

      _currentSupply = token.totalSupply().add(_tokens);
      _phase = phases[phase];
    }

    require(_tokens >= MIN_TOKENS_TO_PURCHASE || _currentSupply == ICO_TOKENS_CAP);

    // if phase changes forward the date of the next phase change by 7 days
    if (_phaseChanged) {
      _changeClosingTime();
    }

    // return leftovers to investor if tokens are over but he sent more ehters.
    if (msg.value > _weiSpent) {
      uint256 _overflowAmount = msg.value.sub(_weiSpent);
      _beneficiary.transfer(_overflowAmount);
    }

    weiRaised = weiRaised.add(_weiSpent);

    require(HardcapToken(token).mint(_beneficiary, _tokens));
    TokenPurchase(msg.sender, _beneficiary, _weiSpent, _tokens);

    // You can access this method either buying tokens or assigning tokens to
    // someone. In the previous case you won't be sending any ehter to contract
    // so no need to forward any funds to wallet.
    if (msg.value > 0) {
      wallet.transfer(_weiSpent);
    }
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // if the phase time ended calculate next phase end time and set new phase
    if (closingTime < _getTime() && closingTime < FINAL_CLOSING_TIME && phase < 8) {
      phase = phase.add(_calcPhasesPassed());
      _changeClosingTime();

    }
    require(_getTime() > INITIAL_START_DATE);
    require(_getTime() >= openingTime && _getTime() <= closingTime);
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(phase <= 8);

    require(token.totalSupply() < ICO_TOKENS_CAP);
    require(!isFinalized);
  }

  function _preValidateAssign(address _beneficiary, uint256 _tokenAmount) internal {
    // if the phase time ended calculate next phase end time and set new phase
    if (closingTime < _getTime() && closingTime < FINAL_CLOSING_TIME && phase < 8) {
      phase = phase.add(_calcPhasesPassed());
      _changeClosingTime();

    }
    // should not allow to assign tokens to team members
    require(_beneficiary != assigner);
    require(_beneficiary != platform);
    require(_beneficiary != wallet);
    require(_beneficiary != teamTokenHolder);

    require(_getTime() >= openingTime && _getTime() <= closingTime);
    require(_beneficiary != address(0));
    require(_tokenAmount > 0);
    require(phase <= 8);

    require(token.totalSupply() < ICO_TOKENS_CAP);
    require(!isFinalized);
  }

  function _changeClosingTime() internal {
    closingTime = _getTime() + 7 days;
    if (closingTime > FINAL_CLOSING_TIME) {
      closingTime = FINAL_CLOSING_TIME;
    }
  }

  function _calcPhasesPassed() internal view returns(uint256) {
    return  _getTime().sub(closingTime).div(7 days).add(1);
  }

 function _getTime() internal view returns (uint256) {
   return now;
 }

}
