# Sprint 04 — Phase A Baseline Report

> **단계:** Sprint 04 Phase A (측정 전용)  
> **목적:** enrich **적용 전** externalId Coverage **실측** · G2 50% 달성 가능성 검증  
> **기준일:** 2026-06-09  
> **측정 도구:** `dart run tool/coverage_sprint_04_baseline.dart --write-json`  
> **원본 산출:** `akasha-db/pipeline/artifacts/coverage_dashboard/sprint_04_baseline.json`

**금지 준수:** enrich 미실행 · Registry/데이터 **수정 없음** · dry-run cohort 로직만 사용

---

## Executive Summary

| 항목 | 값 |
|------|-----|
| **Registry 총 작품 수** | **430** |
| **현재 externalId coverage** | **201 / 430 = 46.74%** |
| **G2 목표 (50%)** | **215 / 430** |
| **G2 갭** | **+14 works** |
| **E1 (Steam) audit OK** | **15** |
| **E2 (TMDB poster) audit OK** | **0** |
| **E1만 적용 시 예상** | **216 / 430 = 50.23%** |
| **G2 50% 달성 가능 (cohort 기준)** | **예** (E1만으로 충분) |

---

## 1. Registry 개요

| 필드 | 값 |
|------|-----|
| 총 작품 수 | **430** |
| externalId 보유 | **201** |
| externalId 미보유 | **229** |
| **coverage** | **46.74%** |

**정의:** `externalIds` 맵에 **비어 있지 않은** provider 키가 1개 이상인 작품.

---

## 2. externalId Coverage — 전체

| 지표 | 값 |
|------|-----|
| numerator | 201 |
| denominator | 430 |
| **rate** | **0.4674** |
| **percent** | **46.74%** |
| G2 phase target | 50.0% (215 works) |
| Charter 90% target | 387 works (본 Phase 범위 외) |

`coverage_dashboard` 동일 시점 KPI: **46.7%** — **일치**.

---

## 3. Category별 Coverage

| category | total | with externalId | without | **coverage %** |
|----------|------:|----------------:|--------:|---------------:|
| animation | 90 | 41 | 49 | **45.6%** |
| book | 29 | 0 | 29 | **0.0%** |
| drama | 16 | 0 | 16 | **0.0%** |
| game | 144 | 110 | 34 | **76.4%** |
| manga | 116 | 49 | 67 | **42.2%** |
| movie | 30 | 0 | 30 | **0.0%** |
| webtoon | 5 | 1 | 4 | **20.0%** |

**관측**

- **game**이 유일하게 50% 초과 — Steam·TMDB 신호 밀집.
- **book · drama · movie**는 externalId **0%** — E1/E2 cohort **대상 아님** (본 Sprint in-scope 아님).
- 미보유 229작 중 **E1+E2 후보는 15작** — 나머지 214작은 poster/legacy deterministic 경로 **없음**.

---

## 4. Provider별 분포

작품 단위 집계 (해당 provider 키가 **비어 있지 않으면** 1회).

| provider | works | 비고 |
|----------|------:|------|
| **Steam** | **110** | 전부 `game` |
| **TMDB** | **91** | animation·manga 중심 |
| **IGDB** | **0** | Sprint 04 out-of-scope |
| **기타** | **0** | — |

**합계 (provider 키 수):** 201 — 작품당 **단일 provider**만 보유 (복수 키 작품 **0**).

---

## 5. Sprint 04 Cohort (dry-run · audit)

[sprint-04-charter.md](sprint-04-charter.md) §2.1 · `coverage_sprint_04_external_id.dart` 동형 로직.

### E1 — Steam candidate

| 필드 | 값 |
|------|-----|
| 모집단 | externalId **미보유** + Steam poster/legacy `appid` deterministic |
| 후보 수 | **15** |
| audit OK | **15** |
| audit blocking | **0** |
| attach 방식 | `externalIds.steam` ← posterPath 또는 legacyIds |

### E2 — TMDB poster candidate

| 필드 | 값 |
|------|-----|
| 모집단 | externalId **미보유** + TMDB poster 캐시 역매핑 |
| 후보 수 | **0** |
| audit OK | **0** |
| attach 방식 | `externalIds.tmdb` ← `tmdb_poster_cache.json` |

**해석:** @430 baseline에서 TMDB poster 역매핑 가능한 **미보유 작품이 이미 소진**됨. 잔여 G2 갭은 **E1(Steam)만**으로 메울 수 있음.

### E1 샘플 (10/15)

| workId | title | steam id |
|--------|-------|----------|
| wk_000000143 | 포털 2 | 620 |
| wk_000000144 | 더 엘더스크롤 V: 스카이림 | 489830 |
| wk_000000146 | 더 위처 3: 와일드 헌트 | 292030 |
| wk_000000270 | 파이널 판타지 XIV | 39210 |
| wk_000000275 | 몬스터 헌터: 월드 | 582010 |
| wk_000000276 | 니어: 오토마타 | 524220 |
| wk_000000277 | 승리의 여신: 니케 | 2358720 |
| wk_000000278 | 옥토패스 트래블러 | 921570 |
| wk_000000279 | 페르소나 5 로열 | 1687950 |
| wk_000000286 | 언더테일 | 391540 |

전체 목록: `sprint_04_baseline.json` · `sprint_04_externalid_report.json`

---

## 6. 예상 증가량 · G2 달성 가능 여부

| 시나리오 | add | 결과 count | **coverage %** | G2 50% |
|----------|----:|-----------:|---------------:|:------:|
| **현재 (baseline)** | — | 201 | **46.74%** | FAIL |
| **E1만 적용** | +15 | 216 | **50.23%** | **PASS** |
| **E1 + E2 적용** | +15 | 216 | **50.23%** | **PASS** |

| 판정 항목 | 결과 |
|-----------|------|
| G2 갭 (필요) | **+14** |
| E1 audit OK | **+15** ≥ 14 |
| E2 기여 | **0** |
| **G2 50% 달성 가능 (cohort·audit 기준)** | **가능** |

**주의**

- 본 표는 **deterministic attach 후보 + audit OK** 기준 **상한 추정**이며, **apply 전** 수치이다.
- Phase B apply 후 `registry_builder` · `quality_gate` · URV **회귀**로 최종 PASS를 확정한다.
- Charter 초안(402작 · 60/402) 대비 registry가 **430작**이며 externalId **201**은 Sprint 03/04 이전 partial apply 반영 상태일 수 있다 — **본 Phase A는 @430 재기준선**이다.

---

## 7. Phase B 진입 조건 (참고 · 본 문서 범위 외)

| # | 조건 |
|---|------|
| 1 | 본 baseline **승인** |
| 2 | `coverage_sprint_04_external_id.dart --apply --phase steam` (E1) |
| 3 | apply 후 KPI **≥215/430 (50%)** 재측정 |
| 4 | `quality_gate --strict` · SW1 · URV PASS |

---

## 8. 재현 명령

```bash
dart run tool/coverage_dashboard.dart
dart run tool/coverage_sprint_04_baseline.dart --write-json
dart run tool/coverage_sprint_04_external_id.dart --dry-run
```

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Sprint 04 Phase A baseline — @430 측정 전용 |
