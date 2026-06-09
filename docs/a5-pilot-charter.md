# A5 Pilot Charter — Pilot 검증 범위

> **목적:** A5 Discovery **종료 후** Pilot 단계가 **무엇을 검증해야 하는지** 정의.  
> **질문:** *「Pilot에서 H1~H5 중 실제로 무엇을 관측·판정하는가?」*  
> **전제:** [a5-discovery-charter.md](a5-discovery-charter.md) · [a5-gate-review.md](a5-gate-review.md) · [a5-hypothesis-map.md](a5-hypothesis-map.md) · Phase 2 **COMPLETE** (402)  
> **기준일:** 2026-06-09

**금지:** Pilot **실행** · 실험 설계 · **수치 결정** · **구현 계획**.

**문서 성격:** Charter — Pilot **범위·목적·Gate 연결**만. Verification Charter·Readiness Review는 **별도**.

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| **Pilot 위치** | Discovery **합의 후** → **Scale(50k 운영 가정)** **이전** |
| **Pilot 한 줄** | **G1(5k) 경로**에서 공급·무결성·규모 신호를 **소량·관측 가능**하게 검증 |
| **핵심 검증** | **H1** · **H2** (Critical) — Pilot **성패를 가름** |
| **부가 검증** | **H3** · **H4** (Supporting) — Pilot에서 **관측** · Scale에서 **확정** |
| **정보 수집** | **H5** (Informational) — 부담 **가시화** (단독 중단 아님) |
| **비목표** | 50k **달성** · **구조 변경** · **신규 아키텍처** |

---

## 1. Pilot 목적

### 1.1 프로그램 목적

Pilot은 A5 가정 — *Contribution 없이 Maintainer + 반자동 Import + Expansion Pipeline만으로 50k까지 **도달·운영 가능한가?*** — 에 대해 **실측 가능한 첫 관문**이다.

Discovery가 **「무엇을 증명해야 하는가」** 를 정의했다면, Pilot은 **「G1 경로에서 그 증명이 성립하는지 관측한다」**.  
50k **전량 달성**이나 **G2 throughput 확정**은 Pilot 목적이 **아니다** ([a5-discovery-charter.md](a5-discovery-charter.md) X8 · [a5-question-register.md](a5-question-register.md) Scale 시점).

### 1.2 H1~H5별 Pilot 검증 역할

| 가설 | Gate | Pilot에서 검증하는 것 | Pilot에서 검증하지 않는 것 |
|------|------|----------------------|---------------------------|
| **H1** Supply Without Contribution | **G-SUPPLY** (Critical) | 공급 경로 **존재·측정 가능** · G1 insert **관측** · add 없이 G2 **경로 기각 여부** (O1 · O2 · O14) | G2 **전량 throughput** 확정 (O3 → Scale) |
| **H2** Ingest Integrity | **G-INTEGRITY** (Critical) | 배치·파이프라인 유입 시 **dedupe·무결성** 수용 가능 여부 (O4) | 대규모·장기 **운영 한계** 전체 |
| **H3** Identity & Coverage Under Scale | **G-IDENTITY** (Supporting) | stub 유입 하 **Coverage·backlog·회귀** **초기 신호** (O5 · O7 · O6 · O10) | 50k 규모 **최종** A2·A3 판정 |
| **H4** Quality & Governance Under Scale | **G-QUALITY** (Supporting) | 기존 gate·감사 **Pilot 볼륨**에서 **동작 가능** 신호 (O8 · O9 샘플) | 50k **주기·샘플 체계** 확정 |
| **H5** Platform & Curator Load | **G-PLATFORM** (Informational) | rebuild·franchise·인적 큐 **부담 기록** (O11 · O12 · O13) | SW2 · headcount **투자 결정** |

### 1.3 Discovery 증명 대상(P1~P5)과의 대응

| Discovery P | Pilot 검증 깊이 |
|-------------|-----------------|
| **P1** 공급 throughput | **핵심** — H1 · O1 · O2 |
| **P2** Coverage·backlog 통제 | **관측** — H3 · O5 · O7 |
| **P3** Quality·Governance 유지 | **관측** — H4 · O8 · O9 (샘플) |
| **P4** dedupe·search_index 부담 | **H2** + **H5/O11** (병행 가능) |
| **P5** 인적 큐 측정·예산 | **기록** — H5 · O12 |

---

## 2. Pilot 범위

**원칙:** Discovery Charter·Question Register에서 **허용된 범위만** Pilot에 포함한다.

### 2.1 포함 (In Scope)

| 축 | Pilot 범위 (구조만) |
|----|---------------------|
| **Data Scale** | **G1(5k) 경로** — Maintainer · 수동 PR · merge · Expansion **기존 파이프라인** 소량 관측 ([a5-discovery-charter.md](a5-discovery-charter.md) §3.1) |
| **Coverage Scale** | Pilot 볼륨에서 **titles.en · zh · externalId** · stub 희석 **신호** ([a5-discovery-charter.md](a5-discovery-charter.md) §3.2) |
| **Governance Scale** | Phase 2 **기존** `quality_gate` · `coverage_dashboard` · SW1 · URV · Release Block **재사용** ([a5-discovery-charter.md](a5-discovery-charter.md) §3.3) |
| **Tooling Scale** | **기존** `registry_builder` · shard · manifest · Sprint Economics runner — **402 이후 확장 관측** ([a5-discovery-charter.md](a5-discovery-charter.md) §3.4) |

### 2.2 Open Question — Pilot 해결 대상

[a5-question-register.md](a5-question-register.md) **Pilot** 시점 질문만 Pilot 범위.

| 우선순위 | ID | 가설 |
|:--------:|:---|------|
| **P0** | O1 · O4 · O14 | H1 · H2 |
| **P1** | O7 · O2 · O5 | H3 · H1 |
| **P2** | O6 · O12 | H3 · H5 |
| **P3 (Pilot 일부)** | O9 · O10 · O11 · O13 | H4 · H3 · H5 |

**Scale로 이관 (Pilot 비범위):** **O3** (G2 throughput) · **O8** (50k 거버넌스 주기) — Pilot 결과 **입력**으로만 사용.

### 2.3 전제 (변경 없음)

| # | 전제 | 출처 |
|---|------|------|
| T1 | Registry **402 baseline** — Phase 2 Coverage·Governance **재검증 아님** | Discovery X6 |
| T2 | **Contribution add(B) 미개방** | Discovery X7 · O14 |
| T3 | Phase 2 **구조·Baseline 고정** | Discovery X2 |
| T4 | Expansion·파이프라인 — **기존 설계** 범위 내 관측 (신규 MVP **본 Charter 범위 밖**) | Discovery X4 |

### 2.4 Pilot 산출 (개념)

Pilot **종료 시** 기대되는 **판정 산출** (실행·형식은 Verification Charter에서 확정):

| 산출 | 내용 |
|------|------|
| **Gate 판정 기록** | G-SUPPLY · G-INTEGRITY · G-IDENTITY · G-QUALITY · G-PLATFORM |
| **Scale GO/NO-GO 입력** | O3 · O8 **이관** · H3·H4 **잔여 리스크** |
| **Assumption A5 방향** | Supported / Unsupported / Deferred **후보** (최종은 A5 종료 판정) |

---

## 3. Pilot 비목표 (Out of Scope)

Discovery 비목표를 Pilot에 **그대로 적용**하고, Pilot 단계 **추가 금지**를 명시한다.

| # | 비목표 | 근거 |
|---|--------|------|
| **X-P1** | **50k 전량 달성** 또는 G2 **완료 선언** | Discovery X8 · Pilot = G1 경로 관측 |
| **X-P2** | **Registry / Franchise / search_index 구조 변경** | Discovery X2 · Phase 2 고정 |
| **X-P3** | **신규 아키텍처** · 신규 ADR · 스키마·shard 모델 **재설계** | Discovery X2 · X3 |
| **X-P4** | **신규 도구·CI·Pipeline MVP 구현**을 Pilot **성공 조건**으로 요구 | Discovery X4 |
| **X-P5** | **A6** · **SW2** · 5M+ Contribution 모델 | Discovery X5 |
| **X-P6** | **402 Coverage 재검증** (titles.en G2 등) | Discovery X6 |
| **X-P7** | Pilot **실행** · 배치 **수치 확정** · Sprint **일정** | 본 문서 = 범위만 |
| **X-P8** | Contribution **정책 결정** (add 개방 여부) | Discovery X7 |

**Pilot 실패 ≠ 구조 변경 허용.** H2 Pause 등은 **운영·도구 보완** — 구조 예외는 Phase 2 Charter **별도 절차** ([a5-gate-review.md](a5-gate-review.md) H2 실패).

---

## 4. Gate 연결

[a5-gate-review.md](a5-gate-review.md) 분류를 Pilot에 **적용**한다.

### 4.1 Gate 유형 × Pilot

| Gate 유형 | 가설 | Gate ID | Pilot 역할 |
|-----------|------|---------|------------|
| **Critical** | H1 | **G-SUPPLY** | Pilot **필수 통과** — 미통과 시 **Stop** |
| **Critical** | H2 | **G-INTEGRITY** | Pilot **필수 통과** — 미통과 시 **Pause** (Pilot 전·중) |
| **Supporting** | H3 | **G-IDENTITY** | Pilot **관측** — 완전 통과는 Scale 가능 · 미통과 시 **Pause** |
| **Supporting** | H4 | **G-QUALITY** | Pilot **관측** — 동일 |
| **Informational** | H5 | **G-PLATFORM** | Pilot **기록** — **Stop 없음** |

### 4.2 검증 순서 (Pilot 내)

[a5-hypothesis-map.md](a5-hypothesis-map.md) §4 준수.

```
H1 (G-SUPPLY) ──► H2 (G-INTEGRITY) ──► H3 (G-IDENTITY) ──► H4 (G-QUALITY)
       │                                                              ▲
       └──────────────── H5 (G-PLATFORM) ── O11 병행 가능 ────────────┘
```

| 순서 | 가설 | Pilot 판정 시점 |
|:----:|------|-----------------|
| 1 | **H1** | Pilot **초기** — 공급 **관측 가능** 전제 |
| 2 | **H2** | **배치 유입 전** — 무결성 **기각 아님** 확인 |
| 3 | **H3** | insert·enrich **병행** 관측 |
| 4 | **H4** | enrich 볼륨 발생 후 gate·감사 |
| 5 | **H5** | H1·H3와 **부분 병행** · 종료 시 **문서화** |

### 4.3 Gate ↔ 질문 (Pilot)

| Gate | Pilot 질문 |
|------|------------|
| G-SUPPLY | O14 → O1 → O2 |
| G-INTEGRITY | O4 |
| G-IDENTITY | O7 → O5 → O6 → O10 |
| G-QUALITY | O9 → O8 (샘플) |
| G-PLATFORM | O11 ∥ O13 → O12 |

---

## 5. 성공 기준

**기준 문서:** [a5-gate-review.md](a5-gate-review.md) §4 (진행) · §5 (성공) — Pilot 범위로 **적용**.

### 5.1 Pilot 착수 조건 (Gate Review §4)

| # | 조건 | Gate |
|---|------|------|
| M1 | A5 명제·O14 범위 **Discovery 합의** | — |
| M2 | G-SUPPLY **기각 아님** (공급 경로 관측 준비) | H1 |
| M3 | G-INTEGRITY **기각 아님** (O4 Pilot 전) | H2 |
| M4 | Phase 2 Governance **baseline** 존재 | — |
| M5 | 구조 변경 예외 **미발동** | — |

```
Pilot 착수  IF  M1~M5 AND G-SUPPLY ≠ Stop
```

### 5.2 Pilot 성공 조건 (Gate Review §5 — Pilot 적용)

| # | Gate Review | Pilot 적용 |
|---|-------------|------------|
| **S1** | G-SUPPLY **통과** | **필수** — G2 경로 **기각 아님** · O1·O2·O14 **관측 완료** |
| **S2** | G-INTEGRITY **통과** | **필수** — O4 **수용** |
| **S3** | G-IDENTITY **통과** | **Pilot:** A2·A3 **퇴화 신호 없음** (완전 확정은 Scale) |
| **S4** | G-QUALITY **통과** | **Pilot:** gate·감사 **동작 확인** (50k 체계는 Scale) |
| **S5** | G-PLATFORM **문서화** | **필수** — 통과 여부 **기록** |

**Pilot 성공 판정 (최소)**

```
Pilot 성공  IF  S1 AND S2
            AND S3·S4 기각 아님 (Pause 가능 — Scale 이관 조건부)
            AND S5 기록됨
```

| 결과 | 다음 단계 |
|------|-----------|
| S1·S2 **통과** · S3·S4 **통과 또는 조건부** | **Scale** 검증 **진행 가능** |
| S1·S2 **통과** · S3 또는 S4 **Pause** | Scale **보류** — SLA·gate **보완 후** |
| S1 **미통과** | A5 **Unsupported** 후보 — Pilot **성공 아님** |

**A5 전체 성공** (Assumption Supported)은 Gate Review §5 **전체** (S1~S4 **모두 통과** + S5) — **Pilot 단독으로 선언하지 않음**.

---

## 6. 중단 조건

**기준 문서:** [a5-gate-review.md](a5-gate-review.md) §3 — **그대로** Pilot에 적용.

### 6.1 가설별 중단 판정

| 가설 | Gate | 판정 | Pilot 조치 |
|------|------|:----:|------------|
| **H1** | G-SUPPLY | **Stop** | Pilot **종료** · A5 **Unsupported** 후보 |
| **H2** | G-INTEGRITY | **Pause** | Pilot **보류** · ingest·dedupe 보완 **후 재개** |
| **H3** | G-IDENTITY | **Pause** | insert·enrich **속도 조정** · Scale **보류** |
| **H4** | G-QUALITY | **Pause** | Pilot **성공 선언 불가** · gate·감사 강화 |
| **H5** | G-PLATFORM | **Continue** | Pilot **본선 유지** · 일정·부담 **조정·기록** |

### 6.2 즉시 Stop (Pilot 종료)

| 조건 | 출처 |
|------|------|
| **H1 완전 기각** — 공급 경로 없음 | Gate Review §3 |
| **H1 부분 미달** — 경로 있으나 G2 불가 (범위 축소 **미선택** 시) | Gate Review §3 |
| **구조 변경 예외 발동** — Pilot 전제 붕괴 | M5 |
| **Contribution add 개방** — O14 전제 상실 | Discovery X7 |

### 6.3 Pause 후 재개

| 조건 | 재개 전제 |
|------|-----------|
| H2 **기각** | O4 **수용 가능** 재확인 |
| H3 **Pause** | backlog·Coverage **균형** 조정 |
| H4 **Pause** | gate·감사 **강화** 후 동일 Pilot 범위 |

**Pause ≠ Stop.** 재개 시 **Pilot 범위 내** — 50k·구조 변경 **여전히 금지** (§3).

### 6.4 Pilot → Scale 전환

| 조건 | 판정 |
|------|------|
| §5.2 **Pilot 성공** | Scale **착수 가능** (Readiness Review **별도**) |
| S1·S2 통과 · S3·S4 **조건부** | Scale **제한 착수** — 리스크 **문서화** |
| **Stop** | Scale **착수 불가** |

---

## 7. 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-pilot-charter.md](a5-pilot-charter.md) | **본 문서** — Pilot 범위 |
| [a5-discovery-charter.md](a5-discovery-charter.md) | Discovery 범위·P1~P5 |
| [a5-gate-review.md](a5-gate-review.md) | Gate · 성공·중단 기준 |
| [a5-hypothesis-map.md](a5-hypothesis-map.md) | H1~H5 |
| [a5-question-register.md](a5-question-register.md) | O1~O14 · Pilot/Scale 시점 |

**후속 (본 문서에 계획 없음):** A5 Verification Charter · A5 Readiness Review.

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — Pilot 범위·Gate 연결 (실행·수치·구현 없음) |
