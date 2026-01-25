// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Ajo} from "../src/Ajo.sol";

contract AjoTest is Test {
    Ajo ajo;

    function setUp() public {
        ajo = new Ajo();
    }

    function testCreateGroup() public {
        // TODO: implement test
    }

    function testContribute() public {
        // TODO: implement test
    }

    function testPayout() public {
        // TODO: implement test
    }
}
