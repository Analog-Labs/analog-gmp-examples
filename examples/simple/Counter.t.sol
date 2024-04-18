// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {GmpTestTools} from "@analog-gmp-testing/GmpTestTools.sol";
import {Counter} from "./Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    uint16 private constant sepoliaId = GmpTestTools.SEPOLIA_NETWORK_ID;
    IGateway private constant sepoliaGateway = GmpTestTools.SEPOLIA_GATEWAY;
    uint16 private constant shibuyaId = GmpTestTools.SHIBUYA_NETWORK_ID;
    IGateway private constant shibuyaGateway = GmpTestTools.SHIBUYA_GATEWAY;

    function setUp() external {
        ////////////////////////////////////
        // Step 1: Setup test environment //
        ////////////////////////////////////
        GmpTestTools.setup();

        ////////////////////////////////////////
        // Step 2: Deploy contract on Sepolia //
        ////////////////////////////////////////
        GmpTestTools.switchNetwork(sepoliaId);
        counter = new Counter(address(sepoliaGateway));
    }

    function test_Increment() external {
        // Fund the msg.sender
        GmpTestTools.deal(msg.sender, 100 ether);
        vm.startPrank(msg.sender, msg.sender);

        // Switch to Sepolia
        GmpTestTools.switchNetwork(sepoliaId);
        assertEq(counter.number(), 0);

        // Deposit funds to pay for the execution cost from Shibuya to Sepolia
        bytes32 source = bytes32(uint256(uint160(msg.sender)));
        sepoliaGateway.deposit{value: 1 ether}(source, shibuyaId);
        assertEq(counter.number(), 0);

        // Submit a message from Shibuya to Sepolia to increment the counter
        GmpTestTools.switchNetwork(shibuyaId);
        shibuyaGateway.submitMessage(address(counter), sepoliaId, 100_000, "");

        // Check the counter before relaying the messages
        GmpTestTools.switchNetwork(sepoliaId);
        assertEq(counter.number(), 0);

        // Check the counter in sepolia before relaying the messages
        GmpTestTools.relayMessages();
        assertEq(counter.number(), 1);
    }
}
