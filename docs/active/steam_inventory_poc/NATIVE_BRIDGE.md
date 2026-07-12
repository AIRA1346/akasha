# Steam Inventory Native Bridge POC

> **Slice:** Windows `ISteamInventory` MethodChannel bridge  
> **Flag:** `steamInAppPurchasesEnabled = false`  
> **Sandbox E2E:** purchase + exchange proven on developer account / local Release — see [README.md](README.md)  
> **Not claimed:** production IAP, depot/library ship, finalized prices

## SDK link

| Item | Value |
|---|---|
| SDK root | `C:/dev/steamworks/steamworks_sdk_164/sdk` (CMake `STEAMWORKS_SDK_ROOT`) |
| Headers | `${STEAMWORKS_SDK_ROOT}/public` |
| Link | `redistributable_bin/win64/steam_api64.lib` |
| Runtime | POST_BUILD + install copy of `steam_api64.dll` |
| AppID file | `windows/runner/steam_appid.txt` → `4677560` (copied next to EXE) |
| Callbacks | `SteamAPI_RunCallbacks()` via `SteamRuntime::Pump` on window timer |

## MethodChannel API (`akasha/steam_inventory_poc`)

| Method | Notes |
|---|---|
| `initialize` / `diagnostic` | Binds to process-startup SteamRuntime; does not re-Init |
| `getInventory` / `getAllItems` | Waits `SteamInventoryResultReady_t`; `CheckResultSteamID` |
| `requestPrices` | CallResult → price list |
| `startPurchase` | Returns **pending** handle; grant only after ResultReady + re-query |
| `exchangeItems` | Returns **pending**; unlock only after ResultReady + re-query |
| `consumeItem` | Debug Theme Reset path; pending → ResultReady |
| `addPromoItem` / `triggerItemDrop` | Pending → ResultReady |
| `poll` | Drain completed events |
| `destroyResult` | **No-op for Steam handles** — see DestroyResult ownership |
| `shutdown` | Channel teardown only; process owns `SteamAPI_Shutdown` |

Event stream: `akasha/steam_inventory_poc/events`  
Statuses: `pending` / `success` / `canceled` / `failed` / `indeterminate`  
`SteamInventoryFullUpdate_t` → `kind=fullUpdate` (ResultReady still owns DestroyResult)

### DestroyResult ownership

| Layer | What it destroys | When |
|---|---|---|
| Native `OnResultReady` | Real `SteamInventoryResult_t` | Exactly **once** per result callback |
| Dart `pump` → `destroyResult(corr)` | Correlation-string bookkeeping only | Idempotent; native method does **not** call `ISteamInventory::DestroyResult` again |

## Authority

Flutter `SteamInventoryPocController` updates Astra/Echo/Theme **only** from successful `getInventory` snapshots. Never Vault / SharedPreferences.

## Remaining before product IAP claim

1. [x] Publish Inventory ItemDefs (incl. `20010`)
2. [x] Sandbox StartPurchase + ExchangeItems on local Release
3. [ ] Cold restart GetAllItems (user checklist in README)
4. [ ] SteamPipe / library build re-verify
5. [ ] Production price policy + `steamInAppPurchasesEnabled` decision

## Build paths

```text
build/windows/x64/runner/Release/akasha.exe
build/windows/x64/runner/Release/steam_api64.dll
build/windows/x64/runner/Release/steam_appid.txt
```

Steam test build script: `scripts/build_steam_inventory_poc.ps1`

## SteamPipe beta upload (user)

1. Build with `scripts/build_steam_inventory_poc.ps1`
2. Point depot content at `build/windows/x64/runner/Release`
3. Upload via existing `scripts/steam/upload_steam_build.ps1` to a **private beta** branch
4. Do **not** check Store IAP / do **not** resubmit for review yet

## Not verified yet (do not claim)

- Production / non-sandbox end-user purchase
- Steam depot/library launch build
- Finalized VLV / Astra / theme economy policy
- GetReport after real-money txn
