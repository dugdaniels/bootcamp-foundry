// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error FundsRequired();
error InvalidAddress();
error NotAuthorized();
error TransferFailed();

contract Multisig {
    event SignerAdded(address indexed addr);
    event Transfer(address indexed to, uint256 value);

    uint256 constant AMOUNT = 10 ether;
    uint256 constant THRESHOLD = 2;

    address recipient;
    uint256 approvals;
    mapping(address => bool) public isSigner;
    mapping(address => bool) hasApproved;

    constructor(address[3] memory signers_, address recipient_) payable {
        if (msg.value != AMOUNT) revert FundsRequired();
        if (recipient_ == address(0)) revert InvalidAddress();

        recipient = recipient_;

        for (uint256 i; i < signers_.length;) {
            _addSigner(signers_[i]);
            unchecked {
                ++i;
            }
        }
    }

    function approve() external onlySigner {
        if (hasApproved[msg.sender]) revert NotAuthorized();
        hasApproved[msg.sender] = true;

        unchecked {
            ++approvals;
        }
        if (approvals == THRESHOLD) _send();
    }

    function _addSigner(address addr) internal {
        if (addr == address(0)) revert InvalidAddress();
        if (isSigner[addr]) revert InvalidAddress();

        isSigner[addr] = true;
        emit SignerAdded(addr);
    }

    function _send() internal {
        (bool success,) = recipient.call{value: AMOUNT}("");
        if (!success) revert TransferFailed();

        emit Transfer(recipient, AMOUNT);
    }

    modifier onlySigner() {
        if (!isSigner[msg.sender]) revert NotAuthorized();
        _;
    }
}
