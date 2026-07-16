# Steam Inventory Production Sandbox Checklist

> **Status:** `40110.store_hidden=false` A/B opened Steam checkout; apply the
> confirmed sale-bundle visibility rule to `40111-40112` and complete the
> cancel/complete/reconciliation matrix
> **Release IAP:** disabled
> **Build:** `scripts/build_steam_inventory_sandbox.ps1`
> **ItemDefs:** `itemdefs_steamworks_upload.json`
> **Readiness gate:** [`../STEAM_SERVICE_RELEASE_READINESS.md`](../STEAM_SERVICE_RELEASE_READINESS.md)

This checklist verifies the guarded production adapter. It does not replace the
historical POC and does not authorize release commerce.

## 1. Preconditions

- Run `scripts/validate_steam_inventory_itemdefs.ps1` and retain the SHA-256.
- Upload `itemdefs_steamworks_upload.json` to the Steamworks partner sandbox.
- Confirm all eight retired POC ItemDefs are hidden and `10020` cannot drop.
- Review Korean/English text and every ItemDef in the Steamworks validator.
- Build with `scripts/build_steam_inventory_sandbox.ps1`.
- Run `scripts/steam/prepare_steam_depot.ps1`; retain the generated manifest.
- Upload only `build/steam/depot_windows` to an internal Steam branch.
- Install and launch that depot build through Steam with a partner account.
- Confirm Store reports real Steam currency availability for `40110-40112`.
- Confirm the Steamworks **Enable Steam Overlay for Application** setting is
  enabled and published, especially if the app type is Software.
- For the authoritative transaction run, install a Steam depot/beta build that
  does not contain `steam_appid.txt`; do not treat a directly launched local
  executable as release-path evidence.
- Confirm Shift+Tab works and the runtime reports `overlayEnabled=true` before
  enabling a purchase button.
- Confirm the account reports `subscribedApp=true` and has publisher-group or
  valid package access.

### Observed incident and resolution — 2026-07-16/17

| Step | Result |
|---|---|
| Production ItemDefs published | PASS |
| `RequestPrices` for `40110-40112` | PASS (`KRW`) |
| Store purchase button | Enabled by current sandbox configuration |
| `40110-40112` with `store_hidden=true` | FAIL at callback: `k_EResultFail`, transaction ID `0` |
| `40110.store_hidden=false` A/B | PASS: Steam checkout Overlay opened |
| `40111-40112.store_hidden=false` | Upload/publish and checkout verification pending |
| Historical POC Overlay checkout | PASS |
| Exact provider phase / `EResult` | PASS: copied for all three sale bundles |
| Inventory grant | No grant claimed |

The single-variable A/B established the ItemDef visibility cause without an app
or SteamPipe change. Keep `40001.store_hidden=true`, publish
`40110-40112.store_hidden=false`, and retain **Copy Steam diagnostics** for each
remaining cancel/complete test.

Do not set `steamInAppPurchasesEnabled=true`. The internal build enables only
`AKASHA_STEAM_SANDBOX_TRANSACTIONS` and
`AKASHA_STEAM_PLAYTIME_REWARDS`.

## 2. Astra pack matrix

Run each pack independently and record initial and reconciled Astra totals.

| ItemDef | Product | Expected inventory delta | Cancel | Complete |
|---:|---|---:|:---:|:---:|
| `40110` | Astra 500 | `+500` of `40001` | [ ] | [ ] |
| `40111` | Astra 1,000 | `+1,000` of `40001` | [ ] | [ ] |
| `40112` | Astra 2,500 | `+2,500` of `40001` | [ ] | [ ] |

For every row:

1. Cancel in the Steam overlay; balance must not change and retry must remain
   available.
2. Complete the sandbox purchase; UI must stay pending until
   `SteamInventoryResultReady_t` and a fresh `GetAllItems` read.
3. Confirm the exact Astra delta, provider correlation handle, order ID, and
   transaction ID.
4. Restart AKASHA and confirm the same Steam-backed balance.

### Raw Astra unit probe

The production gateway and MethodChannel transaction port must reject
`40001`, `10010`, and every other non-allowlisted purchase ItemDef without a
native call. Separately, use a controlled partner-only diagnostic to attempt
`StartPurchase(40001, 1)` once:

| Probe | Expected app behavior | Steam provider result | Result |
|---|---|---|:---:|
| Raw Astra unit `40001 x1` | Production Store/port rejects before native call | Record accepted or rejected; no release UI exposure | [ ] |

If Steam accepts the raw provider call, confirm it charges the localized
equivalent of USD 0.01 and grants exactly one `40001`. This is not a cheaper
path than approved packs, but it means pack-only sales are enforced by AKASHA's
allowlist rather than the ItemDef schema alone. Do not repeat the probe outside
the partner sandbox.

## 3. Echo playtime reward matrix

The app timer is only a trigger cadence. Steam decides eligibility, accrued
playtime, and cooldown-window limits.

| Case | Expected behavior | Result |
|---|---|:---:|
| Before 10 eligible minutes | terminal success with no grant; balance unchanged | [ ] |
| First eligible trigger | `40220` expands through `40210`; Echo `+10` | [ ] |
| Repeated eligible triggers 2-6 | each confirmed only after a fresh `GetAllItems` shows `+10` | [ ] |
| Seventh trigger in the same 1,440-minute window | no grant; balance unchanged | [ ] |
| Restart during the window | Steam keeps the same grant count and balance | [ ] |
| Trigger accepted but polling fails | indeterminate; purchases/exchanges/rewards blocked until reconciliation | [ ] |

Retain the native result handle and granted ItemDef/quantity rows for each
attempt. Never treat a local ten-minute timer as proof that Echo was granted.

## 4. Theme exchange matrix

Each path consumes exactly one currency. Use separate partner test accounts or
Steamworks inventory administration when a permanent entitlement must be reset;
AKASHA has no production entitlement-consume shortcut.

| Theme wrapper | Entitlement | Astra 500 | Echo 500 |
|---:|---:|:---:|:---:|
| `41101` | Sakura `41001` | [ ] | [ ] |
| `41102` | Amethyst `41002` | [ ] | [ ] |
| `41103` | Nocturne `41003` | [ ] | [ ] |

For every path verify:

- only instance IDs belonging to selected ItemDef `40001` or `40002` are
  submitted;
- multiple stacked instances are split to an exact total of 500;
- the unselected currency is unchanged;
- mixed Astra/Echo input is never offered or submitted;
- entitlement appears only after the reconciled inventory read;
- a second exchange is blocked before calling Steam.

## 5. Failure and recovery matrix

| Case | Expected behavior | Result |
|---|---|:---:|
| Insufficient Astra | Button disabled or provider rejects; no inventory change | [ ] |
| Insufficient Echo | Button disabled or provider rejects; no inventory change | [ ] |
| Double click | One in-flight operation; duplicate request rejected locally | [ ] |
| Overlay cancellation | `cancelled`; fresh inventory remains authoritative | [ ] |
| Steam offline before start | Operation not started | [ ] |
| Poll failure after acceptance | `indeterminate`; all provider mutations blocked | [ ] |
| Callback success but expected delta missing | `indeterminate`; all provider mutations blocked | [ ] |
| App restart after indeterminate result | `GetAllItems` determines durable state before retry | [ ] |
| Second PC / Steam session | Same balance and entitlements after refresh | [ ] |

An indeterminate operation is not a safe failure. Do not repeat it until Steam
inventory reconciliation establishes the outcome.

## 6. Evidence to retain

- build commit and executable hash;
- ItemDef upload file SHA-256, Steamworks revision, and publication time;
- account AppID diagnostic (`4677560`);
- initialized/logged-on/subscribed/Overlay capability and callback counters;
- copied transaction phase, API call handle, `steamResultCode`, and
  `steamResultName`;
- provider correlation handle, purchase order ID, and transaction ID;
- staged-depot SHA-256 manifest proving `steam_appid.txt` is absent;
- before/after inventory totals and entitlement set;
- native granted-item rows for playtime rewards;
- Steamworks transaction/GetReport evidence;
- screenshots for cancel, confirmed, insufficient, no-grant, and indeterminate
  states.

Only after this checklist and the release gates in
`../COMMERCE_CURRENCY_CONTRACT.md` pass may a separate reviewed change consider
enabling release IAP.
