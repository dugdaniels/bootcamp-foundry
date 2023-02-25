// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error TransferFailed();

contract SplitPaymentsWithDifferentPercentages {
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    address payable public firstRecipient;
    address payable public secondRecipient;
    uint128 public firstSplit;
    uint128 public secondSplit;
    mapping(address => uint256) public balances;

    constructor(address firstRecipient_, address secondRecipient_, uint8 firstSplit_, uint8 secondSplit_) {
        firstRecipient = payable(firstRecipient_);
        secondRecipient = payable(secondRecipient_);
        firstSplit = firstSplit_;
        secondSplit = secondSplit_;
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

    function _split(uint256 amount_) internal {
        uint256 totalSplit = firstSplit + secondSplit;
        balances[firstRecipient] += amount_ * firstSplit / totalSplit;
        balances[secondRecipient] += amount_ * secondSplit / totalSplit;
    }

    receive() external payable {
        _split(msg.value);
        emit Deposit(msg.sender, msg.value);
    }
}
