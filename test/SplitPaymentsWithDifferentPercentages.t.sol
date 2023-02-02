// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {SplitPaymentsWithDifferentPercentages} from "../src/SplitPaymentsWithDifferentPercentages.sol";

contract SplitPaymentsWithDifferentPercentagesTest is Test {
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    Utilities internal utils;
    SplitPaymentsWithDifferentPercentages internal splitPayments;
    address[] internal users;
    address internal alice;
    address internal bob;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(2);
        alice = users[0];
        bob = users[1];
    }

    function testDepositsAreSplit(uint256 amount, uint8 firstSplit, uint8 secondSplit) public {
        vm.assume(amount > 0 && amount <= type(uint128).max);
        vm.assume(firstSplit > 0);
        vm.assume(secondSplit > 0);

        splitPayments = new SplitPaymentsWithDifferentPercentages(alice, bob, uint8(firstSplit), uint8(secondSplit));
        uint256 totalSplit = uint256(firstSplit) + secondSplit;

        vm.deal(address(this), amount);
        vm.expectEmit(true, false, false, true, address(splitPayments));
        emit Deposit(address(this), amount);

        (bool success,) = address(splitPayments).call{value: amount}("");
        assertTrue(success);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(3)));
        assertEq(vm.load(address(splitPayments), slot), bytes32(amount * firstSplit / totalSplit));

        slot = keccak256(abi.encodePacked(abi.encode(bob), uint256(3)));
        assertEq(vm.load(address(splitPayments), slot), bytes32(amount * secondSplit / totalSplit));

        assertEq(address(splitPayments).balance, amount);
    }

    function testRecipientCanWithdraw(uint256 amount, uint8 firstSplit, uint8 secondSplit) public {
        splitPayments = new SplitPaymentsWithDifferentPercentages(alice, bob, firstSplit, secondSplit);

        uint256 originalAliceBalance = alice.balance;
        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(3)));

        vm.assume(amount > 0 && amount <= type(uint256).max - originalAliceBalance);
        vm.deal(address(splitPayments), amount);
        vm.store(address(splitPayments), slot, bytes32(amount));
        vm.prank(alice);
        vm.expectEmit(true, false, false, true, address(splitPayments));
        emit Withdrawal(alice, amount);

        splitPayments.withdraw();

        assertEq(vm.load(address(splitPayments), slot), bytes32(0));
        assertEq(alice.balance, originalAliceBalance + amount);
        assertEq(address(splitPayments).balance, 0);
    }

    function testSweepSplitsRemainder(uint256 amount, uint8 firstSplit, uint8 secondSplit) public {
        vm.assume(amount > 0 && amount <= type(uint128).max);
        vm.assume(firstSplit > 0);
        vm.assume(secondSplit > 0);

        splitPayments = new SplitPaymentsWithDifferentPercentages(alice, bob, firstSplit, secondSplit);
        uint256 totalSplit = uint256(firstSplit) + secondSplit;

        vm.deal(address(splitPayments), amount);
        splitPayments.sweep();

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(3)));
        assertEq(vm.load(address(splitPayments), slot), bytes32(amount * firstSplit / totalSplit));

        slot = keccak256(abi.encodePacked(abi.encode(bob), uint256(3)));
        assertEq(vm.load(address(splitPayments), slot), bytes32(amount * secondSplit / totalSplit));
    }
}
