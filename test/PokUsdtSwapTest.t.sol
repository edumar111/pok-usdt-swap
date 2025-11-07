// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {PokUsdtSwap} from "../src/PokUsdtSwap.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "forge-std/console.sol";
 // Mock tokens
contract USDTMock is ERC20 {
    string public name_      = "Tether USD";
    string public symbol_    = "USDT";
    uint8 public decimals_   = 6;
    constructor( ) ERC20(name_, symbol_) {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);  
    } 
    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }       
        
}    
contract POKMock is ERC20 {
    string public name_      = "CRYPTOPOK";
    string public symbol_    = "POK";
    uint8 public decimals_   = 6;
    constructor( ) ERC20(name_, symbol_) {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);  
    }
    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }             
        
} 

contract PokUsdtPokUsdtSwapTest  is Test {

   
    USDTMock usdt;
    POKMock pok;
    PokUsdtSwap swap;
    address owner = vm.addr(1);
    address alice = vm.addr(2);

    function setUp() public {
        usdt = new USDTMock();
        pok = new POKMock();

        vm.startPrank(owner);
        swap = new PokUsdtSwap(address(usdt), address(pok), owner);
        vm.stopPrank();

        // Fund the contract with reserves
        pok.mint(address(swap), 1_000_000 * 1e6);
        usdt.mint(address(swap), 1_000_000 * 1e6);

        // Fund Alice
        usdt.mint(alice, 10_000 * 1e6);
        pok.mint(alice, 5_000 * 1e6);
        
    }

    // Constructor: USDT = 0
    function testConstructorShouldRevertOnZeroAddressUSDT() public {
        vm.expectRevert(PokUsdtSwap.ZeroAddress.selector);
        new PokUsdtSwap(address(0), address(pok), owner);
    }

    // Constructor: POK = 0
    function testConstructorShouldRevertOnZeroAddressPOK() public {
        vm.expectRevert(PokUsdtSwap.ZeroAddress.selector);
        new PokUsdtSwap(address(usdt), address(0), owner);
    }

    // Constructor: Owner = 0
    function testConstructorShouldRevertOnZeroOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        new PokUsdtSwap(address(usdt), address(pok), address(0));
    }
    
   //test case setFee
   function testShouldRevertSetFeeWhenNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        swap.setFee(100, alice); // try to set fee as Alice (not owner)
        vm.stopPrank();
    }
   function testShouldFailSetFeeWithInvalidFee() public {
        vm.startPrank(owner);
        vm.expectRevert(PokUsdtSwap.InvalidFee.selector);
        swap.setFee(10_001, owner); // more than 100%
        vm.stopPrank();
    }

    function testShouldFailSetFeeWithZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert(PokUsdtSwap.ZeroAddress.selector);
        swap.setFee(100, address(0)); //  zero address
        vm.stopPrank();
    }
   function testShouldSetFee() public {
        vm.startPrank(owner);
        swap.setFee(200, owner); // 2%
        (uint16 feeBps, address feeReceiver) = (swap.feeBps(), swap.feeReceiver());
        assertEq(feeBps, 200, "Incorrect Fee Bps");
        assertEq(feeReceiver, owner, "Incorrect Fee receiver");
        vm.stopPrank();
    }
    // test case pause/unpause
   function testShouldRevertBuyPokWhenAlreadyPaused() public {
        vm.startPrank(owner);
        swap.pause();
       
        vm.expectRevert();
        swap.buyPok(1_000 * 1e6, alice);
        vm.stopPrank();
    }
    function testShouldRevertPauseWhenNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        swap.pause(); // try to pause as Alice (not owner)
        vm.stopPrank();
    }
    function testShouldPause() public {
        vm.startPrank(owner);
        swap.pause();
        assertTrue(swap.paused(), unicode"The contract should be paused");
        vm.stopPrank();
           
    }
     function testShouldRevertUnpauseWhenNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        swap.unpause(); // try to unpause as Alice (not owner)
        vm.stopPrank();
    }
     function testShouldUnpause() public {
        vm.startPrank(owner);
        swap.pause();
        assertTrue(swap.paused(), unicode"The contract should be paused");
        
        swap.unpause();
        assertFalse(swap.paused(), unicode"The contract should be active");
        vm.stopPrank();
    }

    //test case rescue
    function testShouldRevertRescueWhenNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        swap.rescue(address(usdt), 1_000 * 1e6, alice); //  try to rescue as Alice (not owner)
        vm.stopPrank();
    }
    function testRescue() public {
        uint256 usdtBefore = usdt.balanceOf(owner);
        vm.startPrank(owner);
        swap.rescue(address(usdt), 1_000 * 1e6, owner);
        uint256 usdtAfter = usdt.balanceOf(owner);
        assertEq(usdtAfter - usdtBefore, 1_000 * 1e6, "Incorrect USDT rescued");
        vm.stopPrank();
    }

    // Test case buyPok 
    function testShouldFailBuyWithZeroAmount() public {
        vm.startPrank(alice);
        usdt.approve(address(swap), 0);
        vm.expectRevert(PokUsdtSwap.ZeroAmount.selector);
        swap.buyPok(0, alice);
        vm.stopPrank();
    }
    function testShouldFailBuyWithZeroAddress() public {
        vm.startPrank(alice);
        usdt.approve(address(swap), 1_000 * 1e6);
        vm.expectRevert(PokUsdtSwap.ZeroAddress.selector);
        swap.buyPok(1_000 * 1e6, address(0));
        vm.stopPrank();
    }
    function testshouldFailBuyWithInsufficientFunds() public {
        vm.startPrank(alice);
        uint256 balanceAliceBefore =  usdt.balanceOf(address(alice));
        console.log("Alice's balance before the approve:", balanceAliceBefore / 1e6);
        usdt.approve(address(swap), 20_000 * 1e6);
        
        vm.expectRevert("Not enough USDT balance");
        swap.buyPok(20_000 * 1e6, alice);
        vm.stopPrank();
    }
     function testshouldFailBuyWithInsufficientFundsInContract() public {
        // Fund contract with low reserves
        vm.startPrank(alice);

        usdt.mint(alice, 1_000_000 * 1e6);
        
        usdt.approve(address(swap), 1_010_000 * 1e6);
        
        vm.expectRevert(PokUsdtSwap.InsufficientLiquidity.selector);
        swap.buyPok(1_010_000 * 1e6, alice); // try to buy 1000 POK when there are only 400 in the contract
        vm.stopPrank();
    }
    function testBuy() public {
        vm.startPrank(alice);
        usdt.approve(address(swap), 1_000 * 1e6);
        swap.buyPok(1_000 * 1e6, alice);
        assertEq(pok.balanceOf(alice), 6_000 * 1e6, "Alice should have 6000 POK");
        assertEq(usdt.balanceOf(alice), 9_000 * 1e6, "Alice should have 9000 USDT");
        vm.stopPrank();
    }
    function testFeeGoesToNewReceiver() public {
        address newReceiver = vm.addr(3);
        vm.startPrank(owner);
        swap.setFee(100, newReceiver);
        vm.stopPrank();

        vm.startPrank(alice);
        usdt.approve(address(swap), 1_000 * 1e6);
        swap.buyPok(1_000 * 1e6, alice);
        vm.stopPrank();

        assertEq(pok.balanceOf(newReceiver), 10 * 1e6, "Fee should go to new receiver");
    }

    
      // Test case  sellPok
     function testshouldFailSellWithZeroAmount() public {
        vm.startPrank(alice);
        pok.approve(address(swap), 0);
        vm.expectRevert(PokUsdtSwap.ZeroAmount.selector);
        swap.sellPok(0, alice);
        vm.stopPrank();
    }
    function testshouldFailSellWithZeroAddress() public {
        vm.startPrank(alice);
        pok.approve(address(swap), 1_000 * 1e6);
        vm.expectRevert(PokUsdtSwap.ZeroAddress.selector);
        swap.sellPok(1_000 * 1e6, address(0));
        vm.stopPrank();
    }
    
    function testshouldFailSellWithInsufficientPokFunds() public {
        vm.startPrank(alice);
        uint256 balanceAliceBefore =  pok.balanceOf(address(alice));
        console.log("Alice's POK balance before the approve:", balanceAliceBefore / 1e6);
        pok.approve(address(swap), 8_000 * 1e6);   
        vm.expectRevert("Not enough POK balance");
        swap.sellPok(8_000 * 1e6, alice);
        vm.stopPrank();
    }

     function testshouldFailSellWithInsufficientFundsUsdtInContract() public {
        // Fund contract with low reserves
        vm.startPrank(alice);
        pok.mint(alice, 1_010_000 * 1e6);   
        pok.approve(address(swap), 1_010_000 * 1e6);

        vm.expectRevert(PokUsdtSwap.InsufficientLiquidity.selector);
        swap.sellPok(1_010_000 * 1e6, alice); //

        vm.stopPrank();
    }

    function testSell() public {
        vm.startPrank(alice);
        pok.approve(address(swap), 500 * 1e6);
        swap.sellPok(500 * 1e6, alice);
        assertEq(usdt.balanceOf(alice), 10_500 * 1e6, "Alice should have 10500 USDT");
        assertEq(pok.balanceOf(alice), 4_500 * 1e6, "Alice should have 4500 POK");
        vm.stopPrank();
    }
    
    /*** Fee tests ***/

    function testFeeOnePercentOnBuy() public {
        // set 1% fee
        vm.prank(owner);
        swap.setFee(100, owner);

        vm.startPrank(alice);
        usdt.approve(address(swap), 1_000 * 1e6);
        swap.buyPok(1_000 * 1e6, alice); // fee 10 POK, net 990 POK
        assertEq(pok.balanceOf(alice), 5_000 * 1e6 + 990 * 1e6, "Incorrect net POK to Alice");
        assertEq(pok.balanceOf(owner), 10 * 1e6, "Incorrect fee POK");
        vm.stopPrank();
    }
   

    
    function testPreviewBuyPokWithZeroFee() public view {
        // default fee = 0
        (uint256 pokNet, uint256 feePok) = swap.previewBuyPok(1_000 * 1e6);
        assertEq(feePok, 0);
        assertEq(pokNet, 1_000 * 1e6);
    }

    function testPreviewBuyPokWithFee() public {
        vm.prank(owner);
        swap.setFee(200, owner); // 2%
        (uint256 pokNet, uint256 feePok) = swap.previewBuyPok(1_000 * 1e6);
        assertEq(feePok, 20 * 1e6);
        assertEq(pokNet, 980 * 1e6);
    }

    function testPreviewSellPokWithZeroFee() public view {
        (uint256 usdtNet, uint256 feeUsdt) = swap.previewSellPok(1_000 * 1e6);
        assertEq(feeUsdt, 0);
        assertEq(usdtNet, 1_000 * 1e6);
    }

    function testPreviewSellPokWithFee() public {
        vm.prank(owner);
        swap.setFee(100, owner); // 1%
        (uint256 usdtNet, uint256 feeUsdt) = swap.previewSellPok(1_000 * 1e6);
        assertEq(feeUsdt, 10 * 1e6);
        assertEq(usdtNet, 990 * 1e6);
    }

    function testFeeOnePercentOnSell() public {
        // 1) activate fee 1%
        vm.prank(owner);
        swap.setFee(100, owner); // 1%

        // 2) approve and sell 1000 POK
        vm.startPrank(alice);
        pok.approve(address(swap), 1_000 * 1e6);

        uint256 ownerUsdtBefore = usdt.balanceOf(owner);
        uint256 aliceUsdtBefore = usdt.balanceOf(alice);

        swap.sellPok(1_000 * 1e6, alice); // fee 10 USDT, net 990 USDT
        vm.stopPrank();

        // 3) asserts: fee al owner y neto a alice
        assertEq(usdt.balanceOf(owner) - ownerUsdtBefore, 10 * 1e6, "Fee USDT incorrecto");
        assertEq(usdt.balanceOf(alice) - aliceUsdtBefore, 990 * 1e6, "USDT neto incorrecto");
    }
}
