// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Example} from "./Example.sol";
import {Test} from "forge-std/Test.sol";

contract ConstructorProbe {
    address public immutable deployedAt;
    address public immutable constructorCaller;
    uint256 public immutable constructorValue;
    uint256 public storedValue;

    constructor(uint256 value) payable {
        deployedAt = address(this);
        constructorCaller = msg.sender;
        constructorValue = msg.value;
        storedValue = value;
    }
}

contract RevertingConstructor {
    error ExpectedRevert(uint256 value);

    constructor() {
        revert ExpectedRevert(42);
    }
}

contract InitTest is Test {
    bytes constant INIT_CODE = hex"385f5f5f335afa5f5f5f5f5f515af43d5f5f3e16601a573d5ffd5b3d5ff30000";
    bytes32 constant INIT_CODE_HASH = 0xbcbdfadcc59d9dc57408c9c0b8c471bde38115ed725ac4bbe1308d01651d5d99;

    function testInitCodeIsStable() public view {
        bytes memory initCode = vm.getDeployedCode("out/Init.evm/Init.json");
        assertEq(initCode, INIT_CODE);
        assertEq(initCode.length, 32);
        assertEq(keccak256(initCode), INIT_CODE_HASH);
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

    function testConstructorContext() public {
        address init = deployCode("out/Init.evm/Init.json");
        address target = makeAddr("ConstructorProbe");
        vm.etch(target, abi.encodePacked(type(ConstructorProbe).creationCode, abi.encode(uint256(42))));
        setTarget(target);

        (bool success, bytes memory returned) = init.call{value: 7}("");
        assertTrue(success);
        assertGt(returned.length, 0);

        vm.etch(init, returned);
        ConstructorProbe probe = ConstructorProbe(init);
        assertEq(probe.deployedAt(), init);
        assertEq(probe.constructorCaller(), address(this));
        assertEq(probe.constructorValue(), 7);
        assertEq(probe.storedValue(), 42);
    }

    function testConstructorRevertData() public {
        address init = deployCode("out/Init.evm/Init.json");
        address target = makeAddr("RevertingConstructor");
        vm.etch(target, type(RevertingConstructor).creationCode);
        setTarget(target);

        (bool success, bytes memory returned) = init.call("");
        assertFalse(success);
        assertEq(returned, abi.encodeWithSelector(RevertingConstructor.ExpectedRevert.selector, 42));
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
