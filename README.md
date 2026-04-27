# 🧪 Smart Contract Technical Task

## 📌 Overview

Welcome!  

As part of this task, you will design and implement a **minimal smart contract layer** for a tokenized real estate investment platform.

The goal is to evaluate how you think about:
- Real-world asset (RWA) tokenization  
- On-chain ownership logic  
- Basic financial flows (investment + yield distribution)  

This is **not about perfection** — focus on clarity, structure, and logic.

---

## 🧠 Context (What We’re Building)

We are building an AI-powered real estate investment platform where:

- Properties are tokenized (fractional ownership)
- Users can invest in real-world assets
- Rental income is distributed to token holders
- In the future, AI will optimize portfolio decisions

For this task, focus only on the **on-chain ownership + distribution layer**.

---

## Prerequisites Setup

Before starting the test, complete the following setup steps:

### 1. Clone the Repository

```bash
git clone <REMOTE_REPOSITORY_URL>
cd <REPOSITORY_NAME>
```

### 2. Configure Git Identity

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### 3. Configure Git Hooks Path

```bash
git config core.hooksPath .githooks
```

Verify configuration:

```bash
git config --list
```

---

## 🎯 Task

Implement a **simple smart contract** that represents a tokenized real estate asset.

---

## 🧩 Requirements

### 1. Property Token

- Represent ownership of a single property
- Total supply = 100% of the property
- Users can hold fractional ownership

👉 You may use:
- ERC20 (recommended), or
- a minimal custom implementation

---

### 2. Investment Logic

- Users should be able to "invest" and receive tokens
- You can assume a fixed price per token
- No need for real payment integration (mock logic is fine)

---

### 3. Rental Income Distribution

- Contract owner can deposit rental income into the contract
- Income should be distributed **proportionally** to token holders

---

### 4. Claim Function

- Users should be able to claim their share of accumulated income

---

## ⚙️ Technical Guidelines

- Language: Solidity
- You may use OpenZeppelin if needed
- Keep the implementation simple and readable
- No need for frontend or backend integration

---

## ⏱️ Time Expectation

~30–45 minutes  

We are not expecting a production-ready system.

---

## 📦 Deliverables

Please:

1. Create your contract inside `/contracts`
2. Add clear comments explaining your logic
3. (Optional) Add a short explanation below

---

## 📝 Notes / Approach (Optional)

Briefly explain:

- How you structured the contract
- Any assumptions you made
- What you would improve with more time

---

## ⭐ Bonus (Optional)

If you have time, briefly describe:

> How would you extend this to support multiple properties?

---

## 🚀 Submission

1. Create a new branch:

2. Commit your work

3. Push and open a Pull Request

---

## ✅ Evaluation Criteria

We will evaluate based on:

- Clarity and structure of the contract  
- Understanding of tokenization logic  
- Correct handling of proportional distribution  
- Code readability and simplicity  
- Communication (comments / explanation)  

---

## 💬 Final Note

Focus on **how you think**, not just what you build.

Looking forward to reviewing your approach 🚀