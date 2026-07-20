# Steam v1 Release Acceptance Matrix

> **Role:** Steam **acceptance criteria, evidence, and verdict ledger SSOT**
> (canonical rows, evidence IDs, PASS/BLOCKED/UNVERIFIED/OPERATOR-CONFIRMED,
> tallies, Overall Go math). Live-identity narrative, packaging, and SteamPipe
> ops → [STEAM_RELEASE.md](STEAM_RELEASE.md). Service/commerce readiness detail →
> [STEAM_SERVICE_RELEASE_READINESS.md](STEAM_SERVICE_RELEASE_READINESS.md).
> **Status:** Active release gate (docs-only SSOT; evidence collection in progress)
> **Created:** 2026-07-19 · **REL-DOC-01 update:** 2026-07-20 · **REL-DOC-04B:** role pin
> **Baseline Git SHA (matrix authoring):** `8f4cf35a0ca1e31b0eb4753fad4e61b6e35dda7f`
> **Evaluated IAP-on Git SHA (pin):** `5e95fefeace1f7658f7b9da7597f12fce4777593` (**Artifact-verified**)
> **Evaluated Steam BuildID (pin):** `24282729` · branch `default` Set Live (**Operator-confirmed**)
> **AppID:** `4677560` · **Windows Depot:** `4677561`
> **IAP flag (live train):** `FeatureFlags.steamInAppPurchasesEnabled = true` (**not** Overall Go)
> **Echo rewards:** follow IAP (`steamInventoryPlaytimeRewardsEnabled` true without sandbox dart-define)
> **Sandbox transactions default:** `false`
> **IAP-off rollback source SHA:** `0ce9e052` · rollback BuildID still **BLOCKED** if unsealed
> **Related:** [STEAM_RELEASE.md](STEAM_RELEASE.md) · [STEAM_SERVICE_RELEASE_READINESS.md](STEAM_SERVICE_RELEASE_READINESS.md) · [COMMERCE_CURRENCY_CONTRACT.md](COMMERCE_CURRENCY_CONTRACT.md) · [steam_inventory_production/SANDBOX_TRANSACTION_CHECKLIST.md](steam_inventory_production/SANDBOX_TRANSACTION_CHECKLIST.md) · [CURRENT_STATE.md](CURRENT_STATE.md)

This matrix is the executable acceptance ledger for the **single Commerce-inclusive Steam v1** release train. It consolidates the master launch checklist into canonical requirements, links repeated pack/theme scenarios as cases, and keeps full traceability in the appendix. It does not redefine SteamPipe packaging or Set Live procedure (see [STEAM_RELEASE.md](STEAM_RELEASE.md)).

**Evidence labels used in this revision:** **Artifact-verified** = repository/worktree SteamPipe or seal files; **Operator-confirmed** = human confirmation without a matching repository receipt (do not mix). Release-ops narrative for those labels lives in [STEAM_RELEASE.md](STEAM_RELEASE.md).

**Out of scope for this document revision:** product/code changes, Steamworks mutation, new uploads, inventing CURRENT-RC-PASS without Steam-installed RC evidence, sandbox worktree cleanup.

---

## 1. Release profile

| Field | Value |
|---|---|
| Product | AKASHA |
| Release train | **Steam v1 — Commerce included** (single track) |
| Platform | Windows (Steam) |
| Languages | Korean, English (Interface) |
| Economy authority | Steam Inventory Service |
| Vault policy | Local user-managed Markdown vault (not Steam Cloud) |
| Inventory / entitlement authority | Steam account Inventory (survives reinstall / other PC) |
| Astra packs (real money) | `40110` (+500), `40111` (+1000), `40112` (+2500) |
| Echo | Playtime reward via `40220` → Echo unit `40002` (+10 / eligible grant; max 6 / window) |
| Paid themes | Sakura `41001`, Amethyst `41002`, Nocturne `41003` via wrappers `41101`–`41103` at **500 Astra or 500 Echo** |
| Rollback | Separate **IAP-off** rollback BuildID must exist and be rehearsed; purchase/exchange CTA off; **Inventory remains read-only** (Steam account authority unchanged). Rollback **source** SHA = `0ce9e052` |
| Production purchase UI | IAP flag **true** on live BuildID `24282729`; Overall store/Commerce Go still requires CURRENT-RC P0 evidence (default Set Live alone insufficient) |

### Explicitly in v1 (P0 commerce)

- Steam store launch with real Astra pack sales
- Echo playtime rewards
- Paid theme unlock via Astra/Echo exchange
- Steam Inventory restore after restart and on another PC
- Cancel / fail / offline / indeterminate reconciliation
- IAP-off rollback build

### Deferred / N/A for this train

- Friend-invite Echo, starter Echo promo
- Custom MicroTxn / Cloud Run commerce backend
- Early Access label, controller support claims
- Vault Steam Cloud sync (assumed unsupported; confirm Steamworks before store parity PASS)

---

## 2. Current verdict

| Gate | Verdict |
|---|---|
| **Overall Steam v1 Go/No-Go** | **No-Go** |
| Commerce transaction matrix | **No-Go** |
| Default Set Live | **OPERATOR-CONFIRMED** (BuildID `24282729` @ `default`) — not Overall Go |
| IAP-on build identity | **PARTIAL** — Git SHA / BuildID / exe+manifest seal **Artifact-verified**; Steam-installed CURRENT-RC retest open |
| IAP-off rollback identity | **BLOCKED** (source `0ce9e052`; BuildID unsealed) |
| Production IAP flag | **Enabled** in tree (`true`) — does **not** auto-raise CURRENT-RC-PASS or Overall Go |
| Active FAIL count (Current-RC Go math) | **0** |
| Historical `store_hidden=true` checkout failure | **Not a current FAIL** — see §10 ledger |

Go requires: every P0 row reaches **CURRENT-RC-PASS** (or justified **N/A**), **FAIL = 0**, **BLOCKED = 0**, and §12 checklist.

---

## 3. RC Identity

> IAP-on live identity is a **partial seal** (SteamPipe + local seal files + Operator-confirmed default Set Live).
> This is **not** Commerce CURRENT-RC-PASS and **not** Overall Go.
> Past BuildIDs `24240688` and `24015480` remain **Historical evidence only**.

| Identity field | IAP-on live RC | IAP-off rollback RC | Status |
|---|---|---|---|
| Git SHA | `5e95fefeace1f7658f7b9da7597f12fce4777593` (**Artifact-verified**) | `0ce9e052` (IAP-off **source**; BuildID TBD) | PARTIAL / BLOCKED (rollback) |
| App version / build number | `1.0.0+1` (**Artifact-verified** pubspec + exe `ProductVersion`) | `1.0.0+1` @ source | PARTIAL |
| Executable SHA-256 | `3C387A2166A965EACE5F3C555D7088721117BBA3D66BBD07ADF1508D72066069` (**Artifact-verified** neutral-path seal) | _TBD_ | PARTIAL / BLOCKED (rollback) |
| Staged depot manifest SHA-256 | `C92B7E33018B61046ED512EF7DF57CAED87F4AAED4D1D24DB9BADA939831DF85` (**Artifact-verified** pre-upload seal; files `1756` · bytes `70978364`) | _TBD_ | PARTIAL / BLOCKED (rollback) |
| Steam BuildID | `24282729` (**Artifact-verified** upload receipt) | _TBD_ (rollback) | PARTIAL / BLOCKED (rollback) |
| Depot ID | `4677561` (**Artifact-verified** receipt) | `4677561` (expected) | documented |
| Steam branch | `default` Set Live (**Operator-confirmed**); upload receipt branch was `commerce-sandbox` (**Artifact-verified**) | _TBD_ | OPERATOR-CONFIRMED / BLOCKED (rollback) |
| ItemDef JSON SHA-256 (local candidate @ baseline) | `9653df2609d9ec88dcc7b8b18c0e59c149221113a5c45360570c96dd67235ff3` | same schema family | candidate only (LF / git-canonical) |
| ItemDef Steamworks publication time / revision | _TBD_ | _TBD_ | BLOCKED (publication SHA **UNKNOWN** — evidence not present in repository) |
| Registry | v4 · 10,048 works · `generatedAt` `2026-07-12T07:58:11.178685Z` | same unless RC rebuilds | baseline snapshot; digest seal TBD |
| `steamInAppPurchasesEnabled` | `true` on live train | must remain `false` on rollback | live tree = `true`; source `0ce9e052` = `false` |
| Supported language snapshot | ko, en | ko, en | UNVERIFIED on Steam-installed RC |
| Steamworks feature snapshot | Overlay, Inventory, IAP, Cloud=off (assumed) | same + purchase CTA absent | BLOCKED |
| Test account type | _TBD_ partner/dev | _TBD_ | BLOCKED |
| Windows version / DPI under test | _TBD_ | _TBD_ | BLOCKED |

**Retest rule:** If any sealed identity field changes, re-run every P0 row whose Evidence level ≥ Steam private-branch RC (see §4).

### ItemDef hash policy

- Canonical ItemDef SHA-256 is computed over the **Git-committed LF bytes**, or over bytes **explicitly normalized to LF**.
- A raw Windows checkout `Get-FileHash` is **not** a release artifact identity: with `core.autocrlf=true` it may hash CRLF-materialized bytes and disagree with the git blob while the schema content is identical.
- Audit note (non-authoritative): CRLF checkout hash `BB20770FB7196CE4ABCC60C7086B43DC6BA868093E3F10B0A18712C29C23E88E` measured the **same content** as LF canonical `9653df2609d9ec88dcc7b8b18c0e59c149221113a5c45360570c96dd67235ff3`. Do not treat `BB20770F…` as a different ItemDef revision.
- Steamworks **published** byte SHA remains **UNKNOWN** until partner evidence exists; remote match stays **BLOCKED**.

### Historical BuildIDs (not Current-RC)

| BuildID | Role | May be cited as |
|---|---|---|
| `24282729` | Current default-live IAP-on build (Git `5e95fefe`) | Identity / BUILD-01 Operator-confirmed; **not** automatic CURRENT-RC-PASS for Commerce rows |
| `24015480` | Free / no-IAP SteamPipe upload | HISTORICAL-PASS only |
| `24240688` | commerce-sandbox library install; prices; depot packaging; `40110` Overlay A/B | HISTORICAL-PASS only |

---

## 4. Status semantics

| Status | Meaning | Counts as Go PASS? |
|---|---|:---:|
| **CURRENT-RC-PASS** | Direct evidence on the **sealed final RC** (or the explicit RC named in the row) | **Yes** |
| **IMPLEMENTATION-PASS** | Code and/or automated tests at baseline SHA prove behavior; **not** Steam RC proof | No |
| **IMPLEMENTATION-PASS / UNVERIFIED-RC** | Implementation evidence exists **and** Steam/private-branch or Release RC measurement is still required | No |
| **HISTORICAL-PASS** | Proven on a past BuildID/SHA; informative only; **retest on final RC** | No |
| **OPERATOR-CONFIRMED** | Human operator confirmation without a matching repository artifact for that exact claim | No |
| **UNVERIFIED** | Plausible / partially implemented; no adequate evidence yet | No |
| **BLOCKED** | Cannot verify until a prerequisite (Steamworks, RC seal, 2nd PC, account, publish) exists | No |
| **FAIL** | Reproduced failure or confirmed requirement violation **against the current release train** | No (blocks Go) |
| **N/A** | Outside this release train after policy lock | Neutral |

### Evidence levels (reference)

1. Code presence
2. Unit tests
3. Widget / integration tests
4. Local Release executable manual run
5. Staged Steam depot verification
6. Steam private-branch downloaded BuildID
7. Other PC / other session
8. Steamworks web configuration / transaction reports

Steam RC-required rows must not be promoted to CURRENT-RC-PASS from levels 1–3 alone.

---

## 5. P0 Acceptance Matrix

Columns: **ID** · **Requirement** · **Verify** · **Status** · **Evidence** · **Notes / retest**

Owner default: Release captain (unset). Environment default: Windows Steam unless noted.

### 5.A Scope and release docs

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| REL-SCOPE-01 | Active launch docs and flag commentary describe the **Commerce-inclusive** v1 train (not “free / no-IAP forever”) | Doc review | IMPLEMENTATION-PASS / UNVERIFIED-RC | Aligned [STEAM_RELEASE.md](STEAM_RELEASE.md), [privacy.md](privacy.md), `lib/config/feature_flags.dart` commentary | Release-scope conflict closed in repository; final Store/RC parity still requires sealed RC verification |
| REL-SCOPE-02 | Production Commerce candidate sets `steamInAppPurchasesEnabled=true`, Echo rewards follow IAP, sandbox default `false`; IAP-off source remains `0ce9e052` | Code read | IMPLEMENTATION-PASS / UNVERIFIED-RC | `feature_flags.dart` · tests | Candidate flag landed; sealed Steam RC / CURRENT-RC evidence still required — not automatic Go |
| REL-SCOPE-03 | Rollback train is an IAP-off build: purchase/exchange CTA absent; Inventory stays read-only (no wipe/mutation of Steam balances or entitlements) | Steam RC + local Release | BLOCKED | — | Needs sealed rollback BuildID; see BUILD-09 |
| CLOUD-01 | Vault Steam Cloud **unsupported** for v1; store page must not claim Cloud; confirm Steamworks setting matches | Steamworks + store | BLOCKED | Assumed local-only ([privacy.md](privacy.md), [STEAM_RELEASE.md](STEAM_RELEASE.md)) | P0 policy row; not CURRENT-RC-PASS until console confirmed |

### 5.B Install, launch, exit

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| INST-01 | Steam Library launch starts the app with correct AppID `4677560` | Steam RC | BLOCKED | Historical library launch on `24240688` | HISTORICAL only for past BuildID |
| INST-02 | Non-default install path launches | Steam RC | UNVERIFIED | — | |
| INST-03 | Paths with Korean / spaces work | Steam RC / local | UNVERIFIED | — | |
| INST-04 | Install/run without admin elevation | Steam RC | UNVERIFIED | — | |
| INST-05 | First launch: no black screen / infinite load / hang | Steam RC | UNVERIFIED | — | |
| INST-06 | Single-instance / no conflicting duplicate processes (policy clear + behavior) | Steam RC + code | UNVERIFIED | — | Merge master “duplicate process” + “policy” |
| INST-07 | Window close exits cleanly; Task Manager kill then relaunch works | Steam RC | UNVERIFIED | — | |
| INST-08 | Shutdown flush or next-run recovery for in-flight saves | Steam RC + tests | IMPLEMENTATION-PASS / UNVERIFIED-RC | recoverable write tests | |
| INST-09 | Steam offline: local vault core usable | Steam RC | UNVERIFIED | — | |
| INST-10 | Steam API init failure does not hard-fail the whole app | Steam RC / local | IMPLEMENTATION-PASS / UNVERIFIED-RC | runtime capability gates | |
| INST-11 | Uninstall removes app bits; user Vault not wiped; reinstall keeps Vault | Steam RC | UNVERIFIED | — | Merges uninstall + reinstall vault retention |
| INST-12 | Direct exe launch policy + `SteamAPI_RestartAppIfNecessary` behavior documented and verified | Steam RC | HISTORICAL-PASS | Readiness R0/R2 narrative on `24240688` | Retest on final RC; depot must omit `steam_appid.txt` |

### 5.C First run and Vault setup

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| VAULT-01 | First-run messaging communicates AKASHA’s purpose | Release UI | UNVERIFIED | dogfood notes (non-RC) | |
| VAULT-02 | Create new Vault vs open existing Vault are distinct | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | vault quick-start / coordinator tests | |
| VAULT-03 | Default Vault location shown; custom folder selectable | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| VAULT-04 | Existing AKASHA Vault recognized safely | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | format validator / archive tests | |
| VAULT-05 | Non-empty generic folder: warn or safe handling; invalid structure does not mutate user files | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | path guards | |
| VAULT-06 | Read-only folder / permission denial: actionable error + retry | Release UI | UNVERIFIED | — | Merges readonly + retry |
| VAULT-07 | Failed Vault create cleans partial structure; cancel setup does not freeze incomplete state | Release UI | UNVERIFIED | — | |
| VAULT-08 | Vault can be changed later; Settings show real path; open in Explorer | Release UI | UNVERIFIED | — | |
| VAULT-09 | Disconnect vs delete Vault are distinct; templates never overwrite user files | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| VAULT-10 | Documents default failure uses safe fallback | Release UI | UNVERIFIED | — | |

### 5.D Works, entities, journal

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| WORK-01 | Create / edit / trash-or-delete works | Release UI + tests | IMPLEMENTATION-PASS / UNVERIFIED-RC | vault archive / workbench tests | CRUD merged |
| WORK-02 | Required-field validation; duplicate-work user notice | Release UI | UNVERIFIED | — | |
| WORK-03 | Registry vs user works distinguished; user works open without Registry | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | bundled registry + offline catalog | |
| WORK-04 | Body + metadata persist across restart; IDs stable | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| WORK-05 | Hand-edited YAML / unknown fields preserved; provenance fields not clobbered by edits | Tests + Release | IMPLEMENTATION-PASS / UNVERIFIED-RC | lossless writer tests | |
| WORK-06 | Save failure never shown as success; deleted-work links/indexes safe | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| ENT-01 | Create / edit / safe dispose for supported entity types | Release UI + tests | IMPLEMENTATION-PASS / UNVERIFIED-RC | entity vault tests | |
| ENT-02 | Unknown / custom entity types not lost | Tests + Release | IMPLEMENTATION-PASS / UNVERIFIED-RC | loader issues / lossless | |
| ENT-03 | Link / unlink work↔entity; navigate counterpart; relations survive restart | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| ENT-04 | Broken relations / unknown relation tokens do not crash; tokens preserved | Tests + Release | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| ENT-05 | Duplicate ID/path conflicts detected; index corruption rebuilds from source | Tests + Release | IMPLEMENTATION-PASS / UNVERIFIED-RC | path index / atomic write | |
| JRN-01 | Create / edit / delete journal records | Release UI + tests | IMPLEMENTATION-PASS / UNVERIFIED-RC | journal vault tests | |
| JRN-02 | Empty/draft policy consistent; date-only vs exact time distinguished | Tests + Release | IMPLEMENTATION-PASS / UNVERIFIED-RC | timestamp alignment tests | |
| JRN-03 | UTC/local conversion does not shift calendar day; partial date/time preserved | Tests + Release | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| JRN-04 | Sort order stable across restart; TZ change does not corrupt timeline order | Release UI | UNVERIFIED | — | |
| JRN-05 | External edits re-recognized; save conflicts keep original + proposal | Tests + Release | IMPLEMENTATION-PASS / UNVERIFIED-RC | recovery write conflict tests | |
| JRN-06 | Provenance not overwritten by edits | Tests + Release | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |

### 5.E Data safety (highest priority)

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| SAFE-01 | Interrupted save never silently destroys last verified content | Fault injection + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | `vault_recovery_write_service_test.dart`; [P0_RECOVERABLE_VAULT_WRITE_GATE.md](../history/closure-2026-07/P0_RECOVERABLE_VAULT_WRITE_GATE.md) | Historical gate seal ≠ Current-RC |
| SAFE-02 | Failed save keeps original; staging recovered or quarantined next run | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | recovery write tests | |
| SAFE-03 | Conflicts preserve source + proposal; detect via size/mtime/hash as designed | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| SAFE-04 | Unknown YAML scalars/lists/objects preserved; corrupt YAML not overwritten | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | lossless writer | |
| SAFE-05 | Corrupt files surfaced with recovery location guidance | Release UI | UNVERIFIED | entity loader issues | |
| SAFE-06 | Multi-file canvas/ops not left half-applied; same-file mutations serialized; other files not blocked | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | mutation queue / index ownership | |
| SAFE-07 | JSONL tail damage still reads prior good records | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| SAFE-08 | Migrations idempotent; failure preserves prior files; no duplicate on re-run | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| SAFE-09 | Indexes disposable: delete → rebuild from Vault; source wins on mismatch | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | derived index atomic write | |
| SAFE-10 | Disk-full / removable-drive yank / OneDrive conflict: originals preserved | RC fault drills | UNVERIFIED | — | Merged environmental faults |
| SAFE-11 | User Markdown not arbitrarily normalized/destroyed; app-less readability of md + key metadata | RC + sample vault | IMPLEMENTATION-PASS / UNVERIFIED-RC | vault format spec | |
| SAFE-12 | Vault copy to another PC opens; readonly file/dir fail safely | RC | UNVERIFIED | — | |
| SAFE-13 | Stale recovery draft vs fresh Vault precedence clear; late draft write vs delete no resurrection | Code + RC | UNVERIFIED | noted follow-up in CURRENT_STATE | |
| SAFE-14 | Work/Entity deactivate autosave flush asymmetry does not lose data | RC | UNVERIFIED | CURRENT_STATE follow-up | |
| SAFE-15 | Malformed user files never auto-deleted/auto-fixed | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| SAFE-16 | recovery/candidate/op-log never confused with user source-of-truth | Code review + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | system/ vs `.akasha/` | |

### 5.F Localization (blocking gate)

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| L10N-01 | Store-selected languages match Release binary (ko + en only) | Store + RC | BLOCKED | Store claims ko/en in [STEAM_RELEASE.md](STEAM_RELEASE.md) | Prior review failure history |
| L10N-02 | Major surfaces fully Korean when KO selected | Release RC audit | UNVERIFIED | arb `l10n/app_ko.arb` | |
| L10N-03 | Major surfaces fully English when EN selected | Release RC audit | HISTORICAL-PASS | [p1-english-ui-2026-07-12](../history/closure-2026-07/evidence/p1-english-ui-2026-07-12/README.md) chrome-only | Retest full surfaces on final RC |
| L10N-04 | Language change applies immediately or prompts restart | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | prefs dialog tests | |
| L10N-05 | Home, Settings, Search, Detail, Workbench, Store, Inventory, Theme Gallery translated | Release RC | UNVERIFIED | — | |
| L10N-06 | Dialogs, errors, confirms, empty/loading/tooltips translated | Release RC | UNVERIFIED | — | |
| L10N-07 | Commerce purchase/inventory/transaction strings translated; cancel/fail/indeterminate actionable in both languages | Release RC (sandbox OK) | UNVERIFIED | — | |
| L10N-08 | No leftover Korean in English resources; no user-facing hardcoded strings | Tooling + audit | IMPLEMENTATION-PASS / UNVERIFIED-RC | historical locale gate | Retest on RC |
| L10N-09 | Long English does not overflow critical controls | Release UI | UNVERIFIED | — | |
| L10N-10 | Dates/numbers/prices follow locale + Steam currency rules | RC + code | IMPLEMENTATION-PASS / UNVERIFIED-RC | price formatter tests | |
| L10N-11 | Store copy/capsules/screenshots language aligned; no unsupported language listed; Interface/Subtitles/Audio accurate | Steamworks | BLOCKED | — | |
| L10N-12 | Errors include user action | Release RC | UNVERIFIED | — | |

### 5.G Steam platform integration

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| STEAM-01 | Release/depot uses AppID `4677560`; depot omits `steam_appid.txt` | Depot manifest + RC | HISTORICAL-PASS | readiness R2 on `24240688`; packaging tests | Retest staged manifest on final RC |
| STEAM-02 | Library launch initializes Steam under correct AppID / user | Steam RC | BLOCKED | — | |
| STEAM-03 | User switch does not mix Inventories | Steam RC multi-user | UNVERIFIED | — | |
| STEAM-04 | Logout / offline transitions handled | Steam RC | UNVERIFIED | — | |
| STEAM-05 | Callback pump does not freeze UI; Overlay redraw idle-safe; API shutdown safe | Steam RC | HISTORICAL-PASS | readiness §2 design + sandbox run | Retest RC |
| STEAM-06 | Shift+Tab Overlay open/close; input not duplicated during Overlay; input restored after | Steam RC | HISTORICAL-PASS | `24240688` capability notes | Retest RC |
| STEAM-07 | Overlay disabled ⇒ purchase CTA blocked with guidance | Sandbox/RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | gateway/UI gates | |
| STEAM-08 | initialized · logged on · subscribed · Overlay · prices required before purchase CTA | Sandbox/RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | readiness R0 | |
| STEAM-09 | Software Overlay setting enabled + published in Steamworks | Steamworks | BLOCKED | checklist precondition | |
| STEAM-10 | Retired POC ItemDefs ignored at runtime; non-allowlisted ItemDefs rejected before native call | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | gateway + itemdef tests | |
| STEAM-11 | Steam SDK headers / import lib / `steam_api64.dll` version-coupled | Build audit | IMPLEMENTATION-PASS / UNVERIFIED-RC | readiness §2 | |
| STEAM-12 | Sanitized Steam diagnostics copyable; excludes SteamID/persona/credentials/abs paths/Vault body | Sandbox/RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | readiness R1 | |
| STEAM-13 | Publisher Web API key never shipped in app | Package scan | IMPLEMENTATION-PASS / UNVERIFIED-RC | packaging scripts | |
| STEAM-14 | Payments only via Steam Wallet; no external checkout bypass | Store + app audit | UNVERIFIED | — | |

### 5.H Commerce canonical requirements

Shared rules. Per-pack / per-theme **results** live in §7.

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| COM-ID-01 | Test vs production ItemDefs separated; code/docs/Steamworks IDs align (`40001`/`40002`/`40110–40112`/`41001–41003`/`41101–41103`/`40220`) | Schema + Steamworks | IMPLEMENTATION-PASS / UNVERIFIED-RC | `itemdefs_steamworks_upload.json` + tests | Remote publish seal BLOCKED |
| COM-ID-02 | Sale packs `store_hidden=false`; internal components `store_hidden=true` | Schema + Steamworks | IMPLEMENTATION-PASS / UNVERIFIED-RC | local JSON false for `40110–40112` | `40111/40112` remote verify BLOCKED |
| COM-PRICE-01 | Prices from Steam currency authority; no invented prices; hundredths only; no client FX | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | formatter + gateway | HISTORICAL: KRW prices on `24240688` |
| COM-PRICE-02 | Purchase CTA requires all three pack prices present | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-BUY-01 | Single click ⇒ single in-flight purchase; double-click safe | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | Case results §7 |
| COM-BUY-02 | Only `40110–40112` purchasable; raw `40001` not in Release UI; port rejects non-allowlist | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-BUY-03 | Success authority: StartPurchase → callback → checkout → ResultReady → fresh GetAllItems → **exact delta** (not button callback) | Sandbox RC | UNVERIFIED | design in readiness | HISTORICAL Overlay open for `40110` only |
| COM-BUY-04 | Cancel ⇒ balance delta 0 and retry allowed; fail ⇒ delta 0 | Sandbox RC | UNVERIFIED | checklist unchecked | |
| COM-BUY-05 | Non-zero order + transaction IDs recorded; Steamworks report correlatable | Sandbox RC | UNVERIFIED | — | |
| COM-BUY-06 | Missing exact delta ⇒ indeterminate (not silent success) | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-EX-01 | Theme exchange consumes exactly 500 of **one** selected currency; other currency unchanged; no mixed input | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | Cases §7 |
| COM-EX-02 | Stacked instances submit exact 500; entitlement only after fresh Inventory; owned theme not re-exchanged; duplicate click/retry safe | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-EX-03 | Offline last-known entitlement policy safe; network failure ≠ locked; preferred paid theme id retained with fallback theme | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-ECHO-01 | Timer is trigger only; Steam eligibility/window authoritative; offline does not start reward | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | Cases §7 |
| COM-ECHO-02 | Grants require fresh Echo +10 delta; native granted rows recorded; duplicate timer callbacks no double grant | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-FAIL-01 | Insufficient Astra/Echo: no inventory change | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-FAIL-02 | Offline-before-start: operation not started | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-FAIL-03 | Provider/callback/poll failure after acceptance ⇒ indeterminate; block further provider mutations; no retry until reconciled | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | Cases §7 |
| COM-FAIL-04 | Restart + second PC reconciliation establish durable state before retry | Steam RC | BLOCKED | needs PC2 | |
| COM-FAIL-05 | Refund / ownership change policy defined and evidenced vs Steam reports | Steamworks + RC | BLOCKED | — | |
| COM-SAFE-01 | Release hides Debug Consume/Reset, POC ItemDefs, sandbox switches, raw Astra purchase, test-only ops | Release binary audit | IMPLEMENTATION-PASS / UNVERIFIED-RC | flag defaults false | Must audit final IAP-on **and** rollback RC |
| COM-SAFE-02 | Free core features work without purchase; paid themes never block Vault access | Release RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| COM-REST-01 | Balances and entitlements survive app restart via Inventory | Steam RC | UNVERIFIED | — | Filled by §7 restart columns |
| COM-REST-02 | Same Steam account restores on another PC | Steam RC PC2 | BLOCKED | — | Filled by §7 PC2 columns |

### 5.I Store page parity

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| STORE-01 | Store features ⊆ sealed RC features; no future-as-present | Steamworks + RC | BLOCKED | Repo release-plan copy aligned; Steamworks store fields still pending sealed RC | |
| STORE-02 | Languages / OS / min specs match tested reality | Steamworks | BLOCKED | — | |
| STORE-03 | IAP / Astra / Echo / theme structure & prices described accurately when commerce live | Steamworks | BLOCKED | blocked on scope doc fix + RC | |
| STORE-04 | Local Vault / Markdown / Obsidian compatibility not overstated; absolute claims evidenced | Copy review | UNVERIFIED | — | |
| STORE-05 | ≥5 real RC screenshots at ≥1920×1080 16:9; no mockups-as-product; themes match ship set | Steamworks assets | UNVERIFIED | STEAM_RELEASE screenshot plan | |
| STORE-06 | Capsule shows readable AKASHA name/logo | Steamworks | UNVERIFIED | — | |
| STORE-07 | No external purchase links; privacy + support links work | Steamworks | UNVERIFIED | [privacy.md](privacy.md) | |
| STORE-08 | Mature Content Survey accurate; Coming Soon duration / release date honest | Steamworks | UNVERIFIED | Coming Soon posted (historical note) | |
| STORE-09 | Cloud support not claimed if unsupported; Overlay requirements documented for users | Steamworks + support doc | BLOCKED | depends CLOUD-01 | |
| STORE-10 | Echo limits/cadence match contract (10 min, +10, max 6 / window) | Copy vs contract | UNVERIFIED | [COMMERCE_CURRENCY_CONTRACT.md](COMMERCE_CURRENCY_CONTRACT.md) | |

### 5.J Build, update, rollback

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| BUILD-01 | Review BuildID set on intended branch; default carries the intended live build | Steamworks | OPERATOR-CONFIRMED | Upload receipt BuildID `24282729` / gitSha `5e95fefe` / receipt branch `commerce-sandbox` (**Artifact-verified**); default Set Live (**Operator-confirmed**) | Not CURRENT-RC-PASS; does not clear Commerce P0 or Overall No-Go |
| BUILD-02 | Password-protected internal branch exists for RC testing | Steamworks | HISTORICAL-PASS | `commerce-sandbox` narrative | Confirm still true |
| BUILD-03 | Acceptance uses Steam-downloaded build — not only dev-folder exe | Process | UNVERIFIED | readiness Gate A | |
| BUILD-04 | Release payload: no debug menus/test buttons; no API keys/secrets; no test vaults/logs; VC++ redist considered | Package scan + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | `prepare_steam_depot.ps1`, verify scripts | |
| BUILD-05 | Exe + DLL + Flutter assets present; PDB excluded; `steam_appid.txt` excluded; full SHA-256 manifest | Staging | HISTORICAL-PASS | `24240688` 97 files | Retest final stage |
| BUILD-06 | Personal/repo path & credential content scan passes | Staging scripts | IMPLEMENTATION-PASS / UNVERIFIED-RC | binary payload scan (CURRENT_STATE) | |
| BUILD-07 | Version / logs / Steam build description aligned | RC | BLOCKED | needs sealed identity | |
| BUILD-08 | Update preserves settings + Vault; mid-run update safe; migration failure recoverable | Steam RC update drill | UNVERIFIED | — | |
| BUILD-09 | Rollback to prior stable BuildID rehearsed; rollback does not wipe Inventory; CTA off on rollback RC | Steamworks drill | BLOCKED | REL-SCOPE-03 | |
| BUILD-10 | Patch notes prepared; update test procedure documented | Docs | UNVERIFIED | — | |

### 5.K Errors, privacy, performance (P0 subset)

| ID | Requirement | Verify | Status | Evidence | Notes / retest |
|---|---|---|---|---|---|
| ERR-01 | Loading/save success/failure visible; failures not hidden; local vs network distinguished; actionable copy; no raw stack traces | Release RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| ERR-02 | Empty states for empty vault/search/collections | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| ERR-03 | Registry failure still allows local vault use | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | production registry is bundled | |
| ERR-04 | Inventory checking vs offline vs not-owned distinguished; cancelled/failed/rejected/indeterminate distinguished; accepted-but-unknown not treated as safe failure | Sandbox/RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | commerce UI states | |
| ERR-05 | Error reports exclude persona, SteamID, Vault body, absolute sensitive paths | Diagnostics audit | IMPLEMENTATION-PASS / UNVERIFIED-RC | STEAM-12 | |
| PRIV-01 | Data location explained; no vault upload to developer servers; Steam platform data per Valve policy | Privacy + store | IMPLEMENTATION-PASS / UNVERIFIED-RC | [privacy.md](privacy.md) (Commerce-inclusive IAP section) | Store-page privacy link still needs sealed-RC check |
| PRIV-02 | No unnecessary admin/broad permissions; no analytics without notice (v1: none claimed) | Audit | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| PRIV-03 | Fonts/images/icons/registry poster rights reviewed for ship | Legal review | UNVERIFIED | artwork provenance docs | |
| PRIV-04 | Free core without purchase; themes don’t gate Vault | Release RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | Cross-ref COM-SAFE-02 | — |
| PERF-01 | Typical vault startup acceptable; search typing stays responsive; no full-vault rescan per keystroke/nav | RC + tests | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| PERF-02 | Incremental index updates; no unbounded memory from images; bounded logs | RC | UNVERIFIED | — | |
| PERF-03 | Registry 10,048 / 1,713 shards basic browse OK in Release | Local/RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | CURRENT_STATE Phase 2 Release note | Retest sealed RC |
| PERF-04 | Steam callback pump / Overlay redraw / large Inventory do not freeze UI | Steam RC | UNVERIFIED | related STEAM-05 | |

**P0 canonical row count (this section): 142**

---

## 6. P1 / P2 Matrix

### 6.A P1

| ID | Requirement | Verify | Status | Evidence | Notes |
|---|---|---|---|---|---|
| SRCH-01 | Title search works; KO/EN; case-insensitive; Unicode normalization does not split same title | Release + tests | IMPLEMENTATION-PASS / UNVERIFIED-RC | search index | |
| SRCH-02 | Type filters; empty results messaging; open result → record | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| SRCH-03 | Large result sets don’t hang; no per-keystroke full vault rescan | RC | UNVERIFIED | PERF-01 overlap | |
| SRCH-04 | Recents / favorites / collections OK; back-stack Home↔Sidebar↔Search↔Detail natural | Release UI | UNVERIFIED | — | |
| SRCH-05 | Deleted / broken links don’t crash | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| SRCH-06 | Index missing/corrupt has recovery path; Registry search ≠ user vault search confusion | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| SRCH-07 | Graph/canvas only store-claimed if basically usable; experimental not marketed as finished | Store + RC | N/A | Default: not marketed as finished feature | Reopen as P0 if store claims graph |
| BAK-01 | User can copy whole Vault; backup method explained; personal data warning | Docs + RC | UNVERIFIED | — | |
| BAK-02 | In-app backup (if any) restore-verified; failed export not marked success; overwrite/merge/cancel clear | RC | UNVERIFIED | `vault_backup_exporter_test` partial | |
| BAK-03 | Version compatibility checks; future vault not force-overwritten by older app; leave-with-data possible | RC | UNVERIFIED | — | |
| BAK-04 | External editor edits re-apply; backup logs not overly sensitive; file count/hash verification when offered | RC | UNVERIFIED | — | |
| SET-01 | Language/theme change persists; free vs owned paid themes distinct; locked state clear | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | theme gallery / commerce controller | |
| SET-02 | Steam failure does not wipe paid theme preference; entitlement-unknown ⇒ safe fallback theme | Tests + RC | IMPLEMENTATION-PASS / UNVERIFIED-RC | COM-EX-03 | |
| SET-03 | Commerce-active Release shows purchase/exchange UI; rollback/IAP-off hides it | Both RCs | BLOCKED | needs dual RC | |
| SET-04 | UI scale/font usable; reset settings ≠ delete Vault; confirm before reset; cache clear ≠ wipe Vault | Release UI | UNVERIFIED | — | |
| SET-05 | Version/build visible; OSS licenses visible; Steam connection/inventory status visible; non-sensitive diagnostics copyable | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | build identity widgets | |
| UI-01 | Min resolution + 100/125/150/200% DPI; small/wide windows usable; sidebar/preview stable | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | UX responsive/golden tests | Retest RC |
| UI-02 | Window size/position restore; off-screen recovery after monitor unplug | Release UI | UNVERIFIED | — | |
| UI-03 | Keyboard access, tab order, Enter/Esc/Delete consistency; IME OK; copy/paste/undo | Release UI | UNVERIFIED | — | |
| UI-04 | Rapid multi-click doesn’t duplicate records/transactions; modal blocks background | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | COM-BUY-01 | |
| UI-05 | Destructive/purchase/exchange confirms; F11/Esc; custom chrome min/max/close stable | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | UX-6 notes | |
| UI-06 | Theme contrast/readability; reduced motion consistent if offered | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | theme regression matrix | |
| ERR-P1-01 | Long work doesn’t look hung; identical error not infinite-looping; fatal path offers logs | Release UI | UNVERIFIED | — | |
| PRIV-P1-01 | External link purposes clear; local-app account-deletion N/A explained | Docs | UNVERIFIED | — | |
| PRIV-P1-02 | Steam trade diagnostics exclude secrets (see STEAM-12) | Audit | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| PERF-P1-01 | Background indexing allows edit; no duplicate concurrent indexing; long-run leak check; 10k+ record vault smoke | RC | UNVERIFIED | — | |
| PERF-P1-02 | Don’t market unsupported hundred-thousand / million scales | Store copy | UNVERIFIED | STORE-04 | |
| SUP-01 | Version/build; open logs; no vault bodies in logs; diagnostics export with path redaction | Release UI | IMPLEMENTATION-PASS / UNVERIFIED-RC | — | |
| SUP-02 | Bug report path; support email or Steam discussions; FAQ; backup/restore help; app-down recovery | Support surface | UNVERIFIED | — | |
| SUP-03 | Known issues location; launch feedback triage rules | Process | UNVERIFIED | — | |
| SUP-04 | Steam diagnostics include phase/EResult/order/trans/correlation; rotating logs; indeterminate & refund support playbooks; Overlay-off & offline behavior docs | Support + sandbox | IMPLEMENTATION-PASS / UNVERIFIED-RC | readiness §6 | Playbooks still thin |

**P1 canonical row count: 31**

### 6.B P2

| ID | Requirement | Verify | Status | Evidence | Notes |
|---|---|---|---|---|---|
| CLOUD-P2-01 | Cloud sync conflict preservation / multi-PC simultaneous edit | — | **N/A** (pending CLOUD-01 confirm) | — | Becomes N/A after Cloud=off confirmed; if Cloud ever enabled, reopen as P0 |
| CLOUD-P2-02 | Settings-only sync scope (if ever used) clearly bounded | — | **N/A** (pending) | — | |
| CLOUD-P2-03 | Machine UI prefs vs user records separation under Cloud | — | **N/A** (pending) | — | |
| SCALE-P2-01 | Marketing non-claims for post-v1 discovery scale already covered by STORE/PERF | Copy | N/A | — | Traceability placeholder |
| AGENT-P2-01 | Agent vault write gateway beyond v1 dogfood | — | N/A | — | Deferred product surface |

**P2 canonical row count: 5**

---

## 7. Commerce transaction cases

Link each case to canonical IDs. **Do not** duplicate shared rules here—only case results.

### Case inventory

| Kind | Count | IDs |
|---|---:|---|
| Executable result rows (§7.B–§7.E) | **29** | All `CASE-*` table rows below |
| Unique executable CASE IDs | **29** | Same set as result rows (1:1) |
| Family shorthand in prose (not cases) | — | Phrases like “theme CASE-EX family” or “Echo CASE-ECHO family” refer to the rows above; they are **not** extra CASE IDs and **not** missing tests |

Shared purchase/exchange/echo/failure **rules** live under canonical `COM-*` (§5.H). Suites `S-BUY` / `S-FAULT` orchestrate cases; they are not CASE IDs.

> Earlier draft tallies that reported “32 CASE IDs / 29 rows” counted three prose family stems as IDs. That was incorrect. **Authoritative count: 29 CASE IDs = 29 result rows.**

### 7.A Historical incident (not current FAIL)

| Topic | Record |
|---|---|
| Symptom | `40110–40112` with `store_hidden=true` → `SteamInventoryStartPurchaseResult_t` `k_EResultFail`, transaction ID `0` |
| Classification | **Historical failure** · root cause identified (sale-bundle store visibility) |
| A/B | `40110.store_hidden true→false` opened Steam checkout Overlay (BuildID `24240688`) |
| Current local candidate | `40110–40112` have `store_hidden=false`; `40001` remains `store_hidden=true` |
| Current acceptance | `40110` Overlay = **HISTORICAL-PASS** only · `40111`/`40112` remote publish+checkout = **BLOCKED** · cancel/complete/delta still **UNVERIFIED** |

### 7.B Astra pack cases

| Case ID | ItemDef | Expected delta | Cancel | Complete | Exact delta | Restart | PC2 | Linked canonical |
|---|---|---|---|---|---|---|---|---|
| CASE-ASTRA-40110 | `40110` | +500 `40001` | UNVERIFIED | UNVERIFIED | UNVERIFIED | UNVERIFIED | BLOCKED | COM-BUY-*, COM-REST-*, COM-FAIL-* |
| CASE-ASTRA-40111 | `40111` | +1000 `40001` | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | same + COM-ID-02 remote |
| CASE-ASTRA-40112 | `40112` | +2500 `40001` | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | same + COM-ID-02 remote |

Per case, when executed on sealed RC, also record: order ID, transaction ID, correlation handle, Steamworks report pointer (no SteamID/persona).

### 7.C Theme exchange cases

| Case ID | Wrapper | Entitlement | Currency | Amount | Result | Linked canonical |
|---|---|---|---|---|---|---|
| CASE-EX-SAKURA-ASTRA | `41101` | `41001` | Astra `40001` | 500 | UNVERIFIED | COM-EX-* · COM-REST-* |
| CASE-EX-SAKURA-ECHO | `41101` | `41001` | Echo `40002` | 500 | UNVERIFIED | COM-EX-* · COM-REST-* |
| CASE-EX-AMETHYST-ASTRA | `41102` | `41002` | Astra | 500 | UNVERIFIED | COM-EX-* |
| CASE-EX-AMETHYST-ECHO | `41102` | `41002` | Echo | 500 | UNVERIFIED | COM-EX-* |
| CASE-EX-NOCTURNE-ASTRA | `41103` | `41003` | Astra | 500 | UNVERIFIED | COM-EX-* |
| CASE-EX-NOCTURNE-ECHO | `41103` | `41003` | Echo | 500 | UNVERIFIED | COM-EX-* |

### 7.D Echo playtime cases

| Case ID | Scenario | Result | Linked canonical |
|---|---|---|---|
| CASE-ECHO-BEFORE | Before 10 eligible minutes → no-grant | UNVERIFIED | COM-ECHO-* |
| CASE-ECHO-G1 | First eligible → +10 | UNVERIFIED | COM-ECHO-* |
| CASE-ECHO-G2 | Grant 2 → +10 | UNVERIFIED | COM-ECHO-* |
| CASE-ECHO-G3 | Grant 3 → +10 | UNVERIFIED | COM-ECHO-* |
| CASE-ECHO-G4 | Grant 4 → +10 | UNVERIFIED | COM-ECHO-* |
| CASE-ECHO-G5 | Grant 5 → +10 | UNVERIFIED | COM-ECHO-* |
| CASE-ECHO-G6 | Grant 6 → +10 | UNVERIFIED | COM-ECHO-* |
| CASE-ECHO-G7 | Seventh in window → no-grant | UNVERIFIED | COM-ECHO-* |
| CASE-ECHO-RESTART | Restart preserves grant count + balance | UNVERIFIED | COM-ECHO-* · COM-REST-01 |
| CASE-ECHO-POLLFAIL | Trigger accepted, polling fails → indeterminate | UNVERIFIED | COM-FAIL-03 |
| CASE-ECHO-RECON | Restart reconciliation before retry | UNVERIFIED | COM-FAIL-03/04 |

### 7.E Failure / recovery cases

| Case ID | Scenario | Result | Linked canonical |
|---|---|---|---|
| CASE-FAIL-OFFLINE | Offline before start | UNVERIFIED | COM-FAIL-02 |
| CASE-FAIL-PROVIDER | Provider failure | UNVERIFIED | COM-FAIL-03 |
| CASE-FAIL-CALLBACK | Callback failure | HISTORICAL-PASS (fail path evidenced on hidden packs) / UNVERIFIED on final RC | COM-FAIL-03 |
| CASE-FAIL-POLL | Poll failure after acceptance | UNVERIFIED | COM-FAIL-03 |
| CASE-FAIL-NODELTA | Callback OK but expected delta missing → indeterminate | UNVERIFIED | COM-BUY-06 · COM-FAIL-03 |
| CASE-FAIL-INDET-BLOCK | Indeterminate blocks all provider mutations | IMPLEMENTATION-PASS / UNVERIFIED-RC | COM-FAIL-03 |
| CASE-FAIL-RESTART-RECON | Restart reconciliation | UNVERIFIED | COM-FAIL-04 |
| CASE-FAIL-PC2-RECON | Second-PC reconciliation | BLOCKED | COM-FAIL-04 · COM-REST-02 |
| CASE-FAIL-REFUND | Refund / ownership change vs app snapshot | BLOCKED | COM-FAIL-05 |

---

## 8. Manual RC scenario suites

Suites map to canonical IDs (not extra Pass/Fail votes). Execute on **sealed Steam-downloaded RC**.

### Suite S-NEW — New user

Install → Library launch → new Vault → add work → add entity → link → journal → search → quit → relaunch → data OK → KO path → EN path → free theme change → paid Theme Store entry → Steam connection status.
**Maps:** INST-* · VAULT-* · WORK-* · ENT-* · JRN-* · SRCH-* · L10N-* · SET-01 · STEAM-* · COM-SAFE-02

### Suite S-EXISTING — Existing user

Prior Vault connect → migration → records + custom YAML kept → edit → external md edit → re-recognize → delete indexes → rebuild → update → rollback preserves Vault.
**Maps:** VAULT-04 · WORK-05 · JRN-05 · SAFE-* · BUILD-08/09

### Suite S-FAULT — Fault injection

Force-kill during save · readonly file/dir · disk full · moved Vault · yanked USB · OneDrive conflict · Registry N/A · Steam offline · Overlay off · corrupt YAML · JSONL tail damage · conflict copies · leftover staging · stale recovery draft.
**Expect:** originals preserved; actionable errors; no crash.
**Maps:** SAFE-* · INST-09/10 · STEAM-07 · ERR-*

### Suite S-BUY — Purchaser

Prices → each pack cancel+complete → exact Astra deltas → restart → PC2 → offline/provider/poll/indeterminate → six theme exchanges → Echo window → refund check → rollback RC CTA off + Inventory read-only.
**Maps:** §7 all cases · COM-* · REL-SCOPE-03 · BUILD-09

---

## 9. Steamworks configuration snapshot

| Setting | Expected for v1 | Current evidence | Status |
|---|---|---|---|
| AppID | `4677560` | Docs + scripts | documented |
| Inventory Service | Enabled | readiness R3 narrative | HISTORICAL / reconfirm |
| Asset Server | Configured | readiness R3 | HISTORICAL / reconfirm |
| Item visibility | Private (partner) until release policy | readiness R3 | HISTORICAL / reconfirm |
| Overlay for Software | Enabled + **Published** | checklist precondition | BLOCKED (publication evidence) |
| ItemDefs remote vs local SHA | Match LF canonical local `9653df26…35ff3` | Published Steamworks bytes SHA **UNKNOWN**; local candidate only | BLOCKED |
| `40110–40112` store_hidden | `false` | local false; remote 40111/12 pending per active docs | BLOCKED |
| `40001` store_hidden | `true` | local JSON | IMPLEMENTATION-PASS (candidate) |
| Steam Cloud for Vault | **Off / unsupported** | not confirmed in console from this audit | BLOCKED (`CLOUD-01`) |
| Store IAP disclosure | Accurate when commerce ships | Repo plan aligned; Steamworks store pending sealed RC | BLOCKED |
| Default branch BuildID | Live BuildID recorded; Overall Go still open | `24282729` @ `default` (**Operator-confirmed**); upload receipt **Artifact-verified** | OPERATOR-CONFIRMED (not Overall Go) |

---

## 10. Evidence ledger

| Ledger ID | Kind | Pointer | May support |
|---|---|---|---|
| EV-BASE-SHA | Baseline | Git `8f4cf35a` clean `main` | IMPLEMENTATION-* @ baseline |
| EV-TESTS-ROOT | Auto | `flutter test` **1273** · analyze **0** ([CURRENT_STATE.md](CURRENT_STATE.md)) | IMPLEMENTATION-PASS only |
| EV-TESTS-COM | Auto | commerce domain **17** · backend **18** · `test/steam_inventory_commerce_gateway_test.dart` | IMPLEMENTATION-PASS |
| EV-ITEMDEF-LOCAL | Artifact | `itemdefs_steamworks_upload.json` LF/git-canonical SHA-256 `9653df2609d9ec88dcc7b8b18c0e59c149221113a5c45360570c96dd67235ff3` (CRLF `Get-FileHash` `BB20770F…E88E` is non-authoritative; same content) | COM-ID-* candidate |
| EV-HIST-24015480 | Historical BuildID | [STEAM_RELEASE.md](STEAM_RELEASE.md) upload log | HISTORICAL-PASS packaging/no-IAP upload |
| EV-HIST-24240688 | Historical BuildID | [STEAM_SERVICE_RELEASE_READINESS.md](STEAM_SERVICE_RELEASE_READINESS.md) | HISTORICAL-PASS prices, depot, Overlay A/B |
| EV-HIST-HIDDEN-FAIL | Historical failure | sandbox checklist §1 | root-cause record — **not current FAIL** |
| EV-HIST-40110-AB | Historical PASS | `40110` Overlay open after `store_hidden=false` | HISTORICAL-PASS only |
| EV-HIST-EN-UI | Historical UI | [p1-english-ui-2026-07-12](../history/closure-2026-07/evidence/p1-english-ui-2026-07-12/README.md) | HISTORICAL-PASS L10N chrome |
| EV-HIST-SAFE-GATE | Historical gate | [P0_RECOVERABLE_VAULT_WRITE_GATE.md](../history/closure-2026-07/P0_RECOVERABLE_VAULT_WRITE_GATE.md) | IMPLEMENTATION lineage |
| EV-CHECKLIST-OPEN | Open matrix | [SANDBOX_TRANSACTION_CHECKLIST.md](steam_inventory_production/SANDBOX_TRANSACTION_CHECKLIST.md) §2–5 all `[ ]` | UNVERIFIED/BLOCKED commerce |
| EV-EXT-RELEASE | External | [`AKASHA_Product/release-evidence/steam`](../../AKASHA_Product/release-evidence/steam/README.md) — receipt + pre-upload seal archived (**REL-EVID-01**; archive present ≠ CURRENT-RC-PASS / Commerce Go) | Identity evidence root present |
| EV-RC-SEAL | Live IAP-on identity (partial) | Git `5e95fefe` · BuildID `24282729` · exe `3C387A21…6069` · pre-upload manifest `C92B7E33…DF85` · files `1756` / bytes `70978364` · version `1.0.0+1` (**Artifact-verified** seal + receipt); default Set Live (**Operator-confirmed**) | Identity / BUILD-01 only — **not** blanket CURRENT-RC-PASS |
| EV-UPLOAD-24282729 | SteamPipe receipt | [`build-24282729/upload_receipts/20260719T115647Z.json`](../../AKASHA_Product/release-evidence/steam/build-24282729/upload_receipts/20260719T115647Z.json) (app `4677560`, depot `4677561`, branch `commerce-sandbox`, gitSha `5e95fefe`, buildId `24282729`) | BUILD-01 Artifact-verified half |

---

## 11. Traceability appendix

Master checklist §5.x → Matrix IDs. Every master bullet is covered by at least one ID or an explicit Suite/Case.

| Master section | Coverage strategy | Primary Matrix IDs |
|---|---|---|
| 5.1 Install/launch/exit | Consolidated | INST-01…12 · SAFE-01 · STEAM-01/12 |
| 5.2 First run / Vault | Consolidated | VAULT-01…10 |
| 5.3 Works | Consolidated CRUD + invariants | WORK-01…06 |
| 5.4 Entity | Consolidated | ENT-01…05 |
| 5.5 Journal/timeline | Consolidated | JRN-01…06 |
| 5.6 Search/navigation | P0 critical in suites; detail P1 | SRCH-01…07 · S-NEW |
| 5.7 Data safety | Consolidated environmental rows | SAFE-01…16 |
| 5.8 Import/export/backup | P1 | BAK-01…04 |
| 5.9 Settings | P1 + commerce cross-ref | SET-01…05 · COM-EX-03 |
| 5.10 Localization | P0 gate | L10N-01…12 |
| 5.11 UI/window/input | P1 (+ Overlay→STEAM) | UI-01…06 · STEAM-06/07 |
| 5.12 Status/errors | P0 + P1 | ERR-01…05 · ERR-P1-01 · COM-FAIL-01…05 |
| 5.13 Performance | P0 subset + P1 | PERF-01…04 · PERF-P1-01 · PERF-P1-02 |
| 5.14 Privacy/legal | P0 + P1 | PRIV-01…04 · PRIV-P1-01 · PRIV-P1-02 · STEAM-13/14 |
| 5.15 Steam basics | P0 | STEAM-01…14 · INST-12 |
| 5.16 Commerce | Canonical + §7 cases | COM-ID/PRICE/BUY/EX/ECHO/FAIL/SAFE/REST · all 29 CASE-* rows |
| 5.17 Steam Cloud | P0 policy + P2 N/A pending confirm | CLOUD-01 · CLOUD-P2-01…03 |
| 5.18 Store parity | P0 | STORE-01…10 · REL-SCOPE-01 · L10N-11 |
| 5.19 Build/update/rollback | P0 | BUILD-01…10 · REL-SCOPE-03 · COM-SAFE-01 |
| 5.20 Support/diagnostics | P1 | SUP-01…04 · STEAM-12 |
| 5.21 End-to-end scenarios | Suites (no duplicate scoring) | S-NEW · S-EXISTING · S-FAULT · S-BUY |
| Deferred / non-train | P2 placeholders | SCALE-P2-01 · AGENT-P2-01 |

### Dedup examples (master → single canonical)

| Master duplicates | Canonical |
|---|---|
| Overlay input isolation (5.11 + 5.15) | STEAM-06 |
| Offline local core (5.1 + 5.15 + 5.16) | INST-09 + COM-FAIL-02 |
| Direct exe / RestartAppIfNecessary (5.1 + 5.15) | INST-12 |
| Debug/POC/Consume/Reset hidden (5.16 + 5.19) | COM-SAFE-01 |
| Restart + PC2 inventory (5.16 + 5.21) | COM-REST-01/02 + §7 columns |
| Actionable errors (5.10 + 5.12) | L10N-12 + ERR-01 |

### Traceability coverage statement

- Master sections **5.1–5.21**: **100%** mapped (canonical, case, suite, or N/A/deferred).
- Commerce master bullets that repeat per pack/theme: covered once in **COM-*** + results in **CASE-***.
- Deferred invite Echo / custom backend: **N/A** via release profile (not Commerce N/A abuse—explicitly out of train).

---

## 12. Go/No-Go summary

### Counts @ REL-DOC-01 (`5e95fefe` live identity; authoring baseline `8f4cf35a`)

| Metric | Count |
|---:|---:|
| Canonical requirements (P0+P1+P2) | **178** |
| P0 | **142** |
| P1 | **31** |
| P2 | **5** |
| Commerce cases (§7, non-canonical) | **29** unique CASE IDs = **29** result rows |
| Manual suites | **4** (`S-NEW`, `S-EXISTING`, `S-FAULT`, `S-BUY`) |
| CURRENT-RC-PASS | **0** |
| IMPLEMENTATION-PASS (incl. `/ UNVERIFIED-RC`) | **87** |
| HISTORICAL-PASS | **7** |
| OPERATOR-CONFIRMED | **1** (`BUILD-01`) |
| UNVERIFIED | **60** |
| BLOCKED | **17** |
| FAIL | **0** |
| N/A | **6** (all P1/P2; **P0 N/A = 0**; **COM-* N/A = 0**) |

> Status tallies count **canonical rows only** (§5–§6).
> **Go PASS math uses CURRENT-RC-PASS only.** IMPLEMENTATION-PASS, HISTORICAL-PASS, and OPERATOR-CONFIRMED never count toward Go.
> Case rows (§7) are tracked separately and must all reach CURRENT-RC-PASS (or BLOCKED cleared) before commerce Go.
> With CURRENT-RC-PASS = 0, overall verdict remains **No-Go**.
> Default Set Live for BuildID `24282729` does **not** change this Go math.

### Active FAIL

None. Repository release-scope conflict (`REL-SCOPE-01`) closed; remaining work is Steam-installed CURRENT-RC / Steamworks / rollback evidence.

### Top blockers (execution order)

1. Steam-installed CURRENT-RC Commerce P0 on BuildID `24282729` (identity partial; evidence open)
2. CLOUD-01 — Steamworks Cloud setting confirm
3. STEAM-09 — Overlay Software publish evidence
4. COM-ID-02 / CASE-ASTRA-40111/40112 — remote `store_hidden=false` + checkout
5. CASE-ASTRA-40110 cancel/complete/exact +500
6. CASE-ASTRA-40111 cancel/complete/exact +1000
7. CASE-ASTRA-40112 cancel/complete/exact +2500
8. COM-REST-01 — restart inventory
9. COM-REST-02 / CASE-FAIL-PC2-RECON — second PC
10. Theme exchanges CASE-EX-SAKURA-ASTRA … CASE-EX-NOCTURNE-ECHO (6 paths)
11. Echo window CASE-ECHO-BEFORE … CASE-ECHO-RECON
12. Failure/recovery CASE-FAIL-OFFLINE … CASE-FAIL-REFUND
13. BUILD-09 / REL-SCOPE-03 — IAP-off rollback rehearsal from source `0ce9e052` (CTA off, Inventory read-only; BuildID still BLOCKED)
14. L10N-01…07 — full KO/EN RC audit
15. STORE-01…03 — store parity vs live RC
16. BUILD-01 — default Set Live for `24282729` — **OPERATOR-CONFIRMED** (not Overall Go)
17. COM-SAFE-01 — Release binary audit on Steam-installed IAP-on + rollback
18. EV-EXT-RELEASE — evidence root archived at `AKASHA_Product/release-evidence/steam` (**REL-EVID-01**; archive ≠ CURRENT-RC-PASS / Commerce Go)
19. Production IAP flag — **landed** (`true` on live train); does not replace items 1–15/17–18 or raise CURRENT-RC-PASS

### Go criteria (restate)

- P0 canonical: **100% CURRENT-RC-PASS** (justified N/A only if Applicability locks it out; none today)
- FAIL **0** · BLOCKED **0**
- **Only CURRENT-RC-PASS counts as Go PASS** — IMPLEMENTATION-PASS / HISTORICAL-PASS / OPERATOR-CONFIRMED / UNVERIFIED do not
- Historical BuildIDs `24240688` / `24015480` are never final-RC Commerce evidence
- Live BuildID `24282729` is the current default identity but still requires CURRENT-RC case evidence
- All 29 §7 commerce CASE rows CURRENT-RC-PASS on Steam-installed RC (+ PC2 where required)
- Suites S-NEW / S-EXISTING / S-FAULT / S-BUY executed on Steam-downloaded RC
- Data-loss **0** on fault suite
- Debug/Sandbox/Consume/Reset/POC absent on Release
- Store languages/features/images match RC
- IAP-off rollback RC rehearsed from source `0ce9e052` (CTA off; Inventory read-only preserved; BuildID sealed)
- Steamworks ItemDef publication SHA sealed (currently UNKNOWN in repository)

### Scope-alignment note

Repository release-scope docs were aligned to Commerce-inclusive v1 (`0ce9e052`), then Production IAP enablement landed on `5e95fefe` and uploaded as BuildID `24282729`. Default Set Live is Operator-confirmed. None of these steps alone promote Commerce rows to CURRENT-RC-PASS or change Overall **No-Go**.

---

## Document control

| Item | Value |
|---|---|
| Matrix path | `docs/active/STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md` |
| Authoring baseline | `8f4cf35a` (Matrix creation); ItemDef hash fix `94905aab`; scope align `0ce9e052`; IAP enable `5e95fefe` |
| Sandbox worktree | Untouched by this revision |
| IAP flag | Live train `true` (Overall Go still No-Go; CURRENT-RC-PASS still 0) |
| Changelog | 2026-07-20 — **REL-DOC-01**: record default-live identity `24282729` / `5e95fefe` with Artifact-verified vs Operator-confirmed split; BUILD-01 → OPERATOR-CONFIRMED; BLOCKED 18→17; CURRENT-RC-PASS 0; overall No-Go unchanged |
