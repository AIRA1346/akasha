# externalId Coverage Economics Plan — Sprint 04 (P1 / Q2)

> **목적:** Sprint 04 범위 확정 — **externalId G2 50%** Economics 검증 계획.  
> **전제:** Sprint 03 이후 · [phase2-late-stage-plan.md](phase2-late-stage-plan.md) Q2 · [phase2-governance-review.md](phase2-governance-review.md)  
> **기준일:** 2026-06-09 · Registry **402작**

**금지:** 본 문서 작성 시점 **enrich · 실험 실행 · 구조 변경**.

**Charter 연계:** [phase2-charter.md](phase2-charter.md) §5 **#4** — externalId coverage **≥ 50% (G2)**.

---

## Executive Summary

| 항목 | 값 |
|------|-----|
| **현재** | **60/402 (14.9%)** — `externalIds` non-empty |
| **G2 50%** | **201/402** — **+141작** 필요 |
| **공급원 (보유 60작)** | **TMDB 100%** (60/60) · Steam/IGDB **0** |
| **미보유 342작 attach 신호** | Steam poster/legacy **125** · TMDB poster **31** · 수동 **186** |
| **Sprint 02 추정 (50%)** | **18.8h** (1,128분) · missing tier **100% manual** 가정 |
| **재추정 (poster 우선 cohort)** | auto attach **~46–100%** (141작 선별 시 **~100%** 가능) |

**Sprint 04 핵심:** Sprint 02 **manual-heavy** externalId 모델이 **poster·legacy 신호**를 반영하면 **과대 추정**일 가능성 (titles.en Sprint 03과 동형).

---

## 1. 현재 externalId 현황 (Sprint 03 이후)

### 1.1 Coverage Dashboard

**도구:** `dart run tool/coverage_dashboard.dart`  
**산출:** `coverage_snapshot.json` → `kpis.external_id`

| 지표 | 값 | target | status |
|------|-----|--------|--------|
| **external_id** | **60/402 (14.9%)** | 90% (phase **50%** G2) | **FAIL** |
| phaseTarget (G2) | 50% → **201/402** | — | **+141작** |

### 1.2 Sprint 02 Economics (갱신 실행 · 동일 수치)

**도구:** `coverage_sprint_02_economics.dart` · `sprint_02_economics.json`

| 항목 | 값 |
|------|-----|
| missingCount | **342** |
| remainingToTarget (90%) | **+302** |
| remainingToTarget (**50%**) | **+141** |
| avgMinutesPerMissingWork | **~8.7분** |
| tierBreakdown (missing) | manual_low **308** · manual_high **34** |
| automation (Sprint 02 tier) | **0%** |

> Sprint 02 `automation 0%`는 **이미 externalId가 있는 작품** 기준 tier가 아니라, **미보유 작품**에 `_enrichTier`를 적용한 결과다. 미보유 작품은 tmdb/steam/igdb 키가 없어 **전원 manual_low/high**로 분류된다 (§3 참고).

### 1.3 URV / SW1

| 지표 | 값 | externalId 연계 |
|------|-----|-----------------|
| URV exactId ingress | **100%** (60/60) | ID **있는** 작품만 분모 |
| SW1 recall@10 | **100%** | externalId 밀도와 **직교** (402 쿼리 세트) |

**시사:** externalId ramp의 **1차 목표**는 Charter G2·dedupe **variant fallback**·Economics — SW1 100% **유지가 하한**.

---

## 2. externalId 공급원 분류

### 2.1 보유 작품 (60작) — 키 분포

| 공급원 | 작품 수 | 비율 | 비고 |
|--------|:-------:|:----:|------|
| **TMDB** (`externalIds.tmdb`) | **60** | **100%** | animation · manga · drama 등 |
| **Steam** (`externalIds.steam`) | **0** | 0% | — |
| **IGDB** (`externalIds.igdb`) | **0** | 0% | — |
| **기타** (openlibrary · mal · anilist 등) | **0** | 0% | 402 내 **미사용** |

### 2.2 poster·legacy 신호 (미보유 342작 포함 전체)

| 신호 | 작품 수 | 용도 |
|------|:-------:|------|
| TMDB `posterPath` (`image.tmdb.org`) | **91** | 그중 **31작**은 externalId **미기록** |
| Steam `posterPath` / `steam/apps/` | **125** | 대부분 **game** · externalId **미기록** |
| `extensions.posterSource: tmdb` | (TMDB poster와 대부분 중복) | TMDB ID 후보 |
| legacy `appid{n}` / `gen_game_appid*` | game shard | Steam appId 추출 (Sprint 03 `steam_fetch` 동형) |

### 2.3 카테고리 — externalId 미보유 (342작)

| category | missing | 비고 |
|----------|:-------:|------|
| **game** | **140** | Steam poster·legacy **주력** |
| **manga** | 82 | TMDB poster·수동 혼합 |
| **animation** | 57 | TMDB poster 후보 |
| **movie** | 26 | TMDB 후보 |
| **book** | 24 | openlibrary 등 **수동** |
| **drama** | 12 | TMDB 후보 |
| **webtoon** | 1 | 수동 |

### 2.4 공급원 → attach 방식 (계획 · 구조 변경 없음)

| tier | 공급원 | attach 방법 (기존 도구·신호) | Sprint 03 유사 |
|------|--------|------------------------------|----------------|
| **auto_high** | **Steam** | `posterPath` / legacy → `externalIds.steam` = appId | `steam_fetch` · `_resolveSteamAppId` |
| **auto_high** | **TMDB** | `posterPath` + `posterSource:tmdb` → TMDB ID (기존 poster 캐시·검증) | `resolveTmdbId` · `poster_verification` |
| **auto_medium** | **IGDB** | game · 수동 매핑 또는 API ( **402 내 도구 미실측** ) | 후속 |
| **auto_medium** | **openlibrary** | book ISBN/OLID — **수동·반자동** | — |
| **manual** | **기타** | book · webtoon · ID 신호 없음 | maintainer 조사 |

---

## 3. 자동화 가능 비율 추정

### 3.1 Sprint 02 모델 (보수)

| cohort | 작품 수 | tier | automation |
|--------|:-------:|------|:----------:|
| missing externalId 전체 | 342 | manual_low **308** · manual_high **34** | **0%** |

단가: manual_low **8분** · manual_high **15분** ([coverage_sprint_02_economics.dart](../tool/coverage_sprint_02_economics.dart)).

### 3.2 poster·legacy 신호 기반 (현 데이터 재분류)

**미보유 342작** 중 attach 신호:

| 신호 | 작품 수 | 제안 tier |
|------|:-------:|-----------|
| Steam poster 또는 `appid` legacy | **125** | **auto_high** |
| TMDB poster (ext 없음) | **31** | **auto_high** (ID resolve 필요) |
| 신호 없음 | **186** | **manual** |

| 지표 | 값 |
|------|-----|
| **auto attach 후보 (중복 제거 전)** | **156** (125+31) |
| **auto 비율 (342 기준)** | **~45.6%** |
| **G2 +141작만 선별 시** | Steam 125 + TMDB 31 ≥ 141 → **~100% auto cohort 가능** (우선순위 정렬 전제) |

### 3.3 Sprint 03 titles.en 교훈 적용

| 시나리오 | +141작 @ 50% | automation 가정 | human-equivalent |
|----------|--------------|-------------------|------------------|
| **A. Sprint 02** | 141 | 0% · avg **8.7분** | **~18.8h** |
| **B. poster 우선** | 141 | **100%** · **2분/작** (auto_high) | **~4.7h** |
| **C. 혼합 (46% auto)** | 141 | 65 auto @2분 + 76 manual @8분 | **~12.3h** |

**검증 필요 (Sprint 04 실험):** 시나리오 B의 wall clock · TMDB ID resolve 실패율 · `poster_verification` 정합.

---

## 4. G2 50% 달성 경로

### 4.1 목표

```
현재:  60/402 (14.9%)
목표: 201/402 (50.0%)
갭:   +141 works with non-empty externalIds
```

### 4.2 권장 cohort 전략 (실행 순서 · 계획)

| Phase | 대상 | 예상 작품 수 | 공급원 | 근거 |
|:-----:|------|:------------:|--------|------|
| **E1** | Steam poster 보유 · ext 없음 | **≤125** | `externalIds.steam` | URL/legacy **deterministic** |
| **E2** | TMDB poster 보유 · ext 없음 | **≤31** | `externalIds.tmdb` | poster 캐시·검증 기존 |
| **E3** | G2 50% 잔여 | **≤141−E1−E2** | 혼합 | E1+E2 ≥141이면 **E3 불필요** |
| **E4** | 50% 초과·90% 방향 | 나머지 | manual 위주 | Phase 2 후반 |

**판단:** E1+E2만으로 **141작 충족 가능** (125+31=156 ≥ 141) — **game+animation TMDB subset** 우선이 Economics·리스크 최소.

### 4.3 품질·거버넌스 (enrich 없이 계획만)

| 게이트 | 적용 |
|--------|------|
| `poster_verification.isPosterVerified` | TMDB attach 후 |
| `quality_gate --strict` | 배치 후 |
| SW1 · URV | **≥ 100%** 유지 |
| URV exactId | **100%** 유지 |

**금지:** ID만 채우고 poster 불일치 — [coverage-quality-governance.md](coverage-quality-governance.md) I3 위반.

---

## 5. 예상 비용 모델

### 5.1 Sprint 02 baseline (G2 50%)

| 항목 | 값 |
|------|-----|
| additionalWorks | **141** |
| estimatedMinutes | **1,128** |
| estimatedHours | **18.8** |
| maintainer-days @4h | **~4.7일** |

### 5.2 Sprint 04 검증 가설 (poster-priority cohort)

| 측정 | 추정 (가설) | 검증 방법 |
|------|-------------|-----------|
| **human-equivalent** | **4.7–12h** (시나리오 B–C) | Sprint 04 실측 · tier 단가 동일 |
| **wall clock** | titles.en Sprint 03 대비 **분 단위** 가능 | 스크립트 타이밍 |
| **실패/수동 fallback** | TMDB ID resolve **≤31건** 중 일부 | per-work method 로그 |

### 5.3 90% milestone (참고 · Sprint 04 범위 외 가능)

| milestone | +작업 | Sprint 02 추정 |
|-----------|------|----------------|
| **75%** (302/402) | +242 | **32.3h** |
| **90%** (362/402) | +302 | **40.7h** |

Sprint 04 **권장 범위**는 **G2 50% (+141)** Economics — 90%는 **별 Sprint** 또는 Phase 2 후반.

### 5.4 비용 민감도

| 변수 | 영향 |
|------|------|
| TMDB resolve 실패 → manual | +15분/작 · 31건 상한 |
| Steam appId 추출 실패 | game cohort · legacy fallback |
| 잘못된 ID attach | **품질** 비용 (수동 수정) — Quality Gate **미검출** |

---

## 6. 성공 조건

Sprint 04 **externalId Economics** 실험 성공 시:

| # | 조건 | 측정 |
|---|------|------|
| S1 | **externalId ≥ 50%** | **≥201/402** · `coverage_dashboard` |
| S2 | **Charter §5 #4** | G2 목표 **달성** |
| S3 | **회귀** | SW1 · URV **≥ Sprint 03 baseline (100%)** |
| S4 | **URV exactId** | **100%** 유지 |
| S5 | **Quality** | `quality_gate --strict` **PASS** |
| S6 | **Economics** | Sprint 02 **18.8h** vs 실측 **Δ 문서화** (wall + human-eq) |
| S7 | **자동화율** | attach method mix · auto **≥45%** (전체 141) 또는 **≥90%** (E1+E2 only) |

**산출물 (실험 시):** `sprint_04_externalid_report.json` (가칭) — Sprint 03 `sprint_03_report.json` 동형.

---

## 7. 실패 시 의미

| 실패 유형 | 조건 | 의미 |
|-----------|------|------|
| **F1. Coverage** | 50% 미달 | Phase 2 §5 **미충족** — Phase 2 **종료 지연** |
| **F2. Economics** | 실측 **≫ 18.8h** | poster 자동화 **과소평가** — G1/G2 insert·enrich SLA **보수적** 운영 |
| **F3. Economics** | 실측 **≪ 18.8h** | Sprint 02 externalId 모델 **과대** — composite 계획 **하향** (titles.en과 동형) |
| **F4. 회귀** | SW1/URV 하락 | 잘못된 ID **대량 유입** — 배치 롤백 · Charter §3.2 #2 검토 |
| **F5. 품질** | poster–ID 불일치 | **운영 실패** — 구조 아님 · `poster_verification` 강화 |
| **F6. attach 불가** | 186 manual cohort 비용 폭증 | 50%는 달성하나 **90%** 는 **장기 manual** — A1 공급·A5와 연동 |

**구조 변경은 F1–F6 어디에도 **필수 결론 아님**** — enrich·도구·QA로 우선 대응 ([phase2-charter](phase2-charter.md) §3).

---

## 8. Sprint 04 범위 확정

### 8.1 In scope

| 항목 | 포함 |
|------|:----:|
| externalId **G2 50%** (+141) Economics 실측 | ✅ |
| cohort **E1 Steam + E2 TMDB poster** | ✅ |
| `coverage_dashboard` · `quality_gate` · SW1 · URV 회귀 | ✅ |
| Sprint 02 **18.8h** vs 실측 비교 | ✅ |

### 8.2 Out of scope (Sprint 04)

| 항목 | 사유 |
|------|------|
| titles.en 추가 enrich | Sprint 03 **91.5%** · Mid-Review |
| zh Economics | Q1 · 별 cohort |
| externalId **90%** (+302) | Phase 2 후반 · 별 계획 |
| IGDB/openlibrary **신규 파이프라인** | 도구 미실측 · 구조 변경 없음 |
| 신규 ADR · Registry 구조 변경 | Charter §3 |

### 8.3 예상 Sprint 04 도구 (계획만 · 미구현)

```
coverage_sprint_04_external_id.dart  (가칭)
  --dry-run   # cohort E1+E2 선정
  --apply     # externalIds attach only
  → registry_builder
  → coverage_dashboard · quality_gate --strict
  → sw1 · urv
  → sprint_04_externalid_report.json
```

---

## 9. 문서 맵

| 문서 | 역할 |
|------|------|
| [externalid-economics-plan.md](externalid-economics-plan.md) | **본 문서** — Sprint 04 P1/Q2 계획 |
| [phase2-late-stage-plan.md](phase2-late-stage-plan.md) | Q2 정의 |
| [phase2-governance-review.md](phase2-governance-review.md) | Release·회귀 게이트 |
| [quality-gate-mvp.md](quality-gate-mvp.md) | Quality block |

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — 402 registry 현재 데이터만 (enrich·실험 없음) |

**데이터 출처:** `coverage_dashboard` · `sprint_02_economics.json` (2026-06-09 재생성) · registry shard read-only 감사 (402 manifest).
