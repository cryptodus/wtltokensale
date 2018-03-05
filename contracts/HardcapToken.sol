pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20/CappedToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/PausableToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';

/*
  HardcapToken is PausableToken and on the creation it is paused.
  It is made so because you don't want token to be transferable etc,
  while your ico is not over.
*/
contract HardcapToken is CappedToken, PausableToken, BurnableToken {

  uint256 private constant TOKEN_CAP = 100 * 10**24;

  string public constant name = "WTL token";
  string public constant symbol = "WTL";
  uint8 public constant decimals = 18;

  function HardcapToken() public CappedToken(TOKEN_CAP) {
    paused = true;
  }
}
