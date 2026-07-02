# Steam Early Access RC - AKASHA

> **Updated:** 2026-07-02
> **Status:** Early Access 준비 중. 자동 게이트 PASS, 사용자 수동 dogfood 완료, Steamworks 업로드/리뷰 제출 대기.
> **Code baseline:** `089c198d` until the next release docs commit.

---

## 1. Release Decision

AKASHA는 **정식 1.0 완성판**이 아니라 **Early Access 개인 미디어 아카이브 앱**으로 낸다.

현재 Early Access에서 팔아야 할 가치는 다음 하나다.

```
내가 좋아한 작품, 인물, 장소, 감상을
내 로컬 Markdown vault에 저장하고,
AKASHA가 예쁘게 정리해서 보여준다.
```

출시 메시지에서 낮출 것:

- 대규모 글로벌 작품 사전 규모 강조
- AI agent/player/tool 구현 약속
- 음악 재생, 추천 엔진, 자동화된 외부 도구 연동
- IAP 또는 유료 테마 약속
- v1.1+ 기능을 확정 기능처럼 쓰는 문구

---

## 2. Current Gate Snapshot

| Gate | Result |
|------|--------|
| `flutter test` | PASS, **671/671** |
| `flutter analyze lib` | PASS, **0 issue** |
| `dogfood_precheck.ps1 -Build` | PASS |
| Windows release build | PASS |
| Manual dogfood | PASS, user-confirmed |
| SteamPipe upload | Pending |
| Store page review | Pending |
| Build review | Pending |

Known non-blockers for Early Access:

- Remaining UI/UX friction after dogfood can be handled after Early Access.
- Existing URL posters do not need migration; re-entering the URL localizes again.
- Registry manifest 4 files may be dirty after local rebuild because only `generatedAt` changes.

Blocking before Steam review submission:

- Push the release baseline to `origin/main`.
- Use the copy in this document, not older M2/M3 store drafts.
- Capture store screenshots with demo/owned/generated images, not copyrighted anime/manga/game posters from user dogfood data.

---

## 3. Store Page Basics

| Field | Value |
|------|-------|
| App name | AKASHA |
| Developer | Rune Atelier |
| Platform | Windows |
| Release type | Early Access |
| Price | Free during Early Access unless Steamworks pricing is explicitly changed |
| Languages | Korean, English |
| Primary category | Utilities |
| Suggested tags | `Utilities`, `Design & Illustration`, `Singleplayer`, `Indie`, `Early Access` |
| Controller support | Do not claim controller support |

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

### Korean

```text
AKASHA는 만화, 애니메이션, 영화, 게임, 음악, 인물, 장소처럼 내가 좋아하는 대상을 기록하기 위한 로컬 우선 미디어 아카이브입니다.

이 앱의 중심은 클라우드 계정이나 추천 알고리즘이 아니라, 사용자가 직접 소유하는 Markdown vault입니다. 작품을 추가하고, 포스터를 저장하고, 평점과 상태를 남기고, 감상을 작성하면 AKASHA가 그 기록을 보기 좋은 서재 UI로 정리합니다.

Early Access 현재 제공 기능

• 로컬 Markdown vault 기반 저장
• 작품, 인물, 개념, 사건, 장소, 조직 엔티티 관리
• 작품 포스터 URL을 vault의 posters 폴더로 로컬 저장
• 평점, 감상 상태, 작품 상태, 태그, 메모 기록
• 나만의 서재 생성, 삭제, 작품 드래그 앤 드롭
• 검색 중심 홈 화면과 우측 프리뷰 패널
• 그래프, 타임라인, 저널 기반 탐색
• 휴지통, 복구 초안, ZIP 백업 내보내기
• 한국어/영어 UI 전환 및 데스크톱 환경 설정

AKASHA는 아직 다듬는 중입니다. Early Access 기간에는 실제 사용자의 vault dogfood를 바탕으로 UI/UX, 대량 기록 관리, 가져오기/내보내기, 안정성을 계속 개선합니다.

데이터 소유권

사용자의 기록은 사용자가 선택한 로컬 폴더에 Markdown과 이미지 파일로 저장됩니다. AKASHA는 개인 vault를 개발자 서버로 업로드하지 않습니다.
```

### English

```text
AKASHA is a local-first personal media archive for the works, people, places, and ideas you care about.

Instead of centering on an account, feed, or recommendation algorithm, AKASHA centers on a Markdown vault that you own. Add works, save posters, rate them, track your status, write notes, and organize everything into a visual personal library.

Current Early Access features

• Local Markdown vault storage
• Work, person, concept, event, place, and organization records
• Poster URL localization into your vault's posters folder
• Ratings, personal status, work status, tags, and notes
• Personal libraries with create, delete, and drag-and-drop membership
• Search-first home screen and right-side preview rail
• Graph, timeline, and journal surfaces
• Trash recovery, recovery drafts, and ZIP vault backup export
• Korean/English UI switching and desktop preferences

AKASHA is still being refined. During Early Access, development will focus on real vault dogfood: UI/UX polish, large personal archives, import/export reliability, and stability.

Data ownership

Your records are stored as Markdown and image files in a local folder you choose. AKASHA does not upload your personal vault to a developer server.
```

---

## 6. Early Access FAQ Draft

### Why Early Access?

AKASHA is useful today for a local personal archive, but the experience benefits from real long-term dogfood. Early Access lets us improve the vault workflow, UI density, import/export safety, and large archive behavior with actual user feedback.

### Approximately how long will this app be in Early Access?

Several months is the current expectation, but AKASHA will leave Early Access only when the local vault loop, backup/recovery flow, and daily archive UX are stable enough for a wider audience.

### How is the full version planned to differ from Early Access?

The full version should be more polished and safer for large long-term archives. Planned improvements include smoother onboarding, stronger import/export flows, better large-library performance, more refined UI/UX, and clearer documentation.

### What is the current state of the Early Access version?

The current build supports local Markdown vault storage, work/entity records, poster localization, ratings/status/tags, personal libraries, preview panels, graph/timeline/journal views, trash/recovery, ZIP backup export, and Korean/English UI switching.

### Will the app be priced differently during and after Early Access?

AKASHA is planned to remain free during Early Access unless the Steam store configuration is explicitly changed later. Any future paid cosmetic/supporter items should be announced separately and should not affect access to personal vault data.

### How are you planning on involving the community?

Feedback will focus on real archive workflows: vault setup, adding works, editing records, organizing libraries, backing up data, and using the app on different Windows desktop setups.

---

## 7. Screenshot Plan

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

Do not show:

- Real copyrighted anime/manga/game cover art from dogfood vaults
- Future AI/player/recommendation flows
- Locked IAP UI unless those products are live in Steamworks

---

## 8. Upload Checklist

Run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\dogfood_precheck.ps1 -Build
```

Then:

1. Confirm `git status` has only expected registry manifest `generatedAt` changes, or is clean.
2. Push the release baseline to `origin/main`.
3. Capture screenshots from `build\windows\x64\runner\Release\akasha.exe`.
4. Upload the Windows build with:

```powershell
.\scripts\steam\upload_steam_build.ps1 -SteamUsername <steam_login>
```

5. In Steamworks, submit Store Page review.
6. Submit Build review.
7. After Steam review approval and required Coming Soon time, use Steamworks release controls.

---

## 9. Superseded Documents

This document replaces these as the operational Steam release reference:

- `docs/draft/STEAM_RC_DOGFOOD_CHECKLIST_2026-06-30.md`
- `docs/history/programs/m2-steam-store-page.md`
- `docs/history/release-readiness-checklist.md`

Historical files may remain for context, but release decisions should use this file and `PROJECT_STATUS.md`.
