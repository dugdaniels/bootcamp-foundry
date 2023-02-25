// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error InsufficientFunds();
error InsufficientAllowance();
error TransferFailed();
error InvalidAddress();

contract EtherWalletWithApprovals {
    event Deposit(address indexed sender, address indexed recipient, uint256 amount);
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Allowance(address indexed owner, address indexed spender, uint256 amount);

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    function deposit(address recipient_) external payable {
        balances[recipient_] += msg.value;
        emit Deposit(msg.sender, recipient_, msg.value);
    }

    function increaseAllowance(address spender_, uint256 amount_) external {
        if (spender_ == address(0)) {
            revert InvalidAddress();
        }
        allowances[msg.sender][spender_] += amount_;
        emit Allowance(msg.sender, spender_, allowances[msg.sender][spender_]);
    }

    function decreaseAllowance(address spender_, uint256 amount_) external {
        if (allowances[msg.sender][spender_] < amount_) {
            revokeAllowance(spender_);
        } else {
            allowances[msg.sender][spender_] -= amount_;
            emit Allowance(msg.sender, spender_, allowances[msg.sender][spender_]);
        }
    }

    function revokeAllowance(address spender_) public {
        allowances[msg.sender][spender_] = 0;
        emit Allowance(msg.sender, spender_, 0);
    }

    function allowance(address owner_, address spender_) external view returns (uint256) {
        return allowances[owner_][spender_];
    }

    function withdraw(uint256 amount_) external {
        _transfer(msg.sender, msg.sender, amount_);
    }

    function transferFrom(address from_, address to_, uint256 amount_) external {
        if (allowances[from_][msg.sender] < amount_) {
            revert InsufficientAllowance();
        }
        allowances[from_][msg.sender] -= amount_;

        _transfer(from_, to_, amount_);
    }

    function _transfer(address from_, address to_, uint256 amount_) internal {
        if (balances[from_] < amount_) {
            revert InsufficientFunds();
        }
        balances[from_] -= amount_;

        (bool success,) = to_.call{value: amount_}("");
        if (!success) {
            revert TransferFailed();
        }
        emit Transfer(from_, to_, amount_);
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.sender, msg.value);
    }
}
