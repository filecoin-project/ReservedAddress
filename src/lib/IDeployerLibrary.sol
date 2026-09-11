// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {IDeployer} from "../interfaces/IDeployer.sol";

address constant DEPLOYER_CREATOR = 0x3ef96E9f82CaFE4a05183b59e7671E39B6b26347;
IDeployer constant DEPLOYER = IDeployer(0x000000000000c57CF0A1f923d44527e703F1ad70);

library IDeployerLibrary {
    function ownerOf(IDeployer deployer, address reserved) internal view returns (address owner) {
        return deployer.ownerOf(uint256(uint160(reserved)));
    }

    function getApproved(IDeployer deployer, address owned) internal view returns (address owner) {
        return deployer.getApproved(uint256(uint160(owned)));
    }
}
