// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error InvalidTokenId();
error InvalidOwner();
error InvalidRecipient();
error NotApproved();

interface IERC721 {
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);
    event Approval(address indexed owner_, address indexed approved_, uint256 indexed tokenId_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, bool approved_);

    function balanceOf(address owner_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes calldata data_) external;
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) external;
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
    function approve(address approved_, uint256 tokenId_) external;
    function setApprovalForAll(address operator_, bool approved_) external;
    function getApproved(uint256 tokenId_) external view returns (address);
    function isApprovedForAll(address owner_, address operator_) external view returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID_) external view returns (bool);
}

interface ERC721TokenReceiver {
    function onERC721Received(address operator_, address from_, uint256 tokenId_, bytes calldata data_)
        external
        returns (bytes4);
}

contract NFT is IERC721, IERC165 {
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operators;

    function balanceOf(address owner_) external view returns (uint256) {
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId_) public view returns (address) {
        return _owners[tokenId_];
    }

    function supportsInterface(bytes4 interfaceID_) external pure returns (bool) {
        return interfaceID_ == type(IERC165).interfaceId || interfaceID_ == type(IERC721).interfaceId;
    }

    function approve(address addr_, uint256 tokenId_) external {
        address owner = ownerOf(tokenId_);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert NotApproved();
        }
        _tokenApprovals[tokenId_] = addr_;

        emit Approval(owner, addr_, tokenId_);
    }

    function getApproved(uint256 tokenId_) public view returns (address) {
        return _tokenApprovals[tokenId_];
    }

    function setApprovalForAll(address addr_, bool approved_) external {
        _operators[msg.sender][addr_] = approved_;

        emit ApprovalForAll(msg.sender, addr_, approved_);
    }

    function isApprovedForAll(address owner_, address operator_) public view returns (bool) {
        return _operators[owner_][operator_];
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) external {
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) external {
        _safeTransfer(from_, to_, tokenId_, "");
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes calldata data_) public {
        _safeTransfer(from_, to_, tokenId_, data_);
    }

    function _safeTransfer(address from_, address to_, uint256 tokenId_, bytes memory _data) internal {
        _transfer(from_, to_, tokenId_);

        if (to_.code.length > 0) {
            bytes4 retval = ERC721TokenReceiver(to_).onERC721Received(msg.sender, from_, tokenId_, _data);
            if (retval != ERC721TokenReceiver(to_).onERC721Received.selector) {
                revert InvalidRecipient();
            }
        }
    }

    function _transfer(address from_, address to_, uint256 tokenId_) internal {
        if (to_ == address(0)) revert InvalidRecipient();
        if (from_ == address(0) || from_ != ownerOf(tokenId_)) revert InvalidOwner();
        if (msg.sender != from_ && msg.sender != getApproved(tokenId_) && !isApprovedForAll(from_, msg.sender)) {
            revert NotApproved();
        }
        _balances[from_] -= 1;
        _balances[to_] += 1;
        _owners[tokenId_] = to_;
        _tokenApprovals[tokenId_] = address(0);

        emit Transfer(from_, to_, tokenId_);
    }
}
