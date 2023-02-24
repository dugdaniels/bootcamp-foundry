// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utilities} from "./utils/Utilities.sol";
import "forge-std/Test.sol";

import {NFT} from "../src/NFT.sol";

contract NFTTest is Test {
    Utilities internal utils;
    NFT internal token;
    address[] internal users;
    address internal alice;
    address internal bob;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(2);
        alice = users[0];
        bob = users[1];

        token = new NFT();
    }

    function testSupportsInterface() public {
        assertTrue(token.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(token.supportsInterface(0x80ac58cd)); // ERC721
    }

    function testBalanceOf(address _address, uint256 balance) public {
        bytes32 slot = keccak256(abi.encodePacked(abi.encode(_address), uint256(0)));
        vm.store(address(token), slot, bytes32(balance));

        assertEq(token.balanceOf(_address), balance);
    }

    function testOwnerOf(uint256 tokenId, address owner) public {
        bytes32 slot = keccak256(abi.encodePacked(tokenId, uint256(1)));
        vm.store(address(token), slot, bytes32(abi.encode(owner)));

        assertEq(token.ownerOf(tokenId), owner);
    }
}
