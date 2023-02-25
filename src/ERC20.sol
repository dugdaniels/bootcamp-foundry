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

    function balanceOf(address owner_) public view returns (uint256) {
        return _balances[owner_];
    }

    function transfer(address to_, uint256 amount_) external returns (bool) {
        _transfer(msg.sender, to_, amount_);
        return true;
    }

    function transferFrom(address from_, address to_, uint256 amount_) external returns (bool) {
        _useAllowance(from_, msg.sender, amount_);
        _transfer(from_, to_, amount_);
        return true;
    }

    function approve(address spender_, uint256 amount_) external returns (bool) {
        _setAllowance(msg.sender, spender_, amount_);
        return true;
    }

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return _allowances[owner_][spender_];
    }

    function increaseAllowance(address spender_, uint256 amount_) external {
        _setAllowance(msg.sender, spender_, allowance(msg.sender, spender_) + amount_);
    }

    function decreaseAllowance(address spender_, uint256 amount_) external {
        uint256 currentAllowance = allowance(msg.sender, spender_);
        uint256 newAllowance = amount_ > currentAllowance ? 0 : currentAllowance - amount_;

        _setAllowance(msg.sender, spender_, newAllowance);
    }

    function revokeAllowance(address spender_) external {
        _setAllowance(msg.sender, spender_, 0);
    }

    function _transfer(address from_, address to_, uint256 amount_) internal {
        if (balanceOf(from_) < amount_) {
            revert InsufficientFunds();
        }

        _balances[from_] -= amount_;
        _balances[to_] += amount_;

        emit Transfer(from_, to_, amount_);
    }

    function _setAllowance(address owner_, address spender_, uint256 amount_) internal {
        if (owner_ == address(0) || spender_ == address(0)) revert InvalidAddress();

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    function _useAllowance(address owner_, address spender_, uint256 amount_) internal {
        uint256 currentAllowance = allowance(owner_, spender_);

        if (currentAllowance == type(uint256).max) return;
        if (currentAllowance < amount_) revert InsufficientAllowance();

        _setAllowance(owner_, spender_, currentAllowance - amount_);
    }
}
