// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "../tokens/ERC20.sol";

/// @author copied from openzeppelin-contracts (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/mocks/token/ERC20Mock.sol)
contract ERC20Mock is ERC20 {
    constructor() ERC20("ERC20Mock", "E20M", 18) {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
