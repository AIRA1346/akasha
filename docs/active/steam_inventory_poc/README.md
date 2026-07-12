# Steam Inventory Minimal POC

> **Status:** In-repo harness + ItemDef draft ready · **Live Steamworks proof = USER pending**  
> **Flag:** `steamInAppPurchasesEnabled = false`  
> **Not done:** Cloud Run, Postgres, custom MicroTxn backend, store UI, Store IAP claim

This POC proves client-side inventory orchestration and failure rules **in process**.
It does **not** claim final Go until the checklist below is green on a Steam client.

## Layout

| Path | Role |
|---|---|
| [`itemdefs_poc.json`](itemdefs_poc.json) / [`ITEMDEFS.md`](ITEMDEFS.md) | Test ItemDefs (upload = **user**) |
| [`NATIVE_BRIDGE.md`](NATIVE_BRIDGE.md) | Windows Steam SDK link + MethodChannel contract |
| `lib/dev/steam_inventory_poc/` | Fake + controller + debug/internal harness |
| `windows/runner/steam_inventory_poc_channel.*` | Live `ISteamInventory` MethodChannel |
| `tool/steam_get_report.dart` | Admin GetReport (env key; not in client) |
| `test/steam_inventory_poc_test.dart` | Failure / duplicate / offline rules |
| `scripts/build_steam_inventory_poc.ps1` | Release build with Steam redistributable |

## Pack choice

**Bundle pack (`10010` → `10001x100`)** — see ITEMDEFS.md. Units are `store_hidden` with nominal price for bundle allocation. `commodity` not used.

## Echo contract

Playtime Echo requires the **app** to call `TriggerItemDrop`. Promo uses `AddPromoItem`.  
Attendance / invites / arbitrary activity grants are **out of scope**.

## Debug harness

Debug build → App Preferences → **Steam Inventory POC**.  
Uses native channel when `init` returns ok; otherwise **FakeSteamInventoryClient** (explicitly not live).

No SharedPreferences / Vault authority for Astra, Echo, or theme ownership.

## USER steps (Steamworks) — required for final Go

Do **not** mark these done until personally completed:

1. [ ] Steamworks → App `4677560` → **Inventory Service enabled**
2. [ ] Upload / publish [`itemdefs_poc.json`](itemdefs_poc.json) (fix schema if Steam rejects a field)
3. [ ] Place `steam_appid.txt` containing `4677560` next to the running EXE when testing outside Steam
4. [ ] Run Windows build under Steam (or with Steam client + appid file)
5. [ ] Replace MethodChannel stub with live `ISteamInventory` link (follow-up slice when ItemDefs published)
6. [ ] `StartPurchase` Astra Pack 100 → inventory shows **exactly +100** Astra units
7. [ ] `ExchangeItems` Astra×10 **or** Echo×100 → Theme Nocturne granted; currency consumed
8. [ ] Restart app / other PC → Theme still owned (≥1 instance)
9. [ ] Confirm no Publisher key in client; balances only from `GetAllItems`
10. [ ] `dart run tool/steam_get_report.dart --type SETTLEMENT --time <RFC3339>` with env key → save redacted evidence under `evidence/`

## In-repo verification (automated)

```bash
flutter test test/steam_inventory_poc_test.dart test/feature_flags_v1_scope_test.dart
dart run tool/steam_get_report.dart --fixture tool/fixtures/steam_getreport_settlement.json
```

| Check | Result |
|---|---|
| Load failure → no invented balances | Covered by unit test |
| Purchase pending until callback | Covered |
| Duplicate handle → no double grant | Covered |
| Theme owned → no re-exchange request | Covered |
| Offline blocks buy/exchange; confirmed theme still applicable | Covered |
| GetReport fixture redaction path | Covered by script dry-run |
| Live Steam purchase / exchange / cross-PC | **Pending user Steamworks** |
| Live GetReport after real txn | **Pending user** |

## Final Go (only when live checks pass)

See gate doc. Until then: provisional feasibility Go only — **not** implementation locked.
