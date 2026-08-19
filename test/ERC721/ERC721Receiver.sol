// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {IERC721TokenReceiver} from "../../src/interfaces/IERC721TokenReceiver.sol";

contract ERC721Receiver is IERC721TokenReceiver {
    bytes32 expectedHash;

    // @dev use this to force revert
    function setExpectedData(bytes calldata expectedData) external {
        expectedHash = keccak256(expectedData);
    }

    // @dev use this to check the parameters
    event Received(address operator, address from, uint256 tokenId, bytes data);

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        emit Received(operator, from, tokenId, data);
        require(keccak256(data) == expectedHash);
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}
