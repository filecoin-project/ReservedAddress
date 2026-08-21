// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

contract RevertingConstructor {
    error ExpectedRevert(uint256 value);

    constructor() {
        revert ExpectedRevert(42);
    }
}
