// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MagicNumber {
    event MagicNumberSet(address indexed setter, uint256 number);

    uint256 private number;

    function setMagicNumber(uint256 _number) public {
        number = _number;
        emit MagicNumberSet(msg.sender, _number);
    }

    function getMagicNumber() external view returns (uint256) {
        return number;
    }
}
