// SPDX-License-Identifier: Apache-2.0 OR MIT
pragma solidity ^0.8.36;

interface IDeployer {
    error InvalidAddress();
    error ERC721TokenReceiverRejected();
    error NotOwner();
    error Reserved();
    error BadSalt();

    // Permissioned
    function deploy(address owned, address initCode) external payable;
    function call(address deployed, bytes calldata callData) external payable /*returns (raw_bytes)*/ ;

    // Registration

    function reservation(address reserved) external view returns (address holder, uint96 expiry);

    function reserve(address reserved) external;
    function reveal(address reserved, bytes32 salt) external;
    function dispute(address reserved) external;

    // IERC721
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    // IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    // IERC721Metadata
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function tokenURI(uint256 tokenId) external pure returns (string memory);

    // IERC721Enumerable
    // tokenOfOwnerByIndex is not supported
    function totalSupply() external pure returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}
