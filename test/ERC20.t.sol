// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {ERC20} from "../src/ERC20.sol";

contract ERC20Test is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string internal constant NAME = "Test Token";
    string internal constant SYMBOL = "TT";
    uint256 internal constant SUPPLY = 1000 * 1e18;

    Utilities internal utils;
    ERC20 internal token;
    address[] internal users;
    address internal alice;
    address internal bob;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(2);
        alice = users[0];
        bob = users[1];

        token = new ERC20(NAME, SYMBOL, SUPPLY);
    }

    function testDeployment() public {
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.decimals(), 18);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(address(this)), uint256(3)));
        assertEq(vm.load(address(token), slot), bytes32(SUPPLY));
    }

    function testBalanceOf(uint256 amount) public {
        assertEq(token.balanceOf(alice), 0);

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(3)));
        vm.store(address(token), slot, bytes32(amount));

        assertEq(token.balanceOf(alice), amount);
    }

    function testTransfer(uint256 amount) public {
        vm.assume(amount <= SUPPLY);
        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(address(this), alice, amount);

        assertTrue(token.transfer(alice, amount));

        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(3)));
        assertEq(vm.load(address(token), slot), bytes32(amount));
    }

    function testTransferFrom(uint256 amount) public {
        bytes32 slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(3)));
        vm.store(address(token), slot, bytes32(amount));

        slot = keccak256(
            abi.encodePacked(abi.encode(address(this)), keccak256(abi.encodePacked(abi.encode(alice), uint256(4))))
        );
        vm.store(address(token), slot, bytes32(amount));

        vm.expectEmit(true, true, false, true, address(token));
        emit Transfer(alice, bob, amount);
        assertTrue(token.transferFrom(alice, bob, amount));

        slot = keccak256(abi.encodePacked(abi.encode(alice), uint256(3)));
        assertEq(vm.load(address(token), slot), bytes32(0));

        slot = keccak256(abi.encodePacked(abi.encode(bob), uint256(3)));
        assertEq(vm.load(address(token), slot), bytes32(amount));
    }

    function testIncreaseAllowance(uint256 amount) public {
        bytes32 slot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(4)))));

        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(alice, bob, amount);

        token.increaseAllowance(bob, amount);
        assertEq(vm.load(address(token), slot), bytes32(amount));
    }

    function testDecreaseAllowance(uint256 amount) public {
        bytes32 slot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(4)))));

        vm.assume(amount > 0 && amount % 2 == 0);
        vm.store(address(token), slot, bytes32(amount));
        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(alice, bob, amount / 2);

        token.decreaseAllowance(bob, amount / 2);
        assertEq(vm.load(address(token), slot), bytes32(amount / 2));
    }

    function testRevokeAllowance(uint256 amount) public {
        bytes32 slot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(4)))));

        vm.assume(amount > 0);
        vm.store(address(token), slot, bytes32(amount));
        vm.prank(alice);
        vm.expectEmit(true, true, false, true, address(token));
        emit Approval(alice, bob, 0);

        token.revokeAllowance(bob);
        assertEq(vm.load(address(token), slot), bytes32(0));
    }
}
