// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {Multisig, Transfer, InsufficientFunds, InvalidAddress, NotAuthorized} from "../src/CustomizedMultisig.sol";

contract CustomizedMultisigTest is Test {
    event SignerAdded(address indexed addr);
    event SignerRemoved(address indexed addr);
    event TransferQueued(uint256 indexed transferId, address indexed recipient, uint256 value);
    event ApprovalReceived(uint256 indexed transferId, address indexed approver);
    event TransferExecuted(address indexed to, uint256 value);

    uint256 internal constant BALANCE = 10 ether;

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
        address[] memory signers = new address[](3);
        signers[0] = alice;
        signers[1] = bob;
        signers[2] = carol;
        multisig = new Multisig{value: BALANCE}(signers);
    }

    function testDeployment() public {
        _deployMultisig();

        assertTrue(multisig.isSigner(alice));
        assertTrue(multisig.isSigner(bob));
        assertTrue(multisig.isSigner(carol));
        assertEq(address(multisig).balance, BALANCE);
    }

    function testSignersMustBeUnique() public {
        address[] memory signers = new address[](3);
        signers[0] = alice;
        signers[1] = alice;
        signers[2] = carol;

        vm.expectRevert(abi.encodeWithSelector(InvalidAddress.selector));
        multisig = new Multisig{value: BALANCE}(signers);
    }

    function testCanAddSigner() public {
        _deployMultisig();

        vm.expectEmit(true, false, false, true, address(multisig));
        emit SignerAdded(dave);
        multisig.addSigner(dave);
        assertTrue(multisig.isSigner(dave));
    }

    function testCanRemoveSigner() public {
        _deployMultisig();

        vm.expectEmit(true, false, false, true, address(multisig));
        emit SignerRemoved(alice);
        multisig.removeSigner(alice);
        assertFalse(multisig.isSigner(alice));
    }

    function testCanQueueTransfer() public {
        _deployMultisig();

        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(multisig));
        emit TransferQueued(0, bob, BALANCE);
        uint256 id = multisig.queueTransfer(bob, BALANCE, 2);
        assertEq(id, 0);
    }

    function testBalanceMustCoverQueuedTransfer() public {
        _deployMultisig();

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(InsufficientFunds.selector));
        multisig.queueTransfer(bob, BALANCE * 2, 2);
    }

    function testApprove() public {
        _deployMultisig();
        vm.prank(alice);
        uint256 id = multisig.queueTransfer(bob, BALANCE, 2);

        bytes32 approvalsSlot = bytes32(uint256(keccak256(abi.encodePacked(id, uint256(2)))) + 3);
        bytes32 slot = keccak256(abi.encodePacked(abi.encode(bob), approvalsSlot));
        assertEq(vm.load(address(multisig), slot), bytes32(uint256(0)));

        vm.prank(bob);
        vm.expectEmit(true, true, false, false, address(multisig));
        emit ApprovalReceived(id, bob);
        multisig.approve(id);
        assertEq(vm.load(address(multisig), slot), bytes32(uint256(1)));
    }

    function testCannotApproveTwice() public {
        _deployMultisig();
        vm.startPrank(alice);
        uint256 id = multisig.queueTransfer(bob, BALANCE, 2);
        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector));
        multisig.approve(id);
        vm.stopPrank();
    }

    function testOnlySignerCanApprove() public {
        _deployMultisig();
        vm.prank(alice);
        uint256 id = multisig.queueTransfer(bob, BALANCE, 2);

        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector));
        vm.prank(dave);
        multisig.approve(id);
    }

    function testTransfersAtThreshold() public {
        uint256 initalBalance = dave.balance;
        _deployMultisig();

        vm.prank(alice);
        uint256 id = multisig.queueTransfer(dave, BALANCE, 2);

        vm.expectEmit(true, false, false, true, address(multisig));
        emit TransferExecuted(dave, BALANCE);
        vm.prank(bob);
        multisig.approve(id);

        assertEq(dave.balance, initalBalance + BALANCE);
    }
}
