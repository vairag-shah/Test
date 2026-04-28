# PropertyToken Smart Contract Implementation

## 📋 Overview

This is a minimal smart contract for tokenized real estate investment that implements fractional ownership, investment mechanics, and proportional rental income distribution.

---

## 🏗️ Architecture & Design Decisions

### 1. **Token Structure**
- **Total Supply**: 100 tokens (representing 100% property ownership)
- **Decimals**: 18 (standard for Solidity, allowing fractional ownership)
- **Implementation**: Custom lightweight ERC20-like token instead of full OpenZeppelin ERC20 for simplicity and clarity

**Why**: A minimal implementation makes the logic transparent and easier to understand, while still supporting fractional ownership through the decimals mechanism.

---

### 2. **Investment Logic**
```solidity
function invest(uint256 numTokens) external payable
```

**How it works**:
- User sends required ETH: `numTokens * tokenPrice`
- Tokens are transferred from owner to investor
- Excess ETH is refunded

**Assumptions**:
- Fixed price per token (set at deployment or updated by owner)
- Owner initially holds all 100 tokens and can sell from their balance
- Investment is optional and can be paused via `setInvestmentStatus()`

**Why this approach**: Simplicity. No complex pricing curves or vesting. Owner fully controls availability.

---

### 3. **Rental Income Distribution** (Core Logic)

#### Key Formula:
```
Claimable Income = (User Tokens / Total Supply) × Total Income Deposited - Already Claimed
```

**Flow**:
1. Owner/anyone deposits income via `depositRentalIncome()` or direct `send()`
2. Income is tracked in `totalRentalIncomeDeposited`
3. Token holders calculate their proportional share based on current holdings
4. Users call `claimRentalIncome()` to withdraw their share
5. Claimed amounts are tracked per user to prevent double-claiming

**Important**: Distribution is calculated based on **current token holdings** at claim time, not historical holdings. This means:
- If you buy tokens after income is deposited, you're entitled to your proportional share
- If you sell tokens, your claimable income adjusts proportionally

**Why this design**:
- Simple to understand and implement
- No snapshots or complex history tracking needed
- Fair: distribution is always proportional to current ownership
- Gas efficient

---

### 4. **Key State Variables**

| Variable | Purpose |
|----------|---------|
| `balanceOf[address]` | Token balance per user |
| `totalRentalIncomeDeposited` | Cumulative income ever deposited |
| `rentalIncomeClaimed[address]` | Income already claimed per user |
| `owner` | Contract owner (can manage property & investments) |

---

## 🔄 Transaction Flow Example

### Scenario: Property Investment & Income Distribution

**Step 1: Deploy**
```
Owner deploys contract with:
- Property: "Downtown Apartment"
- Price per token: 1 ETH
- Total tokens: 100 (owner holds all)
```

**Step 2: Alice invests**
```
Alice sends 10 ETH
→ Receives 10 tokens
→ Alice now owns 10% of property
```

**Step 3: Bob invests**
```
Bob sends 20 ETH
→ Receives 20 tokens
→ Bob now owns 20% of property
```

**Step 4: Owner deposits rental income**
```
Owner sends 10 ETH to contract
→ totalRentalIncomeDeposited = 10 ETH
```

**Step 5: Users claim income**
```
Alice claims:
  - Claimable = (10 tokens / 100 total) × 10 ETH = 1 ETH
  - Receives 1 ETH ✓

Bob claims:
  - Claimable = (20 tokens / 100 total) × 10 ETH = 2 ETH
  - Receives 2 ETH ✓

Owner claims:
  - Claimable = (70 tokens / 100 total) × 10 ETH = 7 ETH
  - Receives 7 ETH ✓
```

---

## 📊 Key Functions

### Investment
- `invest(numTokens)`: Purchase fractional tokens
- `setInvestmentStatus(bool)`: Pause/resume investment (owner only)

### Income Distribution
- `depositRentalIncome()`: Owner deposits rental income
- `getClaimableIncome(address)`: View claimable income
- `claimRentalIncome()`: Token holder claims their share

### Utility
- `transfer()` / `transferFrom()` / `approve()`: Basic token transfers
- `setTokenPrice()`: Update price (owner only)
- `getStats()`: Get contract overview

---

## ✅ Requirements Met

| Requirement | Implementation |
|-------------|-----------------|
| **Property Token** | `balanceOf` mapping with 100 total supply |
| **Fractional Ownership** | Users hold decimal tokens (18 decimals) |
| **Investment Logic** | `invest()` function with fixed ETH price per token |
| **Rental Income Distribution** | Proportional distribution via `getClaimableIncome()` |
| **Claim Function** | `claimRentalIncome()` for withdrawals |
| **Code Readability** | Extensive comments and clear function names |

---

## 🚀 Extensions for Multiple Properties

To support multiple properties:

1. **Refactor to Factory Pattern**:
   - Create `PropertyTokenFactory` contract
   - Factory deploys new `PropertyToken` instance per property
   - Users interact with individual property contracts

2. **Alternative: Single Multi-Property Contract**:
   ```solidity
   mapping(uint256 propertyId => PropertyData) properties;
   mapping(uint256 propertyId => mapping(address => uint256)) userTokens;
   // ... etc
   ```

3. **Portfolio Management**:
   - Create a `Portfolio` contract that aggregates multiple properties
   - Track user holdings across all properties
   - Distribute income from all properties in one claim

4. **Data Structure**:
   ```solidity
   struct Property {
       string name;
       string location;
       uint256 totalSupply;  // 100 tokens per property
       uint256 totalIncome;
       mapping(address => uint256) balances;
   }
   ```

**Recommendation**: Start with Factory pattern for modularity—each property is independent, reducing complexity and gas costs.

---

## ⚠️ Assumptions Made

1. **Fixed Token Price**: Price is set at deployment and can be updated, but doesn't change dynamically based on demand
2. **Owner Authorization**: Owner can always withdraw remaining tokens (not locked or vested)
3. **Trust Model**: Contract assumes rental income is deposited correctly (no oracle or external verification)
4. **Single Property**: Current design is for one property; multi-property requires refactoring
5. **No Transfer Restrictions**: Tokens can be freely transferred between users (no lock-up period)

---

## 🔒 Security Considerations

- ✓ Prevents double-claiming via `rentalIncomeClaimed` tracking
- ✓ Checks for zero address in transfers
- ✓ Owner-only functions via `onlyOwner` modifier
- ✓ Refunds excess ETH to prevent accidental overpayment
- ⚠️ No reentrancy guard (simple transfers used; consider adding for production)
- ⚠️ No overflow protection (Solidity 0.8+ has built-in checks)

---

## 📝 Testing Checklist

To verify the contract works correctly:

1. Deploy with a property and token price
2. ✓ Owner initially holds 100 tokens
3. ✓ Alice buys 10 tokens with correct ETH payment
4. ✓ Bob buys 20 tokens
5. ✓ Owner deposits 10 ETH as rental income
6. ✓ Alice claims 1 ETH (10% of 10 ETH)
7. ✓ Bob claims 2 ETH (20% of 10 ETH)
8. ✓ Owner claims 7 ETH (70% of 10 ETH)
9. ✓ Second income deposit distributes correctly
10. ✓ Cannot claim twice for same income

---

## 💡 If More Time Was Available

1. **Add Snapshot Mechanism**: Store historical token balances to distribute income based on holdings at deposit time
2. **Implement Full ERC20 Standard**: Add events, more transfer methods
3. **Add Yield Calculation**: Automatic yield based on rental income over time
4. **Multi-Sig Wallet for Owner**: Require multiple signers for sensitive operations
5. **Upgrade Pattern**: Make contract upgradeable via proxy pattern
6. **Improved Numerics**: Better precision with fixed-point math (instead of simple division)
7. **Admin Dashboard**: Contract for tracking multiple properties and portfolios
8. **Test Suite**: Hardhat tests for all functions and edge cases

---

## 🎯 Summary

This implementation provides a **clear, understandable smart contract** that demonstrates:
- ✓ Fractional ownership tokenization
- ✓ Fair proportional income distribution
- ✓ Investment mechanics with fixed pricing
- ✓ Claim-based withdrawal system
- ✓ Extensible design for future enhancements

The focus is on **clarity and correctness** over production-ready features.
