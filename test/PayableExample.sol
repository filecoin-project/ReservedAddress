// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

contract PayableExample {
    uint256 public immutable CALLVALUE;

    constructor() payable {
        CALLVALUE = msg.value;
    }
}
