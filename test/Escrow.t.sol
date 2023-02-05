// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {Escrow} from "../src/Escrow.sol";

error FundsRequired();
error NotAuthorized();
error FundsNotReleased();

contract EscrowTest is Test {
    event Withdrawal(address indexed recipient, uint256 amount);

    uint256 internal constant FUNDING = 10 ether;
    uint256 internal constant TIMELOCK = 30 days;

    Utilities internal utils;
    Escrow internal escrow;
    address[] internal users;
    address internal alice;
    address internal bob;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(2);
        alice = users[0];
        bob = users[1];

        vm.deal(address(this), FUNDING);
        escrow = new Escrow{value: FUNDING }(alice, TIMELOCK);
    }

    function testDeployment() public {
        assertEq(address(escrow).balance, FUNDING);
        assertEq(escrow.recipient(), alice);
        assertEq(escrow.releaseTimestamp(), block.timestamp + TIMELOCK);
    }

    function testMustBeFunded() public {
        vm.expectRevert(abi.encodeWithSelector(FundsRequired.selector));
        escrow = new Escrow(alice, TIMELOCK);
    }

    function testFundsReleased() public {
        assertEq(escrow.fundsReleased(), false);
        vm.warp(block.timestamp + TIMELOCK - 1);
        assertEq(escrow.fundsReleased(), false);
        vm.warp(block.timestamp + TIMELOCK);
        assertEq(escrow.fundsReleased(), true);
    }

    function testCantWithdrawBeforeRelease() public {
        assertEq(escrow.fundsReleased(), false);
        vm.expectRevert(abi.encodeWithSelector(FundsNotReleased.selector));
        vm.prank(alice);
        escrow.withdraw();
    }

    function testOnlyRecipientCanWithdraw() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector));
        escrow.withdraw();
    }
}
