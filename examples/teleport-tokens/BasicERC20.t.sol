// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";
import {BasicERC20} from "./BasicERC20.sol";
import {GmpTestTools} from "@analog-gmp-testing/GmpTestTools.sol";
import {Gateway} from "@analog-gmp/Gateway.sol";
import {IGateway} from "@analog-gmp/interfaces/IGateway.sol";
import {GmpMessage, GmpStatus, GmpSender, PrimitiveUtils} from "@analog-gmp/Primitives.sol";

contract GmpTestToolsTest is Test {
    using PrimitiveUtils for GmpSender;
    using PrimitiveUtils for address;

    address private constant ALICE = address(bytes20(keccak256("Alice")));
    address private constant BOB = address(bytes20(keccak256("Bob")));

    Gateway private constant SEPOLIA_GATEWAY = Gateway(GmpTestTools.SEPOLIA_GATEWAY);
    uint16 private constant SEPOLIA_NETWORK = GmpTestTools.SEPOLIA_NETWORK_ID;

    Gateway private constant SHIBUYA_GATEWAY = Gateway(GmpTestTools.SHIBUYA_GATEWAY);
    uint16 private constant SHIBUYA_NETWORK = GmpTestTools.SHIBUYA_NETWORK_ID;

    /// @dev Test the teleport of tokens from Alice's account in Shibuya to Bob's account in Sepolia
    function test_teleportTokens() external {
        ////////////////////////////////////
        // Step 1: Setup test environment //
        ////////////////////////////////////

        // Deploy the gateway contracts at pre-defined addresses
        // Also creates one fork for each supported network
        GmpTestTools.setup();

        // Add funds to Alice and Bob in all networks
        GmpTestTools.deal(ALICE, 100 ether);
        GmpTestTools.deal(BOB, 100 ether);

        ///////////////////////////////////////////////////////
        // Step 2: Deploy the sender and recipient contracts //
        ///////////////////////////////////////////////////////

        // Pre-compute the contract addresses, because the contracts must know each other addresses.
        BasicERC20 shibuyaErc20 = BasicERC20(vm.computeCreateAddress(ALICE, vm.getNonce(ALICE)));
        BasicERC20 sepoliaErc20 = BasicERC20(vm.computeCreateAddress(BOB, vm.getNonce(BOB)));

        // Switch to Shibuya network and deploy the ERC20 using Alice account
        GmpTestTools.switchNetwork(SHIBUYA_NETWORK, ALICE);
        shibuyaErc20 = new BasicERC20("Shibuya ", "A", SHIBUYA_GATEWAY, sepoliaErc20, SEPOLIA_NETWORK, ALICE, 1000);
        assertEq(shibuyaErc20.balanceOf(ALICE), 1000, "unexpected alice balance in shibuya");
        assertEq(shibuyaErc20.balanceOf(BOB), 0, "unexpected bob balance in shibuya");

        // Switch to Sepolia network and deploy the ERC20 using Bob account
        GmpTestTools.switchNetwork(SEPOLIA_NETWORK, BOB);
        sepoliaErc20 = new BasicERC20("Sepolia", "B", SEPOLIA_GATEWAY, shibuyaErc20, SHIBUYA_NETWORK, BOB, 0);
        assertEq(sepoliaErc20.balanceOf(ALICE), 0, "unexpected alice balance in sepolia");
        assertEq(sepoliaErc20.balanceOf(BOB), 0, "unexpected bob balance in sepolia");

        // Check if the computed addresses matches
        assertEq(address(shibuyaErc20), vm.computeCreateAddress(ALICE, 0), "unexpected shibuyaErc20 address");
        assertEq(address(sepoliaErc20), vm.computeCreateAddress(BOB, 0), "unexpected sepoliaErc20 address");

        //////////////////////////////
        // Step 3: Send GMP message //
        //////////////////////////////

        // Switch to Shibuya network and Alice account
        GmpTestTools.switchNetwork(SHIBUYA_NETWORK, ALICE);

        // Teleport 100 tokens from Alice to Bob's account in Sepolia
        // Obs: The `teleport` method now calls `gateway.submitMessage(...)` with value
        uint256 deposit = 2400000000000000000;
        vm.expectEmit(false, true, false, true, address(shibuyaErc20));
        emit BasicERC20.OutboundTransfer(bytes32(0), ALICE, BOB, 100);
        bytes32 messageID = shibuyaErc20.teleport{value: deposit}(BOB, 100);

        // Now with the `messageID`, Alice can check the message status in the destination gateway contract
        // status 0: means the message is pending
        // status 1: means the message was executed successfully
        // status 2: means the message was executed but reverted
        GmpTestTools.switchNetwork(SEPOLIA_NETWORK, ALICE);
        assertTrue(
            SEPOLIA_GATEWAY.gmpInfo(messageID).status == GmpStatus.NOT_FOUND,
            "unexpected message status, expect 'pending'"
        );

        ///////////////////////////////////////////////////
        // Step 4: Wait Chronicles Relay the GMP message //
        ///////////////////////////////////////////////////

        // The GMP hasn't been executed yet...
        assertEq(sepoliaErc20.balanceOf(ALICE), 0, "unexpected alice balance in shibuya");

        // Note: In a live network, the GMP message will be relayed by Chronicle Nodes after a minimum number of confirmations.
        // here we can simulate this behavior by calling `GmpTestTools.relayMessages()`, this will relay all pending messages.
        vm.expectEmit(true, true, false, true, address(sepoliaErc20));
        emit BasicERC20.InboundTransfer(messageID, ALICE, BOB, 100);
        GmpTestTools.relayMessages();

        // Success! The GMP message was executed!!!
        assertTrue(SEPOLIA_GATEWAY.gmpInfo(messageID).status == GmpStatus.SUCCESS, "failed to execute GMP");

        // Check ALICE and BOB balance in shibuya
        GmpTestTools.switchNetwork(SHIBUYA_NETWORK);
        assertEq(shibuyaErc20.balanceOf(ALICE), 900, "unexpected alice's balance in shibuya");
        assertEq(shibuyaErc20.balanceOf(BOB), 0, "unexpected bob's balance in shibuya");

        // Check ALICE and BOB balance in sepolia
        GmpTestTools.switchNetwork(SEPOLIA_NETWORK);
        assertEq(sepoliaErc20.balanceOf(ALICE), 0, "unexpected alice's balance in sepolia");
        assertEq(sepoliaErc20.balanceOf(BOB), 100, "unexpected bob's balance in sepolia");
    }
}
