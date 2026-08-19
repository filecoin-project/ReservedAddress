// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {IDeployer} from "../interfaces/IDeployer.sol";

library IDeployerLibrary {
    function ownerOf(IDeployer deployer, address reserved) internal view returns (address owner) {
        return deployer.ownerOf(uint256(uint160(reserved)));
    }

    function getApproved(IDeployer deployer, address owned) internal view returns (address owner) {
        return deployer.getApproved(uint256(uint160(owned)));
    }
}
