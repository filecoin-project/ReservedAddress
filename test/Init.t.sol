// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Example} from "./Example.sol";
import {Test} from "forge-std/Test.sol";

contract InitTest is Test {
    // there are multiple assumptions that Init.evm is 32 bytes
    function testInitSize() public view {
        bytes memory initCode = vm.getDeployedCode("out/Init.evm/Init.json");
        assertEq(initCode.length, 32);
    }

    function testInitReturn() public {
        address init = deployCode("out/Init.evm/Init.json");

        address target = makeAddr("Test");
        vm.etch(target, type(Example).creationCode);
        setTarget(target);

        (bool success, bytes memory returned) = init.call("");
        assertTrue(success);
        assertEq(returned, type(Example).runtimeCode);
    }

    function setTarget(address target) internal {
        assembly ("memory-safe") {
            sstore(0, target)
        }
    }

    fallback() external payable {
        assembly ("memory-safe") {
            mstore(0, sload(0))
            return(0, 32)
        }
    }
}
