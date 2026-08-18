// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {LibClone} from "solady/utils/LibClone.sol";

import {IDeployer} from "../src/interfaces/IDeployer.sol";
import {Example} from "./Example.sol";


contract DeploymentTest is Test {
    // TODO mine a deployer with Nick's Method
    IDeployer constant DEPLOYER = IDeployer(0x000000000000c57CF0A1f923d44527e703F1ad70);
    function setUp() public {
        vm.etch(address(DEPLOYER), vm.getDeployedCode("out/Deployer.evm/Deployer.json"));
    }

    function testReserveRevealDeployCall() public {
        bytes32 salt = bytes32(0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef);
        bytes32 initCodeHash = keccak256(vm.getDeployedCode("out/Init.evm/Init.json"));
        address reserved = LibClone.predictDeterministicAddress(initCodeHash, salt, address(DEPLOYER));

        address sender = makeAddr("sender");
        address initCode = makeAddr("initCode");
        vm.etch(initCode, type(Example).creationCode);

        vm.prank(sender);
        DEPLOYER.reserve(reserved);

        vm.expectRevert(IDeployer.NotOwner.selector);
        DEPLOYER.reveal(reserved, salt);

        vm.prank(sender);
        DEPLOYER.reveal(reserved, salt);

        vm.expectRevert(IDeployer.NotOwner.selector);
        DEPLOYER.deploy(reserved, initCode);

        vm.prank(sender);
        DEPLOYER.deploy(reserved, initCode);

        assertEq(reserved.code, type(Example).runtimeCode);

        Example deployed = Example(reserved);
        assertEq(deployed.owner(), address(DEPLOYER));

        address recipient = makeAddr("recipient");

        vm.expectRevert(IDeployer.NotOwner.selector);
        DEPLOYER.call{value:1 ether}(reserved, abi.encodeWithSelector(Example.pay.selector, recipient));

        assertEq(recipient.balance, 0);

        vm.deal(sender, 1 ether);
        vm.prank(sender);
        DEPLOYER.call{value:1 ether}(reserved, abi.encodeWithSelector(Example.pay.selector, recipient));

        assertEq(recipient.balance, 1 ether);
        assertEq(reserved.balance, 0);
        assertEq(sender.balance, 0);
    }
}
