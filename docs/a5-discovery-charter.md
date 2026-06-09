# A5 Discovery Charter — 50k-Scale Operations

> **목적:** Assumption **A5** 검증 **범위를 정의**하기 위한 Discovery Charter.  
> **질문:** *「Contribution 없이도 50k까지 도달·운영 가능한가?」* — **무엇을 증명해야 하는가?**  
> **전제:** [assumption-register.md](assumption-register.md) A5 **Deferred** · [phase2-summary.md](phase2-summary.md) **PHASE 2 COMPLETE**  
> **기준일:** 2026-06-09 · Registry **402작** (실측 기준선)

**금지:** A5 **검증 실행 없음** · 새 실험 · 새 구조 변경 · 새 구현 · 실행 계획.

**문서 성격:** Discovery — **검증 설계 전** 범위·성공 기준 후보·Open Question 인벤토리.

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| **A5 가정** | 사용자 add(B) 없이 **Maintainer + 반자동 Import + Expansion Pipeline** 만으로 **50k** 도달·운영 |
| **Phase 2 이후** | 402에서 Coverage·Economics·Governance **가능** — **50k 운영**은 **미검증** |
| **Discovery 목표** | A5를 **Supported / Unsupported / Deferred** 중 어디로 옮길지 판단하기 위한 **검증 축·성공 기준 후보** 확정 |
| **핵심 가설** | 50k는 **성능 규모**보다 **공급·enrich·품질·거버넌스 운영 규모** 문제 |

---

## 1. A5 질문 재정의

### 1.1 원문 가정 (A5)

[assumption-register.md](assumption-register.md):

> **Contribution 없이도 50k까지 도달 가능하다** — 50k까지 사용자 add 미개방 · Maintainer + 반자동 Import + Expansion Pipeline.

**성장 맥락** ([contribution-model-strategy.md](contribution-model-strategy.md) · [scale-5k-risk-analysis.md](scale-5k-risk-analysis.md)):

| 구간 | 공급 모델 (문서 가정) |
|------|----------------------|
| **402 → 5k (G1)** | Maintainer 엄선 · 수동 PR · merge |
| **5k → 50k (G2)** | Pipeline MVP + fix↑ · add는 여전히 미개방 |

### 1.2 A5가 증명해야 하는 것

A5는 **「50k Registry를 한 번에 만든다」** 가 아니라, 아래 **운영 가설**을 증명해야 한다.

| # | 증명 대상 | 실패 시 의미 |
|---|-----------|--------------|
| **P1** | **공급 경로**가 50k까지 **지속 가능한 throughput**을 낼 수 있다 | G2 목표 불가 · Contribution 조기 개방 또는 목표 하향 |
| **P2** | 규모가 커져도 **Coverage·enrich backlog**가 **통제 가능**하다 (A2·A3 전제) | stub 희석 · SW1/URV 저하 |
| **P3** | 규모가 커져도 **Quality·Governance**가 **자동·수동 혼합으로 유지**된다 | KPI만 PASS · 신뢰 붕괴 |
| **P4** | **search_index·shard·dedupe**가 50k **운영 부담**에서 **구조 변경 없이** 버틴다 | Phase 2 §3.2 예외 #2·#3 검토 |
| **P5** | **인적 큐** (dedupe · franchise · enrich · merge)가 **측정·예산 가능**하다 | A5 실패 = **운영 가정 붕괴** (구조 반박 아님) |

### 1.3 A5가 증명하지 않는 것

| 제외 | 근거 |
|------|------|
| 5M+ 커뮤니티 기여 모델 | contribution-model **별축** |
| 음악 · SW2 (A6) | Baseline 장기 과제 |
| Registry **구조** 정당성 | Phase 1 **Validated** |
| 402에서 Coverage **가능 여부** | Phase 2 **COMPLETE** |

---

## 2. 성공 기준 후보

> **후보** — Discovery 종료 시 **하나의 A5 Verification Charter**로 수치·측정 도구를 확정한다. 본 문서는 **범위 정의만**.

### 2.1 Registry 규모

| 후보 | 내용 | 근거 문서 |
|------|------|-----------|
| **R1** | G1 **5k** 도달 경로 **실측** (선행 관문) | scale-5k · A1 SIM-A |
| **R2** | G2 **50k** 도달 **경로 존재** (전량 달성 아님) | A5 원문 · contribution-model R0→R1 |
| **R3** | 월 **net insert** 하한 — 문서 가설 **~300–400/월 (5k)** · **~3k–5k/월 (G2)** | assumption-register A5 미검증 항목 |
| **R4** | Expansion Pipeline **운영 수준** 전환 (dry-run → 소량 실가동) | scale-5k §2 · §5 Top 1 |

### 2.2 Enrich 비용

| 후보 | 내용 | Phase 2 시사 |
|------|------|--------------|
| **E1** | **402 extrapolation 한계** 명시 — Sprint 03·04 Economics는 **402 cohort** | Mid-Review · Sprint 04 |
| **E2** | 5k·50k에서 **축별** human-eq · wall clock **실측** (titles.en · zh · externalId · composite) | Sprint 02 composite **~60.1h** (추정만) |
| **E3** | stub 비율 상승 시 **enrich SLA** — backlog가 insert율을 **追いつかない** 조건 정의 | A2 · scale-5k §3.3 |
| **E4** | 자동화율 **402 ≠ 5k ≠ 50k** — poster-priority 등 **cohort 의존** | Sprint 03·04 100% auto는 **선별 cohort** |

### 2.3 Quality 유지

| 후보 | 내용 | Phase 2 기준선 |
|------|------|----------------|
| **Q1** | `invalid_en_count` **0** 유지 (또는 정의된 상한) | Quality Gate MVP |
| **Q2** | `source_breakage_count` **0** | Sprint 03 교훈 |
| **Q3** | **Semantic QA** — syntactic gate **밖** 오류율 **측정 가능** | Phase 2 Open Question |
| **Q4** | 대량 insert·enrich 시 **감사·spot-check** 규모 **산정 가능** | Sprint 04 externalId 감사 |
| **Q5** | dedupe **pre-insert** 또는 **ingest 게이트** 효과 | scale-5k Top 2 · dedupe 사후만 |

### 2.4 Search 유지

| 후보 | 내용 | Phase 2 기준선 |
|------|------|----------------|
| **S1** | SW1 recall@10 **≥ Phase 2 하한** (402: **100%**) | phase2-charter §4.3 |
| **S2** | URV convergence **≥ Phase 2 하한** | 동일 |
| **S3** | GAP panel · alias · subtitle **≥90%** | Panel 운영 게이트 |
| **S4** | search_index **latency·크기** — 50k에서 **SW2 전** 안전대 | scale-5k §3.5 (5k **낮음**) · 50k **미측정** |
| **S5** | 쿼리 세트 **확대** 시 재기준 필요성 문서화 | governance-review M7 |

---

## 3. 검증 축

A5 Discovery는 아래 **4축**으로 검증 범위를 나눈다. (실행은 **후속 Charter**)

### 3.1 Data Scale — 공급·유입

| 검증 질문 | 알려진 단서 |
|-----------|-------------|
| insert 경로가 **월 net 목표**를 낼 수 있는가? | 수동 PR + merge만 **실측 없음** · Expansion **enabled:false** |
| Signal → Minimal Core **변환율·탈락률**은? | dry-run만 · **미측정** |
| 배치 import 시 **dedupe ingest**는? | 사후 linter · pre-insert **미성숙** (scale-5k) |

**Phase 2 연계:** G1 insert **실측 없음** — A2 stub 희석은 **Open Question**.

### 3.2 Coverage Scale — 표면형·식별자 밀도

| 검증 질문 | 알려진 단서 |
|-----------|-------------|
| 50k에서 **titles.en · zh · externalId** 목표 **유지 비용**은? | 402: en **91.5%** · zh **1%** · ext **50%** |
| stub-first 대량 유입 시 **Coverage 희석**은? | A2 Supported @402 · **5k/50k 미검증** |
| 축별 Economics **extrapolation** 한계는? | titles.en·externalId만 **402 실측** |

**Phase 2 연계:** Coverage **가능** — **규모 확장 시 SLA** 미정.

### 3.3 Governance Scale — 게이트·회귀·release

| 검증 질문 | 알려진 단서 |
|-----------|-------------|
| enrich 배치마다 **dashboard · SW1 · URV · quality_gate** — **50k에서 실행 가능**한가? | 402 **수동 PASS** · CI **미연동** |
| Release Block **RB1/RB2** — 대량 변경에서 **유효**한가? | MVP **titles.en** only |
| Panel KPI **연속 PASS** — insert 속도 대비 **감시 주기**는? | Phase 2 **매 Sprint gate** |

**Phase 2 연계:** Governance **MVP 존재** — **규모·자동화** 미검증.

### 3.4 Tooling Scale — 파이프라인·도구·인력

| 검증 질문 | 알려진 단서 |
|-----------|-------------|
| AI validator · merge train **미구현** — 50k에서 **인력 큐**는? | contribution-model · scale-5k §3.6 |
| franchise **수동 연결** — 5k **~400–600** 그룹 추정 | SIM-D · scale-5k §3.4 |
| `registry_builder` · shard · manifest — **50k rebuild** wall clock? | 5k **무위험** 추정 · 50k **미측정** |
| Sprint 02~04 Economics 도구 — **5k/50k cohort** 확장? | 402 전용 Sprint runner |

**Phase 2 연계:** 도구 체인 **402 검증** — **throughput·병렬·CI** Open.

---

## 4. 현재 알려진 사실 (Phase 2·Phase 1 기반)

> 새 분석 없음 — 기존 문서·Sprint 결과만.

### 4.1 구조·규모 (Phase 1)

| 사실 | 출처 |
|------|------|
| Registry · Franchise · Stub-first · **5k 합성** 구조 Supported | phase1-final-review |
| SIM-A throughput **~2,104/월** (합성) — **A1 Supported** | assumption-register |
| 5k에서 search_index·shard **성능 리스크 낮음** | scale-5k-risk-analysis §3.5 |
| 5k **1차 관문 = 공급** (성능 아님) | scale-5k §1 |

### 4.2 Coverage·Identity (Phase 2)

| 사실 | 출처 |
|------|------|
| 표면형 enrich로 SW1/URV/GAP **100%** 회복 가능 (402) | Sprint 01 |
| titles.en **91.5%** · externalId G2 **50%** · panel **100%** | phase2-summary |
| 대량 enrich 후 SW1/URV **100%** 유지 | Sprint 03·04 |
| Sprint 02 Economics는 **manual 상한**에 가까움 — 402 실측은 **더 낮음** | Mid-Review |
| Coverage 수량 ≠ 품질 — TMDB **31건** syntactic 사고 | Sprint 03 |

### 4.3 Governance (Phase 2)

| 사실 | 출처 |
|------|------|
| `quality_gate --strict` / `--release` **PASS** (402) | Sprint 04 종료 snapshot |
| Coverage·Quality KPI **분리 측정** 가능 | coverage_dashboard |
| CI workflow **미연동** | quality-gate-mvp §6.1 |
| externalId 신뢰 — **감사 + URV duplicate** (hard RB 없음) | Sprint 04 |

### 4.4 A5 관련 문서상 미검증 (이미 기록됨)

| 사실 | 출처 |
|------|------|
| Pipeline MVP **~3k–5k건/월** — **미검증** | assumption-register A5 |
| 50k dedupe·enrich **human queue 한도** — **미측정** | assumption-register A5 |
| 50k는 SIM-A/B/C **범위 밖** | assumption-register A5 |
| Expansion **dry-run·비활성** | scale-5k §2 |

---

## 5. 아직 모르는 것 (Open Questions)

Discovery 종료 전 **답이 없는** 항목만. (실패 아님 · **검증 대상**)

| # | Open Question | 축 |
|---|---------------|-----|
| O1 | 실제 **G1 insert rate** (net/월) — 수동·파이프라인 각각 | Data Scale |
| O2 | **5k 도달**까지 걸리는 wall·인력 — SIM-A extrapolation **유효성** | Data Scale |
| O3 | **50k 도달** 경로의 throughput — **~3k–5k/월** 가설 **실측** | Data Scale |
| O4 | 배치 유입 시 **pre-insert dedupe** precision — 사후 linter만으로 **충분한가** | Data Scale · Quality |
| O5 | stub 비율 ↑ 시 **titles.en / zh / externalId** 비율 **하한** | Coverage Scale |
| O6 | **5k·50k** 축별 enrich **human-eq·wall** — 402 Economics ** extrapolation 계수** | Coverage Scale |
| O7 | **enrich backlog > insert rate** 임계 — A2 **퇴화 조건** | Coverage Scale |
| O8 | **50k**에서 `quality_gate` · 감사 **주기·샘플 규모** | Governance Scale |
| O9 | **Semantic** enrich 오류율 — syntactic gate **밖** | Governance Scale |
| O10 | SW1/URV **쿼리 세트 확대** 시 recall 하한 | Search |
| O11 | search_index **50k** latency·크기 — 5k 녹색 구간 **연장 여부** | Search |
| O12 | franchise **수동 큐** — 5k·50k **시간/건** | Tooling Scale |
| O13 | `registry_builder` · manifest rebuild **50k wall clock** | Tooling Scale |
| O14 | Contribution **조기 개방 없이** fix-only·import만으로 G2 **지속 가능한가** | Data Scale · Tooling |

---

## 6. 비목표 (Out of Scope)

A5 Discovery·후속 검증 Charter **포함하지 않음**.

| # | 비목표 | 근거 |
|---|--------|------|
| X1 | **A5 검증 실행** (시뮬·insert·enrich 배치) | 본 문서 = Discovery only |
| X2 | **Registry / Franchise / search_index 구조 변경** | Phase 2·Baseline 고정 |
| X3 | **신규 ADR** | Charter 예외 미발동 |
| X4 | **신규 도구 구현** (Pipeline MVP 코드 · CI workflow) | Discovery 범위 밖 |
| X5 | **A6** 음악 · **SW2** 30M index | 장기 과제 |
| X6 | **402 Coverage 재검증** (titles.en · G2) | Phase 2 COMPLETE |
| X7 | **Contribution add(B) 개방** 정책 결정 | A5는 add **없이** 검증 |
| X8 | **50k 전량 달성**을 Discovery 성공 조건으로 요구 | 경로·운영 **가능성** 검증이 목적 |
| X9 | **실행 일정·Sprint 계획** | 후속 Verification Charter |

---

## 7. Discovery 산출 (후속 문서 예고)

본 Charter **승인 후** (실행 없이) 예상되는 다음 문서 — **본 문서에 계획 없음**, 이름만 참고:

| 산출 | 역할 |
|------|------|
| A5 Verification Charter | 성공 기준 **확정** · 측정·합격 수치 |
| A5 Readiness Review | 검증 착수 GO/NO-GO |

**본 Discovery 완료 조건:** §1 증명 대상 · §2 후보 · §3 축 · §5 Open Question **합의** — **실험 착수 아님**.

---

## 8. 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-discovery-charter.md](a5-discovery-charter.md) | **본 문서** — A5 검증 범위 Discovery |
| [assumption-register.md](assumption-register.md) | A5 정의 · Deferred |
| [phase2-summary.md](phase2-summary.md) | 402 기준선 |
| [phase2-final-review.md](phase2-final-review.md) | A5 Deferred 판정 |
| [scale-5k-risk-analysis.md](scale-5k-risk-analysis.md) | 5k 공급·리스크 |
| [contribution-model-strategy.md](contribution-model-strategy.md) | R0→R1→R2 공급 모델 |

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — A5 Discovery 범위만 (실험·구현·구조 변경 없음) |
