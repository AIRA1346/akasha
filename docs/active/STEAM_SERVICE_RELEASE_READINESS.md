# Steam Service and Commerce Release Readiness

> **Status:** Active release gate
> **Updated:** 2026-07-17
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

On 2026-07-16, `RequestPrices` returned KRW prices for `40110-40112`, but all
three sale bundles reached `SteamInventoryStartPurchaseResult_t` with
`k_EResultFail`, a valid order ID, and transaction ID `0`. Inventory Service,
Asset Server configuration, account access, Steam-library launch, BuildID
`24240688`, and Overlay capability were verified.

The published production definitions matched the local schema. The meaningful
difference from the successful historical POC was that the POC sale bundle
`10010` was not store-hidden, while production sale bundles `40110-40112` used
`store_hidden: true`.

On 2026-07-17, a controlled A/B changed only
`40110.store_hidden: true -> false`. `game_only`, `bundle`, `price_category`,
`use_bundle_price`, the `40001` component price, app code, and SteamPipe build
all remained unchanged. `StartPurchase(40110)` then opened the Steam checkout
Overlay. The checkout failure is therefore assigned to store-hiding the priced
sale bundle. Internal component ItemDef `40001` remains store-hidden; actual
sale bundles `40110-40112` must not be.

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

**Evidence:** confirmed from the Steam-library build on `commerce-sandbox`,
BuildID `24240688`.

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

**Evidence:** retained for `40110`, `40111`, and `40112`; all three failed at
`start_purchase_callback` with `k_EResultFail` and transaction ID `0` before
the `40110` single-field A/B opened checkout.

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
The exact AppBuild/DepotBuild contract, private branch, preflight, and
SteamCMD command are recorded in
[STEAMPIPE_COMMERCE_SANDBOX_UPLOAD.md](steam_inventory_production/STEAMPIPE_COMMERCE_SANDBOX_UPLOAD.md).
`depot_windows.json` is an internal verification manifest, not a SteamCMD
upload script.

**Evidence:** uploaded and installed from `commerce-sandbox` as BuildID
`24240688`, Depot `4677561`, with 97 payload files and no forbidden files.

### R3 — Steamworks configuration checked

Inventory Service is enabled, Asset Server URL/key are configured, Item
visibility is Private, the test account is a developer account, and the remote
definitions matched the upload schema. `40110` checkout opened after changing
only sale-bundle visibility. Remaining Steamworks work is to publish the same
`store_hidden: false` policy for `40111-40112` and verify each checkout.

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
