# Steam Inventory Native Bridge POC

> **Slice:** Windows `ISteamInventory` MethodChannel bridge  
> **Flag:** `steamInAppPurchasesEnabled = false`  
> **Final Go:** still pending live purchase / exchange / restart checks

## SDK link

| Item | Value |
|---|---|
| SDK root | `C:/dev/steamworks/steamworks_sdk_164/sdk` (CMake `STEAMWORKS_SDK_ROOT`) |
| Headers | `${STEAMWORKS_SDK_ROOT}/public` |
| Link | `redistributable_bin/win64/steam_api64.lib` |
| Runtime | POST_BUILD + install copy of `steam_api64.dll` |
| AppID file | `windows/runner/steam_appid.txt` → `4677560` (copied next to EXE) |
| Callbacks | `SteamAPI_RunCallbacks()` in `windows/runner/main.cpp` message loop |

## MethodChannel API (`akasha/steam_inventory_poc`)

| Method | Notes |
|---|---|
| `initialize` / `init` | `SteamAPI_Init`; codes: `steam_not_running`, `restart_via_steam` |
| `getInventory` / `getAllItems` | Waits `SteamInventoryResultReady_t`; `CheckResultSteamID` |
| `requestPrices` | CallResult → price list |
| `startPurchase` | Returns **pending** handle; grant only after ResultReady + re-query |
| `exchangeItems` | Returns **pending**; unlock only after ResultReady + re-query |
| `addPromoItem` / `triggerItemDrop` | Pending → ResultReady |
| `poll` | Drain completed events |
| `destroyResult` | No-op (destroyed once in native ResultReady) |
| `shutdown` | `SteamAPI_Shutdown` |

Event stream: `akasha/steam_inventory_poc/events`  
Statuses: `pending` / `success` / `canceled` / `failed` / `indeterminate`  
`SteamInventoryFullUpdate_t` → `kind=fullUpdate` (ResultReady still owns DestroyResult)

## Authority

Flutter `SteamInventoryPocController` updates Astra/Echo/Theme **only** from successful `getInventory` snapshots. Never Vault / SharedPreferences.

## USER remaining (before claiming live Go)

1. [ ] Publish Inventory/Economy ItemDefs in Steamworks (you said you will Save+Publish)
2. [ ] Run Steam client, launch this build (or place `steam_appid.txt` beside EXE)
3. [ ] Debug → App Preferences → Steam Inventory POC → Initialize / GetAllItems
4. [ ] StartPurchase Astra Pack 100 → confirm +100 Astra after ResultReady + refresh
5. [ ] Exchange → Theme; restart app; confirm theme still owned
6. [ ] Optional: SteamPipe upload to private beta (below)

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

- Live Astra pack purchase grant
- Live ExchangeItems theme unlock
- Cross-PC / restart ownership on Steam account
- GetReport after real money txn
