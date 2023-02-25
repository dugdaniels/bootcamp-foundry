// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract NFT is IERC165 {
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;

    function balanceOf(address owner_) external view returns (uint256) {
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId_) external view returns (address) {
        return _owners[tokenId_];
    }

    function supportsInterface(bytes4 interfaceID_) external pure returns (bool) {
        return interfaceID_ == type(IERC165).interfaceId || interfaceID_ == type(IERC721).interfaceId;
    }
}
