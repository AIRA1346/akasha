# Steam Inventory Commerce Feasibility Gate

> **Date:** 2026-07-13  
> **Verdict:** **Steam Inventory Sandbox E2E POC passed** — not production IAP Go  
> **POC runbook:** [steam_inventory_poc/README.md](steam_inventory_poc/README.md)  
> **Scope:** Feasibility audit + minimal in-repo POC harness — no store UI / flag still false  
> **Flag:** `steamInAppPurchasesEnabled = false` (unchanged)  
> **Sources:** [Steam Inventory Service](https://partner.steamgames.com/doc/features/inventory), [Inventory Schema](https://partner.steamgames.com/doc/features/inventory/schema), [Item Store](https://partner.steamgames.com/doc/features/inventory/itemstore), [ISteamInventory](https://partner.steamgames.com/doc/api/isteaminventory), [Microtransactions Implementation](https://partner.steamgames.com/doc/features/microtransactions/implementation)

---

## Verdict (one sentence)

AKASHA v1 paid themes + Astra packs + Support **can** be owned and settled by **Steam Inventory Service** in a developer Sandbox E2E; keep Astra/Echo **domain rules**, **defer** the custom MicroTxn backend, and use only a **tiny GetReport evidence tool** for review — not Cloud Run + Postgres ledger.

### Sandbox E2E limitations (must stay explicit)

| Constraint | Status |
|---|---|
| Developer sandbox Steam account verified | Yes |
| Local Release exe (`AKASHA_STEAM_INVENTORY_POC`) verified | Yes |
| Steam depot / library launch build re-verified | **Not yet** |
| Production price policy (VLV / Astra pack / theme cost) | **Not finalized** — current numbers are POC tech settings |
| `steamInAppPurchasesEnabled` | **`false`** (must remain until product IAP work) |
| Real-money end-user purchase outside Sandbox | **Not claimed** |

---

## Recommended ItemDef mapping

| AKASHA concept | ItemDef role | Suggested shape | Key schema flags |
|---|---|---|---|
| Astra unit | Stackable currency | `type: item`, id e.g. `10001` | `auto_stack: true`, `tradable: false`, `marketable: false` (no `commodity`) |
| Astra pack (e.g. 100) | Priced sellable grant | `type: bundle` → `10001x100` **or** priced item that expands to units | `price` / `price_category` (VLV…); not tradable/marketable |
| Echo unit | Free-earned stackable | `type: item`, id e.g. `10002` | Same stack/trade flags as Astra; **no** store price |
| Echo grant sources | Promo / playtime | `promo` rules; `type: playtimegenerator` → Echo | Client may call `AddPromoItem` / `TriggerItemDrop`; Steam enforces rules |
| Theme (e.g. Nocturne) | Permanent unlock | ItemDef `20001`; exchange via bundle `20010` | Ownership qty ≥ 1; **do not** put legacy `exchange` on `20001` |
| Support AKASHA | Cosmetic / token | Priced `item` (badge or spend-token) | No gameplay entitlement; optional `purchase_limit`; not tradable/marketable |

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

Support
  StartPurchase(Support ItemDef) or Item Store
  → decorative / non-advantage item only

Echo v1 earn
  AddPromoItem (owns / played / one-shot promo)
  and/or TriggerItemDrop(playtimegenerator)
  — not attendance / invites / app-private events
```

**Choose-one currency for the same theme:** put **two recipes** on the theme’s `exchange` field, semicolon-separated, e.g. `10001x300;10002x3000` (Astra×300 **or** Echo×3000). Steam picks the first recipe satisfied by the materials the client submits.

---

## Possible vs not (this gate)

| Possible on Steam Inventory alone | Not in v1 without trusted grant server |
|---|---|
| Astra pack sale via Wallet (`StartPurchase` / Item Store) | Attendance / friend-invite / arbitrary in-app Echo grants |
| Support item sale | Client-trusted “give N of item X now” |
| Theme ownership in Steam inventory (cross-PC, reinstall) | Local vault as payment authority |
| Atomic Astra→Theme / Echo→Theme via `ExchangeItems` | Perfect hard-block of “wasteful” second theme craft (see below) |
| Promo + playtime Echo under Steam rules | Converting Astra ↔ Echo (we simply never define that recipe) |

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
| Astra / theme / Support ownership | **Steam inventory** | AKASHA DB + ledger |
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
| Flutter store UI | **Still forbidden** until Inventory POC green |

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

**Still paused:** Cloud Run, PostgreSQL, production MicroTxn adapter, store UI, `steamInAppPurchasesEnabled=true`.
