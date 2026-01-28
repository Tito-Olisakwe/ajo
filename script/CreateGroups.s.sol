// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Ajo} from "../src/Ajo.sol";

contract CreateGroupsScript is Script {
    function run() external {
        uint256 pk = vm.envUint("ANVIL_PRIVATE_KEY");

        vm.startBroadcast(pk);

        Ajo ajo = Ajo(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);

        // === Group 1 ===
        address[] memory group1Members = new address[](4);
        group1Members[0] = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        group1Members[1] = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
        group1Members[2] = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
        group1Members[3] = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;

        ajo.createGroup("Friends Ajo", 1 ether, group1Members);

        // === Group 2 ===
        address[] memory group2Members = new address[](4);
        group2Members[0] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        group2Members[1] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        group2Members[2] = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        group2Members[3] = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

        ajo.createGroup("Family Ajo", 0.5 ether, group2Members);

        vm.stopBroadcast();
    }
}
