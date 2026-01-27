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
        vm.txGasPrice(0);

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

        for (uint256 month = 1; month <= numMembers; month++) {
            address recipient = ajo.getCurrentRecipient(groupId);
            uint256 beforeBalance = recipient.balance;

            for (uint256 i = 0; i < numMembers; i++) {
                vm.prank(members[i]);
                ajo.contribute{value: 1 ether}(groupId);
            }

            uint256 afterBalance = recipient.balance;

            uint256 expectedNet = (1 ether * numMembers) - 1 ether;
            assertEq(
                afterBalance - beforeBalance,
                expectedNet,
                "Recipient did not get pot"
            );

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

        for (uint256 i = 0; i < numMembers; i++) {
            (uint256 contributed, uint256 received) = ajo.getMemberInfo(
                groupId,
                members[i]
            );
            assertEq(contributed, 4 ether, "Total contributed mismatch");
            assertEq(received, 4 ether, "Total received mismatch");
        }
    }

    // -----------------------
    // Test 6: Only unpaid members can vote
    // -----------------------
    function testOnlyUnpaidMembersCanVote() public {
        vm.startPrank(member1);
        ajo.contribute{value: 1 ether}(groupId);
        vm.stopPrank();

        vm.startPrank(member1);
        ajo.voteToDisband(groupId);
        vm.stopPrank();

        vm.startPrank(member1);
        vm.expectRevert("Already voted");
        ajo.voteToDisband(groupId);
        vm.stopPrank();
    }

    // -----------------------
    // Test 7: Disband after all unpaid members vote
    // -----------------------
    function testDisbandWhenAllUnpaidVote() public {
        address[] memory members = new address[](4);
        members[0] = member1;
        members[1] = member2;
        members[2] = member3;
        members[3] = member4;

        uint256 numMembers = members.length;

        for (uint256 i = 0; i < numMembers; i++) {
            vm.startPrank(members[i]);
            ajo.contribute{value: 1 ether}(groupId);
            vm.stopPrank();
        }

        vm.startPrank(member2);
        ajo.voteToDisband(groupId);
        vm.stopPrank();

        vm.startPrank(member3);
        ajo.voteToDisband(groupId);
        vm.stopPrank();

        bool disbanded = ajo.groupDisbanded(groupId);
        assertEq(disbanded, false);

        vm.startPrank(member4);
        ajo.voteToDisband(groupId);
        vm.stopPrank();

        disbanded = ajo.groupDisbanded(groupId);
        assertEq(disbanded, true);
    }

    // -----------------------
    // Test 8: Refund contributions for the current month
    // -----------------------
    function testRefundsOnDisband() public {
        uint256 before1 = member1.balance;
        uint256 before2 = member2.balance;

        vm.startPrank(member1);
        ajo.contribute{value: 1 ether}(groupId);
        vm.stopPrank();

        vm.startPrank(member2);
        ajo.contribute{value: 1 ether}(groupId);
        vm.stopPrank();

        vm.startPrank(member1);
        ajo.voteToDisband(groupId);
        vm.stopPrank();

        vm.startPrank(member2);
        ajo.voteToDisband(groupId);
        vm.stopPrank();

        vm.startPrank(member3);
        ajo.voteToDisband(groupId);
        vm.stopPrank();

        vm.startPrank(member4);
        ajo.voteToDisband(groupId);
        vm.stopPrank();

        uint256 after1 = member1.balance;
        uint256 after2 = member2.balance;

        assertEq(after1, before1, "Member1 refund incorrect");
        assertEq(after2, before2, "Member2 refund incorrect");
    }

    // -----------------------
    // Test 9: Auto payout triggers on last contribution
    // -----------------------
    function testAutoPayoutTriggersOnLastContribution() public {
        address recipient = ajo.getCurrentRecipient(groupId);
        assertEq(recipient, member1);

        uint256 beforeRecipient = recipient.balance;

        vm.prank(member1);
        ajo.contribute{value: 1 ether}(groupId);

        vm.prank(member2);
        ajo.contribute{value: 1 ether}(groupId);

        vm.prank(member3);
        ajo.contribute{value: 1 ether}(groupId);

        assertEq(recipient.balance, beforeRecipient - 1 ether);

        vm.prank(member4);
        ajo.contribute{value: 1 ether}(groupId);

        assertEq(recipient.balance - beforeRecipient, 3 ether);

        assertEq(ajo.getCurrentRecipient(groupId), member2);

        assertEq(ajo.contributedCountThisMonth(groupId), 0);
    }
}

// forge test --match-contract AjoTest
