// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error InvalidMagicNumber(uint256 sent);
error MagicNumberAlreadySet(uint256 number, address setter);

contract UserAccountMagicNumber {
    event MagicNumberSet(address indexed setter, uint256 number);

    mapping(address => uint256) private magicNumber;

    function setMagicNumber(uint256 number_) public {
        if (number_ == 0) revert InvalidMagicNumber(number_);
        if (magicNumber[msg.sender] != 0) revert MagicNumberAlreadySet(magicNumber[msg.sender], msg.sender);

        magicNumber[msg.sender] = number_;
        emit MagicNumberSet(msg.sender, number_);
    }

    function getMagicNumber(address setter_) external view returns (uint256) {
        return magicNumber[setter_];
    }
}
