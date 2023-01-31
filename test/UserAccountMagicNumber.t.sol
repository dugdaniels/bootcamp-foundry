// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {UserAccountMagicNumber} from "../src/UserAccountMagicNumber.sol";

error InvalidMagicNumber(uint256 sent);
error MagicNumberAlreadySet(uint256 number, address setter);

contract UserAccountMagicNumberTest is Test {
    event MagicNumberSet(address indexed setter, uint256 number);

    Utilities internal utils;
    UserAccountMagicNumber public magicNumber;
    address[] internal users;
    address internal alice;
    address internal bob;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(1);
        alice = users[0];

        magicNumber = new UserAccountMagicNumber();
    }

    function testSetMagicNumber(uint256 number) public {
        vm.assume(number > 0);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true, address(magicNumber));
        emit MagicNumberSet(alice, number);

        magicNumber.setMagicNumber(number);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        assertEq(vm.load(address(magicNumber), slot), bytes32(number));
    }

    function testCannotSetMagicNumberToZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(InvalidMagicNumber.selector, 0));
        magicNumber.setMagicNumber(0);
    }

    function testMagicNumberCanOnlyBeSetOnce() public {
        vm.startPrank(alice);

        magicNumber.setMagicNumber(1);
        vm.expectRevert(abi.encodeWithSelector(MagicNumberAlreadySet.selector, 1, alice));
        magicNumber.setMagicNumber(2);

        vm.stopPrank();
    }

    function testGetMagicNumber(uint256 number) public {
        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        vm.store(address(magicNumber), slot, bytes32(number));

        assertEq(magicNumber.getMagicNumber(alice), number);
    }
}
