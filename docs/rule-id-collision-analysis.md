# Rule ID 충돌 영향도 분석 — E1~E5

> **목적:** 저장소 전역에서 `E1`~`E5`가 **의미 있는 규칙·게이트·코호트 ID**로 쓰인 위치를 수집하고, **externalId attach gate**와의 충돌 영향도를 평가한다.  
> **기준일:** 2026-06-09  
> **방법:** `docs/` · `tool/` · `ROADMAP.md` 대상 `rg` 전수 검색 + 표·제목 패턴 수동 분류

**금지 준수:** 문서 **수정 없음** · rename **없음** · ADR **없음** · **조사만**

---

## Executive Summary

| # | 질문 | 결론 |
|---|------|------|
| 1 | **Namespace 분리 필요?** | **예** — 동일 저장소에 **최소 5개** 독립 네임스페이스가 `E1`~`E5`를 **동시 사용** |
| 2 | **rename 시 영향 문서 수** | attach gate만 **7 문서 + 1 도구** · cohort 포함 **~17 문서 + 4 도구** · governance까지 **+2 문서** (비권고) |
| 3 | **추천 namespace** | attach gate **`EG1`~`EG5`** · Sprint cohort **`SC1`~`SC4`** · enrich gate **`EN1`~`EN8`** (기존 E1–E8 **유지 시** 각주 필수) |

**RB1~RB5는 비권고** — [quality-gate-mvp.md](quality-gate-mvp.md) **Release Block RB1·RB2**와 **숫자 충돌**.

---

## 1. 네임스페이스 맵 (E1~E5 의미)

| NS | 코드 | E1 | E2 | E3 | E4 | E5 | 도메인 |
|:--:|------|----|----|----|----|-----|--------|
| **EG** | externalId **attach gate** | Site Error | Save prefix | dup attach | title similarity | dup `wk_` | Sprint 04 Phase B-3~B-5 |
| **SC** | Sprint **cohort** (Economics) | Steam | TMDB poster | G2 잔여 | 50% 초과 | — | Sprint 04 Charter·apply |
| **CG** | **Coverage governance** enrich | invalid-en | 출처 매칭 | fallback | registry_builder | Coverage KPI | Phase 2 §4.2 |
| **A5D** | A5 **Discovery** Economics | 402 extrapolation | 축별 실측 | enrich SLA | cohort 자동화율 | — | A5 Discovery |
| **A5S** | A5 **Scale** 관측 증거 | pre_insert_dedupe | v4 hex shard | batch6 BLOCK | batch5 BLOCK | Maintainer 패턴 | a5-scale-plan |
| **SR** | **Search** architecture | Shard+Inverted | Shard+SQLite FTS | category lazy | — | — | search-index-* |
| **V4** | **v4 마일레스톤** | main push | Steamworks | 스토어·IAP | v1 출시 | — | v4-migration-plan |
| **ML** | **My Library** 설계안 | UI 범위 | master_index | — | — | — | my-library-design |
| **RD** | **ROADMAP** | Catalog Expansion Pipeline | — | — | — | — | ROADMAP.md |

**externalId gate(EG)** 는 **CG·SC와 E1~E5 전건 숫자 겹침** — Sprint 04 문서에서 **한 페이지에 3 NS** 가능.

---

## 2. 의미 있는 규칙 ID 사용 문서 — 전수 목록

### 2.1 EG — externalId attach gate (`E1`~`E5`)

| 파일 | 의미 | 상태 | externalId gate 충돌 |
|------|------|:----:|:--------------------:|
| [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) | Rule E1~E5 정의 · BLOCK/REVIEW | **draft** | **정의 원본** |
| [sprint-04-e1-post-gate-audit.md](archive/sprint-04-e1-post-gate-audit.md) | Gate E1~E5 시뮬레이션 · AUTO/REVIEW/BLOCK | **active** (측정) | — |
| [sprint-04-e4-effectiveness-review.md](archive/sprint-04-e4-effectiveness-review.md) | **Gate E4** 실효성 · FALSE_REVIEW 7 | **active** (분석) | — |
| [sprint-04-document-reconciliation.md](sprint-04-document-reconciliation.md) | 3-way E1 대조표 · rename 권고 | **active** (메타) | — |
| [doc-inventory-externalid.md](archive/doc-inventory-externalid.md) | Rule ID 충돌 인벤토리 | **active** (메타) | — |
| [sprint-04-high-risk-disposition.md](archive/sprint-04-high-risk-disposition.md) | 대부분 **SC** 「E1 경로」·B-5에서 **EG E1/E2** 인용 | **active** | **혼용** |
| `tool/coverage_sprint_04_e1_post_gate.dart` | `'E1'`…`'E5'` triggeredRules JSON | **active** (측정) | — |

### 2.2 SC — Sprint 04 cohort / Economics (`E1`~`E4`)

| 파일 | 의미 | 상태 | externalId gate 충돌 |
|------|------|:----:|:--------------------:|
| [sprint-04-charter.md](sprint-04-charter.md) | E1 Steam · E2 TMDB · E3 잔여 · E4 초과 | **active**† | **E1·E2·E3·E4** |
| [externalid-economics-plan.md](archive/externalid-economics-plan.md) | Economics tier E1~E4 표 | **active**† | **E1~E4** |
| [sprint-04-baseline-report.md](sprint-04-baseline-report.md) | E1/E2 cohort 수 · 예상 coverage | **active** | **E1·E2** |
| [sprint-04-final-review.md](archive/sprint-04-final-review.md) | E1/E2 **배치** apply 110+31 | **superseded** | **E1·E2** |
| [sprint-04-e1-audit.md](archive/sprint-04-e1-audit.md) | **E1 Steam cohort** 15건 감사 | **active** | **E1‡** |
| [sprint-04-high-risk-disposition.md](archive/sprint-04-high-risk-disposition.md) | 「E1 attach 경로」poster direct | **active** | **E1‡** |
| [externalid-quality-risk-review.md](externalid-quality-risk-review.md) | Sprint 04 **E1** ≤125 · spot-check 표 | **active** | **E1·E2** |
| [sprint-04-readiness-review.md](archive/sprint-04-readiness-review.md) | Economics 검증 행 E1~E4 + cohort E1/E2 체크리스트 | **active** (historical) | **E1~E4** |
| [phase2-final-review.md](archive/phase2-final-review.md) | E2+E1 poster-priority 실측 | **active** (동결) | **E1·E2** |
| `tool/coverage_sprint_04_baseline.dart` | cohort `'E1'`/`'E2'` JSON 키 | **active** | **E1·E2** |
| `tool/coverage_sprint_04_external_id.dart` | 주석·phase **E1 Steam / E2 TMDB** | **active** | **E1·E2** |
| `tool/coverage_sprint_04_e1_audit.dart` | cohort `'E1 Steam'` | **active** | **E1‡** |

† @402 기준선 — 수치 **구식** · 의미는 유효.  
‡ **파일명 `e1_*`** 이 SC인지 EG인지 **문맥 의존** — 충돌 **최고**.

### 2.3 CG — Coverage governance enrich (`E1`~`E8`, 여기서 E1~E5)

| 파일 | 의미 | 상태 | externalId gate 충돌 |
|------|------|:----:|:--------------------:|
| [coverage-quality-governance.md](coverage-quality-governance.md) | §4.2 enrich 후 **E1** invalid-en … **E5** KPI | **active** | **E1~E5 전건** |
| [phase2-governance-review.md](phase2-governance-review.md) | enrich 후 **E1–E8** 요약 | **active** | **E1~E5** |

### 2.4 A5D — A5 Discovery Economics (`E1`~`E4`)

| 파일 | 의미 | 상태 | externalId gate 충돌 |
|------|------|:----:|:--------------------:|
| [a5-discovery-charter.md](archive/a5-discovery-charter.md) | §2 Economics **E1**~**E4** 가정 | **동결** | 숫자만 (의미 독립) |
| [a5-operational-decisions.md](archive/a5-operational-decisions.md) | 본문 **E2·E3** Discovery 참조 | **active** | 낮음 |
| [a5-pilot-launch-review.md](archive/a5-pilot-launch-review.md) | **E2·E3** 참조 | **동결** | 낮음 |
| [a5-verification-charter.md](a5-verification-charter.md) | 후보 **E1·E3** | **active** | 낮음 |

### 2.5 A5S — A5 Scale 관측 (`E1`~`E5`)

| 파일 | 의미 | 상태 | externalId gate 충돌 |
|------|------|:----:|:--------------------:|
| [a5-scale-plan.md](a5-scale-plan.md) | Scale 증거 표 **E1** dedupe … **E5** Maintainer | **active** | **E1~E5** (도메인 분리) |

### 2.6 SR — Search architecture (`E1`~`E3`)

| 파일 | 의미 | 상태 | externalId gate 충돌 |
|------|------|:----:|:--------------------:|
| [search-index-architecture-options.md](search-index-architecture-options.md) | 옵션 **E1**~**E3** | **active** (설계) | 없음 |
| [search-workload-profile.md](search-workload-profile.md) | POC **E1**(A+B) | **active** | 없음 |
| [search-index-validation-plan.md](search-index-validation-plan.md) | POC **E1** 참조 | **active** | 없음 |
| [ROADMAP.md](../ROADMAP.md) | Milestone **E1** + search **E1** | **active** | 없음 |

### 2.7 V4 · ML — 기타 (`E1`~`E4` / `E1`~`E2`)

| 파일 | 의미 | 상태 | externalId gate 충돌 |
|------|------|:----:|:--------------------:|
| [v4-migration-plan.md](v4-migration-plan.md) | 출시 단계 **E1**~**E4** | **active** (계획) | 없음 |
| [my-library-design.md](my-library-design.md) | 설계 질문 **E1·E2** | **draft** | 없음 |

### 2.8 제외 — 규칙 ID가 **아닌** 매치

| 경로 | 사유 |
|------|------|
| `tool/fix_batch5_posters.dart` | TMDB hash `…AE5cxhHh` |
| `tool/seed_expansion.dart` | URL `DE2JZQ3m` |
| `lib/*` · `akasha-db/*.json` shards | 해시·에셋 ID 부분문자열 |
| [quality-gate-mvp.md](quality-gate-mvp.md) | **RB1·RB2** (Release Block) — `E*` 규칙 ID **없음** |

---

## 3. externalId gate 충돌 심각도

### 3.1 동일 문서 내 이중 의미

| 문서 | SC | EG | CG | 위험 |
|------|:--:|:--:|:--:|------|
| sprint-04-e1-post-gate-audit | 파일명·cohort **E1** | 본문 Rule **E1~E5** | — | **최고** |
| sprint-04-e1-audit | cohort **E1** | — | — | 중 (파일명) |
| sprint-04-high-risk-disposition | **E1 경로** | B-5 **E1/E2** 인용 | — | **높음** |
| sprint-04-readiness-review | cohort **E1/E2** | — | enrich **E1–E3** G4 | **높음** |
| sprint-04-e4-effectiveness-review | cohort **E1** 15건 | **E4** 규칙 전면 | — | **높음** |

### 3.2 숫자별 충돌 (EG 기준)

| ID | EG (attach) | SC (cohort) | CG (enrich) | A5S | 기타 |
|:--:|-------------|-------------|-------------|-----|------|
| **E1** | Site Error | **Steam** | invalid-en | dedupe gate | A5D·RD·SR·V4·ML |
| **E2** | Save prefix | **TMDB** | 출처 매칭 | v4 shard | A5D·SR·V4·ML |
| **E3** | dup attach | G2 잔여 | fallback | batch6 | A5D·SR·V4 |
| **E4** | similarity | 50% 초과 | registry_builder | batch5 | A5D·SR·V4 |
| **E5** | dup `wk_` | — | Coverage KPI | Maintainer | — |

**판정:** EG·SC·CG **삼중 충돌** — externalId·titles.en·attach **동일 Phase 2/Sprint 04 맥락**.

---

## 4. 요약 답변

### 4.1 Rule ID namespace 분리 필요 여부

| 판정 | **필요** |
|------|----------|
| 근거 | (1) **EG vs CG** E1~E5 **완전 동형 번호** · (2) **EG vs SC** Sprint 04 **동일 접두 E1** · (3) `e1_*` 도구·문서 **파일명 고착** |
| 최소 조치 | **EG** attach gate **신규 접두** |
| 권장 조치 | **EG** + **SC** cohort **분리** · CG는 Phase 2 **동결** → 문서 **각주** 또는 후속 **EN*** |
| 비권고 | CG **E1–E8 일괄 rename** (영향 넓음 · Phase 2 frozen) |

### 4.2 rename 시 영향받는 문서 수

| 시나리오 | 문서 | 도구 | 합계 |
|----------|-----:|-----:|-----:|
| **A. EG1~EG5 only** (attach gate) | **7** | **1** | **8** |
| **B. A + SC1~SC4** (Sprint cohort) | **+10** | **+3** | **18** |
| **C. B + EN1~EN8** (governance enrich) | **+2** | **0** | **20** |
| **D. 전역 E1~E5 치환** | **30+** | **4+** | **비현실** |

**A 상세 (EG rename):**

1. externalid-quality-gate-rules.md  
2. sprint-04-e1-post-gate-audit.md  
3. sprint-04-e4-effectiveness-review.md  
4. sprint-04-high-risk-disposition.md (gate 인용부)  
5. sprint-04-document-reconciliation.md  
6. doc-inventory-externalid.md  
7. rule-id-collision-analysis.md (본 문서)  
8. `tool/coverage_sprint_04_e1_post_gate.dart`

**B 추가 (SC rename):** charter · economics-plan · baseline · final-review · e1-audit · quality-risk-review · readiness-review · phase2-final-review + baseline · external_id · e1_audit dart

**교차 참조만 (rename 불필요·각주 권장):** A5D · A5S · SR · V4 · ML · ROADMAP — **도메인 분리**됨.

### 4.3 추천 namespace

| 순위 | 접두 | 범위 | E1 예시 | 비고 |
|:----:|------|------|---------|------|
| **1** | **`EG1`~`EG5`** | externalId **attach gate** | EG1 Site Error | **EG** = ExternalId Gate · RB·R·SC와 **무충돌** |
| **2** | **`SC1`~`SC4`** | Sprint 04 **cohort** tier | SC1 Steam | 파일 `e1_audit` → `sc1_audit` **선택** |
| **3** | **`EN1`~`EN8`** | enrich gate (기존 CG) | EN1 invalid-en | Phase 2 **개정 시만** |
| — | ~~`XG1`~`XG5`~~ | attach gate 대안 | XG1 | reconciliation 제안 · **EG보다 덜 자명** |
| — | ~~`RB1`~`RB5`~~ | — | — | **기존 RB1·RB2** 와 **충돌** · **금지** |

**매핑표 (권장 · EG / SC / EN):**

| # | **EG** (attach) | **SC** (cohort) | **EN** (enrich) |
|---|-----------------|-----------------|-----------------|
| 1 | Site Error BLOCK | Steam attach | invalid-en 가드 |
| 2 | Save prefix BLOCK | TMDB poster | 출처 매칭 |
| 3 | dup attach BLOCK | G2 잔여 tier | fallback 체인 |
| 4 | similarity REVIEW | 50% 초과 tier | registry_builder |
| 5 | dup `wk_` BLOCK | — | Coverage KPI |

---

## 5. 영향도 — 운영·구현

| 영향 | 설명 |
|------|------|
| **독자** | Sprint 04 Phase B 문서 **3 NS 혼동** — 「E2 BLOCK」이 Save인지 TMDB인지 **문맥 없이 불가** |
| **구현** | `post_gate.dart` JSON `triggeredRules: ["E2"]` — runner·대시보드 **계약** |
| **파일명** | `coverage_sprint_04_e1_*` = **SC1** 고정 암시 — gate 문서와 **이름 충돌** |
| **CI** | 현재 quality_gate **EG 미구현** — rename **착수 Gate**로 적합 |
| **A5·Search** | **독립 NS** — rename **불필요** |

---

## 6. 권고 (분석만 · 미실행)

| 우선순위 | 조치 |
|:--------:|------|
| P0 | attach gate **EG1~EG5** 채택 · [externalid-quality-gate-rules.md](externalid-quality-gate-rules.md) **개정 시** 반영 |
| P1 | Sprint cohort **SC1~SC4** · Charter/Economics **각주** |
| P2 | [coverage-quality-governance.md](coverage-quality-governance.md) §4.2 — 「enrich **EN1**」 **교차 링크** (CG 유지) |
| P3 | [docs/README.md](README.md) — **NS 범례** 1표 |
| — | **RB1~RB5** attach gate 명명 **금지** |

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 저장소 전역 E1~E5 규칙 ID 수집 · 충돌 영향도 |
