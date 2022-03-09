pragma solidity ^0.5.10;

import "../ETH2BTC.sol";
import "./lib/ds-test/src/test.sol";

contract ETH2BTCTest is DSTest {
    ETH2BTC eth2BTCTest;

    function setUp() public {
        eth2BTCTest = new ETH2BTC(
            bytes20(0xbE086099e0Ff00fC0cfbC77A8Dd09375aE889FBD),
            msg.sender,
            30,
            100
        );
    }

    function testFail_set_rate_not_admin() public {
        ETH2BTC eth2BTCWithZeroAddressAdmin = new ETH2BTC(
            bytes20(0xbE086099e0Ff00fC0cfbC77A8Dd09375aE889FBD),
            address(0),
            30,
            100
        );
        eth2BTCWithZeroAddressAdmin.setEtherToBitcoinRate(10);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
