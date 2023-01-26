// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Utilities is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() internal returns (address payable user) {
        user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
    }

    function createUsers(uint256 count) external returns (address payable[] memory users) {
        users = new address payable[](count);
        for (uint256 i; i < count;) {
            address payable user = getNextUserAddress();
            vm.deal(user, 100 ether);
            users[i] = user;
            unchecked {
                ++i;
            }
        }
    }
}
