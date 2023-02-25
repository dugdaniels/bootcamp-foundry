// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

error InsufficientFunds();
error InvalidAddress();
error NotAuthorized();
error TransferFailed();

struct Transfer {
    address recipient;
    uint256 value;
    uint128 approvalsRequired;
    uint128 approvalsReceived;
    mapping(address => bool) hasApproved;
    bool executed;
}

contract Multisig is Ownable {
    event SignerAdded(address indexed addr);
    event SignerRemoved(address indexed addr);
    event TransferQueued(uint256 indexed transferId, address indexed recipient, uint256 value);
    event ApprovalReceived(uint256 indexed transferId, address indexed approver);
    event TransferExecuted(address indexed to, uint256 value);

    mapping(address => bool) public isSigner;
    mapping(uint256 => Transfer) public transfers;
    uint256 transferCount;
    uint256 queuedBalance;

    constructor(address[] memory signers_) payable Ownable() {
        for (uint256 i; i < signers_.length;) {
            addSigner(signers_[i]);
            unchecked {
                ++i;
            }
        }
    }

    function queueTransfer(address recipient_, uint256 value_, uint128 approvalsRequired_)
        public
        payable
        onlySigner
        returns (uint256 transferId)
    {
        queuedBalance += value_;
        if (queuedBalance > address(this).balance) revert InsufficientFunds();
        if (recipient_ == address(0)) revert InvalidAddress();

        // transferId is return value
        transferId = transferCount++;

        Transfer storage t = transfers[transferId];
        t.recipient = recipient_;
        t.value = value_;
        t.approvalsRequired = approvalsRequired_;
        t.approvalsReceived = 1;
        t.hasApproved[msg.sender] = true;

        emit TransferQueued(transferId, recipient_, value_);
        emit ApprovalReceived(transferId, msg.sender);
    }

    function approve(uint256 transferId_) public onlySigner {
        Transfer storage t = transfers[transferId_];
        if (t.executed) revert NotAuthorized();
        if (t.hasApproved[msg.sender]) revert NotAuthorized();

        uint128 approvals = ++t.approvalsReceived;
        t.hasApproved[msg.sender] = true;
        emit ApprovalReceived(transferId_, msg.sender);

        if (approvals == t.approvalsRequired) _execute(transferId_);
    }

    function addSigner(address addr_) public onlyOwner {
        if (addr_ == address(0)) revert InvalidAddress();
        if (isSigner[addr_]) revert InvalidAddress();

        isSigner[addr_] = true;
        emit SignerAdded(addr_);
    }

    function removeSigner(address addr_) public onlyOwner {
        if (!isSigner[addr_]) revert InvalidAddress();

        isSigner[addr_] = false;
        emit SignerRemoved(addr_);
    }

    function _execute(uint256 transferId_) internal {
        Transfer storage t = transfers[transferId_];
        address recipient = t.recipient;

        t.executed = true;
        (bool success,) = recipient.call{value: t.value}("");
        if (!success) revert TransferFailed();

        emit TransferExecuted(recipient, t.value);
    }

    modifier onlySigner() {
        if (!isSigner[msg.sender]) revert NotAuthorized();
        _;
    }

    receive() external payable {}
}
