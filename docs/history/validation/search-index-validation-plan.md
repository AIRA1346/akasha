# Search Index Validation Plan

> 목표: **Architecture Validation** — 구조 변경 전에 search_index가 정말 첫 번째 병목인지 **최종 확정**
>
> AKASHA의 목표는 400작품 Registry가 아니라 **세상의 모든 작품을 아카이빙할 수 있는 시스템**이다.
> 100만 작품 이상을 전제로 한 확장성 검토는 반드시 필요하다.
> 다만 **지금 당장 100만 대응 리팩터링**과 **실제 병목 검증**은 다른 문제다.

선행 문서:

- [registry-scaling-review.md](registry-scaling-review.md) — 규모별 가설
- [registry-bottleneck-validation-report.md](registry-bottleneck-validation-report.md) — 402작품 실측 + 병목 후보 순위

---

## 1. 검증 질문

| # | 질문 | 확정 기준 |
|---|------|-----------|
| Q1 | search_index가 **실제 첫 번째 병목**인가? | 다른 축(shard·quality·franchise)보다 먼저 하드/UX 임계 도달 |
| Q2 | **실제 임계 규모**는 어디인가? | GitHub 100MB · parse · RSS · search latency 중 최초 FAIL |
| Q3 | 10k / 100k / 300k / 1M에서 **parse·memory·search**가 어떻게 변하는가? | 규모별 실측 곡선 |
| Q4 | Git 저장소에 **어떤 영향**이 있는가? | 단일 파일 push 한계 · clone 크기 |

**이 단계에서 하지 않는 것**

- search_index를 어떤 구조로 바꿀지 **결정**
- 샤드화 / inverted index / SQLite FTS **구현**
- shardBits 마이그레이션
- 앱 런타임 코드 변경

---

## 2. 검증 절차 (4단계)

```
1. 병목 가설 수립     ← Bottleneck Validation Report (완료)
2. 실측              ← 본 Plan (진행)
3. 병목 우선순위 확정 ← Validation Report 합의
4. 구조 변경 검토     ← Validation 통과 후에만
```

---

## 3. Synthetic Dataset

### 3.1 규모

| Label | 작품 수 | 용도 |
|-------|---------|------|
| `402_real` | 402 | 운영 파일 기준선 (생성 없음) |
| `10k` | 10,000 | 초기 성장 구간 |
| `100k` | 100,000 | GitHub·메모리 경고대 |
| `300k` | 300,000 | 100MB 한계 근접 구간 |
| `1M` | 1,000,000 | 최종 목표 규모 스트레스 |

### 3.2 프로파일

Synthetic entry는 `registry_builder` 산출물과 **동형**이다.

포함 필드:

- `workId`, `title`, `shardId`, `category`, `domain`
- `creator`, `tags`, `titles`, `searchTokens`
- `posterPath` (50%), `qualityScore`, `qualityTier`

생성 규칙:

- `workId` = `wk_` + 9자리 순번
- `shardId` = `{category}_{sha256(workId)[0:2]}`
- `searchTokens` = `buildWorkSearchTokens()` (운영과 동일 함수)
- 카테고리 7종 순환 분포

### 3.3 산출물 위치

```
akasha-db/pipeline/artifacts/search_index_validation/
  search_index_10000.json
  search_index_100000.json
  search_index_300000.json
  search_index_1000000.json
  search_index_validation_report.md
```

`pipeline/artifacts/`는 `.gitignore` 대상 — **Git 저장소에 synthetic 파일을 넣지 않는다.**

---

## 4. 측정 항목

| KPI | 측정 방법 | 임계 (초안) |
|-----|-----------|-------------|
| **fileBytes** | 생성 파일 크기 | GitHub **100 MB** hard / **50 MB** warn |
| **bytesPerWork** | fileBytes ÷ N | 402 실측 ~669 B/work와 비교 |
| **parseMs** | `readAsString` + `json.decode` | > 3s warn · > 10s fail (UX) |
| **rssDelta** | parse 전후 `ProcessInfo.currentRss` | > 200 MB warn · OOM = fail |
| **searchMs** | 선형 scan × 200회 | ms/query 추세 |
| **githubHardLimit** | fileBytes ≥ 100 MB | push 거부선 |

검색 벤치마크는 앱의 `shardIdsForQuery()` / `registryEntryMatchesQuery()`와 **동형** 선형 스캔이다.

---

## 5. 실행

```bash
# 전체 규모 (402 real + 10k + 100k + 300k + 1M)
dart run tool/search_index_validation.dart

# 1M 제외 빠른 실행
dart run tool/search_index_validation.dart --skip-1m

# 선택 규모
dart run tool/search_index_validation.dart --scales 10000,100000,300000
```

보고서: `akasha-db/pipeline/artifacts/search_index_validation/search_index_validation_report.md`

---

## 6. 합격 / 불합격 (Validation Gate)

### search_index = 첫 병목 **최종 확정** 조건

아래를 **모두** 만족하면 Bottleneck Validation의 1순위 가설이 확정된다.

1. **GitHub 100MB**에 search_index가 shard·franchise·manifest보다 **먼저** 도달
2. **parseMs·rssDelta**가 100k 이전 또는 100k에서 UX 임계 초과
3. **searchMs/query**가 규모에 선형 증가 (O(n) 확인)
4. 동일 규모에서 shard parse·franchise parse가 search_index보다 **작음**

### 구조 변경 논의 **시작** 조건

- 위 Validation Gate 통과 (실측 보고서 합의)
- 팀이 "첫 병목 = search_index"에 **명시적 동의**
- 그 다음에만 `Search Index Architecture Options` 문서 작성

---

## 7. 실측 결과 (2026-06-08, Dart VM · Windows)

```bash
dart run tool/search_index_validation.dart --search-iterations 100
```

| scale | file | bytes/work | parse | RSS Δ | search (100×) | ms/query | Git 100MB |
|-------|------|------------|-------|-------|---------------|----------|-----------|
| **402_real** | 262.5 KB | 668.7 | 18 ms | 1.3 MB | 45 ms | **0.45 ms** | OK |
| **10k** | 6.43 MB | 673.7 | 87 ms | 16.8 MB | 1,085 ms | **10.85 ms** | OK |
| **100k** | 64.89 MB | 680.4 | 769 ms | 342 MB | 10,581 ms | **105.81 ms** | WARN |
| **300k** | 196.07 MB | 685.3 | 2,455 ms | 920 MB | 31,566 ms | **315.66 ms** | **FAIL** |
| **1M** | 655.20 MB | 687.0 | 7,746 ms | 3,116 MB | 104,039 ms | **1,040 ms** | **FAIL** |

산출물: `akasha-db/pipeline/artifacts/search_index_validation/search_index_validation_report.md`

### 7.1 임계점 (실측 기반)

| 임계 | 최초 도달 규모 | 근거 |
|------|----------------|------|
| GitHub 100 MB 단일 파일 | **~147k–300k** | 100k=64.9MB · 300k=196MB |
| RSS Δ > 200 MB | **100k** | parse 후 +342 MB |
| parse > 3 s | **1M** | 7.7 s (300k=2.5 s) |
| search > 100 ms/query | **100k** | 105.8 ms/query |
| search > 1 s/query | **1M** | 1,040 ms/query |

### 7.2 가설 대비

| scale | 예상 file | 실측 file | 오차 |
|-------|-----------|-----------|------|
| 10k | ~6 MB | 6.43 MB | +7% |
| 100k | ~64 MB | 64.89 MB | +1% |
| 300k | ~191 MB | 196.07 MB | +3% |
| 1M | ~638 MB | 655.20 MB | +3% |

bytes/work ≈ **670–687 B** — 402 실측(668.7)과 synthetic이 **1~3% 이내**로 일치한다. extrapolation 가설은 신뢰할 수 있다.

### 7.3 Validation Gate 판정

| 조건 | 결과 |
|------|------|
| GitHub 100MB에 search_index가 먼저 도달 | ✅ 300k에서 FAIL (shard 단일 파일은 동일 규모에서 ~315 KB 수준) |
| parse·RSS가 100k에서 UX 임계 | ✅ RSS 342MB · search 106ms/query |
| search가 O(n) 선형 증가 | ✅ 402→1M: 0.45ms → 1,040ms/query |
| 구조 변경 전 실측 완료 | ✅ |

**결론: search_index = 첫 번째 병목 — 실측으로 최종 확정.**

구조 변경 논의는 이 결과 합의 후 `Search Index Architecture Options` 단계에서 시작한다.

---

## 8. 이후 단계

| 순서 | 문서/작업 | 상태 |
|------|-----------|------|
| 1 | Search Index Validation Report (실측) | ✅ |
| 2 | 병목 우선순위 최종 확정 | ✅ search_index |
| 3 | [Search Index Architecture Options](search-index-architecture-options.md) | ✅ 후보 비교 |
| 3b | [Search Workload Profile](search-workload-profile.md) | ✅ 가정 v0 |
| 4 | Search Workload Validation (SW1) | ⏳ 권장 |
| 5 | Architecture Options POC (A/B/E1) | ⏳ Workload 후 |
| 5 | Search Index Refactor | ⏸ POC + ADR 후 |
| 6 | Discovery Throughput Validation | 📋 장기 |

---

## 9. 원칙 (재확인)

- **100만 작품 목표**는 유지한다.
- **지금 당장 100만 대응 리팩터링**은 하지 않는다.
- **100만에서 무엇이 먼저 깨지는지 검증**을 우선한다.
- 목표는 아키텍처 변경이 아니라 **병목 검증**이다.
- Validation 결과가 나온 후에만 구조 변경을 논의한다.
