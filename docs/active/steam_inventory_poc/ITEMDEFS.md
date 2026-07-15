# Steam Inventory POC — ItemDefs

> AppID: `4677560` · File: [`itemdefs_poc.json`](itemdefs_poc.json)  
> **Historical evidence:** this is the schema used for the completed POC. Do
> **not** upload it as the next production revision. Use
> [`../steam_inventory_production/itemdefs_steamworks_upload.json`](../steam_inventory_production/itemdefs_steamworks_upload.json).

## Pack approach decision

| Approach | How | Pros | Cons |
|---|---|---|---|
| A. Priced `bundle` → `Astra×100` | ItemDef `10010` | Clear “pack” SKU; Item Store friendly; Steam expands grant | Bundle pricing needs component `price` on units ([schema](https://partner.steamgames.com/doc/features/inventory/schema)); units `store_hidden: true` |
| B. Direct priced unit × qty | `StartPurchase([10001], [100])` | Fewer defs | No clean pack SKU; Item Store lists raw units |

**POC choice: A (bundle).** Units carry nominal `price: 1;VLV1` for bundle allocation only and stay `store_hidden: true`. Pack uses `price_category: 1;VLV100`.

> **Price note:** VLV100 / Astra×100 / theme exchange cost 100 are **Sandbox POC technical settings**, not finalized production policy.

**Not used:** `commodity` — not treated as a confirmed required schema field for this POC.

## ID map

| ID | Role |
|---|---|
| 10001 | Astra unit (`auto_stack`) |
| 10010 | Astra Pack 100 (bundle) |
| 10002 | Echo unit (`auto_stack`) |
| 10020 | Echo playtime generator — `10002x5` means weight 5 and grants one Echo because it is the only candidate |
| 10021 | Echo starter promo (`owns:4677560`) — prefer as promo bundle target; adjust if Steam rejects `bundle` on promo item |
| 20001 | Theme Nocturne — ownership = qty ≥ 1 |
| 20010 | Theme exchange bundle — `bundle: 20001x1`, `exchange: 10001x100` |
| 30001 | Support AKASHA (priced, no advantage) |

## Echo v1 contract

- Allowed: `promo`, `played:…`, `playtimegenerator` + **`TriggerItemDrop` from the app**
- Playtime is **not** automatic; the client must call `TriggerItemDrop` when appropriate
- In a generator, `xN` is selection weight rather than quantity. Multi-unit
  production rewards require an intermediate bundle that expands to
  `10002xN`.
- **Out of scope:** attendance, friend invites, arbitrary in-app activity grants

## Theme ownership

- Authoritative: Steam inventory has **≥ 1** instance of `20001`
- `purchase_limit: 1` is Item Store only (auxiliary)
- POC UI must not offer exchange when already owned
