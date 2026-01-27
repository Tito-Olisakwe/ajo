// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Ajo} from "../src/Ajo.sol";

contract AjoTest is Test {
    Ajo ajo;

    // Test members
    address member1 = vm.addr(1);
    address member2 = vm.addr(2);
    address member3 = vm.addr(3);
    address member4 = vm.addr(4);

    uint256 groupId;

    function setUp() public {
        // Deploy contract
        ajo = new Ajo();

        // Fund members
        vm.deal(member1, 10 ether);
        vm.deal(member2, 10 ether);
        vm.deal(member3, 10 ether);
        vm.deal(member4, 10 ether);

        // Create group
        address[] memory members = new address[](4);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;
        members[3] = member4;

        ajo.createGroup("Full Cycle Group", 1 ether, members);
        groupId = 1;
    }

    // -----------------------
    // Test 1: Member contribution
    // -----------------------
    function testMemberContribution() public {
        vm.startPrank(member1);
        ajo.contribute{value: 1 ether}(groupId);
        vm.stopPrank();

        (uint256 contributed, uint256 received) = ajo.getMemberInfo(
            groupId,
            member1
        );
        assertEq(contributed, 1 ether);
        assertEq(received, 0);
    }

    // -----------------------
    // Test 2: Non-member cannot contribute
    // -----------------------
    function testNonMemberCannotContribute() public {
        address nonMember = vm.addr(99);
        vm.deal(nonMember, 10 ether);

        vm.startPrank(nonMember);
        vm.expectRevert("Not a group member");
        ajo.contribute{value: 1 ether}(groupId);
        vm.stopPrank();
    }

    // -----------------------
    // Test 3: Cannot double contribute
    // -----------------------
    function testCannotDoubleContribute() public {
        vm.startPrank(member2);
        ajo.contribute{value: 1 ether}(groupId);
        vm.expectRevert("Already contributed this month");
        ajo.contribute{value: 1 ether}(groupId);
        vm.stopPrank();
    }

    // -----------------------
    // Test 4: Payout fails if not all contributed
    // -----------------------
    function testPayoutFailsIfNotAllContributed() public {
        vm.startPrank(member1);
        ajo.contribute{value: 1 ether}(groupId);
        vm.stopPrank();

        vm.expectRevert("Not all members contributed");
        ajo.payout(groupId);
    }

    // -----------------------
    // Test 5: Full cycle month-by-month
    // -----------------------
    function testFullCycleMonthByMonth() public {
        address[] memory members = new address[](4);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;
        members[3] = member4;

        uint256 numMembers = members.length;

        // Track initial balances
        uint256[] memory initialBalances = new uint256[](numMembers);
        for (uint256 i = 0; i < numMembers; i++) {
            initialBalances[i] = members[i].balance;
        }

        for (uint256 month = 1; month <= numMembers; month++) {
            // Each member contributes
            for (uint256 i = 0; i < numMembers; i++) {
                vm.startPrank(members[i]);
                ajo.contribute{value: 1 ether}(groupId);
                vm.stopPrank();
            }

            // Capture current recipient
            address recipient = ajo.getCurrentRecipient(groupId);
            uint256 recipientIndex = 0;
            for (uint256 i = 0; i < numMembers; i++) {
                if (members[i] == recipient) recipientIndex = i;
            }

            uint256 beforeBalance = members[recipientIndex].balance;

            // Payout
            ajo.payout(groupId);

            uint256 afterBalance = members[recipientIndex].balance;

            // Recipient receives total pot
            uint256 expectedPot = 1 ether * numMembers;
            assertEq(
                afterBalance - beforeBalance,
                expectedPot,
                "Recipient did not get pot"
            );

            // Only check next recipient if cycle not complete
            if (month < numMembers) {
                address nextRecipient = ajo.getCurrentRecipient(groupId);
                uint256 expectedIndex = month % numMembers;
                assertEq(
                    nextRecipient,
                    members[expectedIndex],
                    "Next recipient wrong"
                );
            }
        }

        // After full cycle, verify contributed & received totals
        for (uint256 i = 0; i < numMembers; i++) {
            (uint256 contributed, uint256 received) = ajo.getMemberInfo(
                groupId,
                members[i]
            );
            assertEq(contributed, 4 ether, "Total contributed mismatch");
            assertEq(received, 4 ether, "Total received mismatch");
        }
    }
}
