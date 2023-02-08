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

    function queueTransfer(address recipient, uint256 value, uint128 approvalsRequired)
        public
        payable
        onlySigner
        returns (uint256 transferId)
    {
        queuedBalance += value;
        if (queuedBalance > address(this).balance) revert InsufficientFunds();
        if (recipient == address(0)) revert InvalidAddress();

        // transferId is return value
        transferId = transferCount++;

        Transfer storage t = transfers[transferId];
        t.recipient = recipient;
        t.value = value;
        t.approvalsRequired = approvalsRequired;
        t.approvalsReceived = 1;
        t.hasApproved[msg.sender] = true;

        emit TransferQueued(transferId, recipient, value);
        emit ApprovalReceived(transferId, msg.sender);
    }

    function approve(uint256 transferId) public onlySigner {
        Transfer storage t = transfers[transferId];
        if (t.executed) revert NotAuthorized();
        if (t.hasApproved[msg.sender]) revert NotAuthorized();

        uint128 approvals = ++t.approvalsReceived;
        t.hasApproved[msg.sender] = true;
        emit ApprovalReceived(transferId, msg.sender);

        if (approvals == t.approvalsRequired) _execute(transferId);
    }

    function addSigner(address addr) public onlyOwner {
        if (addr == address(0)) revert InvalidAddress();
        if (isSigner[addr]) revert InvalidAddress();

        isSigner[addr] = true;
        emit SignerAdded(addr);
    }

    function removeSigner(address addr) public onlyOwner {
        if (!isSigner[addr]) revert InvalidAddress();

        isSigner[addr] = false;
        emit SignerRemoved(addr);
    }

    function _execute(uint256 transferId) internal {
        Transfer storage t = transfers[transferId];
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
