// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {LibClone} from "solady/utils/LibClone.sol";

import {IDeployer} from "../../src/interfaces/IDeployer.sol";

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

    function testApproveForAllTransfer() public {
        address origin = makeAddr("origin");
        address operator = makeAddr("operator");
        address recipient = makeAddr("recipient");

        uint256 token1 = mint(SALT1, origin);

        assertFalse(DEPLOYER.isApprovedForAll(origin, operator));

        vm.prank(origin);
        DEPLOYER.setApprovalForAll(operator, true);

        assertTrue(DEPLOYER.isApprovedForAll(origin, operator));
    }
}
