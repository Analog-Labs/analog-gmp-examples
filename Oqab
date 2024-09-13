function onGmpReceived(bytes32, uint128, bytes32, bytes calldata) 
                        external payable returns (bytes32) {
        require(msg.sender == _gateway, "unauthorized");
        number++;
        return bytes32(number);
    }
