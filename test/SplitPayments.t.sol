// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {SplitPayments} from "../src/SplitPayments.sol";

contract SplitPaymentsTest is Test {
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    Utilities internal utils;
    SplitPayments internal splitPayments;
    address[] internal users;
    address internal alice;
    address internal bob;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(2);
        alice = users[0];
        bob = users[1];

        splitPayments = new SplitPayments(alice, bob);
    }

    function testDepositsAreSplit(uint256 amount) public {
        vm.assume(amount > 0);
        vm.deal(address(this), amount);
        vm.expectEmit(true, false, false, true, address(splitPayments));
        emit Deposit(address(this), amount);

        (bool success,) = address(splitPayments).call{value: amount}("");
        assert(success);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(2)));
        assertEq(vm.load(address(splitPayments), slot), bytes32(amount / 2));

        slot = keccak256(abi.encodePacked(abi.encode(bob), uint256(2)));
        assertEq(vm.load(address(splitPayments), slot), bytes32(amount / 2));

        assertEq(address(splitPayments).balance, amount);
    }

    function testRecipientCanWithdraw(uint256 amount) public {
        uint256 originalAliceBalance = alice.balance;
        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(2)));

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

    function testSweepSplitsRemainder(uint256 amount) public {
        vm.assume(amount > 0);
        vm.deal(address(splitPayments), amount);

        splitPayments.sweep();

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(2)));
        assertEq(vm.load(address(splitPayments), slot), bytes32(amount / 2));

        slot = keccak256(abi.encodePacked(abi.encode(bob), uint256(2)));
        assertEq(vm.load(address(splitPayments), slot), bytes32(amount / 2));
    }
}
