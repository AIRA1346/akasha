# Sprint 05 Candidate Backlog

> **목적:** Sprint 05 계획 수립 **전** 후보 목록 정리  
> **기준일:** 2026-06-09 · Registry **430** · externalId **46.74%**  
> **근거:** [sprint-04-closure-review.md](archive/sprint-04-closure-review.md) · [repository-ia-priority-review.md](archive/repository-ia-priority-review.md) · [ROADMAP.md](../active/ROADMAP.md)

**금지 준수:** 계획 **확정 없음** · **우선순위 결정 없음** · 신규 정책·ADR **없음** — **후보만**

---

## Executive Summary

| 구분 | 후보 수 | 성격 |
|------|--------:|------|
| **Sprint 04 잔여** | **3** (+ 관련 2†) | 문서·운영·partial apply |
| **Sprint 05 신규** | **7** | 제품·인프라·검증 축 |

† SC cohort 각주 · attach gate runner 구현 — Closure backlog에서 **연관** · 본 표 **§1.4**.

---

## 1. Sprint 04 잔여 작업

### 1.1 EG namespace 정리

| 차원 | 내용 |
|------|------|
| **내용** | attach gate `E1`~`E5` → **`EG1`~`EG5`** (문서 · `coverage_sprint_04_e1_post_gate.dart` JSON 키) |
| **예상 효과** | Rule ID **다의어 제거** (cohort SC · enrich EN · attach EG) · gate 구현·PR 리뷰 **오독 감소** |
| **난이도** | **중** — 문서 **7~8건** · 도구 **1건** · [rule-id-collision-analysis.md](rule-id-collision-analysis.md) |
| **선행조건** | [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) B-5 반영 **완료** (Wave 2) |
| **Steam v1 관련성** | **낮음** (내부) — 출시 기능 **무관** · 카탈로그 **품질·CI** 간접 |

---

### 1.2 Governance 통합

| 차원 | 내용 |
|------|------|
| **내용** | [coverage-quality-governance.md](coverage-quality-governance.md) ↔ attach gate · phase2-governance · quality-gate-mvp **경계·링크** · enrich `E1`–`E8` vs attach **각주** (EN rename은 선택) |
| **예상 효과** | Quality 층 **단일 지도** · insert / enrich / attach / release **읽기 경로** 명확화 |
| **난이도** | **중~높음** — Phase 2 **동결** 축 편집 · **합병 논쟁** 가능 |
| **선행조건** | Sprint 04 SSOT 정리 (Wave 1) · EG namespace **권장 선행** |
| **Steam v1 관련성** | **낮음** — 운영·maintainer · **release gate** 신뢰 간접 |

---

### 1.3 E1 15건 disposition / apply

> **✅ 해소 (2026-06-10)** — [sprint-04-e1-resolution.md](sprint-04-e1-resolution.md) · externalId **215/430 (50.00%)** G2 달성 · 아래는 착수 전 기록.

| 차원 | 내용 |
|------|------|
| **내용** | 잔여 Steam cohort **15건** — HIGH 4 [disposition](archive/sprint-04-high-risk-disposition.md) 실행 · LOW 7 **인적 REVIEW** · partial apply **결정·실행** |
| **예상 효과** | @430 G2 **+0~+7** (LOW만 시 **208/430 = 48.37%**) · duplicate·identity **오염 방지** |
| **난이도** | **중** — Registry **선별 patch** · 144·270·277 **수동** · gate **문서 준수** |
| **선행조건** | [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) (E4 B-5) · HIGH disposition **승인** · `quality_gate` · SW1 · URV **재실행** |
| **Steam v1 관련성** | **중** — `externalIds.steam` **정합** · game 카탈로그 **store 링크** · v1 **~430작** 품질 |

**참고 (측정 기준):**

| 시나리오 | externalId | coverage @430 |
|----------|----------:|--------------:|
| 현재 | 201 | 46.74% |
| LOW 7 apply | 208 | 48.37% |
| 15건 기계적 | 216 | 50.23% |
| G2 목표 | 215 | 50.0% |

---

### 1.4 관련 잔여 (§1 외 · Closure 인용)

| 후보 | 예상 효과 | 난이도 | 선행조건 | Steam v1 |
|------|-----------|--------|----------|----------|
| **SC cohort 각주** (SC1~SC4) | charter·economics **혼동 완화** | **낮음** | EG 또는 reconciliation | 낮음 |
| **attach gate runner 구현** | EG rules **dry-run/apply 통합** | **중** | EG namespace · rules reviewed | 중 (품질) |

*본 항목은 사용자 지정 §1 **3건 외** 연관 후보 — Sprint 05 편입 **선택**.

---

## 2. Sprint 05 신규 후보

[ROADMAP.md](../active/ROADMAP.md) v1.1+ · Validation 백로그 · A5 Scale 상태 기준.

### 2.1 Recall

| 차원 | 내용 |
|------|------|
| **내용** | 「오늘의 회상」카드 — v1 **플래그 off** · v1.1 스토어 노출 후보 |
| **예상 효과** | 재방문·감성 UX · 볼트·아카이브와 **연결** |
| **난이도** | **중** — UI·콘텐츠 선정·빈 볼트 엣지 |
| **선행조건** | v1 **기능 동결** · 아카이브 데이터 **충분** (dogfood) |
| **Steam v1 관련성** | **낮음** (v1.1) — MVP 체크리스트 **제외** · 출시 후 **차별화** |

---

### 2.2 Timeline

| 차원 | 내용 |
|------|------|
| **내용** | 타임라인 / 완성 캘린더 — 철학 **2번 축** · **미구현** |
| **예상 효과** | 소비·완료 이력 **시각화** · 장기 리텐션 |
| **난이도** | **높음** — 볼트 메타·날짜 모델·UI **신규** |
| **선행조건** | 볼트 스키마·`releaseYear`·소비 기록 **계약** |
| **Steam v1 관련성** | **낮음** (v1.1+) — v1 MVP **범위 외** |

---

### 2.3 Discover

| 차원 | 내용 |
|------|------|
| **내용** | 취향 기반 **Discover** (규칙 MVP 설계 언급) · [discovery-policy.md](discovery-policy.md) 경계 — **신규 wk_ 순증** ≠ 외부 DB 복제 |
| **예상 효과** | 카탈로그 **탐색 확장** · Registry Growth **보조** |
| **난이도** | **높음** — 신호→Minimal Core · dedupe · **정책 준수** |
| **선행조건** | Discovery policy · dedupe_linter · A5 **Discovery 종료** (문서) · Scale **hold** 정책 |
| **Steam v1 관련성** | **중~낮음** — v1 **엄선 카탈로그** 우선 · 출시 후 **성장** 축 |

---

### 2.4 Recommendation

| 차원 | 내용 |
|------|------|
| **내용** | 취향 기반 **추천** — ROADMAP 「규칙 기반 MVP」·Discover와 **인접** |
| **예상 효과** | 홈·대시보드 **개인화** · 재탐색 감소 |
| **난이도** | **중~높음** — 볼트·태그·매체 신호 **부족 시 가치 낮음** |
| **선행조건** | 볼트 **밀도** · Discover 또는 **태그/KPI** · 프라이버시 경계 |
| **Steam v1 관련성** | **낮음** (v1.1+) — v1 **필수 아님** |

---

### 2.5 My Library

| 차원 | 내용 |
|------|------|
| **내용** | [my-library-design.md](my-library-design.md) To-Be — 사이드바·메인 패널 **통합** · 즐겨찾기·수동 컬렉션 · v1 **기본 구현 완료** · **잔여 UX** |
| **예상 효과** | v1 약속 「나의 서재」**완성도** · IAP 테마와 **정합** |
| **난이도** | **중** — UI 재배치 · `master_index` 안내 |
| **선행조건** | v1 MyLibraryScreen **현행** · Entitlement 스텁 |
| **Steam v1 관련성** | **높음** — ROADMAP v1 MVP **포함** · 스토어 스크린샷·IAP **직결** |

---

### 2.6 Registry Scale

| 차원 | 내용 |
|------|------|
| **내용** | A5 Scale — SD2.6 **hold** · O3 checkpoint · insert **중단** @430 · [a5-scale-plan.md](a5-scale-plan.md) |
| **예상 효과** | 5k 경로 **실측** · enrich backlog vs insert **가시화** |
| **난이도** | **높음** — governance 관측 · CI · **품질 회귀** |
| **선행조건** | Pilot SUCCESS · pre_insert_dedupe · Scale **문서** · Sprint 04 Quality **교훈** |
| **Steam v1 관련성** | **중** — v1 **430~엄선** 규모 · 출시 후 **확장** · v1 당일 **필수 아님** |

---

### 2.7 Search Quality

| 차원 | 내용 |
|------|------|
| **내용** | SW1 recall · search index POC · [global-search-validation-plan.md](global-search-validation-plan.md) · [search-index-architecture-options.md](search-index-architecture-options.md) — **SW2 보류** |
| **예상 효과** | 검색 **recall@10** 유지·확장 · 5k+ **병목** 완화 근거 |
| **난이도** | **중~높음** — 합성 벤치 **완료** · POC·인덱스 **미착수** |
| **선행조건** | SW1-A baseline @402/430 · URV-A · Workload Profile · Architecture Options **문서** |
| **Steam v1 관련성** | **높음** — v1 「작품 검색」**핵심** · 카탈로그 성장 시 **첫 병목** |

---

## 3. 후보 매트릭스 (참고 · 순위 없음)

| 후보 | 구분 | 난이도 | Steam v1 | G2/coverage 직접 |
|------|------|:------:|:--------:|:----------------:|
| EG namespace | 04 잔여 | 중 | 낮음 | — |
| Governance 통합 | 04 잔여 | 중~高 | 낮음 | — |
| E1 15 disposition/apply | 04 잔여 | 중 | 중 | **예** |
| Recall | 05 신규 | 중 | 낮음 | — |
| Timeline | 05 신규 | 높음 | 낮음 | — |
| Discover | 05 신규 | 높음 | 중~낮음 | — |
| Recommendation | 05 신규 | 중~高 | 낮음 | — |
| My Library | 05 신규 | 중 | **높음** | — |
| Registry Scale | 05 신규 | 높음 | 중 | — |
| Search Quality | 05 신규 | 중~高 | **높음** | — |

---

## 4. 교차 의존 (후보 간 · 확정 아님)

```
Sprint 04 잔여                    Sprint 05 신규
─────────────                    ─────────────
EG namespace ──┬──► gate runner (1.4)
               └──► Governance 통합
E1 15 apply ───────► Registry Scale 품질 신호
Search Quality ◄──► Registry Scale (5k+)
Discover ◄────────► Registry Scale + dedupe
Recommendation ◄──► Discover / 볼트 밀도
My Library ────────► (독립 · v1 출시 UX)
Recall / Timeline ► 볼트·아카이브 데이터
```

---

## 5. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | Sprint 05 candidate backlog — 후보 목록만 |
