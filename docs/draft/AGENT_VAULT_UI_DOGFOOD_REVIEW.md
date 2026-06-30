# Agent Vault UI Dogfood Review — Work Journal 감상 카드

> **일자:** 2026-06-30
> **지위:** 구현 확장 **전** UI/UX 관찰·리뷰 (draft)
> **범위:** Windows/desktop · Home 프리뷰 `내 감상` · Workbench Sanctum `# 📝 메모`
> **상위:** [AGENT_VAULT_LOOP_SLICE.md](../active/AGENT_VAULT_LOOP_SLICE.md) · [AGENT_VAULT_PROTOCOL_V1.md](../active/AGENT_VAULT_PROTOCOL_V1.md)
> **초기 리뷰 기준:** `8840986` (`feat: add Agent Vault work journal UI slice`) · **P0-1 적용:** 이번 커밋

---

## 1. 검증 방법 (한계)

| 수단 | 내용 |
|------|------|
| **코드·토큰 추적** | `PreviewJournalReflectionCard`, `SanctumMemoCard`, `JournalReflectionPreview`, `dashboard_preview_panel` (320px rail) |
| **Fixture 시뮬레이션** | `vault_agent_slice_{create,full}.md` → `MarkdownParser` 필드 매핑 |
| **자동 테스트** | widget/unit 10건 — 레이아웃·카피 존재 여부만, **시각적 밀도·미학은 미검증** |
| **GUI 수동 dogfood** | **권장** — Release 빌드 + 실제 볼트에 fixture 복사 후 §7 체크리스트 |

에이전트 환경에서는 **Windows GUI 픽셀 단위 관찰 불가**. 본 문서는 구조·카피·우선순위·엣지 케이스를 코드 기준으로 평가하며, §7 수동 확인으로 P0/P1 확정을 권장한다.

---

## 2. 시나리오 매트릭스

| 시나리오 | Fixture / 조건 | Home `내 감상` | Sanctum memo card |
|----------|----------------|----------------|-------------------|
| **S1 최소 기록** | `vault_agent_slice_create.md` | 메모 1줄 · `평가 없음` · 상태·태그 숨김 | 제목 `# 📝 메모` + 카드 본문 1줄 |
| **S2 풀 슬라이스** | `vault_agent_slice_full.md` | 별 4.5 · 상태 · 2태그 · 메모 발췌 | 3단락 전체 표시 (발췌 없음) |
| **S3 평점 없음** | `rating: 0` + 메모 있음 | `평가 없음` + 메모 — **톤이 부정적** | N/A |
| **S4 상태 없음** | `볼 예정` / watchlist 라벨 | `hasMeaningfulStatus` false → **행 자체 생략** | N/A |
| **S5 긴 감상** | 본문 300자+ (수동) | 180자 hard truncate + `…` | 전문 표시 |
| **S6 태그 많음** | tags 8개+ (수동) | **전부 표시** · 320px에서 세로 팽창 | N/A |

---

## 3. 영역별 관찰

### 3.1 Home 프리뷰 — `PreviewJournalReflectionCard`

**배치 (320px rail)**

```
히어로 → 제목 → [상세 정보] → 핵심 정보 → 내 감상 → 연결 섹션 → …
```

| # | 질문 | 관찰 | 판정 |
|---|------|------|:----:|
| 1 | 정보 패널 안에서 튀거나 묻히지 않는가? | `borderSubtle(0.035)` 배경 + `sectionLabel` — **핵심 정보**와 동일한 카드 언어. 연결 섹션 직전이라 **스크롤 중간**에 위치. 히어로 대비 과하지 않음. | ✅ 양호 |
| 2 | 평점·상태·태그·메모 우선순위 | 시각 순서: **메타(별·상태) → 태그 → 메모**. 메모가 `dialogBody` 13px로 가장 읽기 좋음 — **감상 본문 우선** 의도와 일치. | ✅ 양호 |
| 3 | 180자 발췌 | `substring(0, 180)` — **문장 경계 무시**. 한글 3줄 분량. rail 폭 320px에서 대략 4~5줄. **「…」만으로 잘림 인지 가능**. | ⚠️ P1 |
| 4 | 빈 상태 카피 | `아직 메모가 없습니다.\n대화나 상세에서…` — 부드러움. 다만 메모 없고 **평점만 있을 때**도 `평가 없음`이 먼저 보임. | ⚠️ P1 |
| 5 | Agent fixture 정합 | create: 메모 표시 OK. full: rating·tags·memo OK. **핵심 정보·내 감상 모두 5점 스케일** (P0-1). 이중 표시는 P1-1 | ⚠️ P1 |

**추가 이슈**

- **`PreviewCoreInfoRow.rating`은 `4.5 / 5` 표기** (P0-1 적용) — `StarRating` 5점 만점과 일치. **핵심 정보·내 감상 이중 표시**는 P1-1.
- **상태 숨김:** Agent create fixture의 `아직 안 봄` → 파서가 `볼 예정`으로 정규화 → `hasMeaningfulStatus` false → **프리뷰에 상태 미표시**. Workbench·그리드와 불일치 가능.
- **태그:** registry merge 시 catalog `tags`가 섞이면 **개인 태그 칩**에 장르 태그 노출 가능 (`MarkdownParser.deserialize`).

### 3.2 Workbench Sanctum — `SanctumMemoCard`

| # | 질문 | 관찰 | 판정 |
|---|------|------|:----:|
| 4 | 진짜 「감상 카드」인가? | 본문만 `DecoratedBox` 카드. **제목 `# 📝 메모`는 카드 밖** 17px bold `Colors.white` — `SanctumQuoteCards`와 동일 패턴이나 **카드 일체감 약함**. | ⚠️ P1 |
| 5 | 빈 상태 | `메모가 비어 있습니다.` (italic muted) — Home과 **문구·톤 불일치**. 압박은 낮음. | ⚠️ P2 |
| 6 | Agent fixture 정합 | full fixture 3단락 — **단락 간 빈 줄**이 `SanctumWikiParagraphs`로 자연스럽게 렌더될 것으로 예상. 슬롯 키워드 `📝` 인식 OK. | ✅ 양호 |
| — | 긴 감상 | 발췌 없음 · 스크롤 영역 내 전문 — **읽기 경험은 Sanctum 쪽이 Home보다 우수**. | ✅ 양호 |

**추가 이슈**

- 명대사 카드는 **인용 스타일**(teal italic)로 메모와 차별화됨 — **메모=일반 prose**는 의도에 맞음.
- `OST 메모` 등 커스텀 제목은 memo kind에서 제외 (`!lower.contains('ost')`) — OK.

---

## 4. 시각적 우선순위 요약

```
Home 320px rail (의도된 계층)
  1. 포스터·제목·CTA        ← 작품 정체성
  2. 핵심 정보 (장르·제작)   ← catalog 메타
  3. 내 감상 (개인 기록)     ← Agent loop 핵심  ★
  4. 연결·discovery         ← 탐색 확장

내 감상 내부
  1. 별·상태 (한 줄)
  2. 태그 (칩)
  3. 메모 (본문)
```

**리스크:** 3번이 2번 **평점 행과 중복**되면 시각적 잡음 — **P1-1** (스케일은 P0-1로 해소).

---

## 5. 개선 후보 (P0 / P1 / P2)

### P0 — dogfood 신뢰도

| ID | 이슈 | 상태 | 파일 |
|----|------|:----:|------|
| **P0-1** | 핵심 정보 `4.5 / 10` vs `StarRating` 5점 만점 **불일치** | **✅ 이번 커밋 적용** (`/ 10` → `/ 5`) | `preview_record_view_model.dart` |

> P0-1 적용 완료 — `preview_record_view_model_test.dart`로 `/ 5` 회귀 검증.

### P1 — 다음 스프린트 (slice 품질)

| ID | 이슈 | 제안 |
|----|------|------|
| **P1-1** | 핵심 정보 + 내 감상 **평점 이중 표시** | 내 감상에 별이 있으면 핵심 정보에서 평점 행 **생략**, 또는 내 감상은 별만·핵심 정보는 숫자만 |
| **P1-2** | 180자 **문장 중간 절단** | `formatMemo`에서 마지막 `.` `。` `!` `?` 이전으로 자르기 |
| **P1-3** | `평가 없음`이 메모·태그와 **공존**할 때 시각적 잡음 | rating=0이면 메타 행에서 **별 영역 생략** (상태만 표시) |
| **P1-4** | Agent create 시 **상태가 프리뷰에 안 보임** | watchlist 라벨도 **회색 pill**로 표시 (숨기지 않음) 또는 Agent protocol에「의미 있는 상태만 쓰기」가이드 |
| **P1-5** | 태그 6개+ 시 rail **세로 폭주** | 프리뷰 태그 **max 4 + `+N`** |
| **P1-6** | Sanctum 제목이 카드 **밖** | `# 📝 메모`를 `SanctumMemoCard` **내부 헤더**로 이동 (quote 카드와 톤 맞춤) |
| **P1-7** | Home 상단 **필터 칩 2줄**이 검색보다 먼저 — 분류/DB 도구 인상 | **✅ slice 적용** — `HomeBrowseSearchChrome`: 검색 최상단 · 필터 접이식 · Ctrl K |
| **P1-8** | **raw wiki link** UI 노출 | 링크를 **라벨·도메인 축약** 또는 내부 탐색으로 — §P1-8 관찰 |
| **P1-9** | Home **중앙** 개인 감상 밀도 부족 | 대시보드 본문에 최근 감상·메모 요약 블록 검토 (rail 보완) |
| **P1-10** | **앱 테마** 적용 범위 불명확 | Release dogfood — 사이드바·프리뷰·다이얼로그 대비·가독성 체크리스트 |

### P1-7 관찰 (Home 상단 · 2026-06-30)

**문제:** `FilterSection`이 Work/Person/Concept/Event + 매체 칩을 **항상 2줄** 노출 → v1 Personal Sanctum에서 **검색·감상 진입**보다 taxonomy가 앞섬.

**적용 (vertical slice):**

| 항목 | 구현 |
|------|------|
| 검색 최상단 | `HomeBrowseSearchChrome` — placeholder `작품, 인물, 감상, 태그를 검색하세요...` |
| Ctrl K | desktop(≥720px) hint 유지 · compact는 검색 full width + 필터 아이콘 |
| 필터 | `filter_list` 버튼 → `FilterSection` inline expand (기능·상태 유지) |
| 기본 | 필터 칩 **비노출** · 활성 필터 시 badge |

**잔여 (수동 dogfood):** 탐험 그리드 vs 홈 대시보드 동시 노출 시 검색 **이중** 여부 · 필터 펼침 후 스크롤 밀도.

### P1-8~P1-10 Home UI 정리 스프린트 관찰 (2026-06-30)

> **기준 커밋:** `cb4131e` (`origin/main` tip) · Home search-first · Slice 1 앱 테마 · Slice 2 사이드바 `나만의 서재`

| ID | 관찰 | 판정 | 비고 |
|----|------|:----:|------|
| — | **검색창 상단 이동** (AppBar → 본문 최상단) | ✅ 긍정 | taxonomy보다 검색·감상 진입이 앞섬 — P1-7 의도와 일치 |
| — | **preview rail `내 감상` 카드** | ✅ 긍정 | Agent loop 메시지와 정합 · §3.1 양호 판정 유지 |
| **P1-8** | **raw wiki link 노출** (프리뷰·연결·Sanctum 등) | ⚠️ P1 | 사용자-facing UI에 URL/위키 원문 링크가 그대로 보임 — 마스킹·라벨·내부 링크 처리 필요 |
| **P1-9** | **Home 중앙 개인 감상 밀도 부족** | ⚠️ P1 | rail·Workbench에는 감상이 보이나 **대시보드 본문**에는 개인 기록이 약함 — 계속 탐험하기·히어로 대비 감상 CTA/요약 밀도 검토 |
| **P1-10** | **앱 테마 적용 범위** (Slice 1) | 🔶 dogfood 필요 | palette·scaffold 배경은 전역 적용 — **사이드바·프리뷰·다이얼로그** 등 잔여 `AkashaColors` 하드코딩과 대비·가독성은 **수동 dogfood**로 확정 전 |

**정리 스프린트 범위:** 위 P1은 **기록·우선순위만** — 신규 기능·Agent operation layer·M3·폴더 구조 이동은 **진행하지 않음**.

### P2 — polish

| ID | 이슈 | 제안 |
|----|------|------|
| **P2-1** | 빈 메모 카피 불일치 | Home / Sanctum 공통 `JournalReflectionPreview.emptyMemoHint` 재사용 |
| **P2-2** | Sanctum 제목 `Colors.white` 하드코딩 | `AkashaColors.textPrimary` + typography 토큰 |
| **P2-3** | `기록하기` CTA가 **완전 빈 기록**에만 | 메모만 있는 경우에도 상세 진입 링크 (선택) |
| **P2-4** | registry tags vs user tags 미구분 | 개인 태그만 칩 표시 (catalog tags 필터) |
| **P2-5** | 수동 dogfood용 **긴 감상·다태그 fixture** 없음 | `vault_agent_slice_long.md` 추가 (테스트·문서용) |

---

## 6. P0-1 적용 내역

**적용:** `PreviewCoreInfoRow.rating` — `Text(' / 5', …)` (기존 `/ 10` 제거)

```dart
// preview_record_view_model.dart — PreviewCoreInfoRow.rating
Text(' / 5', style: AkashaTypography.caption),
```

**검증:** `test/preview_record_view_model_test.dart` — `/ 5` 표시 · `/ 10` 부재 · 수동 dogfood §7 #7

---

## 7. 수동 dogfood 체크리스트 (Windows)

**전제:** Release 빌드 · 볼트 연결 · `vault_agent_slice_full.md`를 animation 폴더에 배치 · 앱 reload

| # | 확인 | Pass |
|---|------|:----:|
| 1 | 320px rail 스크롤 시 **내 감상**이 연결 섹션과 겹쳐 보이지 않음 | ☐ |
| 2 | full fixture — 별·상태·태그·메모 **한 눈에** 읽힘 | ☐ |
| 3 | create fixture — 최소 메모만 있어도 **어색하지 않음** | ☐ |
| 4 | 긴 감상(300자+) — 프리뷰 발췌·Sanctum 전문 **둘 다** 자연스러움 | ☐ |
| 5 | 태그 8개 — rail **과밀** 여부 | ☐ |
| 6 | Sanctum 보기 탭 — memo가 **명대사 카드**와 구분됨 | ☐ |
| 7 | P0-1 — 핵심 정보 **4.5 / 5**와 내 감상 별점 일치 | ☐ |

결과는 [AGENT_VAULT_LOOP_SLICE.md](../active/AGENT_VAULT_LOOP_SLICE.md) §5에 이어 기록.

---

## 8. 총평

| 영역 | 한 줄 |
|------|------|
| **방향** | Agent loop「개인 감상을 rail·Sanctum에 노출」— **제품 메시지와 일치** |
| **Home** | 카드 톤·계층 **양호**. P0-1 rating 스케일 **적용**. 이중 표시·발췌 품질은 P1 |
| **Sanctum** | 본문 카드는 읽기 좋음. **제목 분리**만 손보면 「감상 카드」 완성도 상승 |
| **Fixture** | Agent markdown ↔ 파서 ↔ UI **대체로 정합**. watchlist 상태·registry tag edge는 수동 확인 |

**권장 순서:** §7 수동 dogfood → P1-1·P1-2·**P1-8~P1-10** → (정리 스프린트 종료 후) 구현 확장 재개.

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-30 | 초안 — 코드·fixture 기반 UI/UX dogfood review · P0~P2 분류 |
| 2026-06-30 | P0-1 적용 — 핵심 정보 평점 `/ 5` · 테스트 추가 |
| 2026-06-30 | P1-7 Home 검색·접이식 필터 slice · `HomeBrowseSearchChrome` |
| 2026-06-30 | 정리 스프린트 — P1-8~P1-10 dogfood 관찰 (검색 상단·rail 감상 긍정 · wiki link·중앙 밀도·앱 테마) · tip **cb4131e** |
