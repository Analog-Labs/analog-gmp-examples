// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGmpRecipient} from "@analog-gmp/interfaces/IGmpRecipient.sol";

contract Counter is IGmpRecipient {
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
