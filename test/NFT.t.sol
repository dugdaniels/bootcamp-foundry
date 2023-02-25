// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error NotApproved();

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {NFT} from "../src/NFT.sol";

contract NFTTest is Test {
    Utilities internal utils;
    NFT internal token;
    address[] internal users;
    address internal alice;
    address internal bob;
    address internal carol;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(3);
        alice = users[0];
        bob = users[1];
        carol = users[2];

        token = new NFT();
    }

    function testSupportsInterface() public {
        assertTrue(token.supportsInterface(0x01ffc9a7)); // ERC165
            // assertTrue(token.supportsInterface(0x80ac58cd)); // ERC721
    }

    function testBalanceOf(address _address, uint256 balance) public {
        bytes32 slot = keccak256(abi.encodePacked(abi.encode(_address), uint256(0)));
        vm.store(address(token), slot, bytes32(balance));

        assertEq(token.balanceOf(_address), balance);
    }

    function testOwnerOf(uint256 tokenId_, address owner_) public {
        bytes32 slot = keccak256(abi.encodePacked(tokenId_, uint256(1)));
        vm.store(address(token), slot, bytes32(abi.encode(owner_)));

        assertEq(token.ownerOf(tokenId_), owner_);
    }

    function testSetApproveForAll(address operator_) public {
        bytes32 operatorsSlot = keccak256(
            abi.encodePacked(abi.encode(operator_), keccak256(abi.encodePacked(abi.encode(alice), uint256(3))))
        );
        assertEq(vm.load(address(token), operatorsSlot), bytes32(abi.encode(false)));

        vm.prank(alice);
        token.setApprovalForAll(operator_, true);
        assertEq(vm.load(address(token), operatorsSlot), bytes32(abi.encode(true)));

        vm.prank(alice);
        token.setApprovalForAll(operator_, false);
        assertEq(vm.load(address(token), operatorsSlot), bytes32(abi.encode(false)));
    }

    function testIsApprovedForall(address owner_, address operator_) public {
        bytes32 operatorsSlot = keccak256(
            abi.encodePacked(abi.encode(operator_), keccak256(abi.encodePacked(abi.encode(owner_), uint256(3))))
        );
        vm.store(address(token), operatorsSlot, bytes32(abi.encode(true)));

        assertEq(token.isApprovedForAll(owner_, operator_), true);
    }

    function testApprove(uint256 tokenId_, address approved_) public {
        bytes32 ownerSlot = keccak256(abi.encodePacked(tokenId_, uint256(1)));
        vm.store(address(token), ownerSlot, bytes32(abi.encode(alice)));

        bytes32 approvalsSlot = keccak256(abi.encodePacked(abi.encode(tokenId_), uint256(2)));
        assertEq(vm.load(address(token), approvalsSlot), bytes32(abi.encode(0)));

        vm.prank(alice);
        token.approve(approved_, tokenId_);
        assertEq(vm.load(address(token), approvalsSlot), bytes32(abi.encode(approved_)));
    }

    function testOpperatorCanApprove(uint256 tokenId_, address approved_) public {
        bytes32 ownerSlot = keccak256(abi.encodePacked(tokenId_, uint256(1)));
        vm.store(address(token), ownerSlot, bytes32(abi.encode(alice)));

        bytes32 operatorsSlot =
            keccak256(abi.encodePacked(abi.encode(bob), keccak256(abi.encodePacked(abi.encode(alice), uint256(3)))));
        vm.store(address(token), operatorsSlot, bytes32(abi.encode(true)));

        vm.prank(bob);
        token.approve(approved_, tokenId_);

        bytes32 approvalsSlot = keccak256(abi.encodePacked(abi.encode(tokenId_), uint256(2)));
        assertEq(vm.load(address(token), approvalsSlot), bytes32(abi.encode(approved_)));
    }

    function testOnlyOwnerOrOperatorCanApprove(uint256 tokenId_) public {
        bytes32 ownerSlot = keccak256(abi.encodePacked(tokenId_, uint256(1)));
        vm.store(address(token), ownerSlot, bytes32(abi.encode(alice)));

        vm.expectRevert(abi.encodeWithSelector(NotApproved.selector));
        vm.prank(bob);
        token.approve(bob, tokenId_);
    }

    function testGetApproved(uint256 tokenId_, address approved_) public {
        bytes32 approvalsSlot = keccak256(abi.encodePacked(abi.encode(tokenId_), uint256(2)));
        vm.store(address(token), approvalsSlot, bytes32(abi.encode(approved_)));

        assertEq(token.getApproved(tokenId_), approved_);
    }

    function testTransferFrom(uint256 tokenId_) public {
        bytes32 ownerSlot = keccak256(abi.encodePacked(tokenId_, uint256(1)));
        vm.store(address(token), ownerSlot, bytes32(abi.encode(alice)));

        bytes32 approvalsSlot = keccak256(abi.encodePacked(abi.encode(tokenId_), uint256(2)));
        vm.store(address(token), approvalsSlot, bytes32(abi.encode(bob)));

        bytes32 balancesSlot = keccak256(abi.encodePacked(abi.encode(alice), uint256(0)));
        vm.store(address(token), balancesSlot, bytes32(abi.encode(1)));

        bytes32 toBalancesSlot = keccak256(abi.encodePacked(abi.encode(carol), uint256(0)));
        vm.store(address(token), toBalancesSlot, bytes32(abi.encode(0)));

        vm.prank(alice);
        token.transferFrom(alice, carol, tokenId_);

        assertEq(vm.load(address(token), ownerSlot), bytes32(abi.encode(carol)));
        assertEq(vm.load(address(token), approvalsSlot), bytes32(abi.encode(0)));
        assertEq(vm.load(address(token), balancesSlot), bytes32(abi.encode(0)));
        assertEq(vm.load(address(token), toBalancesSlot), bytes32(abi.encode(1)));
    }
}
