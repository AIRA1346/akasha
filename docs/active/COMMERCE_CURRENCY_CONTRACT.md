# AKASHA Commerce, Currency, Store, and Inventory Contract

> **Status:** Active product SSOT (2026-07-15; IAP identity note 2026-07-20)
> **Authority path:** Steam Inventory Service
> **Shared domain:** `packages/akasha_commerce_domain/`
> **Flutter boundary:** `lib/core/commerce/`
> **Feature flag:** live train `FeatureFlags.steamInAppPurchasesEnabled = true`
> (BuildID `24282729` includes that code state). Flag enablement is **not**
> production commerce acceptance — CURRENT-RC transaction validation remains
> incomplete and the overall commerce verdict remains **No-Go** under
> [STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md](STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md).
> **Steam upload candidate:** [`steam_inventory_production/itemdefs_steamworks_upload.json`](steam_inventory_production/itemdefs_steamworks_upload.json)

This document is the single source of truth for the launch economy, product
catalog, inventory meaning, and store behavior. The older custom MicroTxn
backend remains deferred and must not override this contract.

## 1. Currency policy

| Stable kind | Display | Acquisition | Launch purchasing power |
|---|---|---|---|
| `CurrencyKind.premium` | Astra / 아스트라 | Purchased through Steam | 1 Astra |
| `CurrencyKind.earned` | Echo / 에코 | Steam-verified playtime rewards | 1 Echo |

- Economy reference: **USD 1 = 100 Astra**.
- The reference is not a client-side exchange-rate calculator. Checkout always
  displays Steam's localized real-money price.
- Astra and Echo have equal purchasing power for products that accept both.
- Astra and Echo are never convertible in either direction.
- Mixed payment is forbidden. A purchase consumes its full price from exactly
  one selected currency.
- Echo is not sold for money.
- Launch Echo policy is **10 Echo after 10 eligible play minutes**, up to **6
  grants per 1,440-minute Steam cooldown window** (maximum 60 Echo per window).
  This does not promise a Korean-calendar midnight reset. The app triggers
  evaluation; Steam validates playtime and the cooldown window.
- No starter Echo promo ships at launch.
- Friend-invite Echo rewards are deferred until a trusted service can verify
  inviter, invitee, completion, duplication, and abuse. The client never grants
  invite rewards by itself.

Approved launch Astra packs:

| Product id | Astra grant | USD reference | Checkout display |
|---|---:|---:|---|
| `astra_pack_500` | 500 | $4.99 | Steam localized price |
| `astra_pack_1000` | 1,000 | $9.99 | Steam localized price |
| `astra_pack_2500` | 2,500 | $24.99 | Steam localized price |

Only these domain product ids may map to priced Steam ItemDefs. The raw Astra
unit ItemDef is never a purchase SKU even though it carries a hidden component
price for bundle accounting.

## 2. Launch theme catalog

Classic Dark and Midnight Blue are bundled and need no commerce entitlement.
The three paid themes are complete theme packages, not palette-only unlocks.

| Product id | Entitlement | Astra | Echo | Launch offer |
|---|---|---:|---:|---|
| `theme_package_sakura` | `theme:sakura` | 500 | 500 | choose one |
| `theme_package_amethyst` | `theme:amethyst` | 500 | 500 | choose one |
| `theme_package_nocturne` | `theme:nocturne` | 500 | 500 | choose one |

Each theme entitlement includes the complete theme-specific package:

- palette and component styling;
- bundled artwork and backdrop;
- theme-specific decoration and particles as they are implemented;
- theme-specific motion and pointer/touch feedback as they are implemented.

The same entitlement is granted regardless of whether Astra or Echo was used.
Owning the entitlement disables every alternate purchase recipe for that theme.

When the IAP feature flag is disabled, purchase entry points must remain hidden
and the app must not claim that Steam purchases are live. For the current
IAP-enabled live train, purchase availability does not imply production
acceptance; the release Acceptance Matrix remains authoritative for CURRENT-RC
evidence and the overall commerce verdict.

## 3. Future product expansion

The domain reserves distinct product kinds so later goods do not distort the
theme package contract:

- `themePackage`;
- `interactionEffect` for a standalone pointer/touch effect;
- `audioPack` for a standalone OST/audio product;
- other kinds only after their ownership and composition rules are approved.

The experimental Support AKASHA item is not a launch product. A future support
offer requires separate product and refund UX approval before publication.

Some future products may be Astra-only. This is expressed by a single Astra
payment option, not by a special currency or a new store path. A theme-specific
effect already included in a theme package must not be resold independently
without an explicit duplicate-ownership policy.

## 4. Inventory v1

The first inventory contains only:

1. Astra balance;
2. Echo balance;
3. owned theme packages, including the two bundled themes.

Tabs for effects, OST, or other future item types stay hidden until real
products exist. An empty speculative category is not a launch feature.

`CommerceAccountSnapshot` is the UI read contract:

- balance fields are nullable until Steam returns a real snapshot;
- unknown is not converted to `0`;
- `ready` means the current inventory read succeeded;
- `transactionsEnabled` is a separate capability and must also be true before
  `canTransact` becomes true;
- `playtimeRewardsEnabled` is independent from paid transactions and must be
  true before the app may request a Steam-verified reward;
- `offlineCache` can display clearly marked cached ownership but cannot buy or
  exchange;
- approved Astra pack prices preserve Steam's currency code and opaque raw
  current/base amounts; the app does not infer a display unit from the USD
  economy reference;
- an online diagnostic must report AppID `4677560` before any ItemDef is
  interpreted;
- `indeterminate` operations force an inventory refresh before retry.

Steam Inventory contents are the authority for Astra, Echo, and premium theme
ownership. Vault and SharedPreferences are never payment or entitlement
authority. `EntitlementService` remains a legacy/dev stub until removed from
production commerce paths.

## 5. Store and theme-gallery behavior

The Store and Theme Gallery read the same `CommerceCatalog` product ids,
entitlement keys, and price policy.

- Theme Gallery always exposes all five official themes.
- Planned paid themes show `500 Astra or 500 Echo`. When the IAP feature flag is
  disabled, they remain in a non-transactional launch-preparation state. When
  the flag is enabled, transactional availability still does not mean production
  acceptance until the Acceptance Matrix CURRENT-RC evidence is sealed.
- Store shows only approved products; it never invents a balance, discount,
  avatar, notification, or localized Steam price.
- Store separates approved Astra packs from the launch theme package section.
  Pack cards expose only provider-confirmed currency availability; raw Steam
  amounts remain opaque until their display-unit contract is verified in the
  production sandbox.
- Store and Inventory show explicit `disabled`, `loading`, `ready`,
  `offlineCache`, and `unavailable` authority states. Retry is available only
  when a live controller is enabled and the last read failed or fell back to
  cache.
- A provider-confirmed theme entitlement changes the matching Store card to
  owned without creating a second local ownership source.
- The purchase sheet will require the user to choose Astra or Echo, show the
  full selected-currency price and projected remaining balance, and never offer
  a mixed amount.
- Inventory shows only owned items; locked products belong in Store/Theme
  Gallery.

## 6. Steam Inventory transaction flow

```text
Buy Astra
  StartPurchase(Astra pack ItemDef)
  -> Steam Wallet / Overlay
  -> SteamInventoryResultReady
  -> GetAllItems refresh
  -> display provider-returned Astra balance

Buy theme with Astra or Echo
  verify latest inventory snapshot
  -> choose exactly one currency
  -> ExchangeItems(one 500-unit recipe)
  -> Steam atomically consumes currency and grants theme ItemDef
  -> GetAllItems refresh
  -> enable theme from entitlement ownership
```

Each launch theme needs provider exchange alternatives that grant the same
theme ItemDef. One wrapper ItemDef can express both alternatives:

```text
exchange: "Astra unit x500;Echo unit x500"
```

The semicolon separates alternative recipes. The client submits instance
quantities for exactly one selected currency, so Astra 250 plus Echo 250 never
matches either recipe. Separate wrapper ItemDefs remain valid but are not
required.

No Astra/Echo conversion ItemDef or exchange recipe may be published.

## 6.1 Current production adapter boundary

`lib/core/commerce/steam_inventory/` now contains the production ItemDef
registry, separately-capable read and transaction ports, and
`SteamInventoryCommerceGateway`.

- only production currency ItemDefs `40001` and `40002` are summed;
- only production theme ItemDefs `41001-41003` grant entitlement keys;
- only approved pack ItemDefs `40110-40112` expose localized price data;
- only playtime generator `40220` may be triggered, and its expected grant is
  verified as an Echo balance increase of 10 after a fresh inventory read;
- every retired POC ItemDef is ignored even when it remains in a developer
  account;
- a later offline refresh may expose the last in-memory provider snapshot as
  `offlineCache`, but a cold offline start keeps balances unknown;
- price lookup failure does not erase a valid balance/ownership snapshot;
- raw ItemDef ids never cross from Store UI; only approved domain product ids
  are mapped by the adapter;
- production MethodChannel ports repeat the allowlist and reject raw Astra
  unit `40001`, every retired POC purchase/exchange ID, mismatched reward IDs,
  and all other non-catalog targets before invoking native code;
- purchase waits for the matching terminal Steam result and then requires the
  exact Astra pack delta in a fresh inventory snapshot;
- exchange allocates exactly 500 units across real instance IDs belonging to
  one selected currency, waits for the terminal result, and then requires the
  target entitlement in a fresh inventory snapshot;
- cancellation, rejection, and provider failure never create a local grant;
- timeout, callback success without the expected inventory outcome, or a poll
  failure after API acceptance becomes `indeterminate` and blocks repeat
  mutations for the current session;
- purchase order and transaction IDs are preserved only in the in-memory
  operation result for sandbox/GetReport evidence;
- the app root selects this gateway only behind the release IAP flag, the
  explicit internal `AKASHA_STEAM_SANDBOX_TRANSACTIONS` build define, or the
  independently gated `AKASHA_STEAM_PLAYTIME_REWARDS` define. All three are
  false in the normal build.

The Store/Inventory implementation has loading/offline/unavailable feedback,
retry, owned-theme state, compact currency-card layout, and 125% text-scale
coverage. Normal builds keep every purchase and exchange control disabled. An
explicit sandbox build adds Astra purchase confirmation, one-currency theme
selection, in-flight locking, and reconciled outcome feedback without enabling
release IAP. Its reward scheduler checks at a ten-minute cadence, but Steam —
not the local timer — decides eligibility and enforces the six-grant window.

The Flutter/native transport is `akasha/steam_inventory`. The historical C++
source and diagnostic client retain POC-oriented names as evidence, but
production code imports only the capability-scoped read/transaction facades.

## 7. Authority and failure invariants

1. Provider ItemDef ids are adapter configuration, not domain product ids.
2. Display names and localized copy are never storage keys.
3. Purchase/exchange success is accepted only from Steam result completion and
   a converged inventory refresh.
4. A delayed or duplicate callback never grants local ownership.
5. Already-owned themes are blocked in UI before exchange. Steam's inability to
   hard-block every duplicate exchange remains an accepted v1 residual risk.
6. Offline mode cannot purchase or exchange.
7. Publisher keys never ship in Flutter.
8. Payment, currency, and entitlement data never enter the user Vault.
9. `40001` keeps its component price for Steam bundle accounting.
   It remains `store_hidden: true`, while the actual sale bundles
   `40110-40112` use `store_hidden: false`. A partner-sandbox A/B on `40110`
   confirmed that hiding the sale bundle caused callback-level
   `k_EResultFail`; changing only that field opened Steam checkout. Production
   app surfaces and native ports still reject direct `40001` purchase calls.

## 8. Gates and deferred systems

`steamInAppPurchasesEnabled` is already enabled in the current live train.
The listed gates remain production acceptance conditions and must not be treated
as satisfied merely because the flag is enabled. CURRENT-RC evidence for
purchase, cancellation, completion, inventory reconciliation, restart
persistence, recovery, and related production proof stays incomplete until the
Acceptance Matrix records it; overall commerce verdict remains **No-Go**.

Acceptance gates that still apply:

- production ItemDefs and localized Steam prices are published;
- depot/library-launch build verifies purchase, exchange, restart, and
  cross-device ownership refresh;
- cancellation, timeout, duplicate callback, insufficient balance, and
  indeterminate recovery tests pass;
- GetReport evidence tooling and release documentation are ready.

Deferred:

- starter Echo promotions and Support AKASHA purchases;
- friend-invite Echo rewards;
- arbitrary app-private Echo grants;
- standalone touch effects and OST products;
- the custom Cloud Run/PostgreSQL MicroTxn authority.

The Steam Inventory feasibility evidence remains in
`STEAM_INVENTORY_COMMERCE_FEASIBILITY_GATE.md`. POC ItemDef numbers and costs
remain technical test fixtures and are not production catalog policy.
