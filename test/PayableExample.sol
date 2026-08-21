// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

contract PayableExample {
    uint256 public immutable constructorValue;

    constructor() payable {
        constructorValue = msg.value;
    }
}
