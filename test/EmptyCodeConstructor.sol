// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

contract EmptyCodeConstructor {
    constructor() {
        assembly {
            return(0, 0)
        }
    }
}
