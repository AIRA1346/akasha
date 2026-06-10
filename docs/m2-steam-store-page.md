# M2 Steam Store Page — AKASHA

> **목적:** Steamworks 앱 페이지에 붙여 넣을 카피·태그·스크린샷 가이드  
> **기준일:** 2026-06-10 · 앱 버전: v1 (Windows) · 카탈로그 **430작**

Steam Partner 계정·앱 생성 **완료** — 아래 텍스트를 Store 페이지에 채우면 됩니다.

---

## 1. 기본 정보

| 필드 | 값 |
|------|-----|
| **앱 이름** | AKASHA |
| **개발사** | Rune Atelier |
| **출시 형태** | **무료** (Free to Play) + IAP |
| **플랫폼** | Windows |
| **언어** | 한국어 (주), 영어 (스토어 설명 병기) |

### Steam 카테고리·태그 (권장)

| 구분 | 선택 |
|------|------|
| **Primary genre** | Utilities |
| **Store tags** | `Utilities` · `Design & Illustration` · `Free to Play` · `Indie` · `Singleplayer` |
| **컨트롤러** | Full controller support (선택 — 키보드·마우스 중심이면 Partial) |

---

## 2. 짧은 설명 (Short Description · ~300자)

### 한국어

```
Sanctum 볼트와 연동하는 개인 미디어 아카이브. 엄선 글로벌 작품 사전(430+)과 IP 1카드 그리드, 나만의 서재로 만화·애니·게임·영화 기록을 한곳에.
```

### English

```
Personal media archive linked to your Sanctum vault. Curated global work catalog (430+), IP fusion grid, and My Library for manga, anime, games, and film — all in local Markdown you own.
```

---

## 3. 긴 설명 (About This Game)

### 한국어 (Steam Store Description)

```
AKASHA(아카샤)는 트래커를 넘어, 당신이 사랑한 작품의 감동과 생각을 Sanctum vault 호환 마크다운으로 남기는 Windows 데스크톱 아카이브입니다.

■ 핵심 기능 (v1 · 무료)
• Sanctum 볼트 연동 — 로컬 .md + YAML, 폴더 감시·원자적 저장
• 글로벌 작품 사전 — 430+ 엄선 작품, GitHub 동기화, 포스터 없는 Fact 카드
• 작품 검색 — 내 볼트 + 사전 + 직접 등록
• 대시보드 — 카테고리·도메인 필터, Hall of Fame, 워치리스트
• 나만의 서재 — 아카이브한 작품만 모아 보는 전용 뷰 (기본 무료)

■ AI 가져오기
ChatGPT 등이 만든 YAML+마크다운을 붙여넣어 새 작품을 등록할 수 있습니다.

■ 데이터는 내 것
글로벌 사전은 제목·연도·작가 같은 Fact 참조용입니다. 포스터·평점·상태는 작품을 아카이브한 뒤 내 볼트의 .md에서 직접 관리합니다.

■ IAP (코스메틱)
나만의 서재 테마·꾸미기 팩 — 게임플레이 변경 없음, Steam 인앱 구매.

■ v1.1 예정
오늘의 회상, 타임라인, 취향 Discover 등은 출시 후 로드맵에 있습니다.

개발: Rune Atelier
```

### English

```
AKASHA is a Windows desktop archive for the media you love — not just a tracker, but a space to preserve how each work felt, in Sanctum-compatible local Markdown.

■ Core (v1 · free)
• Sanctum vault sync — local .md + YAML, folder watch, atomic writes
• Global work catalog — 430+ curated titles, GitHub sync, poster-free fact cards
• Search — your vault + catalog + manual entries
• Dashboard — filters, Hall of Fame, watchlist, collapsible sections
• My Library — archived works only (free base view)

■ AI import
Paste YAML+Markdown from ChatGPT and similar tools to register new works.

■ You own your data
The catalog is reference metadata: titles, years, creators, and IDs. Posters, ratings, and status live in your own .md files after you archive a work.

■ IAP (cosmetic)
My Library theme packs — no gameplay impact, Steam in-app purchase.

■ Post-launch roadmap
Daily recall cards, timeline, and Discover are planned for v1.1+.

Developer: Rune Atelier
```

---

## 4. 스크린샷 가이드 (5~8장)

Release 빌드: `.\scripts\build_release.ps1` → `build\windows\x64\runner\Release\akasha.exe`

| # | 화면 | 촬영 방법 | 스토어 메시지 |
|---|------|-----------|---------------|
| 1 | **홈 대시보드** | 포스터 없는 Fact 카드 · 카테고리 플레이스홀더 | 「430+ 텍스트 카탈로그」 |
| 2 | **작품 검색** | 검색 다이얼로그 · 사전+볼트 결과 | 「로컬 + 글로벌 검색」 |
| 3 | **아카이브 + 포스터** | 볼트 연동 · 유저 `poster:` URL 또는 `posters/` | 「내가 고른 이미지만」 |
| 4 | **작품 상세** | 매체 칩·메타 (유저 포스터 있을 때) | 「IP 1카드 · Sanctum vault」 |
| 5 | **서재 테마** | 팔레트 아이콘 → 테마 피커 (미드나잇 블루) | 「무료 테마 + IAP 프리미엄」 |
| 6 | **Sanctum vault 연동** | 볼트 연동 배너 또는 `.md` 파일 | 「100% 로컬 Markdown」 |
| 7 | *(선택)* **AI 가져오기** | 클립보드 import 다이얼로그 | 「AI YAML 가져오기」 |
| 8 | *(선택)* **IAP 잠금** | 사쿠라/자수정 잠금 상태 | 「코스메틱 IAP」 |

**스크린샷 팁:** 홈 그리드는 플레이스홀더가 정상입니다. 포스터가 있는 샷은 **Sanctum vault에 아카이브한 작품**에 유저가 `poster:` 또는 `posters/`를 넣은 뒤 촬영하세요.

**해상도:** Steam 권장 **1920×1080** 또는 **1280×720** (16:9). Windows `Win+Shift+S` 또는 Steamworks 업로드 전 PNG.

**QA용 테마 잠금 해제 (스크린샷만):** 앱에서 `EntitlementService.devUnlockLibraryThemes()` 호출 또는 출시 빌드 전 임시 grant — **스토어 캡처 후 롤백**.

---

## 5. IAP 상품 (Steamworks 등록)

| SKU ID | 표시 이름 | 가격 (권장) | 포함 |
|--------|-----------|-------------|------|
| `akasha_library_theme_pack` | 나의 서재 테마 팩 | ₩3,000~5,000 / $2.99 | 사쿠라 · 자수정 테마 |
| `akasha_supporter_pack` | 서포터 팩 | ₩5,000~9,000 / $4.99 | (v1) 뱃지·감사 메시지 — 범위 최소 |

코드 SSOT: `EntitlementService.libraryThemePackId` · `supporterPackId`

---

## 6. Steamworks 체크리스트

- [ ] Store page — Short / About (ko + en) 붙여넣기
- [ ] Tags · genre · release date (Q3 2026 목표)
- [ ] Screenshots 5~8장 업로드
- [ ] Build — `akasha.exe` depot 업로드 (SteamPipe)
- [ ] IAP 2 SKU 등록 + Microtxn 연동 (M2 후반 코드 작업)
- [ ] Content survey · age rating (일반적으로 Everyone / 전체 이용가 수준 — 자체 입력)
- [ ] Privacy policy URL (없으면 GitHub README 링크 또는 간단 정책 페이지)

---

## 7. Depot / 빌드 업로드 (요약)

1. Steamworks → 앱 → **Depots** → Windows depot 생성 (64-bit)
2. Release 폴더 전체 업로드: `build\windows\x64\runner\Release\`
3. `app_build.vdf` 또는 Steamworks GUI 업로드
4. Default branch `default`에 빌드 연결 후 **Playtest** 또는 **Coming Soon** 공개

상세 SteamPipe 설정은 Partner 문서 참고 — 본 저장소에는 VDF 미포함 (Partner 대시보드에서 생성 권장).

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | M2 스토어 페이지 초안 — Partner 앱 생성 후 copy·스크린샷 가이드 |
