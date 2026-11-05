# Upstream — Pay It Upstream

Decentralized open-source funding protocol. Sponsors send ETH to **one** contract
address and the contract automatically attributes funds to a project maintainer,
five contributors, and three upstream open-source dependencies, according to an
immutable, on-chain split. Every recipient independently pulls their own earnings.

**Competition:** Devcon 8 · Build Battle 2 · Open Infra Sprint  
**Contract:** `UpstreamFunding.sol` (Solidity 0.8.24, Foundry, OpenZeppelin)  
**Target network:** Sepolia (chainId 11155111)

---

## Who Gets Paid and Why

The contract is initialized with nine recipients. Shares are in basis points
(10000 = 100%) and sum to exactly 10000.

| # | Recipient | Category | Share | Percent | Rationale |
|---|-----------|----------|-------|---------|-----------|
| 0 | Alice Maintainer | Maintainer | 3000 bps | 30.00% | Stewards the project; largest single share but **cannot** touch anyone else's funds. |
| 1 | Bob Contributor | Contributor | 800 bps | 8.00% | Regular project contributor. |
| 2 | Carol Contributor | Contributor | 800 bps | 8.00% | Regular project contributor. |
| 3 | Dave Contributor | Contributor | 800 bps | 8.00% | Regular project contributor. |
| 4 | Eve Contributor | Contributor | 800 bps | 8.00% | Regular project contributor. |
| 5 | Frank Contributor | Contributor | 800 bps | 8.00% | Regular project contributor. |
| 6 | Dep Alpha | Upstream dependency | 1000 bps | 10.00% | Open-source dependency the project builds on. |
| 7 | Dep Beta | Upstream dependency | 1000 bps | 10.00% | Open-source dependency the project builds on. |
| 8 | Dep Gamma | Upstream dependency | 1000 bps | 10.00% | Open-source dependency the project builds on. |
|   | **Total** | | **10000 bps** | **100.00%** | |

**Why dependency maintainers get funded automatically.** Open-source projects stand on
the shoulders of other open-source projects. Dependency maintainers carry real
maintenance burden but rarely receive direct funding. By routing a fixed share of
every sponsorship directly to each dependency's own address, Upstream makes that
support automatic, neutral, and impossible to revoke unilaterally. The project
maintainer never holds dependency money.

---

## Core guarantees

1. **Sponsors send ETH to one contract address.** `sponsor()` and `receive()`
   both accept ETH; accounting is derived exclusively from `msg.value`.
2. **The contract derives accounting from actual `msg.value`.** No caller-supplied
   amount is ever trusted for crediting.
3. **Every recipient receives an attributable credit.** Each sponsorship emits an
   `AllocationCredited` event per recipient plus a `FundingReceived` event.
4. **Each recipient withdraws independently.** `withdraw()` is pull-based; a
   recipient can only withdraw their own pending balance to `msg.sender`.
5. **No maintainer or administrator can extract credited funds.** There is no
   owner, no admin, no emergency sweep, and no function that moves recipient
   funds anywhere other than the entitled recipient's own withdrawal.
6. **Reentrancy protection is enforced.** `withdraw()` uses OpenZeppelin's
   `ReentrancyGuard` (`nonReentrant`) and checks-effects-interactions ordering.
7. **Every rounding remainder is allocated.** Integer division is used; the exact
   remainder is credited to the designated remainder recipient so
   `SUM(allocations) == msg.value` always.
8. **The split cannot be changed after initialization.** The configuration is set
   in the constructor and is immutable; there is no setter or privileged role.

---

## Build Battle 2 — Acceptance Criteria Verification

| # | Acceptance criterion | Contract function | Source file | Test | Why it passes |
|---|----------------------|-------------------|-------------|------|---------------|
| 1 | Recipients pull their own payouts | `withdraw()` | `contracts/UpstreamFunding.sol:293` | `test_individual_withdrawal_pays_exact_pending` | Pull-based; `msg.sender` is the only destination; balance cleared before transfer. |
| 2 | No privileged function can send credited funds elsewhere | (none — no such function exists) | `contracts/UpstreamFunding.sol` | `test_no_owner_or_admin_can_extract_funds` | No owner/admin/sweep functions; only `withdraw()` moves ETH, and only to the caller. |
| 3 | Withdrawal clears balance before external call or uses a reentrancy guard | `withdraw()` | `contracts/UpstreamFunding.sol:293` | `test_reentrancy_attack_on_withdraw_reverted`, `test_withdraw_clears_balance_before_transfer` | `nonReentrant` guard + balance zeroed before `address.call{value}`. |
| 4 | Split shares sum to declared total | constructor validation | `contracts/UpstreamFunding.sol:163` | `test_shares_sum_to_denominator`, `test_rejects_invalid_total_shares` | Constructor reverts unless `totalShares == BPS_DENOMINATOR (10000)`. |
| 5 | Rounding remainders are assigned | `_allocate()` | `contracts/UpstreamFunding.sol:224` | `test_rounding_remainder_assigned_to_designated_recipient`, `test_remainder_invariant_sum_equals_msg_value` | Remainder = `msg.value - sum(allocations)` credited to index 0; invariant sum equals `msg.value`. |
| 6 | Credited amount derives from actual received funds | `sponsor()` / `receive()` | `contracts/UpstreamFunding.sol:237` | `test_allocation_derives_from_msg_value_not_caller_input` | Accounting uses `msg.value` only; no caller-supplied amount. |
| 7 | UI split comes from contract reads | `getRecipient`, `recipientCount` | `contracts/UpstreamFunding.sol` | Frontend `AllocationExplorer.tsx` reads on-chain | Frontend reads recipient names/categories/shares via viem/wagmi; nothing hardcoded. |
| 8 | A test asserts exact withdrawn amount | `withdraw()` | `contracts/UpstreamFunding.sol` | `test_exact_withdrawn_amount_assertion` | Asserts `address(recipient).balance - before == expected` and `pendingBalance == 0`. |
| 9 | No credentials in tracked files | — | `.env.example`, `.gitignore` | — | `.env.example` has placeholders only; `.env`/`client/.env` ignored; no keys committed. |

---

## Architecture

```
Sponsor  ── ETH ──►  UpstreamFunding (one address)
                              │
                    _allocate(msg.value)
                              │
        ┌─────────┬─────────┼─────────┬─────────┐
        ▼         ▼         ▼         ▼         ▼
   Maintainer  C1 .... C5    Dep1   Dep2   Dep3   (9 recipients)
   30%         8% each       10%    10%    10%
   credited    credited      credited credited credited
   (immutable shares, sum = 10000 bps)
                              │
                     each recipient calls withdraw()
                              │
                     ETH sent to recipient's own address
```

- `contracts/UpstreamFunding.sol` — the funding contract.
- `contracts/ReentrancyGuard.sol` — vendored OpenZeppelin ReentrancyGuard.
- `test/UpstreamFunding.t.sol` — 26 tests (initialization, validation, sponsorship, allocation, rounding, withdrawal, reentrancy, malicious-recipient isolation, invariants, fuzz).
- `script/Deploy.s.sol` — Sepolia deployment script.
- `client/` — React + TypeScript + Vite + wagmi + viem + Tailwind frontend.

---

## Funding flow

1. Sponsor calls `sponsor()` (or sends ETH to `receive()`/`fallback()`).
2. `_allocate(msg.value)` computes each recipient's share via integer division:
   `allocation[i] = (msg.value * shareBps[i]) / 10000`.
3. The rounding remainder `msg.value - Σ allocations` is credited to the
   designated remainder recipient (index 0, the maintainer).
4. `totalReceived`/`totalCredited` increase by `msg.value`; each recipient's
   `credited` increases by their allocation.
5. `FundingReceived` and one `AllocationCredited` per recipient are emitted.
6. Invariant: `Σ allocations == msg.value`; no dust is left unattributed.

---

## Withdrawal flow

1. A registered recipient calls `withdraw()`.
2. `pending = credited - withdrawn`; revert if zero (`ZeroBalance`).
3. **CEI:** `withdrawn += pending` and `totalWithdrawn += pending` are updated
   **before** the external transfer.
4. `address(msg.sender).call{ value: pending }("")` sends the ETH.
5. On success, `WithdrawalCompleted` is emitted. On failure, accounting is
   restored and `TransferFailed` reverts (recipient can retry).
6. Protected by `nonReentrant`; no batch withdrawal; no push to multiple
   recipients; a malicious recipient cannot block others.

---

## Security model

- No privileged role at all. No owner, no admin, no emergency sweep, no arbitrary
  ETH transfer, no balance modification by administrators, no recipient
  redirection.
- All arithmetic uses Solidity 0.8 built-in overflow/underflow checks; no
  floating point.
- ReentrancyGuard on `withdraw()`; CEI ordering; failed transfers restore state.
- Duplicate and zero-address recipients rejected at initialization; zero shares
  rejected; total shares must equal 10000.
- Forced ETH (e.g. SELFDESTRUCT) increases the native balance but is **not**
  recorded as sponsorship revenue and cannot be withdrawn by anyone. There is no
  administrative sweep for it.

---

## Contract address / deployment

The contract is deployed to Sepolia via `script/Deploy.s.sol`. See `DEPLOY.md`
for instructions.

**Deployed contract:**

| Field | Value |
|-------|-------|
| Contract address | `0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588` |
| Deployment transaction | `0x3ba4f63c0d98d2cf3d87fff667fa5f2120397aa655c0a2f515bed8c28c132855` |
| Deployment block | 12067987 |
| Chain ID | 11155111 (Sepolia) |
| Deployer | `0x81A4d25Ae3f981A67ab6098AA8Ea2b7B821d734E` |
| Etherscan | https://sepolia.etherscan.io/address/0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588 |
| Tx explorer | https://sepolia.etherscan.io/tx/0x3ba4f63c0d98d2cf3d87fff667fa5f2120397aa655c0a2f515bed8c28c132855 |

Configure `VITE_UPSTREAM_FUNDING_ADDRESS` with the contract address above, then
run `npm run build` in `client/` to build the frontend.

---

## Local development

Prerequisites: [Foundry](https://getfoundry.sh/) and Node.js.

### Smart contracts

```bash
# Build
forge build

# Format check
forge fmt --check

# Run tests
forge test -vvv
```

### Frontend

```bash
cd client
cp .env.example .env   # fill in VITE_UPSTREAM_FUNDING_ADDRESS after deployment
npm install            # (network access required)
npm run typecheck      # tsc --noEmit
npm run build          # tsc --noEmit && vite build
npm run dev            # vite
```

> Note: `npm install` was validated outside this repository's drive because the
> mounted drive rejects npm's directory-rename operations (EACCES). The source
> typechecks (`tsc --noEmit`) and builds (`vite build`) cleanly.

---

## Environment configuration

See `.env.example` (placeholders only) and `DEPLOY.md`. Sensitive files are
ignored by `.gitignore` (`.env`, `client/.env`, `broadcast/`, `node_modules/`,
`out/`).

---

## Known limitations

- Contract is deployed to Sepolia at `0x17d3c7875B92a8d6EAbbc3BF45baf965cB67b588`.
- Contract verification on Etherscan is pending (no Etherscan API key configured).
- The rounding remainder always goes to the maintainer (index 0). This is
  documented and intentional.
- There is no administrative path to recover mistakenly sent or forced ETH.
