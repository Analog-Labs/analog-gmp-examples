// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {GmpSender, PrimitiveUtils} from "@analog-gmp/Primitives.sol";
import {GmpTestTools} from "@analog-gmp-testing/GmpTestTools.sol";
import {Counter} from "./Counter.sol";

contract CounterTest is Test {
    using PrimitiveUtils for address;
    using PrimitiveUtils for GmpSender;

    Counter public counter;

    /**
     * @dev The address of Alice
     */
    address private constant alice = address(bytes20(keccak256("Alice")));

    /**
     * @dev Sepolia network ID and gateway
     */
    uint16 private constant sepoliaId = GmpTestTools.SEPOLIA_NETWORK_ID;
    IGateway private constant sepoliaGateway = GmpTestTools.SEPOLIA_GATEWAY;

    /**
     * @dev Shibuya network ID and gateway
     */
    uint16 private constant shibuyaId = GmpTestTools.SHIBUYA_NETWORK_ID;
    IGateway private constant shibuyaGateway = GmpTestTools.SHIBUYA_GATEWAY;

    /**
     * @dev Test setup, deploys the gateways contracts and creates shibuya and sepolia forks respectively.
     * The `Counter.sol` contract is deployed on the Sepolia fork.
     */
    function setUp() external {
        // Setup test environment, deploy gateways and create forks
        GmpTestTools.setup();

        // Deploy Counter contract on Sepolia
        GmpTestTools.switchNetwork(sepoliaId);
        counter = new Counter(address(sepoliaGateway));
    }

    /**
     * @dev Example incrementing the counter by sending a message from Shibuya to Sepolia
     */
    function test_Increment() external {
        // Fund `alice` account with 100 ether in all networks
        GmpTestTools.deal(alice, 100 ether);

        // Set alice as `msg.sender` and `tx.origin` of all subsequent calls
        vm.startPrank(alice, alice);

        // Switch to Sepolia Fork
        GmpTestTools.switchNetwork(sepoliaId);
        assertEq(counter.number(), 0);

        // Submit a new GMP from Shibuya to Sepolia
        GmpTestTools.switchNetwork(shibuyaId);
        uint256 deposit = shibuyaGateway.estimateMessageCost(sepoliaId, 0, 100_000);
        shibuyaGateway.submitMessage{value: deposit}(address(counter), sepoliaId, 100_000, "");

        // Check the counter before relaying the GMP message
        GmpTestTools.switchNetwork(sepoliaId);
        assertEq(counter.number(), 0);

        // Relay all pending GMP messages and check the counter again
        GmpTestTools.relayMessages();
        assertEq(counter.number(), 1);
    }
}
