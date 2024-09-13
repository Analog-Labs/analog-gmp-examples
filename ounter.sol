 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import {IGmpReceiver} from "contracts/IGmpReceiver.sol";
 
contract Counter is IGmpReceiver {
    address private immutable _gateway;
    uint256 public number;
 
    constructor(address gateway) {
        _gateway = gateway;
    }
 
    function onGmpReceived(bytes32, uint128, bytes32, bytes calldata) external payable returns (bytes32) {
        require(msg.sender == _gateway, "unauthorized");
        number++;
        return bytes32(number);
    }
}
 
 
 
IGmpReceiver.sol
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface IGmpReceiver {
    /**
     * @dev Handles the receipt of a single GMP message.
     * The contract must verify the msg.sender, it must be the Gateway Contract address.
     *
     * @param id The EIP-712 hash of the message payload, used as GMP unique identifier
     * @param network The chain_id of the source chain that send the message
     * @param source The pubkey/address which sent the GMP message
     * @param payload The message payload with no specified format
     * @return 32-byte result, which will be stored together with the GMP message
     */
    function onGmpReceived(bytes32 id, uint128 network, bytes32 source, bytes calldata payload)
        external
        payable
        returns (bytes32);
}
