# Steam Inventory Production Sandbox Transaction Checklist

> **Status:** implementation ready; live production-ItemDef sandbox run pending
> **Release IAP:** disabled
> **Build:** `scripts/build_steam_inventory_sandbox.ps1`
> **ItemDefs:** `40001-41103` from `itemdefs_production_draft.json`

This checklist verifies the guarded production adapter. It does not replace
the historical POC and does not authorize enabling release purchases.

## 1. Preconditions

- Publish the reviewed production ItemDefs to the Steamworks partner sandbox.
- Confirm all retired POC ItemDefs remain hidden.
- Add and review public icons for visible Astra packs and theme entitlements.
- Build with `scripts/build_steam_inventory_sandbox.ps1`.
- Launch the resulting Release executable through Steam with a partner account.
- Confirm Store shows the transaction-enabled authority banner and real Steam
  currency availability for ItemDefs `40110-40112`.

Do not use `steamInAppPurchasesEnabled=true`. The internal build define is
`AKASHA_STEAM_SANDBOX_TRANSACTIONS=true`.

## 2. Astra pack matrix

Run each pack independently and record the initial and reconciled Astra totals.

| ItemDef | Product | Expected inventory delta | Cancel case | Complete case |
|---:|---|---:|:---:|:---:|
| `40110` | Astra 500 | `+500` of `40001` | ⬜ | ⬜ |
| `40111` | Astra 1,000 | `+1,000` of `40001` | ⬜ | ⬜ |
| `40112` | Astra 2,500 | `+2,500` of `40001` | ⬜ | ⬜ |

For every row:

1. Cancel in the Steam overlay; balance must not change and retry must remain
   available.
2. Complete the sandbox purchase; UI must remain pending until
   `SteamInventoryResultReady_t` and a fresh `GetAllItems` read.
3. Confirm the exact Astra delta, provider correlation handle, order ID, and
   transaction ID.
4. Restart AKASHA and confirm the same Steam-backed balance.

## 3. Theme exchange matrix

Each path consumes exactly one currency. Use separate partner test accounts or
Steamworks inventory administration when a permanent entitlement must be reset;
AKASHA provides no production entitlement-consume shortcut.

| Theme wrapper | Entitlement | Astra 500 | Echo 500 |
|---:|---:|:---:|:---:|
| `41101` | Sakura `41001` | ⬜ | ⬜ |
| `41102` | Amethyst `41002` | ⬜ | ⬜ |
| `41103` | Nocturne `41003` | ⬜ | ⬜ |

For every path verify:

- only instance IDs belonging to the selected `40001` or `40002` currency are
  submitted;
- multiple stacked instances are split to an exact total of 500;
- the unselected currency is unchanged;
- mixed Astra/Echo input is never offered or submitted;
- the entitlement appears only after the reconciled inventory read;
- a second exchange is blocked before calling Steam.

## 4. Failure and recovery matrix

| Case | Expected behavior | Result |
|---|---|:---:|
| Insufficient Astra | Button disabled or provider call rejected; no inventory change | ⬜ |
| Insufficient Echo | Button disabled or provider call rejected; no inventory change | ⬜ |
| Double click | One in-flight transaction; duplicate request rejected locally | ⬜ |
| Overlay cancellation | `cancelled`; fresh inventory remains authoritative | ⬜ |
| Steam offline before start | Transaction not started | ⬜ |
| Poll failure after acceptance | `indeterminate`; repeat transaction blocked | ⬜ |
| Result callback but expected delta missing | `indeterminate`; repeat transaction blocked | ⬜ |
| App restart after indeterminate result | `GetAllItems` determines the durable outcome before any retry | ⬜ |
| Second PC / second Steam session | Same balance and entitlements after refresh | ⬜ |

An indeterminate operation must never be presented as failure-safe. The user
must not repeat it until Steam inventory reconciliation establishes the outcome.

## 5. Evidence to retain

- build commit and executable build hash;
- ItemDef schema revision and Steamworks publication time;
- account AppID diagnostic (`4677560`);
- provider correlation handle, purchase order ID, and transaction ID;
- before/after inventory totals and entitlement set;
- Steamworks transaction/GetReport evidence;
- screenshots for cancel, confirmed, insufficient, and indeterminate states.

Only after this checklist and the release gates in
`COMMERCE_CURRENCY_CONTRACT.md` pass may a separate reviewed change consider
enabling release IAP.
