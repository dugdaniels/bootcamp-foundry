// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {Multisig} from "../src/Multisig.sol";

error FundsRequired();
error InvalidAddress();
error NotAuthorized();

contract MultisigTest is Test {
    event Transfer(address indexed to, uint256 value);

    uint256 internal constant BALANCE = 10 ether;

    struct Signer {
        address addr;
        bool signed;
    }

    Utilities internal utils;
    Multisig public multisig;
    address[] internal users;
    address internal alice;
    address internal bob;
    address internal carol;
    address internal dave;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(4);
        alice = users[0];
        bob = users[1];
        carol = users[2];
        dave = users[3];

        vm.deal(address(this), BALANCE);
    }

    function _deployMultisig() internal {
        multisig = new Multisig{value: BALANCE}([alice, bob, carol], dave);
    }

    function testDeployment() public {
        _deployMultisig();

        assertTrue(multisig.isSigner(alice));
        assertTrue(multisig.isSigner(bob));
        assertTrue(multisig.isSigner(carol));
        assertEq(address(multisig).balance, BALANCE);
    }

    function testSignersMustBeUnique() public {
        address[3] memory signers = [alice, bob, alice];
        vm.expectRevert(abi.encodeWithSelector(InvalidAddress.selector));
        multisig = new Multisig{value: BALANCE}(signers, dave);
    }

    function testMustBeFunded() public {
        vm.expectRevert(abi.encodeWithSelector(FundsRequired.selector));
        multisig = new Multisig([alice, bob, carol], dave);
    }

    function testApprove() public {
        bytes32 approvalsSlot = bytes32(uint256(1));
        _deployMultisig();

        assertEq(vm.load(address(multisig), approvalsSlot), bytes32(0));
        vm.prank(alice);
        multisig.approve();
        assertEq(vm.load(address(multisig), approvalsSlot), bytes32(uint256(1)));
    }

    function testCannotApproveTwice() public {
        _deployMultisig();

        vm.startPrank(alice);
        multisig.approve();

        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector));
        multisig.approve();
        vm.stopPrank();
    }

    function testOnlySignerCanApprove() public {
        _deployMultisig();

        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector));
        vm.prank(dave);
        multisig.approve();
    }

    function testTransfersAtThreshold() public {
        uint256 initalBalance = dave.balance;
        _deployMultisig();

        vm.prank(alice);
        multisig.approve();

        vm.expectEmit(true, false, false, true, address(multisig));
        emit Transfer(dave, BALANCE);
        vm.prank(bob);
        multisig.approve();

        assertEq(dave.balance, initalBalance + BALANCE);
    }
}
