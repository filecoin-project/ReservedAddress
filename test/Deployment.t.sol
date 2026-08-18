// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";

import {IDeployer} from "../src/interfaces/IDeployer.sol";


contract DeploymentTest is Test {
    IDeployer internal deployer; 

    function setUp() public {
        deployer = IDeployer(deployCode("out/Deploy.evm/Deploy.json"));
    }

    function testAuctionDeployCall() public {
    }
}
