# Steam Release Blocker Closure

> **Status:** Active development track (2026-07-12)  
> **Predecessor:** [ARCHITECTURE_CLOSURE_AUDIT.md](ARCHITECTURE_CLOSURE_AUDIT.md) — **Architecture Closure declared**  
> **Ops companion:** [STEAM_RELEASE.md](STEAM_RELEASE.md)  
> **Rule:** No new generic architecture audits. No SA-05 / §7 ADR / Universal Record / Relationship Assertion.  
> **Fix rule:** Former S1 items live here as a **stability checklist**. Fix only when dogfood or ship is blocked, in small units.

---

## Track goal

Close Steam review / payment / localization blockers so AKASHA can ship and dogfood without pretending unfinished commerce exists.

---

## Priority order (this track)

| # | Work | State |
|---|---|---|
| **P1** | English localization applies to all major UI in a real build | **In progress** — switch path verified in code; full UI sweep checklist below |
| **P2** | Exact English switch path + resubmission Notes for Steam reviewers | **Draft ready** (§Reviewer English path) |
| **P3** | Unimplemented IAP stated clearly in docs + `FeatureFlags` | **Done in this slice** — `steamInAppPurchasesEnabled = false` |
| **P4** | Pearl / Black Pearl currency contract + product · unlock · donation flows | **Design pending** — do not ship UI as live purchase |
| **P5** | Steam Wallet → confirm → grant → consume ledger → no double-grant → refund/cancel → GetReport reconciliation (one verifiable flow) | **Not started** — blocked until P3/P4 contracts exist |
| **P6** | Non-sandbox test purchase + GetReport sample + test account pack for resubmission | **Not started** — after P5 |

**Hard rule:** Do **not** mark Store Page or in-app UI as having IAP while the Steam payment flow is incomplete. Prefer temporarily clearing Store “In-App Purchases” until P5+P6 are green.

---

## Architecture Closure (accepted)

| Gate | Result |
|---|---|
| S0 structural (C-01–C-05) | **Closed** — Bounded Home Read Closure |
| Architecture Closure | **Declared 2026-07-12** |
| Verification | `flutter analyze --no-pub` **0** · `flutter test --no-pub` **930** |
| Next architecture audits | **Stopped** — reopen only for a concrete ship-blocking defect |

Former audit **S1** items are **not** an architecture slice. They are checklist rows below.

---

## Steam stability checklist (former S1)

Fix **only** when dogfood / review / large-vault ship friction is confirmed.

| ID | Item | Trigger to fix | Default |
|---|---|---|---|
| S-01 | Search uses in-memory full lists / entity vault scan | Search unusable on large vault in dogfood | Defer |
| S-02 | `EntityVaultLoader.findByEntityId` full `entities/` fallback | Open misses hang multi-second | Defer |
| S-03 | Watch fingerprint polls all `.md` stats | CPU heat on fallback watch | Defer |
| S-04 | `setVaultPath` silent `ensureIndex` hitch | First-open freeze on large vault | Defer |
| S-05 | Auto-archive `loadAllItems` | Auto-archive path used and slow | Defer |
| S-06 | Stale `.akasha/candidates` comments | Maintainer confusion only | Opportunistic |
| S-07 | `catalogContributions=true` E2E | Contribution loop claimed in store/dogfood | Dogfood |
| S-08 | Timeline loaders while `showTimeline=false` | Accidental enable | Keep OFF |

---

## IAP / commerce status (authoritative for ship)

| Surface | Current truth |
|---|---|
| `FeatureFlags.steamInAppPurchasesEnabled` | **`false`** — no live Steam IAP |
| `EntitlementService.purchaseCosmetic` | Stub; returns `false`; no Steamworks microtxn |
| Themes | Free / unlocked for v1; no locked IAP picker in ship UI |
| Store Page “In-App Purchases” | **May be cleared** until P5+P6 complete |
| Pearl / Black Pearl | **Not implemented** — design under P4 before any grant path |

Do not resubmit claiming purchases exist until P5 is verifiable end-to-end.

---

## Reviewer English path (exact)

Primary path (works without vault linked):

1. Launch AKASHA (Windows build under review).
2. Press **Esc** on the home shell → opens **Preferences** (`appPreferencesTitle`).
3. Under **Display language** / **표시 언어**, choose **English**.
4. UI locale applies immediately (persisted via `CatalogLocalePreferences`).

Alternate path:

1. Open **Vault settings** from the app bar / Preferences → Vault settings.
2. Same **Display language** dropdown → **English**.

### Resubmission Notes (English draft)

```text
Language: The app supports Korean and English.

To switch to English during review:
1. Launch AKASHA.
2. Press Esc to open Preferences (or open Vault settings from the toolbar).
3. Set "Display language" to English.

In-App Purchases: Not implemented in this build.
FeatureFlags.steamInAppPurchasesEnabled is false. There is no Steam Wallet /
microtransaction purchase flow, no Pearl currency grant, and no paid unlock UI.
All current themes are free. Please treat the app as free with no IAP for this
submission. Store "In-App Purchases" may be unset until a complete Steam payment
+ GetReport reconciliation build is ready.
```

Korean mirror (internal):

```text
언어: 한국어·영어 지원.
영어 전환: Esc → Preferences → Display language → English
(또는 볼트 설정 내 동일 드롭다운).
인앱 구매: 본 빌드 미구현. steamInAppPurchasesEnabled=false.
펄/Steam Wallet 결제 없음. 테마는 전부 무료. IAP 완성 전 Store IAP 표시 제거 가능.
```

---

## P1 — English major-UI verification checklist

Run against a **Release** build with locale **English**. Mark each row after visual check.

| Area | Expected English chrome | Status |
|---|---|---|
| Preferences (Esc) | Title, language, scale, theme, vault, quit/close | Code + widget test cover dialog strings |
| Vault settings | Language, path, backup, trash, close | l10n wired; fallbacks Korean if l10n null |
| Home dashboard / app bar | Tooltips, sync, vault settings | Mostly l10n + KO fallbacks |
| Browse / search chrome | Labels, empty states | Sweep needed |
| Work detail / Workbench | Info panel, save, tabs | Sweep needed |
| Personal library / collection dialogs | Create/edit/delete | Sweep needed |
| Sidebar | Library names, prompts | l10n wired |
| Theme picker | Free themes only; no purchase lock copy | Confirm no IAP lock UI |
| Error / SnackBar paths | Prefer l10n; KO fallback only if `l10n == null` | Sweep needed |

**Method:** Set English → walk P0 dogfood surfaces → note any remaining Korean chrome → fix per surface (small PR), do not invent a localization framework.

**Known risk:** Many widgets use `l10n?.key ?? '한국어 fallback'`. When `AppLocalizations` is present (normal MaterialApp), English arb should win. Gaps = hardcoded Korean **without** l10n, or missing arb keys.

---

## P4 — Pearl / Black Pearl (design placeholder)

Do not implement spend/grant UI until this contract is written and reviewed.

Draft skeleton (fill in P4 slice):

| Currency | Role | Grant source | Spend |
|---|---|---|---|
| Pearl | Soft / purchasable via Steam Wallet packs | Steam microtxn confirm + ledger | Unlock cosmetic / tips (TBD) |
| Black Pearl | Premium / scarce (TBD) | TBD — never silent grant | Donation / special unlock (TBD) |

Required before code:

- SKU ↔ pearl amount table  
- Local durable ledger location (`system/` vs app prefs — decide in P4)  
- Idempotency key = Steam order / txn id  
- Refund path zeroes balance or claws back unlock  
- GetReport reconciliation job definition  

---

## Explicit non-goals

- SA-05 Timeline projection product work  
- Constitution §7 physical ADR  
- Universal Record / Relationship Assertion storage  
- New architecture closure audits  

---

## Verification (track baseline)

| Gate | Result |
|---|---|
| Architecture Closure | Declared |
| analyze / test at Closure | 0 / 930 |
| IAP flag | `steamInAppPurchasesEnabled == false` |
| Reviewer English path | Documented above |
