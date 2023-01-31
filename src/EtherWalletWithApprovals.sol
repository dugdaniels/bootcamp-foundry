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

    function deposit(address recipient) external payable {
        balances[recipient] += msg.value;
        emit Deposit(msg.sender, recipient, msg.value);
    }

    function increaseAllowance(address spender, uint256 amount) external {
        if (spender == address(0)) {
            revert InvalidAddress();
        }
        allowances[msg.sender][spender] += amount;
        emit Allowance(msg.sender, spender, allowances[msg.sender][spender]);
    }

    function decreaseAllowance(address spender, uint256 amount) external {
        if (allowances[msg.sender][spender] < amount) {
            revokeAllowance(spender);
        } else {
            allowances[msg.sender][spender] -= amount;
            emit Allowance(msg.sender, spender, allowances[msg.sender][spender]);
        }
    }

    function revokeAllowance(address spender) public {
        allowances[msg.sender][spender] = 0;
        emit Allowance(msg.sender, spender, 0);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function withdraw(uint256 amount) external {
        _transfer(msg.sender, msg.sender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external {
        if (allowances[from][msg.sender] < amount) {
            revert InsufficientAllowance();
        }
        allowances[from][msg.sender] -= amount;

        _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (balances[from] < amount) {
            revert InsufficientFunds();
        }
        balances[from] -= amount;

        (bool success,) = to.call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
        emit Transfer(from, to, amount);
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.sender, msg.value);
    }
}
