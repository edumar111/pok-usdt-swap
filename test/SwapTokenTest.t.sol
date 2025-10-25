// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.24;

import "forge-std/Test.sol";
import "../src/SwapToken.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SwapTokenTest is Test {

    SwapToken public swapToken;
    
    address public owner = vm.addr(1);
    address public notOwner = address(0x1234567890123456789012345678901234567891);

    uint256 public initialSupply = 210000 * 10 ** 6;
    
    string public name = "CryptoPok";
    string public symbol = "POK";
    
    

    function setUp() public {
        vm.prank(owner);
        swapToken = new SwapToken(initialSupply, name, symbol);
    }

    function testInitialSupply() public {
        uint256 totalSupply_ = swapToken.totalSupply();
        assertEq(totalSupply_, initialSupply);
    }
    function testName() public  {
        string memory name_ = swapToken.name();
        assertEq(name_, name);
    }
    function testSymbol() public  {
        string memory symbol_ = swapToken.symbol();
        assertEq(symbol_, symbol);      
    }

    function testDecimals() public  {
        uint8 decimals_ = swapToken.decimals();
        assertEq(decimals_, 6);      
    }   

    function testShouldFailMintIfNotOwner() public {
        vm.prank(notOwner);
        uint256 amountToMint = 500 * 10 ** 6; 
        vm.expectRevert();
        swapToken.mint(amountToMint);
    }
  
    function testMint() public {
        vm.startPrank(owner);
        uint256 amountToMint = 500 * 10 ** 6; 
        
        uint256 balanceBefore_ = IERC20(address(swapToken)).balanceOf(owner);

        swapToken.mint(amountToMint);
         uint256 balanceAfter_ = IERC20(address(swapToken)).balanceOf(owner);

        assertEq( balanceAfter_  - balanceBefore_, amountToMint);
        vm.stopPrank();
    }               

}