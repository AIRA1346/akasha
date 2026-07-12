# AKASHA Commerce Currency Contract (P4 slice)

> **Status:** Active — P4-C physical backend boundary (2026-07-12)  
> **Track:** [STEAM_RELEASE_BLOCKER_CLOSURE.md](STEAM_RELEASE_BLOCKER_CLOSURE.md)  
> **Shared domain:** `packages/akasha_commerce_domain/` (re-exported from `lib/core/commerce/`)  
> **Deployable authority:** `backend/akasha_commerce_server/`  
> **Flutter client:** `lib/core/commerce/client/` (`CommerceApiClient` only)  
> **Flag:** `FeatureFlags.steamInAppPurchasesEnabled = false` (unchanged; store UI / production API not wired)

## Physical boundary

```text
Flutter app
├─ Steam GetAuthTicketForWebApi
├─ CommerceApiClient (HTTP)
├─ MicroTxnAuthorizationResponse → backend
└─ UI
       │
       ▼
backend/akasha_commerce_server (or separate deployable)
├─ Publisher Web API Key (env / secret manager only)
├─ AuthenticateUserTicket → verified 64-bit SteamID
├─ Orders · ledger · entitlement authority
├─ InitTxn / FinalizeTxn / QueryTxn / RefundTxn
└─ GetReport reconciliation
```

Do **not** place Steam HTTP adapters, secrets, or authoritative repositories under
`lib/core/commerce/server/`. P4-B code there was a domain prototype only; P4-C
relocates authority to `backend/`.

## Display names vs stable ids

| Kind (code / ledger / DB) | EN display | KO display | UI qualifier |
|---|---|---|---|
| `CurrencyKind.premium` | Astra | 아스트라 | Paid / 유료 |
| `CurrencyKind.earned` | Echo | 에코 | Earned / 무료 획득 |

Do **not** use `Pearl`, `BlackPearl`, or display strings as storage keys.

## Identity

- Client sends auth ticket; backend calls `AuthenticateUserTicket`.
- Only the verified 64-bit SteamID is the commerce account authority.
- Never trust a client-supplied SteamID string.

## Astra grant timing (finalized ≠ settlement report)

Astra (`premium`) is granted only after **FinalizeTxn succeeds** or **QueryTxn / GetReport independently confirms the transaction as completed**. Grant exactly once (idempotent). **InitTxn success alone never grants.**

GetReport **SETTLEMENT** / **CHARGEBACK** rows are **post-hoc reconciliation** evidence — not a gate that must arrive before the first grant.

```text
Purchase path:   ticket → InitTxn → user auth callback → FinalizeTxn (or QueryTxn/GetReport completed) → grant Astra once
Reconciliation:  GetReport settlement / chargeback → reversal / audit (after the fact)
```

Steam API response models and internal `ServerOrderState` stay separate; map via
`SteamToServerStateMapper`. Unknown Steam statuses → indeterminate / manual review.

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
11. Authorization callbacks must correlate AppID · OrderID · verified SteamID.
12. Original Steam responses are retained as **secret-redacted** audit material.

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
- Steam InitTxn / FinalizeTxn / refund / GetReport (sandbox first)

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
| Thin contract (this doc) | Done |
| Shared domain package | Done — `packages/akasha_commerce_domain/` |
| **P4-B** Secure backend foundation (prototype) | Accepted as domain prototype; authority moved in P4-C |
| **P4-C** Physical backend + Sandbox Steam adapter + ticket auth | Done — `backend/akasha_commerce_server/` |
| Flutter `CommerceApiClient` (unwired) | Done — not connected to store UI / production |
| Production Steam / FeatureFlag | **Not connected** — `steamInAppPurchasesEnabled = false` |

Next: **Steam Inventory Minimal POC** — [steam_inventory_poc/README.md](steam_inventory_poc/README.md). Feasibility is provisional Go only; final Go requires live Steamworks checklist. Cloud Run / Postgres / production MicroTxn remain paused; `backend/akasha_commerce_server/` stays deferred. Flag stays false.
