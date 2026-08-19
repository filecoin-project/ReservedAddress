// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";

import {IDeployer} from "../../src/interfaces/IDeployer.sol";
import {IERC165} from "../../src/interfaces/IERC165.sol";
import {IERC721} from "../../src/interfaces/IERC721.sol";
import {IERC721Metadata} from "../../src/interfaces/IERC721Metadata.sol";


contract ERC165Test is Test {
    IDeployer constant DEPLOYER = IDeployer(0x000000000000c57CF0A1f923d44527e703F1ad70);

    function setUp() public {
        vm.etch(address(DEPLOYER), vm.getDeployedCode("out/Deployer.evm/Deployer.json"));
    }

    function testSupports165() public pure {
        assertTrue(DEPLOYER.supportsInterface(type(IERC165).interfaceId));
        assertFalse(DEPLOYER.supportsInterface(0xffffffff));
    }

    function testSupports721() public pure {
        assertTrue(DEPLOYER.supportsInterface(type(IERC721).interfaceId));
    }

    function testSupports721Metadata() public pure {
        assertTrue(DEPLOYER.supportsInterface(type(IERC721Metadata).interfaceId));
    }

    function testDoesNotSupport721Enumerable() public pure {
        assertFalse(DEPLOYER.supportsInterface(0x780e9d63));
    }

    function testDoesNotSupport721TokenReceiver() public pure {
        assertFalse(DEPLOYER.supportsInterface(0x150b7a02));
    }
}
