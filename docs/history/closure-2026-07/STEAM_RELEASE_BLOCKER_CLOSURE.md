# Steam Release Blocker Closure

> **Status:** Active development track (2026-07-12)  
> **Predecessor:** [ARCHITECTURE_CLOSURE_AUDIT.md](ARCHITECTURE_CLOSURE_AUDIT.md) — **Architecture Closure declared**  
> **Ops companion:** [STEAM_RELEASE.md](../../active/STEAM_RELEASE.md)
> **Rule:** No new generic architecture audits. No SA-05 / §7 ADR / Universal Record / Relationship Assertion.  
> **Fix rule:** Former S1 items live here as a **stability checklist**. Fix only when dogfood or ship is blocked, in small units.

---

## Track goal

Close Steam review / payment / localization blockers so AKASHA can ship and dogfood without pretending unfinished commerce exists.

---

## Priority order (this track)

| # | Work | State |
|---|---|---|
| **P1** | English localization applies to all major UI in a real build | **Visual pass (chrome)** — see [evidence/p1-english-ui-2026-07-12](evidence/p1-english-ui-2026-07-12/README.md); deep Work/Entity vault flows deferred when vault path unavailable |
| **P2** | Exact English switch path + resubmission Notes for Steam reviewers | **Draft ready** (§Reviewer English path) |
| **P3** | Unimplemented IAP stated clearly in docs + `FeatureFlags` | **Done in this slice** — `steamInAppPurchasesEnabled = false` |
| **P4** | Astra/Echo (`premium`/`earned`) currency contract + support · unlock domain | **Domain done** — [COMMERCE_CURRENCY_CONTRACT.md](../../active/COMMERCE_CURRENCY_CONTRACT.md) · `packages/akasha_commerce_domain/` |
| **P4-B** | Secure Commerce Backend Foundation (prototype) | **Accepted as domain prototype** — relocated in P4-C |
| **P4-C** | Secure backend physical boundary + Steam Sandbox adapter | **Done / deferred asset** — `backend/akasha_commerce_server/`; Cloud Run·Postgres·prod MicroTxn **paused** |
| **Inv-Gate** | Steam Inventory Commerce Feasibility | **Sandbox E2E POC passed** — [STEAM_INVENTORY_COMMERCE_FEASIBILITY_GATE.md](STEAM_INVENTORY_COMMERCE_FEASIBILITY_GATE.md); production IAP **not** Go |
| **Inv-POC** | Steam Inventory Minimal POC + Native Bridge | **Sandbox E2E passed** (dev account + local Release) — cold restart / depot re-verify remaining |
| **P5** | Product Inventory proof *or* custom backend if No-Go | **Partial** — Sandbox path proven; price policy + flag + depot still open |
| **P6** | Purchase + GetReport sample + test account pack | **Ops follow-up** — after product policy + depot verify |

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
| S-08 | Timeline quick-capture/projection loaders while `showTimeline=false` | Accidental enable | Keep OFF; UX-2 기존 Records 조회 destination은 허용 |

---

## IAP / commerce status (authoritative for ship)

| Surface | Current truth |
|---|---|
| `FeatureFlags.steamInAppPurchasesEnabled` | **`false`** — no live Steam IAP |
| `EntitlementService.purchaseCosmetic` | Stub; returns `false`; no Steamworks microtxn |
| Themes | Classic Dark / Midnight Blue bundled free; premium 3 visible as planned, with no price or purchase action |
| Store Page “In-App Purchases” | **May be cleared** until P5+P6 complete |
| Astra / Echo (`premium` / `earned`) | Domain contract + fake tests landed; **no live purchase** |

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
microtransaction purchase flow, no Astra currency grant, and no paid unlock UI.
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
Astra/Steam Wallet 결제 없음. Classic Dark와 Midnight Blue는 번들 무료로 적용 가능하고 premium 3종은 승인 가격 `500 Astra 또는 500 Echo · 출시 예정`의 read-only catalog로 노출한다. IAP 완성 전 활성 구매 버튼·Steam 결제 가능 표시·Store IAP 주장은 없음.
```

---

## P1 — English major-UI verification checklist

**Evidence:** [evidence/p1-english-ui-2026-07-12/README.md](evidence/p1-english-ui-2026-07-12/README.md) (Release screenshots + results).

| Area | Expected English chrome | Status |
|---|---|---|
| Preferences (Esc) | Title, language, scale, theme, vault, quit/close | **PASS** (screenshot) |
| Locale persistence | English after restart | **PASS** |
| Vault unlinked banner | English message + actions | **PASS** after l10n fix |
| Home / global nav | Home, Explore, Library, Collections, Graph, Timeline | **PASS**; UX-2는 기존 Graph/Records surface 접근만 복원 |
| Browse / search chrome | Labels, empty states | **PASS** on captured surfaces |
| Work detail / Workbench | Info panel, save, tabs | **Deferred** — vault path unavailable this run |
| Personal library / collection | Create/edit/delete | **Partial** — Library English labels OK |
| Theme picker | Free themes only; no purchase lock copy | **PASS** (no IAP chrome) |
| FeatureFlag-hidden surfaces | Timeline quick capture/projection, experimental Graph CTA, Discovery, Universe, Recall | **PASS**; 기존 Graph/Records destination은 대상 아님 |

**Fixes in P1 slice:** vault banner + default-vault dialog l10n; 당시 Timeline primary-nav gate. UX-2에서 이 판정은 기존 Records 조회 destination 허용으로 대체됐고, flag는 quick capture/projection만 계속 막는다.

---

## P4 — Astra / Echo commerce domain

**SSOT:** [COMMERCE_CURRENCY_CONTRACT.md](../../active/COMMERCE_CURRENCY_CONTRACT.md)

| Kind | Display | Qualifier |
|---|---|---|
| `premium` | Astra / 아스트라 | Paid / 유료 |
| `earned` | Echo / 에코 | Earned / 무료 획득 |

**This slice:** server-neutral models + `CommerceService` + fake repo/provider tests.  
**Not in this slice:** Steam API, Flutter store UI, attendance / invites / auto Echo rewards.  
**Authority:** append-only ledger + entitlements — never in user Vault.

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
| P1 English UI | Evidence folder + 933 tests |
| P4 commerce domain | `packages/akasha_commerce_domain/` + Flutter re-export |
| P4-C backend boundary | `backend/akasha_commerce_server/` — not under Flutter `lib/` |
| IAP flag | `steamInAppPurchasesEnabled == false` |
| Reviewer English path | Documented above |
