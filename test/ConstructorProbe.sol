// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

contract ConstructorProbe {
    address public immutable DEPLOYED_AT;
    address public immutable CALLER;
    uint256 public immutable CALLVALUE;

    uint256 public storedValue;

    constructor(uint256 value) payable {
        DEPLOYED_AT = address(this);
        CALLER = msg.sender;
        CALLVALUE = msg.value;
        storedValue = value;
    }
}
