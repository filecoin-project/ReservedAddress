// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

import {IERC721TokenReceiver} from "../../src/interfaces/IERC721TokenReceiver.sol";

contract ERC721Receiver is IERC721TokenReceiver {
    bytes32 expectedHash;
    bytes4 selector;

    error WrongData(bytes actual);

    constructor() {
        selector = IERC721TokenReceiver.onERC721Received.selector;
    }

    // @dev use this to force revert
    function setExpectedData(bytes calldata expectedData) external {
        expectedHash = keccak256(expectedData);
    }

    // @dev use this to successfully return the wrong selector
    function setSelector(bytes4 wrongSelector) external {
        selector = wrongSelector;
    }

    // @dev use this to check the parameters
    event Received(address operator, address from, uint256 tokenId, bytes data);

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        emit Received(operator, from, tokenId, data);
        require(keccak256(data) == expectedHash, WrongData(data));
        return selector;
    }
}
