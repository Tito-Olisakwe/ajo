# Ajo

Ajo is a Solidity smart contract that implements a **rotating savings and credit association (ROSCA)** — commonly known as *Ajo* or *Esusu*.

Members contribute a fixed amount each round, and once all contributions are complete, the total pot is **automatically paid out** to a designated member based on a fixed rotation order.

The contract also supports **early disbanding** by unpaid members, with safe refunds for current-round contributions.

---

## ✨ Features

- Create savings groups with fixed members and contribution amount
- Enforces one contribution per member per round
- **Automatic payout** when the last member contributes
- Deterministic payout rotation (one member per round)
- Tracks total contributed and total received per member
- Allows **unpaid members** to vote to disband the group
- Disbands only when **all unpaid members vote**
- Refunds only current round contributions on disband
- Fully tested with Foundry

---

## 🧠 How It Works

### Group Creation
- Anyone can create a group
- Group has:
  - fixed list of members
  - fixed contribution amount
  - fixed payout order (rotation)
- The first member in the list receives the first payout, the second receives the second, etc.

### Contributions
- Each member contributes exactly `contributionAmount` once per round
- Double contributions are prevented
- Contributions are tracked per round

### Automatic Payout
- When **all members have contributed** in a round:
  - the full pot is automatically paid to the current recipient
  - the round resets
  - the next recipient becomes active
- No manual `payout()` call is required

### Disbanding a Group
- Only members who have **not yet received a payout** may vote
- When **all unpaid members vote**:
  - the group is disbanded
  - any current-round contributions are refunded
- Past payouts are never reverted

---

## 📦 Smart Contract Overview

### Core Functions

| Function | Description |
|--------|-------------|
| `createGroup` | Creates a new savings group |
| `contribute` | Contribute to the current round (auto-payout if last) |
| `voteToDisband` | Vote to disband the group (unpaid members only) |
| `payout` | Optional manual payout trigger (reverts if not ready) |
| `getMemberInfo` | Returns total contributed & received by a member |
| `getCurrentRecipient` | Returns the current round recipient |

---

## 🔒 Safety & Design Notes

- Uses `ReentrancyGuard`
- ETH transfers happen **after state updates**
- Monthly contribution counters are reset correctly
- Refunds only apply to the current round
- Designed for **EOA wallets** (normal user wallets)

---

## 🧪 Testing

The contract is fully tested using **Foundry**.

### Test Coverage Includes:
- Member and non-member contribution rules
- Double contribution prevention
- Automatic payout on last contribution
- Full multi-round payout cycle
- Correct payout rotation
- Disband voting logic
- Refund correctness
- Net balance accounting

### Run Tests
```bash
forge test
