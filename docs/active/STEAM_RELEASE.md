# Steam Release - AKASHA

> **Updated:** 2026-07-02
> **Status:** 무료 일반 출시 준비 중. Store Presence 공개 완료, SteamPipe 업로드/빌드 리뷰 진행 중.
> **Release stance:** Early Access가 아니라 **무료 일반 출시**. 앱 내 구매/유료 테마는 post-launch로 보류.

---

## 1. Release Decision

AKASHA v1은 **무료 Windows 앱**으로 출시한다.

현재 출시 메시지에서 팔아야 할 가치는 다음 하나다.

```text
내가 좋아한 작품, 인물, 장소, 감상을
내 로컬 Markdown vault에 저장하고,
AKASHA가 예쁘게 정리해서 보여준다.
```

이번 무료 출시에서 하지 않는 것:

- Early Access 라벨 사용
- 앱 내 구매 또는 유료 테마 판매
- 대규모 글로벌 작품 사전 규모 강조
- AI agent/player/tool 구현 약속
- 음악 재생, 추천 엔진, 자동화된 외부 도구 연동 약속

테마는 v1에서 모두 무료로 제공한다. Steam IAP, supporter pack, paid theme pack은 실제 Steam 결제 연동이 준비된 뒤 별도 업데이트로 검토한다.

---

## 2. Current Gate Snapshot

| Gate | Result |
|------|--------|
| `flutter test` | PASS, **672/672** |
| `flutter analyze lib` | PASS, **0 issue** |
| `dogfood_precheck.ps1 -Build` | PASS |
| Windows release build | PASS |
| Manual dogfood | PASS, user-confirmed |
| Store Presence | Coming Soon posted, user-confirmed |
| SteamPipe upload | PASS, BuildID **24015480** |
| Store page review | Pending |
| Build review | Pending after BuildID **24015480** is set live |

Known non-blockers for v1:

- Remaining UI/UX friction after dogfood can be handled after launch.
- Existing URL posters do not need migration; re-entering the URL localizes again.
- Registry manifest 4 files may be dirty after local rebuild because only `generatedAt` changes.

Blocking before final release:

- Set BuildID **24015480** live on the default branch in Steamworks, then submit/update Build review.
- Confirm Store Page review and Build review are approved.
- Capture store screenshots with demo/owned/generated images, not copyrighted anime/manga/game posters from user dogfood data.
- Keep store copy aligned with the free app. Do not mention paid themes until Steam IAP is actually implemented.

---

## 3. Store Page Basics

| Field | Value |
|------|-------|
| App name | AKASHA |
| Developer | Rune Atelier |
| Platform | Windows |
| Release type | Free general release |
| Price | Free |
| Languages | Korean, English |
| Primary category | Utilities |
| Suggested tags | `Utilities`, `Design & Illustration`, `Singleplayer`, `Indie` |
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

현재 제공 기능

• 로컬 Markdown vault 기반 저장
• 작품, 인물, 개념, 사건, 장소, 조직 엔티티 관리
• 작품 포스터 URL을 vault의 posters 폴더로 로컬 저장
• 평점, 감상 상태, 작품 상태, 태그, 메모 기록
• 나만의 서재 생성, 삭제, 작품 드래그 앤 드롭
• 검색 중심 홈 화면과 우측 프리뷰 패널
• 그래프, 타임라인, 저널 기반 탐색
• 휴지통, 복구 초안, ZIP 백업 내보내기
• 한국어/영어 UI 전환 및 데스크톱 환경 설정
• 무료 앱 테마 선택

AKASHA는 출시 후에도 실제 사용자의 vault dogfood를 바탕으로 UI/UX, 대량 기록 관리, 가져오기/내보내기, 안정성을 계속 개선합니다.

데이터 소유권

사용자의 기록은 사용자가 선택한 로컬 폴더에 Markdown과 이미지 파일로 저장됩니다. AKASHA는 개인 vault를 개발자 서버로 업로드하지 않습니다.
```

### English

```text
AKASHA is a local-first personal media archive for the works, people, places, and ideas you care about.

Instead of centering on an account, feed, or recommendation algorithm, AKASHA centers on a Markdown vault that you own. Add works, save posters, rate them, track your status, write notes, and organize everything into a visual personal library.

Current features

• Local Markdown vault storage
• Work, person, concept, event, place, and organization records
• Poster URL localization into your vault's posters folder
• Ratings, personal status, work status, tags, and notes
• Personal libraries with create, delete, and drag-and-drop membership
• Search-first home screen and right-side preview rail
• Graph, timeline, and journal surfaces
• Trash recovery, recovery drafts, and ZIP vault backup export
• Korean/English UI switching and desktop preferences
• Free app theme selection

After launch, AKASHA will continue to improve based on real vault dogfood: UI/UX polish, large personal archives, import/export reliability, and stability.

Data ownership

Your records are stored as Markdown and image files in a local folder you choose. AKASHA does not upload your personal vault to a developer server.
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

Do not show:

- Real copyrighted anime/manga/game cover art from dogfood vaults
- Future AI/player/recommendation flows
- Locked IAP UI or paid theme messaging

---

## 7. Upload Checklist

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

5. In Steamworks, set the uploaded build live on the intended branch and publish the SteamPipe change.
6. Submit Store Page review and Build review.
7. After Steam review approval and required Coming Soon time, use Steamworks release controls.

### Upload Log

| Date | BuildID | Result | Notes |
|------|---------|--------|-------|
| 2026-07-02 | **24013902** | Uploaded | SteamCMD cached login as `royal_herobrine`; superseded by no-IAP build. |
| 2026-07-02 | **24015480** | Uploaded | Free/no-IAP release build. Set live on `default` branch in Steamworks before Build review. |

---

## 8. Superseded Documents

This document replaces these as the operational Steam release reference:

- `docs/active/STEAM_EARLY_ACCESS.md`
- `docs/draft/STEAM_RC_DOGFOOD_CHECKLIST_2026-06-30.md`
- `docs/history/programs/m2-steam-store-page.md`
- `docs/history/release-readiness-checklist.md`

Historical files may remain for context, but release decisions should use this file and `PROJECT_STATUS.md`.
