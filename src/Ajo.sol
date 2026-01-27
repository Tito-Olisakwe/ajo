// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {
    ReentrancyGuard
} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract Ajo is Ownable, ReentrancyGuard {
    // === Structs ===
    struct Member {
        address addr;
        bool active;
        uint256 totalContributed;
        uint256 totalReceived;
    }

    struct AjoGroup {
        uint256 groupId;
        string name;
        address[] members;
        uint256 contributionAmount;
        uint256 currentMonth;
        mapping(uint256 => address) monthRecipient;
        mapping(address => uint256) contributionsThisMonth;
    }

    // === State variables ===
    uint256 public groupCount;
    mapping(uint256 => AjoGroup) public groups;
    mapping(address => uint256[]) public memberToGroups;
    uint256[] public allGroupIds;
    mapping(address => Member) public memberInfo;
    mapping(uint256 => mapping(address => uint256))
        public totalContributedInGroup;
    mapping(uint256 => mapping(address => uint256)) public totalReceivedInGroup;

    // === Events ===
    event GroupCreated(
        uint256 indexed groupId,
        address[] members,
        uint256 contributionAmount
    );
    event ContributionMade(
        uint256 indexed groupId,
        address indexed member,
        uint256 amount
    );
    event PayoutDone(
        uint256 indexed groupId,
        address indexed recipient,
        uint256 amount
    );

    // === Constructor ===
    constructor() Ownable(msg.sender) ReentrancyGuard() {}

    // === Functions ===
    function createGroup(
        string memory groupName,
        uint256 contributionAmount,
        address[] memory memberAddrs
    ) external {
        require(memberAddrs.length > 1, "At least 2 members required");
        require(contributionAmount > 0, "Contribution must be > 0");

        groupCount += 1;
        uint256 newGroupId = groupCount;

        AjoGroup storage g = groups[newGroupId];
        g.groupId = newGroupId;
        g.name = groupName;
        g.contributionAmount = contributionAmount;
        g.currentMonth = 1;

        for (uint256 i = 0; i < memberAddrs.length; i++) {
            address addr = memberAddrs[i];

            g.members.push(addr);
            g.monthRecipient[i + 1] = addr;

            Member storage m = memberInfo[addr];
            m.addr = addr;
            m.active = true;
            m.totalContributed = 0;
            m.totalReceived = 0;

            memberToGroups[addr].push(newGroupId);
        }

        allGroupIds.push(newGroupId);

        address[] memory membersCopy = new address[](g.members.length);
        for (uint256 i = 0; i < g.members.length; i++) {
            membersCopy[i] = g.members[i];
        }

        emit GroupCreated(newGroupId, g.members, contributionAmount);
    }

    function contribute(uint256 groupId) external payable nonReentrant {
        AjoGroup storage g = groups[groupId];
        require(g.groupId != 0, "Group does not exist");

        require(msg.value == g.contributionAmount, "Incorrect contribution");

        bool isMember = false;
        for (uint256 i = 0; i < g.members.length; i++) {
            if (g.members[i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        require(isMember, "Not a group member");

        require(
            g.contributionsThisMonth[msg.sender] == 0,
            "Already contributed this month"
        );

        g.contributionsThisMonth[msg.sender] = msg.value;
        totalContributedInGroup[groupId][msg.sender] += msg.value;

        emit ContributionMade(groupId, msg.sender, msg.value);
    }

    function payout(uint256 groupId) external nonReentrant {
        AjoGroup storage g = groups[groupId];
        require(g.groupId != 0, "Group does not exist");

        uint256 memberCount = g.members.length;
        require(g.currentMonth <= memberCount, "Cycle already completed");

        address recipient = g.monthRecipient[g.currentMonth];
        require(recipient != address(0), "Invalid recipient");

        uint256 totalPot = g.contributionAmount * memberCount;

        for (uint256 i = 0; i < memberCount; i++) {
            address m = g.members[i];
            require(
                g.contributionsThisMonth[m] == g.contributionAmount,
                "Not all members contributed"
            );
        }

        totalReceivedInGroup[groupId][recipient] += totalPot;

        for (uint256 i = 0; i < memberCount; i++) {
            g.contributionsThisMonth[g.members[i]] = 0;
        }

        (bool success, ) = recipient.call{value: totalPot}("");
        require(success, "Transfer failed");

        emit PayoutDone(groupId, recipient, totalPot);

        g.currentMonth += 1;
    }

    // === View Functions ===
    function getMemberInfo(
        uint256 groupId,
        address member
    ) external view returns (uint256 contributed, uint256 received) {
        require(groups[groupId].groupId != 0, "Group does not exist");

        contributed = totalContributedInGroup[groupId][member];
        received = totalReceivedInGroup[groupId][member];
    }

    function getCurrentRecipient(
        uint256 groupId
    ) external view returns (address) {
        AjoGroup storage g = groups[groupId];
        require(g.groupId != 0, "Group does not exist");

        if (g.currentMonth > g.members.length) {
            return address(0);
        }

        return g.monthRecipient[g.currentMonth];
    }
}
