# Steam Release - AKASHA

> **Packaging contract:** SteamPipe uploads only the verified
> `build/steam/depot_windows` stage. The stage and VDF both exclude
> `steam_appid.txt` and PDB files; the manifest must validate before upload.
> See [STEAM_SERVICE_RELEASE_READINESS.md](STEAM_SERVICE_RELEASE_READINESS.md).

> **Updated:** 2026-07-19
> **Status:** Architecture Closure declared. Active gates =
> [STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md](STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md) ·
> [STEAM_SERVICE_RELEASE_READINESS.md](STEAM_SERVICE_RELEASE_READINESS.md).
> **Release stance:** Early Access가 아니라 **무료 기본 앱 + Steam Commerce 포함** 일반 출시.
> **Release scope:** Steam v1 includes optional Astra packs, paid themes, Echo rewards, and Inventory restore.
> **Current production IAP:** **Disabled / Commerce No-Go**
> (`FeatureFlags.steamInAppPurchasesEnabled = false`) — safety gate until P0 evidence, not “IAP out of scope”.
> **Public/store claim:** Do not submit or market an unsealed build as purchase-ready. Enablement is a separate reviewed change after Matrix P0.

Distinguish three layers:

| Layer | Meaning |
|---|---|
| **Release scope** | First-ship goals and included Commerce features |
| **Current readiness** | Implementation, verification, and blockers today |
| **Public/store claim** | What may be asserted only after sealed RC + P0 PASS |

---

## 1. Release Decision

AKASHA Steam v1 ships as a **free Windows base app** with **Steam in-app Commerce in the first-release train**.

Primary product message:

```text
내가 좋아한 작품, 인물, 장소, 감상을
내 로컬 Markdown vault에 저장하고,
AKASHA가 예쁘게 정리해서 보여준다.
```

### In first-release scope

- Free base app (no paid download)
- Free themes: Classic Dark, Midnight Blue
- Paid theme packages: Sakura, Amethyst, Nocturne
- Real-money Astra packs `40110` / `40111` / `40112`
- Theme unlock via **500 Astra or 500 Echo** (wrappers `41101`–`41103`)
- Echo playtime rewards (Steam-verified)
- Steam Inventory as balance / entitlement authority (restart + other PC)
- Cancel / fail / offline / indeterminate recovery
- IAP-off rollback BuildID prepared and rehearsed

Economy detail: [COMMERCE_CURRENCY_CONTRACT.md](COMMERCE_CURRENCY_CONTRACT.md).
Acceptance detail: [STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md](STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md).

### Not in first-release scope (still deferred)

- Early Access label
- Overselling registry / global catalog scale
- AI agent / player / recommendation engine promises
- Music playback or automated external tool integrations
- Friend-invite Echo, starter Echo promo, custom MicroTxn backend
- Vault Steam Cloud sync (assumed unsupported; Steamworks confirmation pending)

### Current readiness (not the same as scope)

- Production purchase / exchange / reward entry points remain **off** while
  `steamInAppPurchasesEnabled=false`
- Commerce verdict remains **No-Go** until Matrix Commerce P0 and rollback evidence pass
- Final IAP-on RC and IAP-off rollback RC identities are **unsealed (BLOCKED)**
- Until then: no active purchase CTA on normal Release builds; do not claim live Steam Wallet checkout in public store copy

---

## 1b. Reviewer English switch (summary)

Exact path and resubmission Notes: [STEAM_RELEASE_BLOCKER_CLOSURE.md](../history/closure-2026-07/STEAM_RELEASE_BLOCKER_CLOSURE.md) §Reviewer English path.

Short: Esc → Preferences → Display language → English.

---

## 2. Current Gate Snapshot

| Gate | Result |
|------|--------|
| `flutter test` | PASS — count in [CURRENT_STATE.md](CURRENT_STATE.md) |
| `flutter analyze lib` | PASS, **0 issue** |
| `dogfood_precheck.ps1 -Build` | PASS |
| Windows release build | PASS — historical size note in CURRENT_STATE |
| Full registry bundle | 10,048 works · 1,713 shards · production registry network 0 |
| Manual dogfood | PASS, user-confirmed |
| Store Presence | Coming Soon posted, user-confirmed |
| Production IAP flag | `false` — safety gate |
| Commerce acceptance | **No-Go** — see Matrix + readiness |
| Final IAP-on RC BuildID | **TBD / BLOCKED** |
| IAP-off rollback BuildID | **TBD / BLOCKED** |
| Store page review / Build review | Pending sealed RC |

### Historical BuildIDs (not final RC)

| BuildID | Role |
|---------|------|
| **24015480** | Historical free / no-IAP SteamPipe upload evidence only |
| **24240688** | Historical commerce-sandbox library evidence (prices, depot packaging, `40110` Overlay A/B) |
| **24013902** | Superseded earlier upload |

Do **not** Set Live `24015480` (or any historical BuildID) as the final Commerce RC. Default / review branch Set Live happens only after a **sealed** IAP-on RC (and a prepared IAP-off rollback RC) exists.

Known non-blockers for vault product polish:

- Remaining UI/UX friction after dogfood can be handled after launch.
- Existing URL posters do not need migration; re-entering the URL localizes again.
- Registry remote/CDN infrastructure may remain deployed, but the production app does not depend on it.

### Blocking before final release (summary)

Canonical rows and cases live in
[STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md](STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md).
Minimum blockers:

1. Seal RC identity (IAP-on + IAP-off rollback)
2. Confirm Steamworks Vault Cloud **off** / unsupported store claim
3. Software Overlay publish evidence
4. Remote ItemDef publication vs local LF candidate
5. Astra `40110–40112` cancel / complete / exact delta
6. Restart + second-PC Inventory restore
7. Theme exchange × 6 paths
8. Echo reward window matrix
9. Failure / indeterminate / refund recovery
10. IAP-off rollback rehearsal (CTA off; Inventory read-only)
11. Full Korean / English Release UI audit
12. Store parity (copy, screenshots, IAP disclosure) on sealed RC
13. **Last:** reviewed change to enable `steamInAppPurchasesEnabled`

---

## 3. Store Page Basics

| Field | Value |
|------|-------|
| App name | AKASHA |
| Developer | Rune Atelier |
| Platform | Windows |
| Release type | Free base app with Steam in-app purchases |
| Base price | Free |
| IAP | Included in first-release **scope**; **not** enabled on the current unsealed production build |
| Languages | Korean, English (Interface) |
| Paid themes | Sakura, Amethyst, Nocturne |
| Steam Cloud (Vault) | Unsupported / off — **Steamworks console confirmation pending** |
| Primary category | Utilities |
| Suggested tags | `Utilities`, `Design & Illustration`, `Singleplayer`, `Indie` |
| Controller support | Do not claim controller support |

Store Page fields that depend on Steamworks console state remain **pending verification** until checked; do not treat them as CURRENT-RC-PASS.

---

## 4. Short Description

### Korean

```text
AKASHA는 내가 좋아한 작품과 감상을 로컬 Markdown vault에 저장하는 개인 미디어 아카이브입니다. 포스터, 평점, 상태, 태그, 나만의 서재를 내 파일로 소유하고 정리하세요.
```

### English

```text
AKASHA is a personal media archive for the works you love. Save posters, ratings, status, tags, notes, and personal libraries into a local Markdown vault you own.
```

---

## 5. About This App

Release-plan feature list for Steam v1. **Final public store wording and screenshots are locked only after Commerce RC P0 passes.** Unsealed builds keep transactions disabled.

### Korean

```text
AKASHA는 만화, 애니메이션, 영화, 게임, 음악, 인물, 장소처럼 내가 좋아하는 대상을 기록하기 위한 로컬 우선 미디어 아카이브입니다.

이 앱의 중심은 클라우드 계정이나 추천 알고리즘이 아니라, 사용자가 직접 소유하는 Markdown vault입니다. 작품을 추가하고, 포스터를 저장하고, 평점과 상태를 남기고, 감상을 작성하면 AKASHA가 그 기록을 보기 좋은 서재 UI로 정리합니다.

Steam v1 출시 범위 기능

• 로컬 Markdown vault 기반 저장
• 작품, 인물, 개념, 사건, 장소, 조직 엔티티 관리
• 작품 포스터 URL을 vault의 posters 폴더로 로컬 저장
• 평점, 감상 상태, 작품 상태, 태그, 메모 기록
• 나만의 서재 생성, 삭제, 작품 드래그 앤 드롭
• 검색 중심 홈 화면과 우측 프리뷰 패널
• 그래프, 타임라인, 저널 기반 탐색
• 휴지통, 복구 초안, ZIP 백업 내보내기
• 한국어/영어 UI 전환 및 데스크톱 환경 설정
• 무료 테마: Classic Dark, Midnight Blue
• 유료 테마 패키지: Sakura, Amethyst, Nocturne
• Steam Wallet을 통한 Astra 팩 구매
• Astra 또는 Echo 500으로 유료 테마 교환
• Steam 검증 Echo 플레이타임 보상
• Steam Inventory 기반 잔액·테마 소유권 복원 (재실행·다른 PC)

경계

• 위 Commerce 기능은 Steam v1 출시 범위에 포함됩니다.
• 실제 상점 문구·스크린샷은 최종 Commerce RC와 Acceptance Matrix P0 통과 후 확정합니다.
• 현재 미봉인 빌드에서는 구매·교환·보상 거래가 비활성입니다 (`steamInAppPurchasesEnabled=false`).

AKASHA는 출시 후에도 실제 사용자의 vault dogfood를 바탕으로 UI/UX, 대량 기록 관리, 가져오기/내보내기, 안정성을 계속 개선합니다.

데이터 소유권

사용자의 기록은 사용자가 선택한 로컬 폴더에 Markdown과 이미지 파일로 저장됩니다. AKASHA는 개인 vault를 개발자 서버로 업로드하지 않습니다. 결제는 Steam Wallet만 사용하며, Astra·Echo·테마 entitlement의 계정 권위는 Steam Inventory입니다.
```

### English

```text
AKASHA is a local-first personal media archive for the works, people, places, and ideas you care about.

Instead of centering on an account, feed, or recommendation algorithm, AKASHA centers on a Markdown vault that you own. Add works, save posters, rate them, track your status, write notes, and organize everything into a visual personal library.

Steam v1 release-scope features

• Local Markdown vault storage
• Work, person, concept, event, place, and organization records
• Poster URL localization into your vault's posters folder
• Ratings, personal status, work status, tags, and notes
• Personal libraries with create, delete, and drag-and-drop membership
• Search-first home screen and right-side preview rail
• Graph, timeline, and journal surfaces
• Trash recovery, recovery drafts, and ZIP vault backup export
• Korean/English UI switching and desktop preferences
• Free themes: Classic Dark, Midnight Blue
• Paid theme packages: Sakura, Amethyst, Nocturne
• Astra pack purchases through Steam Wallet
• Paid theme unlock for 500 Astra or 500 Echo
• Steam-verified Echo playtime rewards
• Steam Inventory restore for balances and theme entitlements across restart and another PC

Boundaries

• Commerce above is in the Steam v1 release train.
• Final store copy and screenshots are locked only after the sealed Commerce RC and Acceptance Matrix P0 pass.
• Current unsealed builds keep purchase, exchange, and reward transactions disabled (`steamInAppPurchasesEnabled=false`).

After launch, AKASHA will continue to improve based on real vault dogfood: UI/UX polish, large personal archives, import/export reliability, and stability.

Data ownership

Your records are stored as Markdown and image files in a local folder you choose. AKASHA does not upload your personal vault to a developer server. Payments use Steam Wallet only; Steam Inventory is the account authority for Astra, Echo, and theme entitlements.
```

---

## 6. Screenshot Plan

Use a clean demo vault. Avoid copyrighted posters, stills, logos, or character art unless Rune Atelier has rights to use them in store marketing.

Recommended captures:

| # | Screen | Message |
|---|--------|---------|
| 1 | Home dashboard | Search-first personal archive home |
| 2 | Work detail | Ratings, status, tags, and notes |
| 3 | Poster localization | User-provided images stored in local `posters/` |
| 4 | Personal library | Create libraries and drag works into them |
| 5 | Vault settings | Trash, backup export, and local storage |
| 6 | Graph/timeline/journal | Different ways to revisit records |
| 7 | Preferences | Korean/English switching and display scale |
| 8 | Theme Gallery | Free + paid theme packages as they ship |
| 9 | Store / Inventory (sealed RC) | Astra packs, balances, owned entitlements on the final Commerce RC |

Allowed on the **sealed Commerce RC** (after P0): real Store, Inventory, Theme Gallery, purchase, and ownership states that actually work in that build.

Do not show:

- Real copyrighted anime/manga/game cover art from dogfood vaults
- Future AI/player/recommendation flows
- Dev sandbox-only controls, mockups, unfinished locked UI, or purchase CTAs that cannot complete on the build being marketed

---

## 7. Upload Checklist

Run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dogfood_precheck.ps1 -Build
```

Aligned order (detail in the Acceptance Matrix):

1. Confirm the release worktree is clean and contains no unintended `akasha-db/**` source changes.
   Run the deterministic full-bundle gate; do not regenerate source manifests as a packaging side effect.
2. Collect Matrix P0 evidence on a Steam-downloaded private-branch RC (not only a local exe).
3. Seal **IAP-on** RC identity and a separate **IAP-off rollback** RC; rehearse rollback (CTA off; Inventory read-only).
4. Capture screenshots from the sealed RC executable (demo/owned/generated assets only).
5. Stage depot (`prepare_steam_depot.ps1`), verify manifest (`steam_appid.txt` / PDB excluded), upload via SteamPipe.
   For commerce sandbox contracts see
   [STEAMPIPE_COMMERCE_SANDBOX_UPLOAD.md](steam_inventory_production/STEAMPIPE_COMMERCE_SANDBOX_UPLOAD.md).
6. Confirm remote ItemDef publication vs LF canonical candidate; retain Steamworks revision/time.
7. Only after Matrix Commerce P0 + rollback: reviewed change enabling `steamInAppPurchasesEnabled`.
8. Upload the final IAP-on build; Set Live on the intended review/default branch.
9. Submit Store Page review and Build review.
10. After approval and required Coming Soon time, use Steamworks release controls.

Do not treat historical BuildIDs `24015480` / `24240688` as the final Set Live target.

### Upload Log (historical)

| Date | BuildID | Result | Notes |
|------|---------|--------|-------|
| 2026-07-02 | **24013902** | Uploaded | Superseded earlier upload |
| 2026-07-02 | **24015480** | Uploaded | Historical free/no-IAP upload evidence only — not final Commerce RC |
| 2026-07-16 | **24240688** | Sandbox library | Historical commerce-sandbox evidence (see readiness) |

---

## 8. Superseded Documents

This document replaces these as the operational Steam release reference:

- `docs/active/STEAM_EARLY_ACCESS.md` (removed)
- `docs/draft/STEAM_RC_DOGFOOD_CHECKLIST_2026-06-30.md` (removed; use [SANDBOX_TRANSACTION_CHECKLIST.md](steam_inventory_production/SANDBOX_TRANSACTION_CHECKLIST.md))
- `docs/history/programs/m2-steam-store-page.md`
- `docs/history/release-readiness-checklist.md`

Historical files may remain for context, but release decisions should use this
file, [STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md](STEAM_V1_RELEASE_ACCEPTANCE_MATRIX.md),
[STEAM_SERVICE_RELEASE_READINESS.md](STEAM_SERVICE_RELEASE_READINESS.md),
and [CURRENT_STATE.md](CURRENT_STATE.md).
