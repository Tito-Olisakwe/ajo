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

    function contribute(uint256 groupId) external payable {
        // to implement
    }

    function payout(uint256 groupId) external {
        // to implement
    }

    function getMemberInfo(
        uint256 groupId,
        address member
    ) external pure returns (uint256, uint256) {
        // to implement
        return (0, 0);
    }

    function getCurrentRecipient(
        uint256 groupId
    ) external pure returns (address) {
        // to implement
        return address(0);
    }
}
