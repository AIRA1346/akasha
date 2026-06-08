# AKASHA Discovery Policy — 발견 계층 경계

> **상태:** v1 (2026-06-08)  
> **지위:** [data-policy.md](data-policy.md) 하위 — Discovery·official_sync 구현의 **고정 경계**  
> **전제:** Discovery는 **외부 DB 복제가 아니다.** Registry에 없는 작품의 **존재 신호**만 얻는다.

---

## 0. 한 줄 원칙

```
AniList 68만 건 가져오기  ≠  Discovery 목표
신규 wk_ 순증 (Facts만)   =  Discovery 목표
```

| | Discovery | Registry |
|--|-----------|----------|
| 역할 | 존재 신호 | 영구 SoT |
| AKASHA identity | 없음 (`externalIds` 참조만) | **`wk_`** |
| Canonical source | **아님** | **AKASHA** |

**AniList는 Discovery Source일 뿐 Canonical Source가 아니다.**  
TMDB·Steam·OpenLibrary·VNDB와 충돌 시에도 AniList가 우선권을 갖지 않는다.

---

## 1. official_sync — Fact만 생성

### 허용 (Signal → Registry Minimal Core)

| 필드 | Registry 매핑 |
|------|---------------|
| `anilist` id | `externalIds.anilist` |
| title (romaji / english / native) | `title` / `titles` |
| releaseYear (startDate·seasonYear) | `releaseYear` |
| creator (staff·studios 이름, 선별) | `creator` |
| format → category | `category` |
| synonyms (선별) | `aliases` |

### 금지 (Signal·Registry 모두)

| 필드 | 이유 |
|------|------|
| description / synopsis | Copyright Risk |
| tags (AniList 콘텐츠 태그) | UGC |
| coverImage / bannerImage | Copyright Risk |
| characters | Copyright Risk |
| popularity / score / favourites | DB 미러링 |
| relations (전체) | Canonicalization 힌트만, Signal 폐기 |
| **raw API response** | 절대 저장 금지 |

코드: `tool/discovery/signal_gate.dart` · `tool/discovery/anilist_facts.dart`

---

## 2. Signal 영구 저장 금지

| | Git 저장 | 비고 |
|--|:--------:|------|
| `pipeline/discovery/manifest.json` | ✅ | 채널·한도·KPI 메타 |
| `pipeline/discovery/cursors/*.json` | ✅ | cursor 상태만 |
| candidate queue / `*.jsonl` | ❌ | 실행 중 메모리·CI artifact |
| AniList 응답 JSON | ❌ | fetch 직후 Facts 추출 → 폐기 |
| raw dump | ❌ | |

`akasha-db/pipeline/.gitignore`가 ephemeral 경로를 차단한다.

---

## 3. Registry 등록 조건 (Minimal Core)

Discovery가 Registry에 쓸 수 있는 **최소 단위:**

```json
{
  "workId": "wk_000012345",
  "title": "체인소 맨",
  "category": "manga",
  "releaseYear": 2018,
  "externalIds": { "anilist": "101922" }
}
```

| 필드 | 필수 |
|------|:----:|
| `workId` | ✅ (할당 후) |
| `title` | ✅ |
| `category` | ✅ |
| `releaseYear` **또는** `externalIds` | ✅ (둘 중 하나) |
| `description` / `posterPath` / `tags` | ❌ 없어도 등록 |

---

## 4. Discovery 성공 지표 (KPI)

**중요하지 않음:** 하루 몇 천 건 수집했는가

**중요함:**

| KPI | 의미 |
|-----|------|
| `signalsFetched` | 소스에서 읽은 신호 수 |
| `signalsNew` | Registry에 없던 신호 |
| `wkCreated` | 신규 `wk_` 생성 수 (**순증**) |
| `dedupeRejected` | 중복으로 등록 안 함 |
| `policyRejected` | data_policy 위반으로 차단 |
| `policyViolations` | **0이어야 함** |

목표: **품질 유지 상태에서의 순증**, not 수집량.

---

## 5. 구현 순서 (확정)

| # | 작업 | 상태 |
|---|------|------|
| 1 | Discovery 경계 문서 + manifest 스키마 | ✅ 본 문서 |
| 2 | `official_sync` 인터페이스 + signal_gate | ✅ 코드 |
| 3 | AniList Contract Test Runner (HTTP, 100건) | ✅ 코드 |
| 4 | Shadow Write + Registry 영향 측정 | ✅ 코드 |
| 4.5 | 수동 검증 리포트 (wouldCreate 10건 샘플) | ✅ 코드 |
| 5 | **Registry Impact Test** (5~10건 선정·리포트) | ✅ 코드 |
| 5a | **Registry Snapshot Compare** (402 vs 412 diff) | ✅ 코드 |
| 5c | **Product Value Review** (제품·정책 게이트) | ✅ 코드 |
| 5d | **AniList Removal Test** (독립 Registry 증명) | ✅ 코드 |
| 5b | 실제 patch + CI | **보류** — 3-gate 통과 후 |
| 6 | 100건 Trial Batch — Product+Diff 통과 후만 | ⏳ Phase C |
| 7 | `enabled=true` 자동 동기화 | ⏳ Phase D |

---

## 6. 채널 로드맵 (단계별)

| 목표 Registry 규모 | 활성 채널 |
|--------------------|-----------|
| 10,000 | AniList + Steam + OpenLibrary |
| 50,000 | + TMDB |
| 100,000 | + VNDB |
| 100,000+ | Wikidata·웹 발견 |

**지금:** `anilist_animation` 1채널만 manifest에 정의, `enabled: false`.

---

## 7. Shadow Write (Phase A — 현재)

**목표:** Registry 등록이 아니라 **Registry 영향 측정**.

```
Minimal Core Draft
  → wk_ 할당 (shadow, 미저장)
  → shard 계산
  → dedupe 검사
  → registry_builder 시뮬레이션 (in-memory)
```

| 출력 | 의미 |
|------|------|
| `wouldCreate` | 신규 `wk_`·shard 삽입 예정 |
| `wouldMerge` | 기존 Registry와 externalId 일치 |
| `mergeCandidates` | fuzzy dedupe 성공 (Discovery 성공 사례) |
| `wouldReject` | policy·contract 차단만 |
| `targetShardDistribution` | shard 편중 여부 |
| `qualityScoreDistribution` | 점수 분포 (0~1 tier 몰림 탐지) |
| `duplicateRate` | `(wouldMerge + mergeCandidates) / input` |

```bash
dart run tool/discovery/shadow_write.dart --offline   # CI
dart run tool/discovery/shadow_write.dart --live      # 수동 AniList
```

**mergeCandidate:** fuzzy title 중복 = dedupe **성공** (`wouldReject` 아님)

**핵심 KPI:** `mirroringIntegrityPassed` — 외부 DB 미러링으로 변질되지 않았는가

---

## 8. Manual Review Report (Phase A.5)

Trial Write **전** AKASHA Identity 검증 — 대량 쓰기가 아니라 **10건 수동 검증**.

각 샘플에 대해:

1. 왜 신규로 판단되었는가
2. 어떤 필드가 저장되는가 (Minimal Core)
3. Data Policy 위반 가능성
4. AniList 제거 후 `wk_` 정체성 유지 여부
5. 검색 가치 (searchTokens·Gap)
6. **User Value** — 지금 Registry에 넣을 **사용자 가치** (Prioritization, 필터 아님)

| User Value | 예시 |
|------------|------|
| **High** | Core 작품, 검색 Gap, 장르 대표작, Franchise 확장 |
| **Low** | 희귀 단편, 정보 부족 1회성, 검색 수요 낮음 예상 |

```bash
dart run tool/discovery/review_report.dart --live
dart run tool/discovery/review_report.dart --live \
  --output akasha-db/pipeline/artifacts/review.md
```

**Phase B(Impact Test) 진행 조건:** Manual Review + User Value 수동 확인

---

## 9. Registry Impact Test (Phase B)

**목표 수정:** AniList → Registry 쓰기 ❌ → **Registry 품질이 실제로 좋아지는지** 검증 ✅

**핵심 KPI:** 등록 건수 < **Coverage KPI** (Gap·검색 토큰·animation 커버리지)

### 선정 (5~10건)

`wouldCreate` + **User Value High** 중:

1. **Registry Gap** — 기존에 없던 제목·searchToken
2. **Core Work** — 대표작 (creator·titles·aliases)
3. **Franchise 연결** — `franchise_groups` 인접 IP

### mergeCandidate (정책 확정)

| | |
|--|--|
| 성격 | 신규 작품 **아님** |
| 의미 | 기존 `wk_`에 `externalIds.anilist` **연결 후보** |
| Phase B | Impact Test 선정 **제외** → 링크 큐 (`artifacts/`) |

### 산출물

**Registry Impact Report** — Trial Write보다 **"왜 이 N건을 선택했는가"**가 본체.

```bash
dart run tool/discovery/registry_impact_test.dart --live
dart run tool/discovery/registry_impact_test.dart --live \
  --output akasha-db/pipeline/artifacts/impact_report.md
```

### 성공 기준

| | |
|--|--|
| 기술 | shard patch + strict CI (수동 승인 후) |
| **검색 품질** | 신규 searchTokens·실제 검색 가능 |
| **Coverage** | Gap fill 비율 (`coverageDelta`) |
| **사용자 체감** | "들어온 게 맞다" (수동) |

### Phase C 게이트

- `recommendPhaseC=false` → 5~10건도 체감 없으면 **100건 Batch 이유 없음**
- `recommendPhaseC=true` → Coverage·검색 가치 분명 → Discovery 확장 검토

---

## 10. Registry Snapshot Compare (Phase 5a — 5b 게이트)

**질문:** "AKASHA가 실제로 더 좋아졌는가?" (10건 추가 사실이 아님)

| Snapshot | |
|----------|--|
| Before | 현재 Registry (402) |
| After | 선정 10건 **가상 적용** (412) |

### 비교 항목

1. **검색** — 0건이던 검색어 발견, 랭킹
2. **Coverage** — creator / aliases / releaseYear (animation)
3. **Franchise** — franchise gap 감소 신호
4. **User-visible** — 체감 가능한 신규 검색 성공 사례

```bash
dart run tool/discovery/registry_diff_test.dart --live
```

산출물: `akasha-db/pipeline/artifacts/registry_diff_report.md`

### 5b 성공 기준

| | |
|--|--|
| ❌ | write 성공, CI 통과만 |
| ✅ | **Registry Improvement 증명** (`recommend5bPatch`) |

`recommend5bPatch=false` → 5b **보류**, 선정 기준 수정

---

## 11. Product Value Review (Phase 5c — 5b 게이트)

**기술 검증 완료.** Contract · Shadow · Impact · Diff 통과.

**5b Patch 보류** — 이유: 기술이 아니라 **제품·정책**.

### 핵심 질문

> AniList에 **존재해서** 추가되는가?  
> AKASHA 사용자에게 **가치 있어서** 추가되는가?

| 검토 질문 |
|-----------|
| 현재 **사용자 검색 Gap**을 해결하는가? |
| **추천/관계망** 품질을 높이는가? |
| AniList 없이도 **AKASHA에 남아야** 하는가? |
| **외부 DB 복제** 오해를 받지 않는가? |
| 우선순위가 **User Value** 기반인가? |

### Discovery KPI (수정)

| 구분 | KPI |
|------|-----|
| 기술 (기존) | `wouldCreate` · `coverageDelta` · `zeroToHit` |
| **제품 (추가)** | `userValueCoverage` · `userSearchGapResolved` · `independentRegistryValue` |

```bash
dart run tool/discovery/product_value_review_cli.dart --live
```

산출물: `akasha-db/pipeline/artifacts/product_value_report.md`

### additionDriver

| 값 | 의미 |
|----|------|
| `userGap` | Gap·AKASHA 가치 (AniList = 발견 채널) |
| `both` | Gap + 정체성; AniList = **참조만** |
| `anilistPresence` | AniList 존재 위주 → **5b 부적합** |

**5b 조건:** Product Value Review **수동 통과** + KPI 임계값

AKASHA ≠ "많이 모은 DB" → **"사용자에게 가치 있는 작품 사전"**

---

## 12. AniList Removal Test (Phase 5d)

**목표:** AKASHA가 AniList **미러가 아닌 독립 Registry**임을 증명.

선정 10건에 대해:

- `externalIds.anilist` 제거
- AniList 출처·ingest 메타 제거

### 4질문 (모두 YES → PASS)

1. 여전히 AKASHA에 **존재해야** 하는가?
2. **사용자 검색** 가치가 있는가?
3. title / aliases / creator / releaseYear로 **정체성** 유지?
4. AniList가 내일 사라져도 **Registry에 남아야** 하는가?

| 결과 | 의미 |
|------|------|
| **PASS** | AKASHA 독립 가치 |
| **FAIL** | AniList 존재에 의존 |

```bash
dart run tool/discovery/anilist_removal_cli.dart --live
```

산출물: `akasha-db/pipeline/artifacts/anilist_removal_report.md`

### KPI 계층 (분리)

| 계층 | KPI |
|------|-----|
| **Discovery** | `wouldCreate` · `mergeCandidates` · `coverageDelta` · `zeroToHit` |
| **Product** | `userSearchGapResolved` · `aliasCoverageIncrease` · `searchRecallIncrease` · `franchiseCoverageIncrease` |
| **Independence** | `independentRegistryValue` · `percentWorksJustifiedWithoutAniList` |

### 5b Patch Gate (모두 true)

- `recommend5bPatch` (기술)
- `productReviewApproved`
- `anilistRemovalTestPassed`

→ `allow5bReview` — **수동 승인 후**에만 5b 검토

---

## 13. Contract Test Runner

**목표:** Discovery 수집기가 아니라 **Discovery Contract 검증**.

```
AniList GraphQL (허용 필드만)
  → Facts 변환
  → Signal Gate
  → Minimal Core Draft (wk_CONTRACT_DRAFT)
  → KPI 집계
```

| | 허용 | 금지 |
|--|:----:|:----:|
| `enabled=false` 수동 실행 | ✅ | |
| `trialBatchSize` (100) | ✅ | `dailyLimit` |
| cursor / manifest Git | ✅ | raw JSON·candidate queue |
| Registry Write | | ❌ (다음 PR) |

**출력 KPI:** `fetched` · `policyRejected` · `dedupeCandidates` · `minimalCoreDrafts` · `missingTitle` · `missingYearOrExternalId`

**성공 기준:** Policy 위반 0 · Raw 저장 0 · Fact 외 필드 0 · Minimal Core 생성 성공 (`contractPassed`)

```bash
# 오프라인 (CI)
dart run tool/discovery/official_sync.dart --contract-test --offline

# 라이브 AniList (수동)
dart run tool/discovery/official_sync.dart --contract-test
```

---

## 14. 관련 문서·코드

| 항목 | 경로 |
|------|------|
| 데이터 권리 | [data-policy.md](data-policy.md) |
| Discovery manifest | [akasha-db/pipeline/discovery/manifest.json](../akasha-db/pipeline/discovery/manifest.json) |
| Shadow write | `tool/discovery/shadow_write.dart` |
| Manual review | `tool/discovery/review_report.dart` |
| Registry Impact Test | `tool/discovery/registry_impact_test.dart` |
| Snapshot Compare | `tool/discovery/registry_diff_test.dart` |
| Product Value Review | `tool/discovery/product_value_review_cli.dart` |
| AniList Removal Test | `tool/discovery/anilist_removal_cli.dart` |
| Contract runner | `tool/discovery/contract_test_runner.dart` |
| AniList client | `tool/discovery/anilist_client.dart` |
| Signal gate | `tool/discovery/signal_gate.dart` |
| Fact 추출 | `tool/discovery/anilist_facts.dart` |
| CLI | `tool/discovery/official_sync.dart` |
| Manifest 로더 | `tool/discovery/discovery_manifest.dart` |
