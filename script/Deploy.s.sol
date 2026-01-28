// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Ajo} from "../src/Ajo.sol";

contract DeployAjo is Script {
    function run() external {
        uint256 pk = vm.envUint("ANVIL_PRIVATE_KEY");

        vm.startBroadcast(pk);

        Ajo ajo = new Ajo();

        vm.stopBroadcast();

        console2.log("Ajo deployed at:", address(ajo));
    }
}
