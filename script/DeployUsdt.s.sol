// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SwapToken} from "../src/SwapToken.sol"; 
contract DeployUsdt is Script {
    function run() external {
        string memory name = "Tether USDP";
        string memory symbol = "USDTP";
        uint256 initialSupply = 1000000000 * 10 ** 6; // 1,000,000,000 USDT con 6 decimales
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory sepoliaUrl = vm.envString("SEPOLIA_RPC_URL");
        
        vm.createSelectFork(sepoliaUrl);
        vm.startBroadcast(deployerPrivateKey);
       
        SwapToken usdt = new SwapToken(initialSupply, name, symbol);
        vm.stopBroadcast();
    }
}
