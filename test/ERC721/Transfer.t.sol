// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {LibClone} from "solady/utils/LibClone.sol";

import {IDeployer} from "../../src/interfaces/IDeployer.sol";
import {IERC721} from "../../src/interfaces/IERC721.sol";

contract MetadataTest is Test {
    IDeployer constant DEPLOYER = IDeployer(0x000000000000c57CF0A1f923d44527e703F1ad70);

    bytes32 initCodeHash;

    bytes32 constant SALT1 = 0x1234123412341234123412341234123412341234123412341234123412341234;

    function setUp() public {
        vm.etch(address(DEPLOYER), vm.getDeployedCode("out/Deployer.evm/Deployer.json"));
        initCodeHash = keccak256(vm.getDeployedCode("out/Init.evm/Init.json"));
    }

    function mint(bytes32 salt, address owner) internal returns (uint256 tokenId) {
        address reserved = LibClone.predictDeterministicAddress(initCodeHash, salt, address(DEPLOYER));
        vm.prank(owner);
        DEPLOYER.reserve(reserved);
        vm.prank(owner);
        DEPLOYER.reveal(reserved, salt);

        tokenId = uint256(uint160(reserved));
        assertEq(DEPLOYER.ownerOf(tokenId), owner);
    }

    function testOwnerTransfer() public {
        address origin = makeAddr("origin");
        address approved = makeAddr("approved");
        address recipient = makeAddr("recipient");
        uint256 token1 = mint(SALT1, origin);

        vm.prank(origin);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Approval(origin, approved, token1);
        DEPLOYER.approve(approved, token1);

        assertEq(DEPLOYER.getApproved(token1), approved);
        assertEq(DEPLOYER.balanceOf(origin), 1);
        assertEq(DEPLOYER.balanceOf(recipient), 0);

        vm.prank(origin);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Transfer(origin, recipient, token1);
        DEPLOYER.transferFrom(origin, recipient, token1);

        assertEq(DEPLOYER.getApproved(token1), address(0));
        assertEq(DEPLOYER.balanceOf(origin), 0);
        assertEq(DEPLOYER.balanceOf(recipient), 1);
    }

    function testApproveTransfer() public {
        vm.expectRevert();
        DEPLOYER.getApproved(1);

        address origin = makeAddr("origin");
        address approved = makeAddr("approved");
        address operator = makeAddr("operator");
        address recipient = makeAddr("recipient");

        uint256 token1 = mint(SALT1, origin);

        assertEq(DEPLOYER.getApproved(token1), address(0));

        vm.expectRevert(IDeployer.NotOwner.selector);
        DEPLOYER.approve(approved, token1);

        vm.prank(origin);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Approval(origin, approved, token1);
        DEPLOYER.approve(approved, token1);

        assertEq(DEPLOYER.getApproved(token1), approved);

        vm.prank(origin);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.ApprovalForAll(origin, operator, true);
        DEPLOYER.setApprovalForAll(operator, true);

        vm.prank(operator);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Approval(origin, address(0), token1);
        DEPLOYER.approve(address(0), token1);

        assertEq(DEPLOYER.getApproved(token1), address(0));

        vm.prank(operator);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Approval(origin, approved, token1);
        DEPLOYER.approve(approved, token1);

        assertEq(DEPLOYER.getApproved(token1), approved);
        assertEq(DEPLOYER.balanceOf(origin), 1);
        assertEq(DEPLOYER.balanceOf(recipient), 0);

        vm.prank(approved);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Transfer(origin, recipient, token1);
        DEPLOYER.transferFrom(origin, recipient, token1);

        assertEq(DEPLOYER.getApproved(token1), address(0));
        assertEq(DEPLOYER.balanceOf(origin), 0);
        assertEq(DEPLOYER.balanceOf(recipient), 1);
    }

    function testApproveForAllTransfer() public {
        address origin = makeAddr("origin");
        address operator = makeAddr("operator");
        address approved = makeAddr("approved");
        address recipient = makeAddr("recipient");

        uint256 token1 = mint(SALT1, origin);

        assertFalse(DEPLOYER.isApprovedForAll(origin, operator));

        vm.expectEmit(address(DEPLOYER));
        emit IERC721.ApprovalForAll(origin, operator, true);
        vm.prank(origin);
        DEPLOYER.setApprovalForAll(operator, true);

        assertTrue(DEPLOYER.isApprovedForAll(origin, operator));

        vm.prank(origin);
        DEPLOYER.approve(approved, token1);

        assertEq(DEPLOYER.getApproved(token1), approved);
        assertEq(DEPLOYER.balanceOf(origin), 1);
        assertEq(DEPLOYER.balanceOf(recipient), 0);

        vm.prank(operator);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Transfer(origin, recipient, token1);
        DEPLOYER.transferFrom(origin, recipient, token1);

        assertEq(DEPLOYER.getApproved(token1), address(0));
        assertEq(DEPLOYER.balanceOf(origin), 0);
        assertEq(DEPLOYER.balanceOf(recipient), 1);
    }
}
