# AKASHA Commerce Currency Contract (P4 slice)

> **Status:** Active — domain + contract corrections (2026-07-12)  
> **Track:** [STEAM_RELEASE_BLOCKER_CLOSURE.md](STEAM_RELEASE_BLOCKER_CLOSURE.md)  
> **Code:** `lib/core/commerce/`  
> **Flag:** `FeatureFlags.steamInAppPurchasesEnabled = false` (unchanged; no Steam/UI wiring yet)

## Display names vs stable ids

| Kind (code / ledger / DB) | EN display | KO display | UI qualifier |
|---|---|---|---|
| `CurrencyKind.premium` | Astra | 아스트라 | Paid / 유료 |
| `CurrencyKind.earned` | Echo | 에코 | Earned / 무료 획득 |

Do **not** use `Pearl`, `BlackPearl`, or display strings as storage keys.

## Astra grant timing (finalized ≠ settlement report)

Astra (`premium`) is granted only after **FinalizeTxn succeeds** or **QueryTxn / GetReport independently confirms the transaction as completed**. Grant exactly once (idempotent).

GetReport **SETTLEMENT** / **CHARGEBACK** rows are **post-hoc reconciliation** evidence — not a gate that must arrive before the first grant.

```text
Purchase path:   InitTxn → user auth → FinalizeTxn (or QueryTxn/GetReport completed) → grant Astra once
Reconciliation:  GetReport settlement / chargeback → reversal / audit (after the fact)
```

## Invariants

1. Astra is granted only on finalized/completed confirmation (above) — never because a SETTLEMENT report arrived first.
2. Echo (`earned`) is issued only as free grants (test bootstrap, operator grant, limited event codes).
3. Astra and Echo are **never** convertible.
4. A product uses exactly one payment policy: premium-only, earned-only, or choose-one (premium **or** earned).
5. Theme purchase spends currency **and** creates a permanent entitlement (separate records).
6. **Support** (`ProductKind.support`) is an Astra-spend product with **no** functional advantage / entitlement. EN: “Support AKASHA”. KO: “AKASHA 후원”. Do not use English “Donation” for this SKU.
7. Balances are projections over an **append-only** ledger — never a mutable balance field as authority.
8. Premium currency, orders, transaction state, and entitlements are **server-authoritative**.
9. User Vault must **not** store payment authority data.
10. Refund / chargeback / cancel adds a **reversal** ledger entry referencing the original premium grant; never mutate or delete prior entries.

## Refund / chargeback balance policy (v1)

| Rule | v1 behavior |
|---|---|
| Reversal | Append reversal against the original premium grant |
| Negative premium | **Allowed** after reversal if Astra was already spent |
| Further Astra spend | **Forbidden** while `premium <` required price (negative blocks all premium spend) |
| Theme entitlement | **Not** auto-revoked on refund |
| Entitlement clawback | Deferred until ops policy + purchase-source tracking exist |
| Echo | Steam refund / chargeback **does not** affect `earned` |

## First-ship scope (P4–P6)

In scope:

- Buy Astra packs (finalized/completed → premium grant)
- Read Astra / Echo balances (wallet projection)
- Unlock themes with Astra or Echo (per product policy)
- Astra-only theme SKUs
- Astra **Support** (spend-only)
- Server transaction ledger + idempotency / no double-grant
- Steam InitTxn / FinalizeTxn / refund / GetReport (later slices)

Deferred until payment system is stable:

- Attendance check-in
- Friend invites
- Recurring events
- Activity-based auto rewards
- Season economy
- Automatic entitlement revocation on refund

## This slice

| Deliverable | State |
|---|---|
| Thin contract (this doc) | Done (+ finalized / refund / Support corrections) |
| `CurrencyKind` + Product / Order / Ledger / Wallet / Entitlement models | Done |
| Fake repository + fake payment provider | Done |
| **P4-B** Secure backend foundation (SteamID account, 64-bit orders, state machine, fake Steam, reconciliation) | Done — `lib/core/commerce/server/` |
| Real Steam Publisher Web API / Flutter store UI | **Not connected** |
| `steamInAppPurchasesEnabled` | **false** |

Next: **Real Steam adapter** (Publisher Web API Key on server only) → then Flutter store UI. `steamInAppPurchasesEnabled` stays false until verified.
