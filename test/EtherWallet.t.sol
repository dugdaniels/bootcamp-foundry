// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error InsufficientFunds();

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {EtherWallet} from "../src/EtherWallet.sol";

contract EtherWalletTest is Test {
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed sender, uint256 amount);

    Utilities internal utils;
    EtherWallet public wallet;
    address[] internal users;
    address internal alice;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(1);
        alice = users[0];

        wallet = new EtherWallet();
    }

    function testUserCanDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= alice.balance);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true, address(wallet));
        emit Deposit(alice, amount);

        wallet.deposit{value: amount}();

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        assertEq(vm.load(address(wallet), slot), bytes32(amount));
    }

    function testUserCanDepositViaTransfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= alice.balance);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true, address(wallet));
        emit Deposit(alice, amount);

        (bool success,) = address(wallet).call{value: amount}("");
        assert(success);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        assertEq(vm.load(address(wallet), slot), bytes32(amount));
    }

    function testUserCanWithdraw(uint256 amount) public {
        vm.assume(amount > 0 && amount <= type(uint256).max - alice.balance);
        vm.deal(address(wallet), amount);
        uint256 startingBalance = alice.balance;

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        vm.store(address(wallet), slot, bytes32(amount));

        vm.prank(alice);
        vm.expectEmit(true, false, false, true, address(wallet));
        emit Withdrawal(alice, amount);

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
}
