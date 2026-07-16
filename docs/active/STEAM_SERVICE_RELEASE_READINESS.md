# Steam Service and Commerce Release Readiness

> **Status:** Active release gate
> **Updated:** 2026-07-16
> **Current verdict:** **Commerce No-Go** until a Steam-library build completes
> the purchase, inventory, restart, and recovery matrix
> **AppID:** `4677560`
> **Economy SSOT:** [COMMERCE_CURRENCY_CONTRACT.md](COMMERCE_CURRENCY_CONTRACT.md)
> **Transaction matrix:**
> [steam_inventory_production/SANDBOX_TRANSACTION_CHECKLIST.md](steam_inventory_production/SANDBOX_TRANSACTION_CHECKLIST.md)

This document is the operational source of truth for connecting AKASHA to
Steam reliably. It complements the product/economy contract; it does not change
the Astra, Echo, or theme pricing policy.

## 1. Observed incident

On 2026-07-16, the production ItemDefs were visible through
`RequestPrices`: KRW prices for `40110-40112` were returned and the Store UI
enabled its sandbox purchase buttons.

Calling `StartPurchase(40110)` did not open a Steam Overlay checkout and AKASHA
reported a generic transaction failure.

The historical POC purchase flow opened the Steam Overlay successfully on the
same project. That is strong evidence that the renderer hook and basic native
Overlay integration can work. It does not prove that the newly published
production ItemDef, current account/package access, or current launch build is
valid. Investigation therefore prioritizes the exact production
`StartPurchase` result over rebuilding the Overlay integration.

Confirmed from the screenshot and code:

- Steam initialized sufficiently to read inventory definitions and prices.
- The purchase did not reach a user-visible checkout.
- No Astra grant was claimed and no local balance was invented.
- The exact Steam `EResult`, immediate API phase, launch context, and overlay
  capability were not visible in the product UI.

Therefore the incident is **not yet assigned to one root cause**. The next
attempt must distinguish these cases:

1. production ItemDef/provider rejection such as invalid item, access denied,
   or service unavailable;
2. the account is missing the app license, partner-group access, or a valid
   Dev Comp package;
3. the test executable was run directly while `steam_appid.txt` was present,
   rather than installed and launched from the Steam library;
4. the current published application/Overlay configuration differs from the
   previously successful POC environment;
5. the Steam client and app are running under different Windows privilege
   levels.

The updated sandbox build now retains the exact phase, API call handle,
`steamResultCode`, `steamResultName`, order/transaction IDs, and sanitized
detail required to distinguish them.

## 2. What the current implementation gets right

| Area | Current implementation | Assessment |
|---|---|---|
| Startup order | `SteamAPI_RestartAppIfNecessary` and `SteamAPI_Init` run before Flutter/D3D | Correct overlay hook order |
| Callback pump | `SteamAPI_RunCallbacks` runs on the UI thread about 33 times/second | Sufficient for callbacks |
| Event-driven rendering | `BOverlayNeedsPresent` forces Flutter redraws | Correct protection for an idle desktop UI |
| Result authority | Purchase success waits for terminal Steam result and a fresh `GetAllItems` delta | Correct; no client-side grant |
| AppID/online check | AppID `4677560`, initialization, and logged-on state are checked | Necessary but incomplete |
| Operation allowlist | Only `40110-40112` can enter production purchase calls | Correct product boundary |
| Failure safety | Unknown accepted outcomes become indeterminate and block more mutations | Correct duplicate-charge defense |
| SDK binaries | headers, import library, and `steam_api64.dll` come from the same SDK root | Correct version coupling |

## 3. Closed code gaps and remaining release evidence

### R0 — runtime capability gate implemented

The Store now enables purchase actions only when all of the following are true:

- Steam initialized and is logged on;
- the active account reports subscription to AppID `4677560`;
- `ISteamUtils::IsOverlayEnabled()` is true;
- all three approved pack prices `40110-40112` are present;
- the sandbox/release transaction gate and guarded transaction port are active.

Missing capability leaves the account readable but transactions disabled with
an actionable banner. The user can refresh after the Overlay finishes hooking.

**Remaining evidence:** confirm these values from a Steam-library build.

### R1 — provider failure evidence implemented

Native and Dart operations now preserve:

- phase (`start_purchase_api`, `start_purchase_callback`, result-ready);
- `steamResultCode` and `steamResultName`;
- API call handle;
- order and transaction IDs;
- correlation handle;
- overlay activation events.

The commerce dialog provides **Copy Steam diagnostics**. The report excludes
persona names, Steam IDs, credentials, publisher keys, absolute paths, and Vault
content. User feedback distinguishes provider configuration, access, transient
service failure, cancellation, and indeterminate reconciliation.

**Remaining evidence:** reproduce `StartPurchase(40110)` once and retain the
copied report.

### R2 — depot packaging defect fixed

The local sandbox build intentionally contains `steam_appid.txt`. Steam
documents that this file overrides the AppID supplied by Steam and makes
`SteamAPI_RestartAppIfNecessary` return false, even when the executable was not
launched through the Steam client.

The file is useful beside a local developer executable, but it must not be in
the Steam depot. The raw Flutter build directory contains it.

`scripts/steam/prepare_steam_depot.ps1` now copies the raw Release output into
`build/steam/depot_windows`, excludes `steam_appid.txt` and `*.pdb`, verifies
the executable, Steam DLL, and Flutter assets, and writes a SHA-256 file
manifest. The upload script uses only this staged directory and repeats both
VDF exclusions defensively.

The 2026-07-16 preflight produced 97 staged files and no forbidden file.

**Remaining evidence:** upload that staged payload to an internal branch and
verify the installed manifest.

### R3 — Steamworks configuration is not yet a checked contract

Before another purchase attempt, record screenshots or exported evidence for:

- Inventory Service enabled and ItemDefs published;
- application type;
- Installation > General Installation >
  **Enable Steam Overlay for Application** enabled and published;
- launch executable and working directory;
- default/closed beta build set live;
- Dev Comp package includes the AppID and depot;
- tester account belongs to the publisher group or owns an appropriate key;
- global and per-app Steam Overlay settings enabled.

## 4. Required test order

Use this order so one failure identifies one layer.

### Gate A — Steam library launch

1. Run `scripts/steam/prepare_steam_depot.ps1`.
2. Retain `build/steam/manifests/depot_windows.json`.
3. Upload the staged payload to a password-protected internal branch.
4. Install and launch it from the Steam library.
5. Confirm AppID, logged-on, subscribed-app, and same Windows user context.

### Gate B — Overlay preflight

1. Wait until `IsOverlayEnabled` becomes true; it can be false briefly during
   startup.
2. Press Shift+Tab and confirm the normal Steam Overlay opens and closes.
3. Record `GameOverlayActivated_t` and `BOverlayNeedsPresent` counters.
4. Keep purchase actions disabled if this gate fails.

### Gate C — read-only Inventory

1. Load ItemDefs and `GetAllItems`.
2. Confirm prices exist for exactly `40110-40112`.
3. Confirm retired POC IDs are ignored.
4. Confirm balances and entitlements survive an app restart.

### Gate D — purchase lifecycle

For each pack, separately verify:

1. `StartPurchase` returns a valid API call handle.
2. `SteamInventoryStartPurchaseResult_t` returns `k_EResultOK` with non-zero
   order and transaction IDs.
3. Steam Overlay checkout opens.
4. cancellation produces no inventory delta and remains safely retryable;
5. completion produces the exact Astra delta only after
   `SteamInventoryResultReady_t` and a fresh `GetAllItems`;
6. a cold restart and a second PC show the same Steam-authoritative result.

If a checkout does not appear, immediately use **Copy Steam diagnostics** and
record the report before retrying. Do not change ItemDefs based only on the
generic visual symptom.

### Gate E — exchange, rewards, and recovery

Complete the existing matrix for:

- Astra and Echo theme exchanges;
- already-owned theme and duplicate-click guards;
- six eligible Echo grants and the seventh no-grant result;
- offline-before-start;
- provider failure;
- accepted-but-unknown result and restart reconciliation;
- refund/report evidence appropriate to the released product.

## 5. Release architecture

```text
Steam library launch
  -> SteamAPI_RestartAppIfNecessary / SteamAPI_Init
  -> runtime capability preflight
       initialized
       logged on
       correct AppID
       subscribed app
       overlay enabled
       approved prices present
  -> Store CTA enabled
  -> StartPurchase(approved pack only)
  -> Steam Overlay confirmation
  -> StartPurchase callback with order/trans IDs
  -> SteamInventoryResultReady_t
  -> fresh GetAllItems
  -> reconcile exact Astra delta
  -> update UI
```

Steam Inventory remains the authority. AKASHA must never grant Astra, Echo, or
premium ownership from a button callback, local preference, Vault file, or
unverified order ID.

## 6. Service and support requirements

Before enabling release IAP:

- provide a read-only Steam connection status page;
- expose retry only for operations known not to have started;
- require reconciliation before retrying an accepted/unknown operation;
- retain a bounded, rotating local diagnostic log;
- allow users to copy a sanitized support report;
- document Steam-offline behavior and Overlay requirements;
- keep Publisher Web API keys outside the distributed app;
- retain ItemDef revision, build ID, executable hash, and deployment time;
- establish a rollback build with purchase actions disabled;
- enable IAP only in a dedicated reviewed release change.

## 7. Go / No-Go

Release commerce is **Go** only when all of the following are true:

- Steamworks Overlay setting is published;
- the depot manifest proves `steam_appid.txt` is absent;
- a depot build without `steam_appid.txt` launches through Steam;
- Shift+Tab and `IsOverlayEnabled` both pass;
- all approved packs pass cancel and completion tests;
- exact Astra deltas survive restart and second-PC verification;
- exchange and Echo limits pass;
- failure and indeterminate recovery pass;
- support diagnostics identify the actual provider phase/result;
- normal non-sandbox builds remain unable to call test-only operations;
- the release rollback procedure has been rehearsed.

Until then:

- `FeatureFlags.steamInAppPurchasesEnabled` remains `false`;
- the current sandbox build is an internal diagnostic build only;
- Store Page copy must not claim that paid themes or Astra purchases are live.

## 8. Primary Steamworks references

- [Steamworks API initialization and `steam_appid.txt`](https://partner.steamgames.com/doc/sdk/api)
- [Steam Overlay requirements and Software-app setting](https://partner.steamgames.com/doc/features/overlay)
- [`ISteamInventory::StartPurchase`](https://partner.steamgames.com/doc/api/isteaminventory#StartPurchase)
- [Steam Inventory Service implementation flow](https://partner.steamgames.com/doc/features/inventory)
- [Steam Inventory Item Store testing](https://partner.steamgames.com/doc/features/inventory/itemstore)
- [Testing builds and Dev Comp packages](https://partner.steamgames.com/doc/store/testing)
- [Steam builds and branches](https://partner.steamgames.com/doc/store/application/builds)
