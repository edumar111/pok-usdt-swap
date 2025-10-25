// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SwapToken} from "../src/SwapToken.sol";
contract DeployPok is Script {
    function run() external {
        string memory name = "CryptoPok";
        string memory symbol = "POK";
        uint256 initialSupply = 21000000 * 10 ** 6; // 21,000,000 POK con 6 decimales
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory sepoliaUrl = vm.envString("SEPOLIA_RPC_URL");

        // Configure RPC URL for Sepolia
        vm.createSelectFork(sepoliaUrl);
        
        // Start the broadcast with the private key
        vm.startBroadcast(deployerPrivateKey);
       
        SwapToken pok = new SwapToken(initialSupply, name, symbol);
        vm.stopBroadcast();
    }
}