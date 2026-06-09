# A5 Operational Decisions — Pilot 착수 전 결정 항목

> **목적:** A5 Pilot 착수 **전** 결정이 필요한 **운영 항목**을 정리.  
> **질문:** *「A5 Pilot 착수 전에 실제로 무엇을 결정해야 하는가?」*  
> **전제:** [a5-pilot-launch-review.md](a5-pilot-launch-review.md) **PILOT LAUNCH GO** · 설계 단계 **CLOSED**  
> **기준일:** 2026-06-09

**금지:** **수치** 결정 · **기간** 결정 · **배치** 결정 · Pilot **실행**.

**문서 성격:** 결정 **인벤토리** — 값·일정·규모 **미포함**. 본 문서는 **결정해야 할 항목**만 나열한다.

---

## Executive Summary

| ID | 결정 영역 | Pilot 착수 전 필수 |
|:--:|-----------|:------------------:|
| **D1** | **관측 기간** | **예** — 첫 실측 **전** |
| **D2** | **배치 규모** | **예** — 첫 배치 **전** |
| **D3** | **합격 수치** | **예** — Gate **판정 전** |

**한 줄:** 설계 문서는 **무엇을·어떻게** 관측·판정할지 정의했다. D1~D3은 **얼마나·얼마 동안·어떤 기준으로** 실행할지 — Pilot **첫 이벤트 전** 확정해야 한다.

**출처:** [a5-pilot-launch-review.md](a5-pilot-launch-review.md) §6 · [a5-verification-charter.md](a5-verification-charter.md) §7.

---

## Decision D1 — 관측 기간

### D1 개요

| 필드 | 내용 |
|------|------|
| **결정 대상** | Pilot **시간 축** — 언제 시작·종료하고, 각 질문·Gate를 **얼마나 관측**할지 |
| **Pilot 착수 전 필수** | **예** — **첫 실측·기록 이벤트 전** |

### 왜 필요한가

Verification Charter는 **관측 시점 구조**(H1 전체 · H2 배치 전·중·후 등)만 정의한다. **실제 달력·윈도**가 없으면 O1(insert rate)·O7(backlog vs insert)·O2(wall·인력) 등 **시계열 질문에 답할 수 없다**. Pilot **정상 종료**(Exit X3·X4)도 **종료 시점** 정의 없이는 판정 불가.

### 어떤 문서에서 요구되는가

| 문서 | 요구 |
|------|------|
| [a5-verification-charter.md](a5-verification-charter.md) §2 | 관측 **시점** 구조 — **기간 미포함** (§7) |
| [a5-verification-charter.md](a5-verification-charter.md) §6.1 | Exit **X3·X4** — 관측 **완료**·S1·S2 판정 **가능** 시점 |
| [a5-pilot-launch-review.md](a5-pilot-launch-review.md) §6.1 · §7.4 | **첫 실측 전** 확정 |
| [a5-discovery-charter.md](a5-discovery-charter.md) §2 | **R1** G1 경로 실측 · **E3** enrich SLA |
| [a5-question-register.md](a5-question-register.md) | O1 · O2 · O7 — **Pilot** 시점 · 시계열 **의존** |

### 결정하지 않을 경우 발생하는 문제

| 문제 | 영향 |
|------|------|
| Pilot **시작·종료** 미정 | P1 Observation Log **맥락**(E0) **누락** · P3 Final Review **불가** |
| O1 **관측 윈도** 미정 | insert rate **측정 불가** · H1 **판정 불가** |
| O7 **최소 관측 기간** 미정 | backlog vs insert **추이** 미확보 · H3 **조기·과대 판정** |
| H2 **배치 전** O4 기간 미정 | Verification §3.4 — 배치 **보류** 무기한 |
| gate·SW1/URV **주기** 미정 | H3·H4 **증거 수집** 불규칙 · P2 Gate Record **근거 부족** |

### D1 하위 결정 항목

| # | 결정 항목 | 관련 H·O | Discovery 후보 | 착수 전 필수 |
|---|-----------|----------|----------------|:------------:|
| D1.1 | Pilot **시작 시점** 정의 | 전체 | — | **예** |
| D1.2 | Pilot **종료 조건·시점** (X3·X4) | 전체 | Exit §6.1 | **예** |
| D1.3 | O1 insert rate **관측 윈도** | H1 · O1·O2 | R1 · R3 | **예** |
| D1.4 | O7 backlog vs insert **최소 관측 기간** | H3 · O7 | E3 | **예** |
| D1.5 | H2 O4 **배치 전** 선행 관측 기간 | H2 · O4 | Q5 | **예** |
| D1.6 | `quality_gate` · SW1/URV **실행 주기** | H3·H4 · O8·O10 | Governance §3.3 · S1·S2 | **예** |
| D1.7 | H5 rebuild·franchise 큐 **리뷰 주기** | H5 · O11·O12·O13 | Tooling §3.4 | **권장** (H5 Informational) |

---

## Decision D2 — 배치 규모

### D2 개요

| 필드 | 내용 |
|------|------|
| **결정 대상** | Pilot **볼륨 축** — insert·enrich·시험·샘플의 **단위 크기·누적 상한·경로 비중** |
| **Pilot 착수 전 필수** | **예** — **첫 배치 insert·enrich 전** |

### 왜 필요한가

Pilot Charter는 **G1 경로 소량 관측**만 허용한다. **「소량」의 운영 정의**가 없으면 H2(무결성)·H3(Coverage 희석)·H4(gate 부하) 관측이 **재현·비교 불가**하다. O1 **경로별 분리**(수동 PR vs 파이프라인)도 **볼륨 배분** 없이는 답할 수 없다.

### 어떤 문서에서 요구되는가

| 문서 | 요구 |
|------|------|
| [a5-verification-charter.md](a5-verification-charter.md) §7 | 배치 **크기** — Charter **미포함** |
| [a5-pilot-launch-review.md](a5-pilot-launch-review.md) §6.2 · §7.4 | **첫 배치 전** 확정 |
| [a5-pilot-charter.md](a5-pilot-charter.md) §2.1 | G1 경로 · Expansion **소량** · 기존 파이프라인 |
| [a5-discovery-charter.md](a5-discovery-charter.md) §2 · §3 | **R4** 소량 실가동 · Data Scale §3.1 |
| [a5-verification-charter.md](a5-verification-charter.md) §3.4 | H2 배치 **전** O4 증거 없으면 **유입 보류** |
| [scale-5k-risk-analysis.md](scale-5k-risk-analysis.md) | Top 2 dedupe — O4 **시험 규모** 맥락 |

### 결정하지 않을 경우 발생하는 문제

| 문제 | 영향 |
|------|------|
| insert **누적 상한** 미정 | Pilot 범위 **과대** · X-P1(50k 달성) **혼선** · 리스크 **비통제** |
| PR vs 파이프라인 **비중** 미정 | O1 **분리 측정 불가** · H1 증거 **불충분** |
| enrich **배치·축** 미정 | O5·O6 **관측 불가** · Economics runner **cohort 불명** |
| O4 **시험 규모** 미정 | H2 **관측 미시작** 또는 **과소·과대** 시험 |
| semantic **샘플 규모** 미정 | O9 **증거 패키지** 미충족 (§3.3) |

### D2 하위 결정 항목

| # | 결정 항목 | 관련 H·O | Discovery 후보 | 착수 전 필수 |
|---|-----------|----------|----------------|:------------:|
| D2.1 | Pilot **단일 배치** insert **상한** | H1 · O1 | R4 | **예** |
| D2.2 | Pilot **누적** insert **상한** | H1 · O1·O2 | R1 | **예** |
| D2.3 | **수동 PR** vs **파이프라인** 비중·순서 | H1 · O1 | Data §3.1 | **예** |
| D2.4 | enrich **배치 크기** | H3 · O5·O6·O7 | E2 | **예** |
| D2.5 | enrich **축** (titles.en · zh · externalId) **선택** | H3 · O5·O6 | E2 · E4 | **예** |
| D2.6 | O4 **배치 유입 시험** 규모 | H2 · O4 | Q5 · scale-5k Top 2 | **예** |
| D2.7 | O9 semantic **spot-check 샘플** 규모 | H4 · O9 | Q3 · Q4 | **예** |
| D2.8 | Expansion Pipeline **가동 범위** (기존 설계 내) | H1 · O14 | R4 | **예** |

---

## Decision D3 — 합격 수치

### D3 개요

| 필드 | 내용 |
|------|------|
| **결정 대상** | Gate **판정 기준** — Continue / Pause / Stop에 쓰일 **임계·하한·비교 규칙** |
| **Pilot 착수 전 필수** | **예** — **첫 Gate 판정(P2) 전** (실측 **시작 후**·판정 **이전**까지 확정 가능하나 **착수 전 문서화 권장**) |

> **시점:** Launch Review §6.4 — 배치 **시작**보다 Gate **판정** 직전이 **최종 데드라인**. 운영상 **Pilot 킥오프 전** D3를 확정하지 않으면 중간 실측 **판정 불가** → 실질적으로 **착수 전 필수**로 취급.

### 왜 필요한가

Verification Charter §4는 **정성·구조** 판정 규칙만 정의한다. 「Phase 2 baseline 대비 퇴화 패턴 없음」「O7 실패 시 의미」 등을 **운영에서 적용**하려면 **구체적 비교 기준**(KPI 하한·Pause 임계·기각 조건)이 필요하다. 없으면 P2 Gate Decision Record가 **주관적**이 되어 H1 Stop · H3 Pause **재현 불가**.

### 어떤 문서에서 요구되는가

| 문서 | 요구 |
|------|------|
| [a5-verification-charter.md](a5-verification-charter.md) §4 · §7 | 판정 **구조** — 합격 **수치 미포함** |
| [a5-discovery-charter.md](a5-discovery-charter.md) §2 | **R3** · **E3** · **Q1~Q5** · **S1~S5** — **후보** |
| [a5-gate-review.md](a5-gate-review.md) §5 | S1~S4 **통과** 정의 |
| [a5-pilot-launch-review.md](a5-pilot-launch-review.md) §6.3 | Gate **판정 전** 확정 |
| [a5-question-register.md](a5-question-register.md) | 각 O **성공·실패 시 의미** — 수치 **미정** |
| [phase2-summary.md](phase2-summary.md) | 402 **baseline** — 비교 **참조** |

### 결정하지 않을 경우 발생하는 문제

| 문제 | 영향 |
|------|------|
| net insert **하한** 미정 | H1 Continue/Stop **판정 불가** · O1·O14 **미결** |
| backlog Pause **임계** 미정 | H3 **Pause** 적용 **불가** · O7 **미답** |
| Coverage **축별 하한** 미정 | H3 O5 **희석** 판정 **불가** |
| quality_gate KPI **기준** 미정 | H4 **Continue/Pause** **불가** · O8·O9 **근거 부족** |
| SW1/URV/GAP **하한** 미정 | H3 O10 · A3 회귀 **판정 불가** |
| 402 **대비 허용 변화** 규칙 미정 | Verification §3.1 E0 **적용 불가** |
| Pilot **성공**(§6.2 S1~S4) **선언 불가** | Scale 진입 **입력(P4) 무의미** |

### D3 하위 결정 항목

| # | 결정 항목 | 관련 H·O | Discovery 후보 | 착수 전 필수 |
|---|-----------|----------|----------------|:------------:|
| D3.1 | G1 **net insert** 하한·측정 정의 | H1 · O1·O2 | R3 | **예** |
| D3.2 | G2 throughput **참조값** (Scale 입력용) | H1 · O3 | R3 · assumption-register A5 | **권장** (Scale 이관) |
| D3.3 | Coverage **축별** 하한 (titles.en · zh · externalId) | H3 · O5 | A2·A3 · Discovery §3.2 | **예** |
| D3.4 | enrich **backlog > insert** Pause **임계** | H3 · O7 | E3 | **예** |
| D3.5 | `invalid_en_count` · `source_breakage_count` **기준** | H4 | Q1 · Q2 | **예** |
| D3.6 | SW1 recall · URV · GAP panel **하한** | H3 · O10 | S1 · S2 · S3 | **예** |
| D3.7 | semantic 오류 **관측·기각 기준** | H4 · O9 | Q3 | **예** |
| D3.8 | search_index **latency·크기** 참조 (H5) | H5 · O11 | S4 | **권장** |
| D3.9 | 402 baseline **대비** 변화 **서술·판정 규칙** | H3·H4 | Phase 2 baseline | **예** |
| D3.10 | H1 **Stop** vs **범위 축소** (G1 only) **분기 규칙** | H1 · O14 | Gate Review §3 | **예** |

---

## D1~D3 의존 관계

```
D1 (기간) ──► D2 (볼륨) ──► 실측 이벤트
                              │
D3 (합격 수치) ◄──────────────┘
        │
        ▼
   P2 Gate Decision Record
```

| 의존 | 설명 |
|------|------|
| D1 → D2 | 관측 **윈도** 없이 누적 insert **상한**만 정하면 **기간 대비 과대** 위험 |
| D2 → D3 | 볼륨·cohort 없이 Coverage·Economics **기준** 정의 **불완전** |
| D3 ⊥ D1·D2 | D3는 **판정**용 — D1·D2 **후** 미세 조정 가능하나 **첫 판정 전** 확정 필요 |

---

## 착수 전 필수 요약

| 시점 | 필수 결정 | 미결 시 |
|------|-----------|---------|
| **첫 기록·실측 전** | **D1** 전항 (D1.7 권장) | Observation Log **시작 불가** |
| **첫 insert·enrich 배치 전** | **D2** 전항 | Verification §3.4 **배치 보류** |
| **첫 Gate 판정 전** | **D3** (D3.2·D3.8 권장 제외 가능) | P2 **작성 불가** · Pause/Stop **미적용** |

| D | 하위 항목 수 | 착수 전 **필수** | **권장** |
|---|:-----------:|:----------------:|:--------:|
| **D1** | 7 | 6 | 1 |
| **D2** | 8 | 8 | 0 |
| **D3** | 10 | 8 | 2 |

---

## 본 문서가 하지 않는 것

| 제외 | 근거 |
|------|------|
| D1~D3 **값·수치·일정 확정** | 사용자 지시 · 본 문서 성격 |
| Pilot **실행** · 배치 **계획** | Launch Review §7.4 |
| 신규 **도구 구현** | Pilot Charter X-P4 |
| **결정 권한·승인 절차** | 설계 범위 밖 |

**다음 단계 (본 문서 범위 밖):** D1~D3 **값 확정** → Pilot **킥오프** → Verification Charter §4·§5 **적용**.

---

## 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-operational-decisions.md](a5-operational-decisions.md) | **본 문서** — D1~D3 인벤토리 |
| [a5-pilot-launch-review.md](a5-pilot-launch-review.md) | LAUNCH GO · §6 출처 |
| [a5-verification-charter.md](a5-verification-charter.md) | 관측·판정 방법론 · §7 이관 |
| [a5-discovery-charter.md](a5-discovery-charter.md) | R/E/Q/S 후보 |
| [a5-gate-review.md](a5-gate-review.md) | S1~S4 · Stop/Pause/Continue |

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — D1~D3 결정 인벤토리 (값·기간·배치 미확정) |
