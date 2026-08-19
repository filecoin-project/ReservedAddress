// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";

import {IDeployer} from "../../src/interfaces/IDeployer.sol";

contract MetadataTest is Test {
    IDeployer constant DEPLOYER = IDeployer(0x000000000000c57CF0A1f923d44527e703F1ad70);

    function setUp() public {
        vm.etch(address(DEPLOYER), vm.getDeployedCode("out/Deployer.evm/Deployer.json"));
    }

    function testName() public {
        assertEq(DEPLOYER.name(), "Contract");
    }

    function testSymbol() public {
        assertEq(DEPLOYER.symbol(), "CODE");
    }

    function testTotalSupply() public {
        assertEq(DEPLOYER.totalSupply(), 2 ** 160);
    }

    function testTokenURI() public {
        assertEq(DEPLOYER.tokenURI(0x009a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a), "https://filecoin.blockscout.com/address/0x9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a9a");
        assertEq(DEPLOYER.tokenURI(0x001234123412341234123412341234123412341234), "https://filecoin.blockscout.com/address/0x1234123412341234123412341234123412341234");
        assertEq(DEPLOYER.tokenURI(0x000000000000000000000000000000000000000000), "https://filecoin.blockscout.com/address/0x0000000000000000000000000000000000000000");
        assertEq(DEPLOYER.tokenURI(0x00abcdef05abcdef05abcdef05abcdef05abcdef05), "https://filecoin.blockscout.com/address/0xabcdef05abcdef05abcdef05abcdef05abcdef05");
        assertEq(DEPLOYER.tokenURI(0x007cd807cd807cd807cd807cd807cd807cd807cd80), "https://filecoin.blockscout.com/address/0x7cd807cd807cd807cd807cd807cd807cd807cd80");
    }
}
