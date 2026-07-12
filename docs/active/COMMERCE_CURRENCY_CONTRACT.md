# AKASHA Commerce Currency Contract (P4 slice)

> **Status:** Active — domain slice landed (2026-07-12)  
> **Track:** [STEAM_RELEASE_BLOCKER_CLOSURE.md](STEAM_RELEASE_BLOCKER_CLOSURE.md)  
> **Code:** `lib/core/commerce/`  
> **Flag:** `FeatureFlags.steamInAppPurchasesEnabled = false` (unchanged; no Steam/UI wiring yet)

## Display names vs stable ids

| Kind (code / ledger / DB) | EN display | KO display | UI qualifier |
|---|---|---|---|
| `CurrencyKind.premium` | Astra | 아스트라 | Paid / 유료 |
| `CurrencyKind.earned` | Echo | 에코 | Earned / 무료 획득 |

Do **not** use `Pearl`, `BlackPearl`, or display strings as storage keys.

## Invariants

1. Astra (`premium`) is issued only after a settled Steam Wallet (or fake settlement in tests) payment.
2. Echo (`earned`) is issued only as free grants (test bootstrap, operator grant, limited event codes).
3. Astra and Echo are **never** convertible.
4. A product uses exactly one payment policy: premium-only, earned-only, or choose-one (premium **or** earned).
5. Theme purchase spends currency **and** creates a permanent entitlement (separate records).
6. Donation is an Astra-spend product with **no** functional advantage / entitlement.
7. Balances are projections over an **append-only** ledger — never a mutable balance field as authority.
8. Premium currency, orders, transaction state, and entitlements are **server-authoritative**.
9. User Vault must **not** store payment authority data.
10. Refund / chargeback / cancel adds a **reversal** ledger entry; never mutate or delete prior entries.

## First-ship scope (P4–P6)

In scope:

- Buy Astra packs (settled payment → premium grant)
- Read Astra / Echo balances (wallet projection)
- Unlock themes with Astra or Echo (per product policy)
- Astra-only theme SKUs
- Astra donation (spend-only)
- Server transaction ledger + idempotency / no double-grant
- Steam InitTxn / FinalizeTxn / refund / GetReport (later slices; not this domain-only slice)

Deferred until payment system is stable:

- Attendance check-in
- Friend invites
- Recurring events
- Activity-based auto rewards
- Season economy

## This slice (domain only)

| Deliverable | State |
|---|---|
| Thin contract (this doc) | Done |
| `CurrencyKind` + Product / Order / Ledger / Wallet / Entitlement models | Done |
| Fake repository + fake payment provider | Done |
| Unit tests for grant, idempotency, theme unlock, refund, insufficient funds | Done |
| Steam API / Flutter store UI | **Not connected** |
| `steamInAppPurchasesEnabled` | **false** |

Next: secure backend + Steam adapter (still behind the FeatureFlag).
