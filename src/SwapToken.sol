// SPDX-License-Identifier: MIT

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol"; 
import {Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
pragma solidity ^0.8.24;
contract SwapToken is ERC20 , Ownable2Step, ReentrancyGuard{
    
    constructor(uint256 initialSupply, string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint( uint256 amount_) external onlyOwner() {
        _mint(msg.sender, amount_);
    }
    function decimals() public view virtual override  returns (uint8) {
        return 6;
    }
}