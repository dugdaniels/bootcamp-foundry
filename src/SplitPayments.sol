// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error TransferFailed();

contract SplitPayments {
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    address payable public firstRecipient;
    address payable public secondRecipient;
    mapping(address => uint256) public balances;

    constructor(address _firstRecipient, address _secondRecipient) {
        firstRecipient = payable(_firstRecipient);
        secondRecipient = payable(_secondRecipient);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
        emit Withdrawal(msg.sender, amount);
    }

    function sweep() external {
        uint256 dust = address(this).balance - (balances[firstRecipient] + balances[secondRecipient]);
        _split(dust);
    }

    function _split(uint256 amount) internal {
        uint256 half = amount / 2;
        balances[firstRecipient] += half;
        balances[secondRecipient] += half;
    }

    receive() external payable {
        _split(msg.value);
        emit Deposit(msg.sender, msg.value);
    }
}
