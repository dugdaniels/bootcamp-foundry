// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MagicNumber.sol";

contract MagicNumberTest is Test {
    event MagicNumberSet(address indexed setter, uint256 number);

    MagicNumber public magicNumber;

    function setUp() public {
        magicNumber = new MagicNumber();
    }

    function testSetMagicNumber(uint256 number) public {
        assertEq(vm.load(address(magicNumber), bytes32(uint256(0))), 0);

        vm.expectEmit(true, false, false, true, address(magicNumber));
        emit MagicNumberSet(address(this), number);

        magicNumber.setMagicNumber(number);

        assertEq(vm.load(address(magicNumber), bytes32(uint256(0))), bytes32(number));
    }

    function testGetMagicNumber(uint256 number) public {
        vm.store(address(magicNumber), bytes32(uint256(0)), bytes32(number));

        assertEq(magicNumber.getMagicNumber(), number);
    }
}
