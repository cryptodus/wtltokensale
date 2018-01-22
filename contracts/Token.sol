pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/MintableToken.sol';

contract Token is MintableToken {
  string public constant name = "TOKEN";
  string public constant symbol = "TOK";
  uint8 public constant decimals = 18;
}
