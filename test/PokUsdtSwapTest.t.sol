// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {PokUsdtSwap} from "../src/PokUsdtSwap.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
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

        // Fondear contrato con reservas
        pok.mint(address(swap), 1_000_000 * 1e6);
        usdt.mint(address(swap), 1_000_000 * 1e6);
 
        // Fondos de Alice
        usdt.mint(alice, 10_000 * 1e6);
        pok.mint(alice, 5_000 * 1e6);
        
    }
 /*
    function testInitialBalances() public {
        assertEq(usdt.balanceOf(address(swap)), 1_000_000 * 1e6, "USDT reserva inicial incorrecta");
        assertEq(pok.balanceOf(address(swap)), 1_000_000 * 1e6, "POK reserva inicial incorrecta");
    }
    function testInitialBalancesOfAlice() public  {
        assertEq(usdt.balanceOf(alice), 10_000 * 1e6, "USDT saldo inicial de Alice incorrecto");
        assertEq(pok.balanceOf(alice), 5_000 * 1e6, "POK saldo inicial de Alice incorrecto");
    } */
    
   //test case setFee
   function testShouldRevertSetFeeWhenNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        swap.setFee(100, alice); // intentar setear fee como Alice (no owner)
        vm.stopPrank();
    }
   function testShouldFailSetFeeWithInvalidFee() public {
        vm.startPrank(owner);
        vm.expectRevert(PokUsdtSwap.InvalidFee.selector);
        swap.setFee(10_001, owner); // más de 100%
        vm.stopPrank();
    }

    function testShouldFailSetFeeWithZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert(PokUsdtSwap.ZeroAddress.selector);
        swap.setFee(100, address(0)); // dirección cero
        vm.stopPrank();
    }
   function testShouldSetFee() public {
        vm.startPrank(owner);
        swap.setFee(200, owner); // 2%
        (uint16 feeBps, address feeReceiver) = (swap.feeBps(), swap.feeReceiver());
        assertEq(feeBps, 200, "Fee Bps incorrecto");
        assertEq(feeReceiver, owner, "Fee receiver incorrecto");
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
        swap.pause(); // intentar pausar como Alice (no owner)
        vm.stopPrank();
    }
    function testShouldPause() public {
        vm.startPrank(owner);
        swap.pause();
        assertTrue(swap.paused(), unicode"El contrato debería estar pausado");
        vm.stopPrank();
           
    }
     function testShouldRevertUnpauseWhenNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        swap.unpause(); // intentar reanudar como Alice (no owner)
        vm.stopPrank();
    }
     function testShouldUnpause() public {
        vm.startPrank(owner);
        swap.pause();
        assertTrue(swap.paused(), unicode"El contrato debería estar pausado");     
        
        swap.unpause();
        assertFalse(swap.paused(), unicode"El contrato debería estar activo");     
        vm.stopPrank();
    }

    //test case rescue
    function testShouldRevertRescueWhenNotOwner() public {
        vm.startPrank(alice);
        vm.expectRevert();
        swap.rescue(address(usdt), 1_000 * 1e6, alice); // intentar rescatar como Alice (no owner)
        vm.stopPrank();
    }
    function testRescue() public {
        uint256 usdtBefore = usdt.balanceOf(owner);
        vm.startPrank(owner);
        swap.rescue(address(usdt), 1_000 * 1e6, owner);
        uint256 usdtAfter = usdt.balanceOf(owner);
        assertEq(usdtAfter - usdtBefore, 1_000 * 1e6, "USDT rescatados incorrectos");
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
        console.log("Balance de Alice antes de la approve:", balanceAliceBefore / 1e6);
        usdt.approve(address(swap), 20_000 * 1e6);
        
        vm.expectRevert("Fondos ETH insuficientes");
        swap.buyPok(20_000 * 1e6, alice);
        vm.stopPrank();
    }
     function testshouldFailBuyWithInsufficientFundsInContract() public {
        // Fondear contrato con pocas reservas
        vm.startPrank(alice);
        //usdt.transfer(address(alice), 1_000_000 * 1e6); 
        usdt.mint(alice, 1_000_000 * 1e6);
        
        usdt.approve(address(swap), 1_010_000 * 1e6);
        
        vm.expectRevert(PokUsdtSwap.InsufficientLiquidity.selector);
        swap.buyPok(1_010_000 * 1e6, alice); // intentar comprar 1000 POK cuando solo hay 400 en el contrato
        vm.stopPrank();
    }
    function testBuy() public {
        vm.startPrank(alice);
        usdt.approve(address(swap), 1_000 * 1e6);
        swap.buyPok(1_000 * 1e6, alice);
        assertEq(pok.balanceOf(alice), 6_000 * 1e6, "Alice debe tener 6000 POK");
        assertEq(usdt.balanceOf(alice), 9_000 * 1e6, "Alice debe quedar con 9000 USDT");
        vm.stopPrank();
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
        console.log("Balance de Alice en pok antes de la approve:", balanceAliceBefore / 1e6);
        pok.approve(address(swap), 8_000 * 1e6);   
        vm.expectRevert("Fondos POK insuficientes");
        swap.sellPok(8_000 * 1e6, alice);
        vm.stopPrank();
    }

     function testshouldFailSellWithInsufficientFundsUsdtInContract() public {
        // Fondear contrato con pocas reservas
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
        assertEq(usdt.balanceOf(alice), 10_500 * 1e6, "Alice debe tener 10500 USDT");
        assertEq(pok.balanceOf(alice), 4_500 * 1e6, "Alice debe quedar con 4500 POK");
        vm.stopPrank();
    }

    function testFeeOnePercentOnBuy() public {
        // set 1% fee
        vm.prank(owner);
        swap.setFee(100, owner);

        vm.startPrank(alice);
        usdt.approve(address(swap), 1_000 * 1e6);
        swap.buyPok(1_000 * 1e6, alice); // fee 10 POK, net 990 POK
        assertEq(pok.balanceOf(alice), 5_000 * 1e6 + 990 * 1e6, "POK net incorrecto");
        assertEq(pok.balanceOf(owner), 10 * 1e6, "Fee POK incorrecto");
        vm.stopPrank();
    }
}
