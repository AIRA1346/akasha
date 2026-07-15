# AKASHA Commerce, Currency, Store, and Inventory Contract

> **Status:** Active product SSOT (2026-07-15)
> **Authority path:** Steam Inventory Service
> **Shared domain:** `packages/akasha_commerce_domain/`
> **Flutter boundary:** `lib/core/commerce/`
> **Feature flag:** `FeatureFlags.steamInAppPurchasesEnabled = false` until production transaction verification

This document is the single source of truth for the launch economy, product
catalog, inventory meaning, and store behavior. The older custom MicroTxn
backend remains deferred and must not override this contract.

## 1. Currency policy

| Stable kind | Display | Acquisition | Launch purchasing power |
|---|---|---|---|
| `CurrencyKind.premium` | Astra / 아스트라 | Purchased through Steam | 1 Astra |
| `CurrencyKind.earned` | Echo / 에코 | Steam-verifiable play events and promotions | 1 Echo |

- Economy reference: **USD 1 = 100 Astra**.
- The reference is not a client-side exchange-rate calculator. Checkout always
  displays Steam's localized real-money price.
- Astra and Echo have equal purchasing power for products that accept both.
- Astra and Echo are never convertible in either direction.
- Mixed payment is forbidden. A purchase consumes its full price from exactly
  one selected currency.
- Echo is not sold for money.
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

All three products remain `planned` while the production feature flag is false.
The app may show the approved catalog and prices, but it must not show an active
purchase action or claim that Steam purchases are live.

## 3. Future product expansion

The domain reserves distinct product kinds so later goods do not distort the
theme package contract:

- `themePackage`;
- `interactionEffect` for a standalone pointer/touch effect;
- `audioPack` for a standalone OST/audio product;
- other kinds only after their ownership and composition rules are approved.

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
- `ready` is the only state that can transact;
- `offlineCache` can display clearly marked cached ownership but cannot buy or
  exchange;
- `indeterminate` operations force an inventory refresh before retry.

Steam Inventory contents are the authority for Astra, Echo, and premium theme
ownership. Vault and SharedPreferences are never payment or entitlement
authority. `EntitlementService` remains a legacy/dev stub until removed from
production commerce paths.

## 5. Store and theme-gallery behavior

The Store and Theme Gallery read the same `CommerceCatalog` product ids,
entitlement keys, and price policy.

- Theme Gallery always exposes all five official themes.
- Planned paid themes show `500 Astra or 500 Echo` and a non-transactional
  launch-preparation state while the flag is false.
- Store shows only approved products; it never invents a balance, discount,
  avatar, notification, or localized Steam price.
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

## 8. Gates and deferred systems

Production purchase actions stay disabled until all of the following pass:

- production ItemDefs and localized Steam prices are published;
- depot/library-launch build verifies purchase, exchange, restart, and
  cross-device ownership refresh;
- cancellation, timeout, duplicate callback, insufficient balance, and
  indeterminate recovery tests pass;
- GetReport evidence tooling and release documentation are ready;
- `steamInAppPurchasesEnabled` is deliberately enabled in a reviewed change.

Deferred:

- friend-invite Echo rewards;
- arbitrary app-private Echo grants;
- standalone touch effects and OST products;
- the custom Cloud Run/PostgreSQL MicroTxn authority.

The Steam Inventory feasibility evidence remains in
`STEAM_INVENTORY_COMMERCE_FEASIBILITY_GATE.md`. POC ItemDef numbers and costs
remain technical test fixtures and are not production catalog policy.
