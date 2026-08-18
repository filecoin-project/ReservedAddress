// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

interface IDeployer {
    // permissioned
    function deploy(address reserved, address initCode) external;
    function call(address deployed, bytes calldata callData) external payable /*returns (raw_bytes)*/;

    // auction
    function reveal(address reserved, bytes32 salt) external;
    function reserve(address reserved) external;
    function dispute(address reserved) external;

    // IERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    // IERC721Metadata
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
