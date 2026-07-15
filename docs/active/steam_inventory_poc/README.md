# Steam Inventory Minimal POC

> **Status:** **Steam Inventory Sandbox E2E POC passed** (2026-07-13)  
> **Flag:** `steamInAppPurchasesEnabled = false` (unchanged; no active purchase UI)
> **Not done:** Cloud Run, Postgres, custom MicroTxn backend, active Store purchase UI, Store IAP claim, production ItemDef publication/icons/live verification

> **Historical evidence — do not upload as the next schema revision.** Use the
> reviewed production candidate
> [`../steam_inventory_production/itemdefs_steamworks_upload.json`](../steam_inventory_production/itemdefs_steamworks_upload.json).

This POC proved client-side inventory orchestration against **Steam Inventory Service in a developer Sandbox**.  
It does **not** claim production IAP, depot/library ship, published production
ItemDefs, or live localized Steam pack-price verification.

### Limitations

| Constraint | Status |
|---|---|
| Developer sandbox Steam account | Verified |
| Local Release exe (`AKASHA_STEAM_INVENTORY_POC`) | Verified |
| Steam depot / library launch build | **Not re-verified** |
| Product economy | **Approved separately:** USD 1 reference = Astra 100; launch theme = Astra 500 or Echo 500 |
| POC ItemDef ids / costs | **Technical fixtures only — not production provider configuration** |
| `steamInAppPurchasesEnabled` | **`false`** |

## Layout

| Path | Role |
|---|---|
| [`itemdefs_poc.json`](itemdefs_poc.json) / [`ITEMDEFS.md`](ITEMDEFS.md) | Historical test ItemDefs; do not re-upload as production |
| [`../steam_inventory_production/README.md`](../steam_inventory_production/README.md) | Production upload candidate and POC retirement policy |
| [`NATIVE_BRIDGE.md`](NATIVE_BRIDGE.md) | Windows Steam SDK link + MethodChannel contract |
| `lib/dev/steam_inventory_poc/` | Fake + controller + debug/internal harness |
| `windows/runner/steam_inventory_poc_channel.*` | Live `ISteamInventory` MethodChannel |
| `tool/steam_get_report.dart` | Admin GetReport (env key; not in client) |
| `test/steam_inventory_poc_test.dart` | Failure / duplicate / offline rules |
| `scripts/build_steam_inventory_poc.ps1` | Release build with Steam redistributable |

## Pack / exchange contract (POC)

| Role | ID | Notes |
|---|---|---|
| Purchase bundle | `10010` | Grants `10001x100` |
| Theme entitlement | `20001` | Ownership = qty ≥ 1 |
| Exchange generate | `20010` | `bundle: 20001x1`, `exchange: 10001x100` |
| Exchange cost | Astra **100** | Real instance IDs destroyed — never ItemDef IDs |

**Bundle pack (`10010` → `10001x100`)** — see ITEMDEFS.md. Units are `store_hidden` with nominal price for bundle allocation. `commodity` not used.

## Echo contract

Playtime Echo requires the **app** to call `TriggerItemDrop`. Promo uses `AddPromoItem`.  
Attendance / invites / arbitrary activity grants are **out of scope**.

### Published POC generator semantics correction

The published POC definition `10020` contains `bundle: 10002x5`. For a
`generator` or `playtimegenerator`, `x5` is a relative selection weight, not a
grant quantity. Because `10002` is the only candidate, one successful trigger
grants **one Echo**, not five. Its 30-minute interval and one-drop-per-1440-
minute window also make it unsuitable for the launch reward policy.

The Fake client and tests intentionally mirror that exact POC behavior. A
production multi-unit Echo grant must select an intermediate `bundle` such as
`Echo Pack 10 -> 10002x10`; the playtime generator then selects that bundle.
The historical POC JSON remains unchanged so it continues to match the schema
that was published for the recorded sandbox evidence.

## Debug harness

- Debug / Release+`AKASHA_STEAM_INVENTORY_POC=true` → App Preferences → **Steam Inventory POC**
- **Consume Theme Reset** button: **Debug only** (hidden in Release, including dart-define harness)
- Verbose audit log lines: **Debug only**
- Uses native channel when available; otherwise **FakeSteamInventoryClient**

No SharedPreferences / Vault authority for Astra, Echo, or theme ownership.

## Sandbox E2E proof (2026-07-13)

1. [x] Inventory Service + ItemDefs published (incl. exchange bundle `20010`)
2. [x] Sandbox `StartPurchase` Astra Pack 100 → +100 Astra
3. [x] Theme Reset (ConsumeItem, Debug) keeps Astra; Theme cleared
4. [x] `ExchangeItems` generate=`20010×1`, destroy=Astra instance IDs totaling 100
5. [x] `k_EResultOK` → Astra 370→270, Theme false→true
6. [x] Theme ownership = inventory qty ≥ 1; authority = `GetAllItems` after ResultReady
7. [ ] Cold restart GetAllItems (user checklist) — Steam-side durable; confirm once
8. [ ] Steam depot/library launch re-verify
9. [ ] GetReport SETTLEMENT evidence after real txn — optional ops follow-up

### Cold restart checklist (user)

1. Fully quit `akasha.exe` (no tray/background)
2. Launch local Release POC exe with Steam running
3. App Preferences → Steam Inventory POC → **GetAllItems**
4. Expect **Astra=270**, **Theme 20001=true**
5. Confirm **Exchange** disabled (Theme owned); purchase button still available
6. Confirm **Consume Theme Reset** is **not** shown (Release)

## In-repo verification (automated)

```bash
flutter analyze
flutter test
```

| Check | Result |
|---|---|
| Load failure → no invented balances | Unit test |
| Purchase pending until callback | Unit test |
| Duplicate handle → no double grant | Unit test |
| Theme owned → no re-exchange request | Unit test |
| Mutation busy → no duplicate buy/exchange | Unit test |
| Controller recreate → same client inventory authority | Unit test |
| Sandbox purchase / exchange | **Passed (developer account)** |

## Production disposition

The launch policy is now fixed separately: 10 Echo after 10 eligible play
minutes, maximum six grants per 1,440-minute Steam cooldown window. Starter
promo and Support are excluded from launch. Current VLV100, Astra pack 100,
one-Echo playtime drop, and theme exchange 100 remain **technical POC settings**
and are retired by the production upload candidate rather than repurposed.
