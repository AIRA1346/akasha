# Steam Inventory Production ItemDef Draft

> **Status:** reviewed local draft; not published
> **AppID:** `4677560`
> **Draft:** [`itemdefs_production_draft.json`](itemdefs_production_draft.json)
> **Product SSOT:** [`../COMMERCE_CURRENCY_CONTRACT.md`](../COMMERCE_CURRENCY_CONTRACT.md)

This file is separate from the historical
[`../steam_inventory_poc/itemdefs_poc.json`](../steam_inventory_poc/itemdefs_poc.json).
The POC file remains unchanged evidence of the sandbox experiment. The draft
uses a new production ID range so old POC currency and the cheaply exchanged
POC Nocturne entitlement cannot become launch ownership.

## Approved production ID ranges

| Range | Meaning |
|---|---|
| `40001-40099` | currency units |
| `40100-40199` | real-money Astra packs |
| `40200-40299` | Steam-verified Echo reward helpers |
| `41000-41099` | permanent theme entitlements |
| `41100-41199` | atomic theme exchange wrappers |
| `42000-42999` | reserved for future interaction effects |
| `43000-43999` | reserved for future audio/OST products |

POC IDs `10001`, `10002`, `10010`, `10020`, `10021`, `20001`, `20010`, and
`30001` are included only as `hidden: true` retirement records. Production
adapters must ignore every POC ID even if a developer account still owns old
instances.

## Client adapter

The local draft is mirrored by the explicit registry in
`lib/core/commerce/steam_inventory/steam_inventory_itemdefs.dart`. The
production gateway:

- verifies diagnostic AppID `4677560`, then obtains a fresh account inventory
  through `GetAllItems`;
- maps only production currency and entitlement ItemDefs;
- obtains the user's currency code and priced pack amounts through
  `RequestPrices` followed by `GetItemsWithPrices`;
- never accepts raw ItemDef ids from UI;
- exposes purchase and exchange only through approved domain product IDs and
  the production ItemDef registry;
- preserves real Steam instance IDs for exact single-currency exchange input;
- treats native API acceptance as pending, waits for the matching terminal
  result, and confirms only after a fresh inventory read exposes the expected
  balance or entitlement change;
- blocks duplicate, already-owned, insufficient-balance, and indeterminate
  retry paths before another Steam mutation;
- keeps promo, consume, and playtime reward methods outside the production
  transaction port;
- remains unreachable in the normal app while both the release IAP flag and
  the explicit sandbox transaction build define are false.

The returned Steam price integer is stored as an opaque amount. It must not be
called a micro-unit or formatted by guessing currency decimals before sandbox
evidence confirms the display contract.

Internal transaction builds use
`--dart-define=AKASHA_STEAM_SANDBOX_TRANSACTIONS=true` through
[`scripts/build_steam_inventory_sandbox.ps1`](../../../scripts/build_steam_inventory_sandbox.ps1).
This does not change `steamInAppPurchasesEnabled`, which remains false. The live
manual matrix is tracked in
[`SANDBOX_TRANSACTION_CHECKLIST.md`](SANDBOX_TRANSACTION_CHECKLIST.md).

## Launch definitions

| ItemDef | Role | Contract |
|---:|---|---|
| `40001` | Astra unit | stackable; hidden from Item Store; internal USD 0.01 value |
| `40002` | Echo unit | stackable; never real-money priced |
| `40110` | Astra Pack 500 | `VLV500` = USD 4.99 reference |
| `40111` | Astra Pack 1,000 | `VLV1000` = USD 9.99 reference |
| `40112` | Astra Pack 2,500 | `VLV2500` = USD 24.99 reference |
| `40210` | Echo Pack 10 | intermediate bundle expanding to `40002x10` |
| `40220` | Echo playtime reward | 10 eligible minutes; max 6 grants per 1,440-minute cooldown window |
| `41001-41003` | Sakura/Amethyst/Nocturne | permanent theme entitlement, ownership quantity `>= 1` |
| `41101-41103` | theme exchange wrappers | one selected recipe: Astra 500 **or** Echo 500 |

The six-grant cap is a Steam-managed cooldown window and does not promise a
Korean-calendar midnight reset. The app calls `TriggerItemDrop(40220)` when it
believes a grant is due; Steam remains responsible for playtime and window
validation.

## Explicitly absent at launch

- no starter Echo promo;
- no Support AKASHA purchase;
- no Astra/Echo conversion;
- no mixed-currency theme recipe;
- no priced Echo ItemDef;
- no active purchase/exchange path for POC IDs.

## Before publishing or enabling commerce

1. Add public `icon_url` and `icon_url_large` assets for visible pack and theme
   definitions.
2. Review English and `koreana` names/descriptions in Steamworks.
3. Publish only to the partner sandbox first and confirm POC IDs are hidden.
4. Verify `RequestPrices` returns Valve-localized prices for `40110-40112`.
5. Test six successful `TriggerItemDrop(40220)` grants and confirm a seventh is
   denied within the same 1,440-minute window.
6. Complete every row in
   [`SANDBOX_TRANSACTION_CHECKLIST.md`](SANDBOX_TRANSACTION_CHECKLIST.md),
   including all six theme exchange paths and duplicate-entitlement guards.
7. Test restart and a second PC before enabling
   `FeatureFlags.steamInAppPurchasesEnabled`.

Uploading/publishing ItemDefs and enabling the Steam Item Store are external
Steamworks operations and are never performed by repository tests.
