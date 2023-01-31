// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error InsufficientFunds();
error InsufficientAllowance();

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {EtherWalletWithApprovals} from "../src/EtherWalletWithApprovals.sol";

contract EtherWalletWithApprovalsTest is Test {
    event Deposit(address indexed sender, address indexed recipient, uint256 amount);
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Allowance(address indexed owner, address indexed spender, uint256 amount);

    Utilities internal utils;
    EtherWalletWithApprovals public wallet;
    address[] internal users;
    address internal alice;
    address internal bob;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(2);
        alice = users[0];
        bob = users[1];

        wallet = new EtherWalletWithApprovals();
    }

    function testUserCanDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= alice.balance);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(wallet));
        emit Deposit(alice, alice, amount);

        wallet.deposit{value: amount}(alice);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        assertEq(vm.load(address(wallet), slot), bytes32(amount));
    }

    function testUserCanDepositViaTransfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= alice.balance);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(wallet));
        emit Deposit(alice, alice, amount);

        (bool success,) = address(wallet).call{value: amount}("");
        assert(success);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        assertEq(vm.load(address(wallet), slot), bytes32(amount));
    }

    function testUserCanDepositToOtherUser(uint256 amount) public {
        vm.assume(amount > 0 && amount <= alice.balance);

        uint256 originalAliceBalance = alice.balance;

        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(wallet));
        emit Deposit(alice, bob, amount);

        wallet.deposit{value: amount}(bob);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(bob), uint256(0)));
        assertEq(vm.load(address(wallet), slot), bytes32(amount));

        slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        assertEq(vm.load(address(wallet), slot), bytes32(0));
        assertEq(alice.balance, originalAliceBalance - amount);
    }

    function testUserCanIncreaseAllowance(uint256 amount) public {
        bytes32 slot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(1)))));

        vm.assume(amount > 0);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(wallet));
        emit Allowance(alice, bob, amount);

        wallet.increaseAllowance(bob, amount);
        assertEq(vm.load(address(wallet), slot), bytes32(amount));
    }

    function testUserCanDecreaseAllowance(uint256 amount) public {
        bytes32 slot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(1)))));

        vm.assume(amount > 0 && amount % 2 == 0);
        vm.store(address(wallet), slot, bytes32(amount));
        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(wallet));
        emit Allowance(alice, bob, amount / 2);

        wallet.decreaseAllowance(bob, amount / 2);
        assertEq(vm.load(address(wallet), slot), bytes32(amount / 2));
    }

    function testUserCanRevokeAllowance(uint256 amount) public {
        bytes32 slot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(1)))));

        vm.assume(amount > 0);
        vm.store(address(wallet), slot, bytes32(amount));
        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(wallet));
        emit Allowance(alice, bob, 0);

        wallet.revokeAllowance(bob);
        assertEq(vm.load(address(wallet), slot), bytes32(0));
    }

    function testUserCanWithdraw(uint256 amount) public {
        vm.assume(amount > 0 && amount <= type(uint256).max - alice.balance);
        vm.deal(address(wallet), amount);
        uint256 startingBalance = alice.balance;

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        vm.store(address(wallet), slot, bytes32(amount));

        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(wallet));
        emit Transfer(alice, alice, amount);

        wallet.withdraw(amount);

        assertEq(vm.load(address(wallet), slot), bytes32(0));
        assertEq(alice.balance, startingBalance + amount);
    }

    function testUserCannotWithdrawMoreThanBalance(uint256 amount) public {
        vm.assume(amount > 0);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(InsufficientFunds.selector));
        wallet.withdraw(amount);
    }

    function testSpenderCanTransferAllowance(uint256 amount) public {
        vm.assume(amount > 0);
        uint256 allowance = amount / 2;
        vm.deal(address(wallet), amount);
        uint256 startingBalance = bob.balance;

        bytes32 balanceSlot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        vm.store(address(wallet), balanceSlot, bytes32(amount));

        bytes32 allowanceSlot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(1)))));
        vm.store(address(wallet), allowanceSlot, bytes32(allowance));

        vm.prank(bob);
        vm.expectEmit(true, true, false, true, address(wallet));
        emit Transfer(alice, bob, allowance);
        wallet.transferFrom(alice, bob, allowance);

        assertEq(vm.load(address(wallet), balanceSlot), bytes32(amount - allowance));
        assertEq(address(wallet).balance, amount - allowance);
        assertEq(bob.balance, startingBalance + allowance);
        assertEq(vm.load(address(wallet), allowanceSlot), bytes32(0));
    }

    function testSpenderCannotTransferMoreThanAllowance(uint256 amount) public {
        vm.assume(amount > 0);
        uint256 allowance = amount / 2;
        vm.deal(address(wallet), amount);
        uint256 startingBalance = bob.balance;

        bytes32 balanceSlot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        vm.store(address(wallet), balanceSlot, bytes32(amount));

        bytes32 allowanceSlot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(1)))));
        vm.store(address(wallet), allowanceSlot, bytes32(allowance));

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(InsufficientAllowance.selector));
        wallet.transferFrom(alice, bob, amount);

        assertEq(vm.load(address(wallet), balanceSlot), bytes32(amount));
        assertEq(vm.load(address(wallet), allowanceSlot), bytes32(allowance));
        assertEq(address(wallet).balance, amount);
        assertEq(bob.balance, startingBalance);
    }
}
