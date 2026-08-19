// SPDX-License-Identifier: CC0
pragma solidity ^0.8.36;

// Christian Reitwießner <chris@ethereum.org>, Nick Johnson <nick@ethereum.org>, Fabian Vogelsteller <fabian@lukso.network>, Jordi Baylina <jordi@baylina.cat>, Konrad Feldmeier <konrad.feldmeier@brainbot.com>, William Entriken <github.com@phor.net>, "ERC-165: Standard Interface Detection," Ethereum Improvement Proposals, no. 165, January 2018. Available: https://eips.ethereum.org/EIPS/eip-165.

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
