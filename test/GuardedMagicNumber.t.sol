// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GuardedMagicNumber.sol";

contract GuardedMagicNumberTest is Test {
    event MagicNumberSet(address indexed setter, uint256 number);

    GuardedMagicNumber public magicNumber;

    function setUp() public {
        magicNumber = new GuardedMagicNumber();
    }

    function testSetMagicNumber(uint256 number) public {
        vm.expectEmit(true, false, false, true, address(magicNumber));
        emit MagicNumberSet(address(this), number);

        magicNumber.setMagicNumber(number);

        assertEq(vm.load(address(magicNumber), bytes32(uint256(1))), bytes32(number));
    }

    function testGetMagicNumber(uint256 number) public {
        vm.store(address(magicNumber), bytes32(uint256(1)), bytes32(number));

        assertEq(magicNumber.getMagicNumber(), number);
    }

    function testOnlyOwnerCanSetMagicNumber(uint256 number) public {
        address alice = payable(address(uint160(uint256(keccak256(abi.encodePacked("alice"))))));

        vm.prank(alice);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        magicNumber.setMagicNumber(number);
    }
}
