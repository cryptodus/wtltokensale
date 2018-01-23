pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/Token.sol";
import "../../contracts/Ico.sol";

contract TestIco {

  function testInitialSetup() {
    Ico ico = Ico(DeployedAddresses.Ico());
    Token token = Token(ico.token());

    Assert.equal(token.totalSupply(), 0, "should have 0 initial supply");
    Assert.equal(ico.tokenCap(), 10000, "should have 10000 initial token cap");

  }

}
