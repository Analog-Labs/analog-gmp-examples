// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {GmpTestTools} from "@analog-gmp-testing/GmpTestTools.sol";
import {Counter} from "./Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() external {
        GmpTestTools.setup();
        GmpTestTools.switchNetwork(GmpTestTools.SEPOLIA_NETWORK_ID);
        counter = new Counter(address(GmpTestTools.SEPOLIA_GATEWAY));
    }

    function test_Increment() external {
        GmpTestTools.switchNetwork(GmpTestTools.SEPOLIA_NETWORK_ID);
        assertEq(counter.number(), 0);
        // Deposit
        bytes32 source = bytes32(uint256(uint160(msg.sender)));
        GmpTestTools.SEPOLIA_GATEWAY.deposit{value: 100 ether}(source, GmpTestTools.SEPOLIA_NETWORK_ID);

        GmpTestTools.switchNetwork(GmpTestTools.SHIBUYA_NETWORK_ID);
        GmpTestTools.SHIBUYA_GATEWAY.submitMessage(address(counter), GmpTestTools.SEPOLIA_NETWORK_ID, 100_000, "");

        GmpTestTools.switchNetwork(GmpTestTools.SEPOLIA_NETWORK_ID);
        assertEq(counter.number(), 0);

        GmpTestTools.relayMessages();
        assertEq(counter.number(), 1);
    }
}
