// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {LibClone} from "solady/utils/LibClone.sol";

import {IDeployer} from "../../src/interfaces/IDeployer.sol";
import {IERC721} from "../../src/interfaces/IERC721.sol";

contract TransferTest is Test {
    IDeployer constant DEPLOYER = IDeployer(0x000000000000c57CF0A1f923d44527e703F1ad70);

    bytes32 initCodeHash;

    bytes32 constant SALT1 = 0x1234123412341234123412341234123412341234123412341234123412341234;
    bytes32 constant SALT2 = bytes32(uint256(2));

    function setUp() public {
        vm.etch(address(DEPLOYER), vm.getDeployedCode("out/Deployer.evm/Deployer.json"));
        initCodeHash = keccak256(vm.getDeployedCode("out/Init.evm/Init.json"));
    }

    function mint(bytes32 salt, address owner) internal returns (uint256 tokenId) {
        address reserved = LibClone.predictDeterministicAddress(initCodeHash, salt, address(DEPLOYER));
        tokenId = uint256(uint160(reserved));
        vm.expectRevert(IDeployer.InvalidAddress.selector);
        DEPLOYER.ownerOf(tokenId);

        vm.prank(owner);
        DEPLOYER.reserve(reserved);
        vm.prank(owner);
        DEPLOYER.reveal(reserved, salt);

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

    function testOwnerOfEvenAddress() public {
        mint(SALT2, address(2));
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

    function testTransferToZeroAddressReverts() public {
        address origin = makeAddr("origin");
        uint256 token1 = mint(SALT1, origin);

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        vm.prank(origin);
        DEPLOYER.transferFrom(origin, address(0), token1);
    }

    function testTransferUnauthorizedReverts() public {
        address origin = makeAddr("origin");
        address recipient = makeAddr("recipient");
        address stranger = makeAddr("stranger");
        uint256 token1 = mint(SALT1, origin);

        vm.expectRevert(IDeployer.NotOwner.selector);
        vm.prank(stranger);
        DEPLOYER.transferFrom(origin, recipient, token1);
    }

    function testTransferFromMismatchReverts() public {
        address origin = makeAddr("origin");
        address impostor = makeAddr("impostor");
        address recipient = makeAddr("recipient");
        uint256 token1 = mint(SALT1, origin);

        vm.expectRevert(IDeployer.NotOwner.selector);
        vm.prank(origin);
        DEPLOYER.transferFrom(impostor, recipient, token1);
    }

    function testTransferUnrevealedReservationReverts() public {
        address reserver = makeAddr("reserver");
        address recipient = makeAddr("recipient");
        address reserved = makeAddr("pendingReserved");

        vm.prank(reserver);
        DEPLOYER.reserve(reserved);

        uint256 tokenId = uint256(uint160(reserved));
        vm.expectRevert(IDeployer.NotOwner.selector);
        vm.prank(reserver);
        DEPLOYER.transferFrom(reserver, recipient, tokenId);
    }

    function testTransferOutOfRangeTokenIdReverts() public {
        address origin = makeAddr("origin");
        address recipient = makeAddr("recipient");
        uint256 token1 = mint(SALT1, origin);

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        vm.prank(origin);
        DEPLOYER.transferFrom(origin, recipient, token1 + 2 ** 160);

        assertEq(DEPLOYER.ownerOf(token1), origin);
    }

    function testApproveOutOfRangeTokenIdReverts() public {
        address origin = makeAddr("origin");
        address approved = makeAddr("approved");
        uint256 token1 = mint(SALT1, origin);

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        vm.prank(origin);
        DEPLOYER.approve(approved, token1 + 2 ** 160);

        assertEq(DEPLOYER.getApproved(token1), address(0));
    }

    function testTransferFromZeroAddressWhenUnownedReverts() public {
        address recipient = makeAddr("recipient");
        address unowned = makeAddr("unowned");
        uint256 tokenId = uint256(uint160(unowned));

        vm.expectRevert(IDeployer.InvalidAddress.selector);
        DEPLOYER.ownerOf(tokenId);

        vm.expectRevert(IDeployer.NotOwner.selector);
        DEPLOYER.transferFrom(address(0), recipient, tokenId);
    }
}
