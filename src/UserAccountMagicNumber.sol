// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error InvalidMagicNumber(uint256 sent);
error MagicNumberAlreadySet(uint256 number, address setter);

contract UserAccountMagicNumber {
    event MagicNumberSet(address indexed setter, uint256 number);

    mapping(address => uint256) private magicNumber;

    function setMagicNumber(uint256 _number) public {
        if (_number == 0) revert InvalidMagicNumber(_number);
        if (magicNumber[msg.sender] != 0) revert MagicNumberAlreadySet(magicNumber[msg.sender], msg.sender);

        magicNumber[msg.sender] = _number;
        emit MagicNumberSet(msg.sender, _number);
    }

    function getMagicNumber(address _setter) external view returns (uint256) {
        return magicNumber[_setter];
    }
}
