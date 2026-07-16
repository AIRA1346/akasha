# Steam Inventory Production ItemDefs

> **Status:** published to the private partner environment; localized price
> reads pass, but the first production-pack `StartPurchase` attempt failed
> before a visible Overlay checkout
> **AppID:** `4677560`
> **Upload file:** [`itemdefs_steamworks_upload.json`](itemdefs_steamworks_upload.json)
> **Product SSOT:** [`../COMMERCE_CURRENCY_CONTRACT.md`](../COMMERCE_CURRENCY_CONTRACT.md)
> **Release readiness:**
> [`../STEAM_SERVICE_RELEASE_READINESS.md`](../STEAM_SERVICE_RELEASE_READINESS.md)

Do **not** upload the historical
[`../steam_inventory_poc/itemdefs_poc.json`](../steam_inventory_poc/itemdefs_poc.json)
as the next schema revision. It records the completed sandbox experiment and
still contains the Pack 100, one-Echo playtime drop, 100-Astra Nocturne recipe,
starter promo, and Support item. The upload candidate uses a separate production
ID range and includes the old POC definitions only as retired records.

## Upload shape

The checked-in file follows Steam's documented whole-schema shape:

```json
{
  "appid": "4677560",
  "items": []
}
```

Use that file when the Steamworks Inventory Service page asks for the complete
ItemDef JSON. If automation later calls the publisher-only
`IGameInventory/UpdateItemDefs` Web API, send only the value of the `items`
array as its `itemdefs` parameter. A Steam publisher Web API key must remain on
a trusted server or operator machine and must never be added to Flutter,
scripts committed with credentials, or a distributed build.

Run the local preflight before every upload:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate_steam_inventory_itemdefs.ps1
```

Steamworks remains the final validator. Publish to the private partner sandbox
first and complete
[`SANDBOX_TRANSACTION_CHECKLIST.md`](SANDBOX_TRANSACTION_CHECKLIST.md) before
considering release commerce.

The 2026-07-16 incident proved that price availability is not sufficient
evidence that Overlay checkout is usable. Do not repeat purchase tests until
the Steam library launch, Overlay capability, account subscription, and
diagnostic-result gates in the release-readiness document are in place.

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
`30001` are present only as `hidden: true` retirement records. The deprecated
POC playtime generator also has `use_drop_limit: true` and `drop_limit: 0`, the
Steam-documented combination for preventing future drops. Production adapters
ignore every POC ID even if a developer account still owns old instances.

Every definition is `game_only: true`, non-tradable, non-marketable, and hidden
from the public Steam Item Store. Therefore public icon URLs are not a
functional prerequisite for the in-app sandbox flow. Add and validate icons
before changing those visibility decisions or exposing a Steam-hosted Item
Store/Backpack experience.

## Launch definitions

| ItemDef | Role | Contract |
|---:|---|---|
| `40001` | Astra unit | stackable; internal USD 0.01 component value; never a standalone SKU |
| `40002` | Echo unit | stackable; never real-money priced |
| `40110` | Astra Pack 500 | `VLV500` = USD 4.99 reference |
| `40111` | Astra Pack 1,000 | `VLV1000` = USD 9.99 reference |
| `40112` | Astra Pack 2,500 | `VLV2500` = USD 24.99 reference |
| `40210` | Echo Pack 10 | intermediate bundle expanding to `40002x10` |
| `40220` | Echo playtime reward | 10 eligible minutes; max 6 grants per 1,440-minute cooldown window |
| `41001-41003` | Sakura/Amethyst/Nocturne | permanent theme entitlement, ownership quantity `>= 1` |
| `41101-41103` | theme exchange wrappers | one selected recipe: Astra 500 **or** Echo 500 |

For a generator, `xN` means selection weight rather than output quantity. The
generator therefore selects ItemDef `40210`; that bundle expands to exactly 10
Echo. The six-grant cap is a Steam-managed cooldown window and does not promise
a Korean-calendar midnight reset. The app calls `TriggerItemDrop(40220)`;
Steam validates eligible playtime and the window limit.

The theme recipe `40001x500;40002x500` contains two alternatives separated by
a semicolon. It accepts 500 Astra or 500 Echo, never a mixed 250/250 payment.

## Client adapter

The schema is mirrored by
`lib/core/commerce/steam_inventory/steam_inventory_itemdefs.dart`. The current
production adapter:

- verifies diagnostic AppID `4677560` before interpreting inventory;
- reads only production currency and entitlement ItemDefs;
- maps UI product IDs through an allowlisted registry and never accepts raw
  ItemDef IDs from Store UI;
- enforces the same allowlist again at the production MethodChannel ports:
  purchases accept only `40110-40112`, exchanges only `41101-41103`, and
  rewards only `40220 -> 40002`;
- preserves real Steam instance IDs for exact single-currency exchanges;
- waits for a matching terminal callback and then confirms purchase, exchange,
  or reward only after a fresh inventory read exposes the expected change;
- treats an accepted operation with an unknown durable outcome as
  `indeterminate` and blocks further provider mutations for that session;
- keeps transaction and playtime-reward capabilities independently gated;
- never writes local Astra, Echo, or theme ownership.

Internal transaction/reward builds use
`--dart-define=AKASHA_STEAM_SANDBOX_TRANSACTIONS=true` and
`--dart-define=AKASHA_STEAM_PLAYTIME_REWARDS=true` through
[`scripts/build_steam_inventory_sandbox.ps1`](../../../scripts/build_steam_inventory_sandbox.ps1).
Neither define changes `steamInAppPurchasesEnabled`, which remains false.

## Astra unit price and direct-purchase probe

ItemDef `40001` has `price: "1;USD1"` because Steam requires bundle components
to carry prices for bundle accounting, while `40110-40112` use exact
`use_bundle_price` overrides. Steam documents `store_hidden` as hiding an item
from the public Item Store, whereas only `hidden` explicitly makes an ItemDef
unavailable for purchase.

AKASHA therefore applies two client guards: the commerce gateway maps only the
three approved domain pack products, and the production transaction port
rejects every purchase ItemDef except `40110-40112` before calling native code.
This prevents accidental or injected raw ItemDef input through production app
surfaces, but it is not claimed as a Steam-server security boundary against a
separately modified client.

Do not set `hidden: true` on active currency units before sandbox evidence:
Steam's bundle-selling guidance explicitly recommends component prices plus
`store_hidden`, and changing that relationship before validating checkout
could break pack pricing or grants. After publication, run one controlled
partner-sandbox probe for `StartPurchase(40001, 1)`. If Steam accepts it, record
the result as a residual provider behavior and keep the app allowlist; revisit
the economy schema only if pack-only sales must also be enforced by Steam.

## Explicitly absent at launch

- no starter Echo promo;
- no Support AKASHA purchase;
- no Astra/Echo conversion;
- no mixed-currency theme recipe;
- no priced Echo ItemDef;
- no active purchase, exchange, or reward path for POC IDs.

## Before publishing or enabling commerce

1. Run the local validation script and retain its SHA-256 result.
2. Review English and `koreana` names/descriptions in the Steamworks preview.
3. Publish only to the private partner sandbox and confirm all POC IDs are
   hidden and ItemDef `10020` cannot drop.
4. Verify Steam returns localized prices for `40110-40112`.
5. Run the controlled `StartPurchase(40001, 1)` probe and record whether Steam
   permits a store-hidden component unit; never expose this probe in Store UI.
6. Test six successful `TriggerItemDrop(40220)` grants and confirm a seventh is
   denied in the same 1,440-minute window.
7. Complete every transaction, reward, recovery, restart, and second-PC row in
   the sandbox checklist.
8. Enable release IAP only in a separate reviewed change.

Uploading or publishing ItemDefs is an external Steamworks action and is never
performed by repository tests.
