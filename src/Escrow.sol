// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error FundsRequired();
error NotAuthorized();
error FundsNotReleased();
error TransferFailed();

contract Escrow {
    event Withdrawal(address indexed recipient, uint256 amount);

    address public immutable recipient;
    uint256 public releaseTimestamp;

    constructor(address recipient_, uint256 timelock_) payable {
        if (msg.value == 0) revert FundsRequired();

        recipient = payable(recipient_);
        releaseTimestamp = block.timestamp + timelock_;
    }

    function fundsReleased() public view returns (bool) {
        return block.timestamp >= releaseTimestamp;
    }

    function withdraw() public {
        if (msg.sender != recipient) revert NotAuthorized();
        if (!fundsReleased()) revert FundsNotReleased();

        (bool success,) = address(recipient).call{value: address(this).balance}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(recipient, address(this).balance);
    }
}
