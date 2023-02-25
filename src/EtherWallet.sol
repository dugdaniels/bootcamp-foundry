// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error InsufficientFunds();
error TransferFailed();

contract EtherWallet {
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed sender, uint256 amount);

    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount_) external {
        if (balances[msg.sender] < amount_) {
            revert InsufficientFunds();
        }
        balances[msg.sender] -= amount_;
        (bool success,) = msg.sender.call{value: amount_}("");
        if (!success) {
            revert TransferFailed();
        }
        emit Withdrawal(msg.sender, amount_);
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
