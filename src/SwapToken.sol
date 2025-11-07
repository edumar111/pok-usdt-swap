// SPDX-License-Identifier: MIT

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol"; 
import {Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
pragma solidity ^0.8.24;

/// @title ERC20 Token with 6 decimals
/// @notice ERC20 Token contract that allows the owner to mint new tokens and has 6 decimals.
/// @dev Inherits from OpenZeppelin's ERC20, Ownable2Step, and ReentrancyGuard contracts.
contract SwapToken is ERC20 , Ownable2Step, ReentrancyGuard{
    
    constructor(uint256 initialSupply, string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
    * @notice Mints new tokens.
    * @param amount_ The amount of tokens to mint.
    */
    function mint( uint256 amount_) external onlyOwner() {
        _mint(msg.sender, amount_);
    }
    
    /// @notice Returns the number of decimals used by the token (6 decimals).
    /// @return The number of decimals (6).
    function decimals() public view virtual override  returns (uint8) {
        return 6;
    }
}