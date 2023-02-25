// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MagicNumber {
    event MagicNumberSet(address indexed setter, uint256 number);

    uint256 private _number;

    function setMagicNumber(uint256 number_) public {
        _number = number_;
        emit MagicNumberSet(msg.sender, number_);
    }

    function getMagicNumber() external view returns (uint256) {
        return _number;
    }
}
