// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {LibClone} from "solady/utils/LibClone.sol";
import {LibRLP} from "solady/utils/LibRLP.sol";

import {IDeployer} from "../src/interfaces/IDeployer.sol";
import {DEPLOYER, DEPLOYER_CREATOR, IDeployerLibrary} from "../src/lib/IDeployerLibrary.sol";
import {DeployerCheats} from "../src/lib/DeployerCheats.sol";
import {EmptyCodeConstructor} from "./EmptyCodeConstructor.sol";
import {Example} from "./Example.sol";
import {PayableExample} from "./PayableExample.sol";
import {RevertingConstructor} from "./RevertingConstructor.sol";

uint256 constant DAY = 24 * 60 * 60;
uint256 constant START_TIME = 1787089200;

contract DeploymentTest is Test {
    using IDeployerLibrary for IDeployer;
    using DeployerCheats for Vm;

    function setUp() public {
        vm.deployDeployer();
        vm.warp(START_TIME);
    }

    // @dev there isn't a view method for the salt, but it can be checked this way
    function getStoredSalt(address reserved) internal view returns (bytes32 salt) {
        bytes32 slot = bytes32(0x010000000000000000000000000000000000000000 | uint256(uint160(reserved)));
        return vm.load(address(DEPLOYER), slot);
    }

    function reserveAddress(bytes32 salt, address owner) internal returns (address reserved) {
        bytes32 initCodeHash = keccak256(vm.getDeployedCode("out/Init.evm/Init.json"));
        reserved = LibClone.predictDeterministicAddress(initCodeHash, salt, address(DEPLOYER));
        vm.startPrank(owner);
        DEPLOYER.reserve(reserved);
        DEPLOYER.reveal(reserved, salt);
        vm.stopPrank();
    }

    function testDeployerCreator() public pure {
        assertEq(address(DEPLOYER), LibRLP.computeAddress(DEPLOYER_CREATOR, 0));
    }

    function testFallbackRejectsValue() public {
        address sender = makeAddr("sender");
        vm.deal(sender, 1 ether);

        vm.prank(sender);
        (bool success, bytes memory returned) = address(DEPLOYER).call{value: 1 ether}("");

        assertFalse(success);
        assertEq(returned, abi.encodeWithSelector(IDeployer.UnexpectedValue.selector));
        assertEq(address(DEPLOYER).balance, 0);
        assertEq(sender.balance, 1 ether);
    }

    function testFactoryBalanceDoesNotBlockDeployment() public {
        address owner = address(3);
        address reserved = reserveAddress(bytes32(uint256(1)), owner);
        address initCode = makeAddr("initCode");
        vm.etch(initCode, type(Example).creationCode);
        vm.deal(address(DEPLOYER), 1);

        vm.prank(owner);
        DEPLOYER.deploy(reserved, initCode);

        assertEq(reserved.code, type(Example).runtimeCode);
        assertEq(reserved.balance, 0);
        assertEq(address(DEPLOYER).balance, 1);
    }

    function testDeployForwardsOnlyCallValue() public {
        address owner = address(3);
        address reserved = reserveAddress(bytes32(uint256(2)), owner);
        address initCode = makeAddr("initCode");
        vm.etch(initCode, type(PayableExample).creationCode);
        vm.deal(address(DEPLOYER), 2 ether);
        vm.deal(owner, 1 ether);

        vm.prank(owner);
        DEPLOYER.deploy{value: 1 ether}(reserved, initCode);

        assertEq(PayableExample(reserved).CALLVALUE(), 1 ether);
        assertEq(reserved.balance, 1 ether);
        assertEq(address(DEPLOYER).balance, 2 ether);
    }

    function testDeployPropagatesCreateFailure() public {
        address owner = makeAddr("owner");
        bytes32 salt = bytes32(uint256(3));
        address reserved = reserveAddress(salt, owner);

        address initCode = makeAddr("revertingInitCode");
        vm.etch(initCode, type(RevertingConstructor).creationCode);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(RevertingConstructor.ExpectedRevert.selector, 42));
        DEPLOYER.deploy(reserved, initCode);

        assertEq(reserved.code.length, 0);
        assertEq(getStoredSalt(reserved), salt);
    }

    function testDeployRevertsOnEmptyCode() public {
        address owner = makeAddr("owner");
        bytes32 salt = bytes32(uint256(4));
        address reserved = reserveAddress(salt, owner);

        address initCode = makeAddr("emptyCodeInitCode");
        vm.etch(initCode, type(EmptyCodeConstructor).creationCode);

        vm.prank(owner);
        vm.expectRevert(IDeployer.EmptyCode.selector);
        DEPLOYER.deploy(reserved, initCode);

        assertEq(reserved.code.length, 0);
        assertEq(getStoredSalt(reserved), salt);
    }

    function testReserveRevealDeployCall() public {
        bytes32 salt = bytes32(0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef);
        bytes32 initCodeHash = keccak256(vm.getDeployedCode("out/Init.evm/Init.json"));
        address reserved = LibClone.predictDeterministicAddress(initCodeHash, salt, address(DEPLOYER));

        address sender = makeAddr("sender");
        address initCode = makeAddr("initCode");
        vm.etch(initCode, type(Example).creationCode);

        address holder;
        uint96 expiry;

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        DEPLOYER.ownerOf(reserved);
        (holder, expiry) = DEPLOYER.reservation(reserved);
        assertEq(holder, address(0));
        assertEq(expiry, 0);

        vm.expectRevert();
        DEPLOYER.getApproved(reserved);

        vm.prank(sender);
        DEPLOYER.reserve(reserved);

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        DEPLOYER.ownerOf(reserved);
        (holder, expiry) = DEPLOYER.reservation(reserved);
        assertEq(holder, sender);
        assertEq(expiry, vm.getBlockTimestamp() + DAY);

        vm.expectRevert(IDeployer.Reserved.selector);
        DEPLOYER.reserve(reserved);

        vm.expectRevert(IDeployer.NotOwner.selector);
        DEPLOYER.reveal(reserved, salt);

        bytes32 badSalt = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
        vm.expectRevert(IDeployer.BadSalt.selector);
        vm.prank(sender);
        DEPLOYER.reveal(reserved, badSalt);

        assertEq(DEPLOYER.balanceOf(sender), 0);

        vm.prank(sender);
        DEPLOYER.reveal(reserved, salt);

        assertEq(getStoredSalt(reserved), salt);

        assertEq(DEPLOYER.balanceOf(sender), 1);
        assertEq(DEPLOYER.ownerOf(reserved), sender);
        (holder, expiry) = DEPLOYER.reservation(reserved);
        assertEq(holder, sender);
        assertEq(expiry, 0);

        vm.expectRevert(IDeployer.NotOwner.selector);
        DEPLOYER.deploy(reserved, initCode);

        skip(DAY);
        vm.expectRevert(IDeployer.Reserved.selector);
        DEPLOYER.dispute(reserved);

        vm.prank(sender);
        DEPLOYER.deploy(reserved, initCode);

        assertEq(reserved.code, type(Example).runtimeCode);
        // salt was cleared from storage
        assertEq(getStoredSalt(reserved), bytes32(0));

        Example deployed = Example(reserved);
        assertEq(deployed.owner(), address(DEPLOYER));

        address recipient = makeAddr("recipient");

        vm.expectRevert(IDeployer.NotOwner.selector);
        DEPLOYER.call{value: 1 ether}(reserved, abi.encodeWithSelector(Example.pay.selector, recipient));

        assertEq(recipient.balance, 0);

        vm.deal(sender, 1 ether);
        vm.prank(sender);
        DEPLOYER.call{value: 1 ether}(reserved, abi.encodeWithSelector(Example.pay.selector, recipient));

        assertEq(recipient.balance, 1 ether);
        assertEq(reserved.balance, 0);
        assertEq(sender.balance, 0);
        assertEq(DEPLOYER.ownerOf(reserved), sender);
        (holder, expiry) = DEPLOYER.reservation(reserved);
        assertEq(holder, sender);
        assertEq(expiry, 0);
    }

    function testDispute() public {
        address reserved = makeAddr("reserved");
        address squatter = makeAddr("squatter");
        address disputer = makeAddr("disputer");

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        DEPLOYER.ownerOf(reserved);

        address holder;
        uint96 expiry;

        (holder, expiry) = DEPLOYER.reservation(reserved);
        assertEq(holder, address(0));
        assertEq(expiry, 0);

        vm.prank(squatter);
        DEPLOYER.reserve(reserved);

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        DEPLOYER.ownerOf(reserved);

        (holder, expiry) = DEPLOYER.reservation(reserved);
        assertEq(holder, squatter);
        assertEq(expiry, vm.getBlockTimestamp() + DAY);

        vm.expectRevert(IDeployer.Reserved.selector);
        vm.prank(disputer);
        DEPLOYER.dispute(reserved);

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        DEPLOYER.ownerOf(reserved);

        skip(DAY);

        vm.prank(disputer);
        DEPLOYER.dispute(reserved);
        vm.expectRevert(IDeployer.InvalidAddress.selector);
        DEPLOYER.ownerOf(reserved);

        (holder, expiry) = DEPLOYER.reservation(reserved);
        assertEq(holder, disputer);
        assertEq(expiry, vm.getBlockTimestamp() + DAY);
    }
}
