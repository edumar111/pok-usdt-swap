// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {Script} from "forge-std/Script.sol";

import {PokUsdtSwap} from "../src/PokUsdtSwap.sol";

contract Deploy is Script {
    function run() external {
        address usdt = vm.envAddress("USDT");
        address pok  = vm.envAddress("POK");
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast(); // requiere PRIVATE_KEY
        PokUsdtSwap swap = new PokUsdtSwap(usdt, pok, owner);
         swap.setFee(0, owner);
        vm.stopBroadcast();
    }
}
