# Assumption Register (Baseline v1)

> **목적:** [Baseline v1](baseline-v1.md)이 **현재 무엇을 믿고 있는지**를 명시한다.  
> 새 설계가 아니라 **가정의 인벤토리** — 검증(SIM·URV·SW1)이 반박하면 Baseline 개정으로 이어진다.
>
> **상태:** **Phase 1 종료** · Baseline v1 **Validated through Phase 1** (2026-06-09)  
> **검증 종료:** [phase1-final-review.md](phase1-final-review.md)  
> **다음:** [phase2-charter.md](phase2-charter.md)  
> **선행:** [scale-5k-risk-analysis.md](scale-5k-risk-analysis.md) · [registry-growth-strategy.md](registry-growth-strategy.md) · [contribution-model-strategy.md](contribution-model-strategy.md)

---

## 1. 사용 방법

| 열 | 의미 |
|----|------|
| **근거** | Baseline v1 문서·실측(402)에서 가정이 나온 이유 |
| **미검증** | 아직 실측·시뮬로 확인하지 못한 부분 |
| **검증 실험** | 해당 가정을 시험하는 절차 (우선 SIM-A/B/C/D) |
| **실패 영향** | 가정이 틀렸을 때 Baseline·로드맵에 미치는 영향 |
| **증거 등급** | §1.1 — SIM 후 갱신 |

**원칙:** 가정은 "맞다/틀리다"가 아니라 **증거 등급**으로 관리한다. SIM 결과는 본 문서에 **반영만** 하고, Baseline v1 본문은 검증이 명시적으로 반박할 때만 개정한다.

### 1.1 증거 등급 (2026-06-09)

| 등급 | 의미 |
|------|------|
| **미검증** | SIM·실측 전 |
| **Supported** | 검증 통과 · 조건부 전제 명시 가능 |
| **Contested** | 핵심 가정 **조건부 반박** — Baseline 개정 후보 |
| **Supported (Operational Dependency)** | 구조 Supported · **Coverage KPI 유지**가 운영 전제 ([phase2-charter](phase2-charter.md)) |
| **장기 과제** | 5k·SW2 범위 밖 |
| **반박** | SIM FAIL · Baseline 개정 트리거 |

| ID | 등급 | 검증 | 비고 |
|----|------|------|------|
| **A1** | **Supported** | SIM-A | 5k 공급 가능 · maintainer burden은 운영 과제 |
| **A2** | **Supported** | SIM-C + SW1-A | stub-first 유지 · token collision·enrich 감시 |
| **A3** | **Supported (Operational Dependency)** | Sprint 01~03 + [phase2-mid-review](phase2-mid-review.md) | Coverage KPI·품질 가드 유지 전제 · §10 |
| **A4** | **Supported** | SIM-D | ADR-006 지연 생성 |
| **A5** | 미검증 | — | 50k 범위 밖 |
| **A6** | **장기 과제** | — | 음악·SW2 |

### 1.2 Phase 1 최종 판정 (2026-06-09)

> 근거: [phase1-final-review.md](phase1-final-review.md)

| ID | 가정 (요약) | Phase 1 판정 | 핵심 검증 | Phase 2 |
|----|-------------|--------------|-----------|---------|
| **A1** | 5k 공급 가능 | **Supported** | SIM-A throughput ~2,104/월 | G1 실측 insert |
| **A2** | Stub-first가 SW1을 무너뜨리지 않음 | **Supported** | SIM-C · SW1-A 81.6% | enrich SLA 감시 |
| **A3** | Canonical Identity | **Supported (Operational Dependency)** | Sprint 01~03 · [phase2-mid-review](phase2-mid-review.md) | zh · externalId · 품질 가드 |
| **A4** | Franchise 지연 생성 | **Supported** | SIM-D PASS | franchise 큐 운영 |
| **A5** | Contribution 없이 50k | **미검증** | 5k SIM 범위 밖 | G2+ |
| **A6** | 곡=Work(B안) 장기 규모 | **장기 과제** | 음악 0건 · SW2 미착수 | 음악 도입 시 |

---

## 2. 가정 목록

### A1. 5,000 작품 확보가 가능하다

| | 내용 |
|---|------|
| **근거** | G1 목표가 **~5,000 Work** ([registry-growth-strategy](registry-growth-strategy.md) §2.1). 402→5k에 **~4,600건** 신규 필요. [scale-5k-risk-analysis](scale-5k-risk-analysis.md) §1: 5k는 **성능이 아니라 공급** 문제 — search_index·shard는 무위험. G0→G1 가설 **~400건/월 · 12~18개월**. 음악(ADR-002)은 5k 범위 밖 ([baseline-v1](baseline-v1.md) §3). |
| **미검증** | 실제 insert 경로(**수동 PR + `merge_catalog_contribution`**)가 월 **≥300 net** 을 지속할 수 있는지 **한 번도 측정하지 않음**. Expansion 파이프라인은 **dry-run·`enabled:false`** ([scale-5k-risk-analysis](scale-5k-risk-analysis.md) §2). Signal→Minimal Core 변환율·정책 탈락률·수동 보정 시간 미상. |
| **검증 실험** | **SIM-A** (배치 500건 dry-run → throughput 곡선) · **G1-1** (≥300 net/월 경로) · 보조: **URV-A** (유입 stub 정체성) |
| **실패 영향** | **G1 마일스톤 불가** — 402에서 SW1/URV만 반복, 제품 커버리지 정체. 성장 전략 G1→G2 일정 붕괴. **Top 1 리스크**로 우선 검증 대상. |

---

### A2. Stub-first 전략이 SW1 품질을 무너뜨리지 않는다

> **Stub-first:** Minimal Core(`title`·`category`·식별자)로 Work를 **먼저 등록**하고, `titles`·`aliases`·포스터 등 enrich는 **등록과 분리·비동기**로 쌓는다 ([registry-growth-strategy](registry-growth-strategy.md) §3.3 G2, §3.4 enrich queue).

| | 내용 |
|---|------|
| **근거** | 데이터 확보가 1순위 병목 ([registry-growth-strategy](registry-growth-strategy.md) §1). G1 파이프라인은 **존재 우선** 배치 stub. SW1은 recall이 핵심이며 성능 병목과 분리 ([global-search-validation-plan](global-search-validation-plan.md) §1). 402에서 search_index latency는 양호. |
| **미검증** | 402 실측 **titles.en 28% · zh 0%** — 신규가 같은 패턴이면 5k에서 recall **점진 저하** 가능 ([scale-5k-risk-analysis](scale-5k-risk-analysis.md) §3.3). enrich backlog가 신규 등록율을 **追いつかない** 시나리오 미측정. stub 비율과 recall의 **인과** 미확립. |
| **검증 실험** | **SIM-C** (합성 5k × {현 갭, enrich 목표} → SW1 recall@10) · **SW1-A** (402 baseline) · **G1-3** (enrich 세트 recall ≥ baseline) |
| **실패 영향** | 커버리지는 늘지만 **글로벌 검색 가치 하락** — "작품은 많은데 못 찾는 Registry". stub-first 유지 시 **enrich SLA·규율**을 Baseline에 **조건부 전제**로 승격해야 함 (설계 변경은 검증 후 ADR 개정). |

---

### A3. Canonical Identity Coverage — **Supported (Operational Dependency)**

> **재정의:** 핵심 문제는 **dedupe 알고리즘**이 아니라 **Registry가 충분한 표면형을 알고 있는가**이다.  
> **전제:** [Coverage Dashboard](canonical-identity-coverage-dashboard.md) KPI 유지 — panel·회귀 게이트.

| | 내용 |
|---|------|
| **근거** | Phase 1: 구조 Supported. **Sprint 01~03** ([phase2-mid-review](phase2-mid-review.md)): enrich만으로 SW1/URV/GAP **100%** · titles.en **91.5%** · 구조 무변경. |
| **판정** | **Supported (Operational Dependency)** — Identity 모델 성립. **운영 의존:** KPI·품질 가드·Economics 없으면 품질·비용 리스크 재현. |
| **실패 영향** | Coverage KPI 미달·auto enrich QA 공백 시 SW1/URV 회귀 — **구조 붕괴가 아닌 운영 실패**. |
| **검증 실험** | Coverage Sprint 01~04 · `coverage_dashboard` · SW1/URV 회귀 · Economics 실측 (§10) |

---

### A4. Franchise 지연 생성이 운영 비용을 통제한다

> **지연 생성:** ADR-006 F1 — 전수 franchise 강제 생성 금지, **tier·지연 생성·members soft cap** ([baseline-v1](baseline-v1.md) §2, [ADR-006](adr/ADR-006-franchise-boundary-hierarchy.md)).

| | 내용 |
|---|------|
| **근거** | 5k 추정 franchise **~400~600** · linter는 **후보만** · 결정은 수동 ([scale-5k-risk-analysis](scale-5k-risk-analysis.md) §3.4). 100k 물리 한계는 멀고 **운영 노동**이 이슈. IP 1카드·depth≤3 스키마는 승인됨. |
| **미검증** | 5k에서 **연결 작업량(시간/건)** 미추정. multi-media 클러스터 급증 시 지연 생성이 UX(IP 1카드)를 **실질적으로 비활성화**하는지 미상. anchor·분할(O1~O6) 구현 전 **운영 가정**만 존재. |
| **검증 실험** | **SIM-D** (SIM-B 데이터에서 franchise 후보 수·노동 추정) · **G1-4** (지연 생성 정책 수치화) · 장기: G2 franchise 큐 SLA |
| **실패 영향** | Maintainer **franchise 큐 포화** — G1 일정은 지키나 IP 경험 저하. 지연 생성 완화(더 많은 자동 연결) 또는 **headcount 전제**를 성장 전략에 명시해야 함. 5k에서 즉시 붕괴는 아니나 **운영 비용 가정 붕괴**. |

---

### A5. Contribution 없이도 50k까지 도달 가능하다

> **Contribution 없이:** 사용자 **add(B)** 는 50k까지 미개방 · **Maintainer + 반자동 Import + Expansion Pipeline** 만으로 G2 진입 ([contribution-model-strategy](contribution-model-strategy.md) §2.1·§3.1).

| | 내용 |
|---|------|
| **근거** | Phase **R0→R1**: 402~5k Maintainer 엄선, **5k~50k** Pipeline MVP + fix↑ ([contribution-model-strategy](contribution-model-strategy.md) §1.3). 커뮤니티 없이 현실 상한 **~30만~50만**(주류 중심) — **50k는 그 이내**. 5k에서 add는 maintainer 대행·gap 보고만. |
| **미검증** | **Pipeline MVP**가 G1→G2 **~3k~5k건/월** 을 실제로 내는지 미검증. 50k에서 dedupe·enrich **human queue** 한도 미측정. AI validator·merge train **미구현** ([scale-5k-risk-analysis](scale-5k-risk-analysis.md) §3.6). 50k는 **SIM-A/B/C 범위 밖** — 5k 통과 후 extrapolation 가정. |
| **검증 실험** | **근거선:** SIM-A throughput → G1 실현 가능성. **간접:** SIM-B/C가 ingest·품질 한도 시사. **50k 전용:** G2 파일럿 시뮬(미계획) · contribution workflow dry-run. **SW1-A·URV-A**는 402 품질 기준선. |
| **실패 영향** | 50k 전에 **Contribution add 조기 개방** 또는 **G2 목표 하향**. [contribution-model-strategy](contribution-model-strategy.md) Phase R1·R2 경로 재검토. 5M+ 커뮤니티 필수 전제와는 별개 — **중기(50k) 공급 주체 가정** 붕괴. |

---

### A6. 곡=Work(B안)도 장기 규모에서 유지 가능하다

> **B안:** 곡=Work · 앨범=Container · tier·인기곡 우선 ([ADR-002](adr/ADR-002-music-registry-model.md), [baseline-v1](baseline-v1.md) §3).

| | 내용 |
|---|------|
| **근거** | AKASHA **작품 기록** 정체성과 정합 · SW1 **곡명 recall** 유리 · ADR-005 음악 행 **B안 잠정**. 조건: **tier 0/1/2 점진 커버리지** + **search_index 30M 인프라 게이트(SW2)**. 현재 402에 **음악 0건** → 5k 검증 범위 밖. |
| **미검증** | Work 규모 **~30M~100M+** 시 search_index·shard·enrich 비용 ([baseline-v1](baseline-v1.md) §3 표). tier 커버리지 없이 전곡 등록 시 **SW2 병목** 조기 도래. A/B **최종 확정 전** — 음악 카테고리 도입 시점에 재판단. |
| **검증 실험** | **5k SIM과 무관.** 음악 도입 전: **SW2** (search_index 10M~30M synthetic) · tier 커버리지 파일럿 · ADR-002 최종 결정 회의. **SW1** 곡명 쿼리 서브셋(음악 등록 후). |
| **실패 영향** | **A안(앨범=Work) 또는 하이브리드**로 회귀 · search_index 분리 아키텍처 일정 앞당김. Baseline §3 "B안 가중" 철회 → ADR-002 개정. **G1~G3 마일스톤에는 직접 영향 없음** (음악 미포함). |

---

## 3. 가정 ↔ 검증 매트릭스

| 가정 | SIM-A | SIM-B | SIM-C | SIM-D | SW1-A | URV-A | G1 게이트 |
|------|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|-----------|
| A1 | ● | | | | | ○ | G1-1 |
| A2 | | | ● | | ● | | G1-3 |
| A3 | ○ | ● | | | | ● | G1-2 |
| A4 | | | | ● | | ○ | G1-4 |
| A5 | ○ | ○ | ○ | | ● | ● | (G2+) |
| A6 | | | | | ○ | | (SW2) |

● = 직접 검증 · ○ = 간접·보조

---

## 4. 검증 후 갱신 규칙

1. SIM-A/B/C/D 산출물: `akasha-db/pipeline/artifacts/scale_5k_sim/` (gitignored).
2. 각 가정에 **증거 등급** 부여: §1.1 (`Contested` 포함).
3. **Contested / 반박** 시: 본 문서·§6 요약 → Baseline v1 개정 항목 목록 → (필요 시) ADR 개정. **새 ADR 추가는 사용자 승인 전 중단** 유지.
4. Phase 1 종료 — A3 Coverage는 [phase2-charter.md](phase2-charter.md) 운영으로 이관.
5. Phase 2 거버넌스 — **신규 ADR · Registry/Franchise 구조 변경 원칙적 금지** · 예외는 Charter §3.2 (Coverage 불가 · SW1/URV 구조 결함 · A5/A6 반박).

---

## 5. 다음 행동 (Phase 2 · Mid-Review 이후)

| 순위 | 작업 | 본 문서와의 관계 |
|------|------|------------------|
| 1 | ~~**Coverage Economics (titles.en)**~~ | Sprint 02~03 ✅ · §10.3–10.4 · [phase2-mid-review](phase2-mid-review.md) |
| 2 | **Sprint 04 (재정의)** | zh · externalId · composite Economics |
| 3 | **auto enrich 품질 가드** | TMDB fallback · CI (§10.4 품질 사고) |
| 4 | **Coverage Dashboard + 회귀** | KPI 유지 (A3 전제) |
| 5 | B-1 KPI 교정 | scale_5k_sim (후순위) |

---

## 6. SIM-B 심화 — A3 실패 유형 분석 (2026-06-09)

> seed=42 · 402 + 합성 4,600 + 의도적 중복 368(8%) · **구현 없음·원인 분석만**

### 6.1 두 가지 recall (혼동 주의)

| 지표 | 값 | 의미 |
|------|-----|------|
| **보고 recall** (SIM-B KPI) | **68.5%** (252/368) | `externalIds.sim` 키로만 적중 집계 — **과소계상** |
| **outcome recall** (shadow 결과) | **100%** (368/368) | wouldMerge 18 + mergeCandidate 350 · **wouldCreate slipped 0** |
| **사후 dedupe** | 잔존 **0** | naive insert 후에도 linter가 slipped 0건 |

**31.5%p 갭(116건)의 정체:** 전부 **mode-0**(기존 `externalIds` 복사) 중복이 **externalId 경로로 적중**했으나, SIM-B 집계가 `sim` 라벨만 조인해 **미집계**된 것. 즉 **탐지 실패가 아니라 측정 정의 문제**다.

그럼에도 A3를 **Contested**로 올리는 이유:

1. **운영 KPI로 68.5%**가 찍히면 G1-2는 실패 — 게이트 정의·신뢰 경로 정비 필요.
2. 본 배치에서 **탐지 경로 95%가 title fuzzy**(350/368) — **externalId는 18건만** 기여. 402 Registry **85%**(342/402)가 `externalIds` 없음 → 파이프라인 실전에서는 fuzzy 의존이 더 커짐.
3. “사후만으로 충분”은 **slipped 0 + 사후 0**으로 이번 합성에서는 성립했으나, **pre-insert 신뢰 90%**라는 운영 기준과 **측정·경로 불균형**이 Baseline 가정과 충돌.

### 6.2 실패 유형 분류 (368건 중 “미달 116건” = metric gap)

보고 recall 68.5%의 **116건 미집계**를 탐지 메커니즘·유형으로 분해:

| 유형 | 건수 | 비율 | 설명 |
|------|------|------|------|
| **(외부 ID 활용)** | **116** | **100%** | mode-0: Registry `externalIds` 복사 → `wouldMerge`/`mergeCandidate` **성공** · `sim` 키 없어 KPI 미반영 |
| alias | 0 | 0% | — |
| 번역 제목 | 0 | 0% | — |
| 시리즈/개별 | 0 | 0% | — |
| punctuation | 0 | 0% | — |
| 기타 | 0 | 0% | — |

→ **상위 실패 유형 = external ID 경로 성공의 KPI 누락 100%** (탐지 실패 유형 아님).

### 6.3 잠재 실패 유형 (실전 90% 달성 관점·구조 추론)

이번 배치 outcome miss **0건**. 아래는 Registry·코드·402 메타 분포에서 추론한 **향후 miss 기여도** (SIM-B 2차 실험 가설):

| 유형 | 추정 기여도 | 근거 |
|------|:-----------:|------|
| **번역 제목** | **~40%** | `titles.en` 28% · fuzzy는 `title`+`titles`+`aliases` norm만 사용 · 번역만 다른 stub 쌍 |
| **외부 ID 활용** | **~30%** | 402의 85% Work에 `externalIds` 없음 · 신규 소스 ID만 다른 duplicate는 title fuzzy로만 잡힘 |
| **punctuation** | **~15%** | `normalizeTitle` 구두점 제거 · 부제가 primary `title`에만 있고 `titles.en`/alias 없으면 miss |
| **alias** | **~10%** | primary title 다르고 alias만 겹치는 경우 — fuzzy norm에 alias 포함되나 **stub enrich 전**엔 빈약 |
| **시리즈/개별** | **~5%** | `releaseYear ±1` 게이트 · `franchise_groups` 형제 제외 — 의도적 분리 vs miss 경계 |

### 6.4 90% 달성 레버 영향도 (구현 없음·영향 추정)

| 레버 | 영향 | 대상 유형 | 판단 |
|------|:----:|-----------|------|
| **외부 ID 활용** | **최대** | 외부 ID · mode-0 canonical | Registry·ingest 양쪽 `externalIds` 밀도 올리면 **정확 merge** · KPI도 정합. 402의 85% 공백이 병목. |
| **alias / titles.en 확장** | **큼** | 번역 제목 · punctuation · alias | stub-first와 직결 — fuzzy **입력 토큰**을 늘림. SIM-C en gap(28%)과 동일 축. |
| **규칙 추가** | **중간** | punctuation · 시리즈 | norm 확장·부제 파싱·시리즈 정책 명시 — 상한 있음(title fuzzy 한계). |

**한 줄:** 90%에 **가장 큰 영향 = 외부 ID 활용**(canonical identity) + **alias/titles.en 확장**(fuzzy 입력 품질). 규칙 추가만으로는 번역·ID 공백을 단독 커버하기 어렵다.

### 6.5 SIM-B 2차 실험 제안 (문서만)

| 실험 | 입력 | 목적 |
|------|------|------|
| B-1 | mode별 분리 + KPI join 수정 | metric vs outcome recall 정합 |
| B-2 | `externalIds` 공백 85% 반영 synthetic | 외부 ID 레버 민감도 |
| B-3 | en/ja title-only duplicate 주입 | 번역·alias miss율 실측 |
| B-4 | 부제·괄호·시즌 변형 주입 | punctuation·시리즈 miss율 실측 |

---

## 7. SIM-B 2차 — 실데이터 대표성 검증 (B-2/B-3/B-4) · 2026-06-09

> seed=42 · 402 + 합성 4,600 + 의도적 중복 368 · **externalId 밀도 15%** (실측 14.9% 반영) · titles.en 21.1% 반영 · **구현 없음**
>
> 핵심 질문: **"externalIds가 거의 없는 현실 Registry 조건에서도 outcome recall이 90% 이상 유지되는가?"**

### 7.1 결과 (KPI recall ↔ outcome recall 분리)

| 시나리오 | 중복 변형 | **outcome recall** | KPI recall | slipped | 사후 잔존 | 판정 |
|----------|-----------|:------------------:|:----------:|:-------:|:---------:|:----:|
| **B-2** | externalId 공백 · **title 보존** | **100%** (368/368) | 13.9% (51/368) | 0 | 0 | ✅ ≥90% |
| **B-3** | 다국어 (다른 언어 표기 primary) | **25.0%** (92/368) | 4.1% | 276 | **276** | ❌ |
| **B-4** | 부제·괄호·시즌 변형 | **22.0%** (81/368) | 2.7% | 287 | **287** | ❌ |

- 모든 시나리오 catchPath = **title fuzzy(registry) 100%** · externalId 경로 0건 (밀도 15% 중복 stub은 새 sim ID라 기존과 불일치).

### 7.2 B-2 질문에 대한 직접 답

**"externalId 거의 없어도 outcome recall 90% 유지되는가?"**

→ **조건부 YES.** **title 표면형이 보존되면** externalId 0건이어도 **title fuzzy만으로 100%** 탐지. externalId 공백 **자체는** dedupe를 무너뜨리지 않는다.

→ 그러나 **title이 변형되면(B-3·B-4) recall 22~25%로 붕괴.** externalId가 없으니 **fallback이 없다.** 즉 위험은 "externalId 공백"이 아니라 **"externalId 공백 + 표면형 변형"의 결합**이다.

### 7.3 사후 dedupe로 충분한가 — 직접 반박

- B-3/B-4에서 **slipped = 사후 잔존** (276/287 전량). `dedupe_linter`는 shadow_write와 **동일한 norm-title + externalId 키**를 쓰므로, pre-insert가 놓친 표면형 변형 중복을 **사후에도 동일하게 놓친다.**
- → "사후 정리로도 충분"(A3)은 **표면형이 보존된 경우에만 성립.** 다국어·부제 변형 유입 시 **사후·사전 모두 실패** → A3 Contested 근거 강화.

### 7.4 위험 원인 재정의

| 기존 가설 | 현재 증거 | 갱신 |
|-----------|-----------|------|
| ~~탐지 실패~~ | B-2 outcome 100% · slipped 0 | **기각** |
| ~~KPI 측정 오류만~~ | KPI 13.9% vs outcome 100% (B-2) | **부분** — 측정 결함은 별도(B-1) |
| **Identity Resolution** | B-3 25% · B-4 22% · SW1 GAP 0% · SW1 번역 76.6% | **승격** — 동일 작품의 **다양한 표면형 처리** 실패 |

**A3 위험 원인 = Identity Resolution** — alias · 번역 · 부제 · 시즌 변형을 canonical `wk_`/searchTokens로 연결하지 못함. dedupe와 SW1은 **동일 fuzzy 키**를 공유하므로 함께 무너진다.

### 7.5 90% 달성 레버 — 재확정

| 레버 | B-2 | B-3 | B-4 | 종합 |
|------|:---:|:---:|:---:|------|
| **외부 ID 활용** | 불필요(title로 충분) | **결정적** | **결정적** | 변형 내성의 유일한 구조적 fallback |
| **alias/titles 정규화** | — | **결정적** (다국어 표기 보유) | **결정적** (원제 alias 보유) | fuzzy 입력 품질 = 변형 흡수 |
| **규칙 추가** | — | 부분 | 부분(부제 stripping) | 단독으로 90% 불가 |

→ 90% 유지에는 **externalId 밀도 ↑ 또는 alias/titles 정규화** 중 **최소 하나가 필수.** 둘 다 없으면(현 stub-first 최악 케이스) recall 22~25%.

### 7.6 남은 실험

| 실험 | 상태 |
|------|------|
| B-2/B-3/B-4 | ✅ 완료 (§7.1) |
| B-1 (KPI join 수정) | scale_5k_sim KPI를 outcome 기준으로 교정 권고 (도구 결함) |
| URV-A (402) | ✅ 완료 (§9) |

> **A3 = Contested 유지.** 위험 원인: **Identity Resolution** (표면형 변형 + externalId 공백).

---

## 8. SW1-A — 402 baseline recall@10 (2026-06-09)

> 실행: `dart run tool/sw1_a_validation.dart`  
> 산출물: `akasha-db/pipeline/artifacts/global_search_validation/sw1_a_report.json`  
> eval **87건** (NOT_IN_REGISTRY 8건 제외)

### 8.1 전체

| 지표 | 값 |
|------|-----|
| **recall@10** | **81.6%** (71/87) |

### 8.2 버킷별 recall@10 (B-3/B-4 연계)

| # | 버킷 | recall@10 | n | B-3/B-4 연계 |
|---|------|:---------:|:-:|--------------|
| 1 | **원제 검색** | **100%** | 6/6 | B-2 title 보존 — **강함** |
| 2 | **영어 제목 검색** | **100%** | 9/9 | B-2 en 표기 — **강함** |
| 3 | **번역 제목 검색** | **76.6%** | 36/47 | **B-3 다국어 표면형** — 주요 리스크 |
| 4 | **시즌/부제 검색** | **78.6%** | 11/14 | **B-4 부제/시즌** — enrich 시 90% (Registry) vs 22% (합성 stub) |
| 5 | **Alias 검색** | **81.8%** | 9/11 | alias 보강 필요 |

### 8.3 GAP 진단 (B-3 직접 재현)

| 지표 | 값 |
|------|-----|
| GAP 태그 쿼리 | **15건** |
| recall@10 | **0%** (0/15) |
| 실패 태그 | 전건 **MISSING_LOCALE** / **MISSING_TOKEN** |

대표 실패 (B-3와 동일 축): Demon Slayer · Kimetsu no Yaiba · Spy x Family · FMA · Lord of the Rings · Dandadan — **영어/로마자 쿼리 ↔ Registry에 해당 searchToken 없음**.

### 8.4 SIM-B ↔ SW1 교차 해석

| 축 | SIM-B (합성 stub) | SW1-A (402 실측) | 일치 |
|----|-------------------|------------------|------|
| title 보존 | outcome 100% | 원제·영어 100% | ✅ |
| 다국어 표면형 | outcome 25% | 번역 76.6% · **GAP 0%** | ✅ 방향 일치 — Registry는 enrich되어 있으나 **GAP 15건은 완전 실패** |
| 부제/시즌 변형 | outcome 22% | 시즌/부제 78.6% | △ Registry는 alias로 일부 보강 · **stub 유입 시 B-4 수준으로 하락 예상** |

**한 줄:** B-3/B-4에서 실패한 유형은 SW1 **번역·GAP·시즌/부제** 버킷에서 **직접 재현**된다. 문제는 dedupe가 아니라 **searchTokens/aliases/titles.en에 canonical 표면형이 없는 Identity Resolution**이다.

### 8.5 A2·A3에 대한 시사

| 가정 | SW1-A 시사 |
|------|------------|
| **A2** (stub-first) | 원제·영어는 유지 가능. **번역·GAP·부제**는 stub-first 최악 케이스에서 **SIM-B·SW1 동시 저하** — enrich SLA가 A2 전제. |
| **A3** (Contested) | 사후 dedupe는 표면형 보존 시 충분. **표면형 변형**은 dedupe·SW1 **동시 실패** → Identity Resolution 선행 필요. |

---

## 9. URV-A — 402 Canonical Identity Coverage (2026-06-09)

> 실행: `dart run tool/urv_a_validation.dart`  
> 산출물: `akasha-db/pipeline/artifacts/universal_registry_validation/urv_a_report.json`  
> 핵심 질문: **동일 작품의 여러 표면형이 하나의 `wk_`로 안정적으로 수렴 가능한가?**

### 9.1 방법

| 측정 | 정의 |
|------|------|
| **canonicalCoverage** | variant ∈ normalize(title · titles · aliases · searchTokens) of target `wk_` |
| **ingressConvergence** | minimal stub(title=variant) → RegistrySnapshot fuzzy title match |
| **converged** | coverage **OR** ingress (SW1 recall과 별개 — 정체성 부착 여부) |

eval **87건** (SW1-A와 동일 스위트 · NOT_IN_REGISTRY 제외)

### 9.2 5축 판정

| # | 축 | 수렴률 | 판정 | SW1-A 연계 |
|---|-----|:------:|:----:|------------|
| 1 | **Alias 수렴** | 81.8% (9/11) | **PARTIAL** | alias 81.8% — 동일 |
| 2 | **번역 제목 수렴** | 92.7% (51/55) | **PASS** | 번역 76.6% — URV는 **이미 부착된** ko/ja/zh 표기 강함 · 미부착 4건(CJK GAP) |
| 3 | **로마자 표기 수렴** | **0%** (0/7) | **FAIL** | GAP 15건 중 라틴 7건 — **전건 미수렴** |
| 4 | **시즌/부제 변형 수렴** | 78.6% (11/14) | **PARTIAL** | 시즌/부제 78.6% — 동일 |
| 5 | **외부 ID 기반 수렴** | exactId **100%** (60/60) · variantNoId **0%** (0/5) | **PARTIAL** | SIM-B B-2 — **구조는 강함** · 밀도 ~15% |

**전체 수렴:** 81.6% (71/87) — SW1 recall@10과 **수치 일치** (동일 71건 성공)

### 9.3 축별 실패 대표

| 축 | 실패 케이스 | 진단 |
|----|------------|------|
| 로마자 | Demon Slayer · Kimetsu no Yaiba · Spy x Family · Fullmetal Alchemist · Mushoku Tensei · Re:Zero · 20th Century Boys | `titles.en` / alias **미부착** — MISSING_TOKEN = SW1 GAP |
| 번역(CJK) | 鬼滅の刃 · 鬼灭之刃 · 死亡笔记 · 火影忍者 | ja/zh locale **미부착** |
| Alias | Re:ゼロ · FMA | 약칭 **미부착** |
| 시즌/부제 | Lord of the Rings · Fellowship · Dandadan | 영문 시리즈/부제 **미부착** |
| externalId | GAP 5종 variant-only stub | externalId 없으면 fuzzy **0%** — B-3 재현 |

### 9.4 SW1-A ↔ URV-A 교차 해석

| 관찰 | 의미 |
|------|------|
| recall@10 ≡ identity convergence (71/87) | 검색 실패 = canonical 표면형 **미부착** (RANKING 아님) |
| 번역 PASS(92.7%) vs SW1 번역 76.6% | SW1 버킷에 **로마자·혼합 쿼리 포함** — 축 분리 시 번역 자체는 양호 |
| 로마자 FAIL(0%) | A3 **핵심 리스크** — 공식 영문/로마자 enrich 없이는 수렴 불가 |
| exactId 100% · 밀도 15% | **구조는 Supported** · **커버리지는 Contested** |

### 9.5 A3 명칭·판정 (URV-A 시점)

| 항목 | URV-A 후 (Phase 1 말) |
|------|------------------------|
| 작업 명칭 | ~~Dedupe~~ → **Canonical Identity Coverage** |
| A3 등급 | Contested → **Sprint 01 후 §10에서 승격** |

---

## 10. A3 재평가 · Coverage Sprint 01–03 (2026-06-09)

> **최신 의사결정 기록:** [phase2-mid-review.md](phase2-mid-review.md)  
> **Phase 2 Charter:** [phase2-charter.md](phase2-charter.md) §1.1

### 10.1 Sprint 01 — 구조 vs Coverage 증거

| 항목 | Before | After | 구조 변경 |
|------|:------:|:-----:|:---------:|
| SW1 recall@10 | 81.6% | **100%** | 없음 |
| URV convergence | 81.6% | **100%** | 없음 |
| GAP panel | 0% | **100%** | 없음 |
| enrich | 17 Work `titles`·`aliases` | — | 최소 메타만 |

→ A3 핵심 문제는 **구조가 아니라 Coverage**였음을 **실측으로 확인**.

### 10.2 A3 최종 등급 (Mid-Review 기준)

| 항목 | 판정 |
|------|------|
| **A3** | **Supported (Operational Dependency)** — **유지** |
| **최신 근거** | [phase2-mid-review.md](phase2-mid-review.md) — Sprint 01~03 실측 |
| **전제** | Coverage Dashboard KPI 유지 · SW1/URV 회귀 게이트 · **auto enrich 품질 가드** |
| **실패 시** | 운영·enrich·QA 실패 (구조 반박 아님) |
| **미해결 질문** | *「Coverage 가능한가?」* → **해소** · *「어떤 품질 관리 체계로 유지할 것인가?」* → **Phase 2 후반 핵심** |

### 10.3 Sprint 02 — Coverage Economics (402)

> 실행: `dart run tool/coverage_sprint_02_economics.dart`  
> 산출물: `coverage_dashboard/sprint_02_economics.json`

**질문:** Registry-wide Coverage 90% 비용은?

| # | 측정 | 값 (402 · Sprint 01 이후) |
|---|------|---------------------------|
| 1 | **남은 GAP (panel)** | **0** / 16 ✅ |
| 2 | **enrich 예상 작업량 (titles.en→90%)** | **+262 Work** (현 100/402 = 24.9%) |
| 3 | **작품당 평균 enrich 비용** | **~13.6분/작** (missing 기준) · Sprint 01 보정 **~8분/작** (패널 최소 enrich) |
| 4 | **titles.en 마일스톤 소요** | 50%: **22.9h** · 75%: **48.1h** · 90%: **60.1h** (~**15 maintainer-days** @4h/일) |
| 5 | **자동화 가능 비율** | titles.en missing 중 **~11%** (tmdb/steam/igdb 보유) · **~89% 수동** |

**축별 90% 잔여 (작업량):** romanized +238 · zh +358 · alias +345 · externalId +302 · season +36 (80% target).

**Phase 2 다음 리스크 (Sprint 02 시점):** **Coverage Economics** — 특히 externalId·zh는 자동화율 낮음.

### 10.4 Sprint 03 — Economics 실측 · Mid-Review

> 실행: `dart run tool/coverage_sprint_03_titles_en.dart` (`--apply` · `--remediate`)  
> 분석: [phase2-mid-review.md](phase2-mid-review.md)

**질문:** Sprint 02 추정(50% · **22.9h**)이 실측과 얼마나 다른가?

| # | 측정 | Sprint 02 추정 | Sprint 03 실측 |
|---|------|----------------|----------------|
| 1 | **titles.en** | 24.9% → 50% (+101) | **24.9%→91.5%** (368/402) |
| 2 | **50% 마일스톤 비용** | **22.9h** (1,372분) | wall **~1분** · human-eq **~11.6h** |
| 3 | **자동화 (titles.en)** | **~11%** auto · **~89%** manual | auto+semi **100%** (성공작) |
| 4 | **회귀** | — | SW1 · URV · GAP **100%** 유지 |
| 5 | **품질 사고** | — | TMDB 파싱 **31건** — remediate·fallback 필수 |

**Mid-Review 합의 (검증됨):**

| 항목 | 판정 |
|------|------|
| Coverage 리스크 존재 | ✅ |
| enrich로 해결 가능 | ✅ |
| 구조 변경 불필요 | ✅ |
| Economics 과대추정 (manual 상한) | ✅ |
| 자동화 실효성 (titles.en 축) | ✅ |

**Sprint 04 재정의:** titles.en 연장 ❌ → **zh · externalId · composite Economics** ([phase2-mid-review](phase2-mid-review.md) §7).

> **한 줄 (Mid-Review):** Coverage **가능성**은 확인됨. Phase 2 게이트는 **품질 관리 체계·잔여 축 Economics** 이다. Sprint 02 **60.1h** composite는 titles.en binding이 **Sprint 03으로 완화** — 잔여는 **zh · externalId**.
