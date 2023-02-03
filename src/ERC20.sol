// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error InsufficientFunds();
error InsufficientAllowance();
error InvalidAddress();

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_, uint256 supply) {
        name = name_;
        symbol = symbol_;
        totalSupply = supply;
        _balances[msg.sender] = supply;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _useAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _setAllowance(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 amount) external {
        _setAllowance(msg.sender, spender, allowance(msg.sender, spender) + amount);
    }

    function decreaseAllowance(address spender, uint256 amount) external {
        uint256 currentAllowance = allowance(msg.sender, spender);
        uint256 newAllowance = amount > currentAllowance ? 0 : currentAllowance - amount;

        _setAllowance(msg.sender, spender, newAllowance);
    }

    function revokeAllowance(address spender) external {
        _setAllowance(msg.sender, spender, 0);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (balanceOf(from) < amount) {
            revert InsufficientFunds();
        }

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _setAllowance(address owner, address spender, uint256 amount) internal {
        if (owner == address(0) || spender == address(0)) revert InvalidAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _useAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);

        if (currentAllowance == type(uint256).max) return;
        if (currentAllowance < amount) revert InsufficientAllowance();

        _setAllowance(owner, spender, currentAllowance - amount);
    }
}
