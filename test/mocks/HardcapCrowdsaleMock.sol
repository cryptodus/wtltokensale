pragma solidity ^0.4.18;

import './../../contracts/HardcapCrowdsale.sol';

contract HardcapCrowdsaleMock is HardcapCrowdsale {

  uint256 private currentTime;

  function HardcapCrowdsaleMock(address _wallet, address _platform, HardcapToken _token) public
    HardcapCrowdsale(_wallet, _platform, _token) {
  }

  function setCurrentTime(uint256 _currentTime) public {
    currentTime = _currentTime;
  }

  function _getTime() internal view returns (uint256) {
    return currentTime;
  }
}
