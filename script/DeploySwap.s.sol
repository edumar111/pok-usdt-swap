// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {Script} from "forge-std/Script.sol";

import {PokUsdtSwap} from "../src/PokUsdtSwap.sol";

contract DeploySwap is Script {
    function run() external {
        address usdt = vm.envAddress("USDT");
        address pok  = vm.envAddress("POK");
        address owner = vm.envAddress("OWNER");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory sepoliaUrl = vm.envString("SEPOLIA_RPC_URL");
        
        vm.createSelectFork(sepoliaUrl);
        vm.startBroadcast(deployerPrivateKey);
        
        PokUsdtSwap swap = new PokUsdtSwap(usdt, pok, owner);
        swap.setFee(0, owner);
        vm.stopBroadcast();
    }
}
