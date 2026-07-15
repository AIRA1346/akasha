# Steam Inventory Commerce Feasibility Gate

> **Date:** 2026-07-13  
> **Verdict:** **Steam Inventory Sandbox E2E POC passed** — not production IAP Go  
> **POC runbook:** [steam_inventory_poc/README.md](steam_inventory_poc/README.md)  
> **Production draft:** [steam_inventory_production/README.md](steam_inventory_production/README.md)
> **Scope:** Feasibility audit + minimal in-repo POC harness — POC has no store UI / flag still false
> **Flag:** `steamInAppPurchasesEnabled = false` (unchanged)  
> **Sources:** [Steam Inventory Service](https://partner.steamgames.com/doc/features/inventory), [Inventory Schema](https://partner.steamgames.com/doc/features/inventory/schema), [Item Store](https://partner.steamgames.com/doc/features/inventory/itemstore), [ISteamInventory](https://partner.steamgames.com/doc/api/isteaminventory), [Microtransactions Implementation](https://partner.steamgames.com/doc/features/microtransactions/implementation)

---

## Verdict (one sentence)

AKASHA v1 paid themes + Astra packs **can** be owned and settled by **Steam Inventory Service** in a developer Sandbox E2E; keep Astra/Echo **domain rules**, **defer** the custom MicroTxn backend, and use only a **tiny GetReport evidence tool** for review — not Cloud Run + Postgres ledger. Support was technically tested but is not a launch product.

### Sandbox E2E limitations (must stay explicit)

| Constraint | Status |
|---|---|
| Developer sandbox Steam account verified | Yes |
| Local Release exe (`AKASHA_STEAM_INVENTORY_POC`) verified | Yes |
| Steam depot / library launch build re-verified | **Not yet** |
| Product economy policy | **Finalized 2026-07-15** — USD 1 reference = Astra 100; launch themes = Astra 500 or Echo 500, never mixed; Echo 10 per eligible 10 minutes, max 6 per 1,440-minute window |
| Production ItemDef ids / localized pack prices | **Local draft only** — new `40000-41199` ranges and VLV500/1000/2500 are repository-tested but not published |
| `steamInAppPurchasesEnabled` | **`false`** (must remain until product IAP work) |
| Real-money end-user purchase outside Sandbox | **Not claimed** |

---

## Recommended ItemDef mapping

| AKASHA concept | ItemDef role | Suggested shape | Key schema flags |
|---|---|---|---|
| Astra unit | Stackable currency | `type: item`, production id `40001` | `auto_stack: true`, `tradable: false`, `marketable: false` (no `commodity`) |
| Astra packs (500/1,000/2,500) | Priced sellable grants | `type: bundle` → Astra unit quantity | `price` / `price_category` (VLV…); not tradable/marketable; explicit adapter allowlist |
| Echo unit | Free-earned stackable | `type: item`, production id `40002` | Same stack/trade flags as Astra; **no** store price |
| Echo grant source | Playtime | `40220 playtimegenerator` → `40210 Echo Pack 10` | 10 minutes; max 6 grants per 1,440-minute cooldown window; client calls `TriggerItemDrop` |
| Theme (e.g. Nocturne) | Permanent unlock | ItemDef `41003`; exchange via bundle `41103` | Ownership qty ≥ 1; entitlement and exchange stay separate |
| Support AKASHA | POC evidence only | Retired POC ItemDef `30001` | `hidden: true` in the Steamworks upload candidate; not a launch offer |

Display names (Astra/Echo) stay in UI/l10n; ItemDef `name` can match EN for Steam Store surfaces.

---

## Flows (v1)

```text
Buy Astra
  Flutter → ISteamInventory.StartPurchase(pack ItemDef)
         → Steam Overlay / Wallet
         → SteamInventoryResultReady → Astra units in Steam inventory
  (alt) Steam-hosted Item Store pages for priced ItemDefs

Unlock theme
  Flutter shows price in Astra and/or Echo
  → ExchangeItems(theme ItemDef, destroy N currency instances)
  → Steam atomically consumes currency + grants theme if recipe matches

Echo v1 earn
  app calls TriggerItemDrop(40220)
  → Steam validates 10 eligible play minutes and the cooldown window
  → generator expands Echo Pack 10 → Echo ×10
  → maximum six grants / 60 Echo per 1,440-minute window
```

**Choose-one currency for the same theme:** one wrapper ItemDef may define
`exchange: "40001x500;40002x500"`. The semicolon separates alternative
recipes, so Astra×500 **or** Echo×500 can grant the same theme while a mixed
Astra+Echo material list matches neither. Separate wrappers are also valid but
not required. Exact production ItemDef ids remain adapter configuration.

---

## Possible vs not (this gate)

| Possible on Steam Inventory alone | Not in v1 without trusted grant server |
|---|---|
| Astra pack sale via Wallet (`StartPurchase` / Item Store) | Attendance / friend-invite / arbitrary in-app Echo grants |
| Support item sale is technically possible but launch-deferred | Client-trusted “give N of item X now” |
| Theme ownership in Steam inventory (cross-PC, reinstall) | Local vault as payment authority |
| Atomic Astra→Theme / Echo→Theme via `ExchangeItems` | Perfect hard-block of “wasteful” second theme craft (see below) |
| Playtime Echo under Steam rules | Converting Astra ↔ Echo (we simply never define that recipe) |

**Duplicate theme:** `purchase_limit` blocks **Item Store** repurchase, not `ExchangeItems`. Steam will consume more currency if the client asks twice. v1 rule: entitlement = **owns ≥ 1 theme instance**; UI hides unlock when already owned. That is not privilege escalation (user pays twice), acceptable for solo v1.

**Refund:** Steam refunds packs only while granted items remain unmodified; after Astra→Theme exchange, pack refund paths tighten. Theme stays Steam-owned; no AKASHA ledger clawback server required for v1 product rule (matches prior “no auto entitlement clawback” preference).

---

## Offline / failure handling (client duties)

| Case | Approach |
|---|---|
| Offline | Apply already-cached inventory for theme unlock UI; block purchase/exchange until online |
| Inventory load fail | Retry `GetAllItems`; do not invent local balances |
| Exchange / purchase result delay | Wait on `SteamInventoryResultReady_t`; treat in-flight as indeterminate in UI |
| Duplicate callback | Destroy results; re-query inventory; never grant from local side effects |

Authority remains Steam inventory contents, not Flutter SharedPreferences / Vault.

---

## Minimal external security (GetReport)

| Need | Required? | Shape |
|---|---|---|
| Publisher Web API Key in Flutter | **Forbidden** | — |
| Always-on order + Astra balance DB | **No** for Inventory Go path | Deferred with custom backend |
| GetReport for Steam review evidence / refund awareness | **Yes, minimal** | Admin-only Dart script or tiny scheduled function; env secret; `SETTLEMENT` (covers in-game MTX incl. inventory-related sales per Steam docs) |
| InitTxn / FinalizeTxn purchasing server | **No** if using Inventory `StartPurchase` | Steam grants items |

**Separation:** GetReport evidence tool ≠ custom commerce authority. Inventory Go does **not** require reactivating Cloud Run Postgres ledger.

---

## Responsibility: Steam vs AKASHA vs deferred backend

| Concern | Steam Inventory path | Custom backend (`backend/akasha_commerce_server`) |
|---|---|---|
| Wallet charge | Steam | Steam (via MicroTxn) |
| Astra / theme ownership | **Steam inventory** | AKASHA DB + ledger |
| Currency spend → theme | **`ExchangeItems` atomic** | Finalize + ledger debit + entitlement |
| Echo trusted custom events | Needs later grant server | Already designed for server grants |
| Idempotent double-grant | Steam item instances + UI | Ledger idempotency keys |
| GetReport | Small admin tool | Built into server worker |

### Prototype disposition

| Asset | Decision |
|---|---|
| `packages/akasha_commerce_domain/` | **Keep** — product rules / naming / later mapping aid |
| `backend/akasha_commerce_server/` | **Defer** — do not delete; freeze Cloud Run / Postgres / production MicroTxn adapter |
| `lib/core/commerce/client/` | **Keep unwired** — may later wrap Inventory SDK instead of HTTP ledger API |
| Flutter store UI | Read-only approved catalog is allowed; active purchase UI remains gated |

---

## Go / No-Go checklist

### Go (met)

- [x] Astra purchase + theme ownership can be Steam-authoritative  
- [x] `ExchangeItems` can atomically consume currency and grant theme (incl. Astra **or** Echo recipes)  
- [x] No Publisher key / no authoritative balance in Flutter  
- [x] Realistic review path without always-on own order server: Inventory purchases + **admin GetReport dump** for evidence  

### No-Go (not triggered)

- [ ] Essential economy cannot be expressed safely on Inventory → would revert to custom backend  
- [ ] Review evidence forces full own transaction server → would revert  
- [ ] Theme/currency consistency impossible → would revert  

**Residual risks accepted for Go:** Echo v1 limited to Steam-verifiable grants; second theme exchange not Steam-hard-blocked; refund after craft may leave theme (policy OK for v1).

---

## Next implementation slice (only after this Go)

1. Steamworks: enable Inventory Service; upload **test** ItemDefs — **USER**  
2. In-repo Minimal POC harness + GetReport admin tool — see [steam_inventory_poc/README.md](steam_inventory_poc/README.md)  
3. Live `ISteamInventory` link after ItemDefs publish — prove purchase / exchange / restart  
4. If live POC fails consistency → **No-Go escalate**, unfreeze custom backend path  

**Still paused:** Cloud Run, PostgreSQL, production MicroTxn adapter, active Store purchase UI, `steamInAppPurchasesEnabled=true`.
