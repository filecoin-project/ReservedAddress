// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {LibClone} from "solady/utils/LibClone.sol";

import {ERC721Receiver} from "./ERC721Receiver.sol";
import {IDeployer} from "../../src/interfaces/IDeployer.sol";
import {IERC721} from "../../src/interfaces/IERC721.sol";

contract SafeTransferTest is Test {
    IDeployer constant DEPLOYER = IDeployer(0x000000000000c57CF0A1f923d44527e703F1ad70);

    bytes32 initCodeHash;
    ERC721Receiver receiver;

    bytes32 constant SALT1 = 0x5678567856785678567856785678567856785678567856785678567856785678;

    function setUp() public {
        vm.etch(address(DEPLOYER), vm.getDeployedCode("out/Deployer.evm/Deployer.json"));
        initCodeHash = keccak256(vm.getDeployedCode("out/Init.evm/Init.json"));
        receiver = new ERC721Receiver();
    }

    function mint(bytes32 salt, address owner) internal returns (uint256 tokenId) {
        address reserved = LibClone.predictDeterministicAddress(initCodeHash, salt, address(DEPLOYER));
        assertEq(DEPLOYER.ownerOf(tokenId), address(0));

        vm.prank(owner);
        DEPLOYER.reserve(reserved);
        vm.prank(owner);
        DEPLOYER.reveal(reserved, salt);

        tokenId = uint256(uint160(reserved));
        assertEq(DEPLOYER.ownerOf(tokenId), owner);
    }

    function testSafeTransferAccepted() public {
        address origin = makeAddr("origin");
        address approved = makeAddr("approved");

        uint256 token1 = mint(SALT1, origin);

        vm.prank(origin);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Approval(origin, approved, token1);
        DEPLOYER.approve(approved, token1);

        receiver.setExpectedData("");

        vm.prank(approved);
        vm.expectEmit(address(receiver));
        emit ERC721Receiver.Received(approved, origin, token1, "");
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Transfer(origin, address(receiver), token1);
        DEPLOYER.safeTransferFrom(origin, address(receiver), token1);
    }

    function testSafeTransferData() public {
        address origin = makeAddr("origin");
        address approved = makeAddr("approved");

        uint256 token1 = mint(SALT1, origin);

        vm.prank(origin);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Approval(origin, approved, token1);
        DEPLOYER.approve(approved, token1);

        bytes memory lorem =
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
        receiver.setExpectedData(lorem);

        vm.prank(approved);
        vm.expectEmit(address(receiver));
        emit ERC721Receiver.Received(approved, origin, token1, lorem);
        vm.expectEmit(address(DEPLOYER));
        emit IERC721.Transfer(origin, address(receiver), token1);
        DEPLOYER.safeTransferFrom(origin, address(receiver), token1, lorem);
    }
}
