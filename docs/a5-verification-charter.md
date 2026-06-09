# A5 Verification Charter — Pilot 관측·판정 방법론

> **목적:** A5 Pilot에서 **무엇을 관측**하고, **어떤 방식으로** H1~H5를 Continue / Pause / Stop 판정할지 정의.  
> **질문:** *「A5 Pilot에서 무엇을 측정하고 어떤 결과가 나오면 어떤 Gate 판정인가?」* — **방법론**만.  
> **전제:** [a5-pilot-readiness-review.md](a5-pilot-readiness-review.md) **PILOT GO** · [a5-pilot-charter.md](a5-pilot-charter.md) · [a5-gate-review.md](a5-gate-review.md)  
> **기준일:** 2026-06-09 · Registry **402** baseline

**금지:** Pilot **실행** · **수치 목표** 확정 · **합격선** 결정 · **데이터 수집**.

**문서 성격:** Verification **방법론** — 관측 항목·증거 유형·판정 **규칙 구조**. 합격 **수치**·배치 **규모**·관측 **기간**은 Pilot **착수 전 별도 결정** (본 문서 **미포함**).

**판정어** ([a5-gate-review.md](a5-gate-review.md))

| 판정 | 의미 |
|------|------|
| **Continue** | 가설 **기각 신호 없음** — Pilot **다음 관측** 진행 |
| **Pause** | **기각 또는 위험 신호** — 보완·조정 **후 재개** |
| **Stop** | 가설 **기각** — Pilot **종료** · A5 **Unsupported** 후보 |

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| **검증 단위** | H1~H5 (Gate) · O1~O14 (관측 질문) |
| **관측 원칙** | Phase 2 **기존 도구** 재사용 · 402 baseline **대비 기록** (신규 합격선 **본 문서에서 정의 안 함**) |
| **판정 원칙** | [a5-gate-review.md](a5-gate-review.md) §3 + [a5-question-register.md](a5-question-register.md) **성공·실패 시 의미**와 **증거 정합** |
| **Critical** | H1 → **Stop** 가능 · H2 → **Pause** |
| **Supporting** | H3 · H4 → **Pause** (성공 선언 불가) |
| **Informational** | H5 → **Continue** (단독 Stop 없음) |

---

## 1. Verification Scope

[a5-pilot-charter.md](a5-pilot-charter.md) §2 범위 내. **G1(5k) 경로** 관측.

### 1.1 H1 — G-SUPPLY (Critical)

| 필드 | 내용 |
|------|------|
| **가설** | Contribution 없이 공급 경로가 G1→G2까지 **지속 가능** |
| **Gate** | G-SUPPLY |
| **Pilot 질문** | O14 · O1 · O2 |
| **Scale 이관** | O3 (G2 throughput) |
| **Discovery 축** | P1 · Data Scale |
| **후보 카테고리** | R1 · R4 ([a5-discovery-charter.md](a5-discovery-charter.md) §2.1) |

**관측 범위:** Maintainer · 수동 PR · merge · Expansion **기존 경로**의 **존재·가동·측정 가능성**. G2 **전량 달성** 아님.

### 1.2 H2 — G-INTEGRITY (Critical)

| 필드 | 내용 |
|------|------|
| **가설** | 배치 유입 시 dedupe·무결성 **수용 가능** |
| **Gate** | G-INTEGRITY |
| **Pilot 질문** | O4 |
| **Discovery 축** | P4 (dedupe) · Data Scale |
| **후보 카테고리** | Q5 |

**관측 범위:** 배치 유입 **전·중·후** 중복·오염 stub **신호**. 구조 변경 **요구 여부** 아님 — **운영 수용** 여부.

### 1.3 H3 — G-IDENTITY (Supporting)

| 필드 | 내용 |
|------|------|
| **가설** | 규모 확대 시 A2·A3 (Coverage·회귀) **유지 가능** |
| **Gate** | G-IDENTITY |
| **Pilot 질문** | O7 · O5 · O6 · O10 |
| **Discovery 축** | P2 · Coverage Scale · Search |
| **후보 카테고리** | E1 · E3 · S1 · S2 · S5 |

**관측 범위:** insert·enrich **병행** 시 Coverage KPI · SW1/URV · backlog **추이**. 50k **최종** A2·A3 판정은 Scale.

### 1.4 H4 — G-QUALITY (Supporting)

| 필드 | 내용 |
|------|------|
| **가설** | 규모 확대 시 품질·거버넌스 **운영 가능** |
| **Gate** | G-QUALITY |
| **Pilot 질문** | O9 · O8 (샘플) |
| **Scale 이관** | O8 (50k 주기·체계) |
| **Discovery 축** | P3 · Governance Scale |
| **후보 카테고리** | Q1 · Q2 · Q3 · Q4 |

**관측 범위:** Pilot 볼륨에서 gate·감사·semantic **관측 가능성**. 50k **주기·샘플 체계**는 Scale.

### 1.5 H5 — G-PLATFORM (Informational)

| 필드 | 내용 |
|------|------|
| **가설** | 플랫폼·인적 운영 부담이 **구조 변경 없이** 감당 가능 |
| **Gate** | G-PLATFORM |
| **Pilot 질문** | O11 · O12 · O13 |
| **Discovery 축** | P4 · P5 · Tooling Scale |
| **후보 카테고리** | S4 |

**관측 범위:** rebuild · search_index · franchise 큐 **부담 기록**. SW2·headcount **결정** 아님.

### 1.6 Scope 요약

| 가설 | Gate 유형 | Pilot 관측 | Scale 이관 |
|------|-----------|------------|------------|
| H1 | Critical | **전면** | O3 |
| H2 | Critical | **전면** | — |
| H3 | Supporting | **전면** | 최종 판정 |
| H4 | Supporting | **샘플** | O8 체계 |
| H5 | Informational | **기록** | 50k 구간 |

---

## 2. Observation Plan

**순서:** H1 → H2 → H3 → H4 · H5는 H1·H3와 **부분 병행** ([a5-hypothesis-map.md](a5-hypothesis-map.md) §4).

**관측 주기 (구조만 — 기간·볼륨 미정)**

| 가설 | 관측 시점 |
|------|-----------|
| H1 | Pilot **전체** — 공급 이벤트 **발생 시** |
| H2 | **배치 유입 전** 선행 · 유입 **중·후** |
| H3 | insert **후** · enrich **배치 후** · gate 실행 **후** |
| H4 | enrich·insert **배치 후** gate·감사 **실행 시** |
| H5 | registry rebuild · franchise 큐 **리뷰 시** · O11 **병행** |

### 2.1 H1 — Observation Plan

| ID | 관측 항목 | 관측 대상 (구조) |
|:---|-----------|------------------|
| **O14** | add(B) **없이** fix-only·import만으로 G2 **경로 기각 여부** | 공급 모델 **전제 유지** · Contribution **미개방** 확인 |
| **O1** | G1 **net insert rate** — 수동 PR vs 파이프라인 **분리** | insert·merge **이벤트** · 경로별 **발생 여부** |
| **O2** | G1 도달 **wall·인력** · SIM-A extrapolation **정합** | O1 시계열 · Phase 1 SIM-A **문서 대비** 기록 |

**질문 순서:** O14 (전제 확인) → O1 → O2

### 2.2 H2 — Observation Plan

| ID | 관측 항목 | 관측 대상 (구조) |
|:---|-----------|------------------|
| **O4** | pre-insert dedupe **효과** · 사후 linter **충분성** | 유입 **전** 중복 후보 · 유입 **후** 중복 stub · merge train **부담** |

**선행 조건:** O1에서 **배치 유입 전제** 확립 **후** 본격 관측 ([a5-question-register.md](a5-question-register.md) O4 의존성).

### 2.3 H3 — Observation Plan

| ID | 관측 항목 | 관측 대상 (구조) |
|:---|-----------|------------------|
| **O7** | enrich **backlog** vs insert rate **균형** | stub·enrich **대기열** · insert **속도** **상대 추이** |
| **O5** | stub 비율 ↑ 시 **titles.en / zh / externalId** | Coverage **축별** dashboard 지표 |
| **O6** | 축별 enrich **human-eq·wall** · 402 extrapolation | Sprint Economics runner **출력** · 402 cohort **대비** |
| **O10** | SW1/URV **쿼리 세트** 민감도 | 기존 쿼리 세트 **실행 결과** · 확대 **필요성** 신호 |

**질문 순서:** O7 → O5 → O6 → O10

### 2.4 H4 — Observation Plan

| ID | 관측 항목 | 관측 대상 (구조) |
|:---|-----------|------------------|
| **O9** | **Semantic** enrich 오류 — syntactic gate **밖** | spot-check · 감사 **샘플** · gate **미포착** 사례 |
| **O8** | gate·감사 **Pilot 볼륨**에서 **실행 가능성** (50k 체계 아님) | `quality_gate` 실행 **완료 여부** · 감사 **기록 가능성** |

**질문 순서:** O9 → O8 (샘플)

### 2.5 H5 — Observation Plan

| ID | 관측 항목 | 관측 대상 (구조) |
|:---|-----------|------------------|
| **O11** | search_index **latency·크기** (5k 구간 실측) | index **크기** · 쿼리 **지연** **추이** |
| **O13** | `registry_builder` · manifest rebuild **wall** | rebuild **완료** · 소요 **기록** |
| **O12** | franchise **수동 큐** 부담 | 큐 **깊이** · 처리 **이벤트** |

**질문 순서:** O11 ∥ O13 → O12

### 2.6 O1~O14 × Pilot 매핑

| ID | 가설 | Pilot 관측 | Scale 이관 |
|:---|------|:----------:|:----------:|
| O1 | H1 | **예** | |
| O2 | H1 | **예** | |
| O3 | H1 | | **예** |
| O4 | H2 | **예** | |
| O5 | H3 | **예** | |
| O6 | H3 | **예** | 부분 |
| O7 | H3 | **예** | |
| O8 | H4 | 샘플 | **예** |
| O9 | H4 | **예** | 부분 |
| O10 | H3 | **예** | |
| O11 | H5 | **예** | 부분 |
| O12 | H5 | **예** | 부분 |
| O13 | H5 | **예** | 부분 |
| O14 | H1 | **예** | |

---

## 3. Evidence Requirements

**원칙:** Phase 2 **기존 산출물·도구**에서 **추출 가능**한 증거만 요구. 신규 구현 **필수 아님** ([a5-pilot-charter.md](a5-pilot-charter.md) X-P4).

### 3.1 공통 증거 요건

| # | 요건 | 용도 |
|---|------|------|
| E0 | **관측 시점** · Registry **작품 수** · **경로**(수동/파이프라인) **기록** | 모든 O **맥락** |
| E0 | Phase 2 baseline (**402**) **대비** **상대 변화** 서술 | 퇴화·개선 **방향** (합격선 **아님**) |
| E0 | 증거 **출처** (도구명·로그·문서) **명시** | 감사·재현 |

### 3.2 가설별 증거

| 가설 | 필수 증거 유형 | 연결 도구·산출 (Phase 2) |
|------|----------------|--------------------------|
| **H1** | insert·merge **이벤트 로그** · 경로별 **분리 기록** | PR·merge 이력 · Expansion **가동 상태** |
| **H1** | O14: add **미개방** · fix/import **만** 사용 **확인** | 운영 정책 기록 |
| **H2** | 유입 **전후** dedupe **리포트** | `dedupe_linter` · 중복 stub **인벤토리** |
| **H3** | Coverage **축별** 스냅샷 | `coverage_dashboard` |
| **H3** | 회귀 **실행 결과** | SW1 · URV · GAP panel |
| **H3** | enrich **backlog** 추이 | stub·enrich **대기** 기록 |
| **H3** | Economics **실측 출력** | Sprint 02~04 Economics runner |
| **H4** | gate **실행 결과** | `quality_gate` (`--strict` / `--release`) |
| **H4** | **감사·spot-check** 기록 | Sprint 03·04 감사 **형식** 준용 |
| **H4** | semantic **미포착** 사례 | 수동 검토 **메모** |
| **H5** | rebuild **완료·소요** 기록 | `registry_builder` · manifest |
| **H5** | search_index **크기·지연** | index 메트릭 · SW1 실행 **맥락** |
| **H5** | franchise 큐 **상태** | 수동 큐 **이벤트** 기록 |

### 3.3 질문별 최소 증거 (Pilot)

| ID | 최소 증거 패키지 |
|:---|------------------|
| O1 | 경로별 insert **시계열** + 이벤트 **출처** |
| O2 | O1 + SIM-A·Phase 1 문서 **대비 서술** |
| O4 | 유입 전 dedupe 후보 + 유입 후 중복 stub + linter **출력** |
| O5 | 축별 Coverage **전후** dashboard |
| O6 | 축별 Economics runner **출력** + 402 **대비** |
| O7 | backlog·insert **동시** 시계열 |
| O8 | gate **1회 이상** 완료 기록 + 감사 **가능/불가** 서술 |
| O9 | spot-check **샘플** + syntactic gate **통과** 사례 중 semantic 이슈 |
| O10 | SW1/URV **실행 기록** + 쿼리 세트 **민감도** 서술 |
| O11 | index 크기·latency **기록** |
| O12 | franchise 큐 **이벤트** |
| O13 | rebuild **wall** 기록 |
| O14 | O1·O2 **종합** + add 미개방 + G2 경로 **기각/유지** **논리 서술** |

**O3 · O8(50k 체계):** Pilot **증거 불요** — Scale **입력**만.

### 3.4 증거 불충분 시

| 상황 | 처리 |
|------|------|
| 필수 증거 **누락** | 해당 O **미결** — Gate 판정 **보류** (Continue **아님**) |
| 증거 **상충** | Pause — **추가 관측** 또는 **증거 정합** 후 재판정 |
| H2 배치 **전** O4 증거 없음 | H2 **관측 미시작** — 배치 **보류** ([a5-pilot-charter.md](a5-pilot-charter.md) §4.2) |

---

## 4. Decision Rules

**판정 기준:** [a5-gate-review.md](a5-gate-review.md) §3 + [a5-question-register.md](a5-question-register.md) 각 O **성공·실패 시 의미**와 증거 **정합**.

**합격 수치 없음:** 아래 규칙은 **정성·구조** 패턴. 수치 **임계**는 Pilot 착수 전 **별도 부록**에서 확정 (본 Charter **범위 밖**).

### 4.1 H1 — G-SUPPLY

| 판정 | 증거 패턴 (구조) | Question Register 정합 |
|------|------------------|------------------------|
| **Continue** | 공급 경로 **존재** · O1 **측정 가능** · O14 **기각 신호 없음** | O1 성공 시 의미 |
| **Pause** | *(H1 기본 Stop — Pause는 **범위 축소 검토** 시에만)* G1 경로 **유지**하나 G2 **불확실** — **별도 결정** | Gate Review §3 H1 부분 미달 |
| **Stop** | 공급 경로 **부재** · O1 **측정 불가** · O14 **실패 시 의미** (add 개방·G2 하향 **필요**) | O1·O14 실패 시 의미 |

### 4.2 H2 — G-INTEGRITY

| 판정 | 증거 패턴 (구조) | Question Register 정합 |
|------|------------------|------------------------|
| **Continue** | O4 **수용** — 중복·오염 **통제 가능** · 구조 변경 **불요** | O4 성공 시 의미 |
| **Pause** | O4 **실패 시 의미** — 선유입 중복 **비수용** · ingest 게이트·merge **보완 필요** | O4 실패 시 의미 |
| **Stop** | *(H2 단독 Stop 없음 — Gate Review)* H1 **Stop** 시 **연쇄 종료** | — |

### 4.3 H3 — G-IDENTITY

| 판정 | 증거 패턴 (구조) | Question Register 정합 |
|------|------------------|------------------------|
| **Continue** | O7·O5·O10 **기각 신호 없음** · Phase 2 baseline **대비 퇴화 패턴 없음** | O7·O5 성공 시 의미 |
| **Pause** | O7 **실패** (backlog > insert **지속**) · O5 **실패** (Coverage **희석**) · O6 extrapolation **무효** | O7·O5·O6 실패 시 의미 |
| **Stop** | *(H3 단독 Stop 없음)* H1 **Stop** 시 **연쇄** | — |

### 4.4 H4 — G-QUALITY

| 판정 | 증거 패턴 (구조) | Question Register 정합 |
|------|------------------|------------------------|
| **Continue** | gate **실행 가능** · O9 **관측 가능** · semantic·syntactic **분리 측정 가능** | O9 성공 시 의미 |
| **Pause** | gate **미실행·불가** · O9 **실패** (KPI PASS·신뢰 **붕괴** 공존) · 감사 **불가** | O9·O8 실패 시 의미 |
| **Stop** | *(H4 단독 Stop 없음)* | — |

### 4.5 H5 — G-PLATFORM

| 판정 | 증거 패턴 (구조) | Question Register 정합 |
|------|------------------|------------------------|
| **Continue** | O11·O12·O13 **기록 완료** — 부담 **가시화** (통과·실패 **무관**) | Informational |
| **Pause** | *(H5 단독 Pause 없음 — 본선 Continue)* 일정·인력 **조정** **기록** | O11·O12·O13 실패 시 의미 |
| **Stop** | **없음** — H5 **단독 Stop 불가** ([a5-gate-review.md](a5-gate-review.md)) | — |

### 4.6 교차 판정 규칙

| 규칙 | 내용 |
|------|------|
| **R-X1** | **H1 Stop** → Pilot **즉시 종료** · H2~H5 **판정 중단** |
| **R-X2** | **H2 Pause** → **배치 유입 중단** · H3·H4 관측 **오염 방지** |
| **R-X3** | **H3 또는 H4 Pause** → Pilot **계속 가능** · **성공 선언 불가** · Scale **보류** |
| **R-X4** | **H5** → **항상 Continue** (본선) · 결과는 **S5 문서화** |
| **R-X5** | Critical **Continue** + Supporting **Pause** → Pilot **종료 가능** · Scale **조건부** ([a5-pilot-charter.md](a5-pilot-charter.md) §5.2) |

### 4.7 Gate 판정 절차 (방법론)

```
1. 질문(O)별 증거 패키지 수집 (§3)
2. Question Register 성공·실패 시 의미와 대조
3. 가설(H)별 §4.1~4.5 규칙 적용
4. §4.6 교차 규칙 적용
5. Gate Decision Record 기록 (§5)
6. H1=Stop 이면 §6 Exit 즉시
```

---

## 5. Pilot Outputs

Pilot **종료 시** (또는 Stop 시 **중간**) 생성 **필수** 문서. **형식·템플릿**은 본 Charter **미정** — **내용 요건만** 정의.

### 5.1 필수 산출물

| # | 산출물 | 내용 요건 |
|---|--------|-----------|
| **P1** | **A5 Pilot Observation Log** | O1~O14 (Pilot 범위) **질문별** · §3 증거 **링크** · **미결** 표시 |
| **P2** | **A5 Gate Decision Record** | H1~H5 **각각** Continue / Pause / Stop · **판정 일시** · **근거 증거** · **교차 규칙** 적용 기록 |
| **P3** | **A5 Pilot Final Review** | Pilot **요약** · Gate **최종 상태** · Assumption A5 **방향** (Supported / Unsupported / Deferred **후보**) |
| **P4** | **A5 Scale Readiness Input** | O3 · O8 **이관** · H3·H4 **잔여 리스크** · Scale **GO/NO-GO 입력** (판정 **아님**) |

### 5.2 선택 산출물

| 산출물 | 조건 |
|--------|------|
| **Pause Remediation Note** | H2·H3·H4 **Pause** 시 — 보완 **항목**·재개 **전제** |
| **H5 Platform Load Summary** | O11·O12·O13 **종합** — 일정·인력 **입력** |

### 5.3 산출물 의존

```
P1 (Observation Log)
        │
        ▼
P2 (Gate Decision Record)
        │
        ├──► P3 (Pilot Final Review)
        └──► P4 (Scale Readiness Input)
```

---

## 6. Exit Conditions

[a5-pilot-charter.md](a5-pilot-charter.md) §5 · §6 · [a5-gate-review.md](a5-gate-review.md) §5 **방법론 적용**.

### 6.1 Pilot 종료 조건

다음 **어느 하나** 충족 시 Pilot **종료**.

| # | 조건 | 유형 |
|---|------|------|
| **X1** | **H1 Stop** | **강제 종료** |
| **X2** | **구조 변경 예외 발동** · add 개방 | **강제 종료** |
| **X3** | Pilot 범위 O **관측 완료** (§2.6 Pilot=예) · P1 **작성** | **정상 종료** |
| **X4** | Gate Review **S1·S2** 판정 **가능** · P2 **작성** | **정상 종료** |
| **X5** | 운영 **합의** 조기 종료 (범위 **축소** 포함) | **조기 종료** |

**정상 종료 시 필수:** P1 · P2 · P3 · P4 (**§5.1**).

### 6.2 Pilot 성공 (Gate Review S — Pilot 적용)

| # | 조건 | 방법론 |
|---|------|--------|
| S1 | G-SUPPLY **통과** | H1 **Continue** · O1·O2·O14 **기각 아님** |
| S2 | G-INTEGRITY **통과** | H2 **Continue** · O4 **수용** |
| S3 | G-IDENTITY | H3 **Continue** 또는 **조건부** (Pause **해소** 기록) |
| S4 | G-QUALITY | H4 **Continue** 또는 **조건부** |
| S5 | G-PLATFORM | H5 **기록** (P2·H5 Summary) |

```
Pilot 성공  IF  S1 AND S2
            AND H3·H4 ≠ Pause (또는 Pause 해소·조건부 문서화)
            AND S5 기록
```

### 6.3 Scale 단계 진입 조건

| # | 조건 | 근거 |
|---|------|------|
| **C1** | Pilot **정상 종료** (X3 또는 X4) | §6.1 |
| **C2** | **S1·S2** 충족 | Critical Gate |
| **C3** | H3·H4 **Stop 없음** — Pause 시 **Remediation Note** | Supporting |
| **C4** | P4 **Scale Readiness Input** 작성 | §5.1 |
| **C5** | 50k 달성 **요구 없음** | Discovery X8 |

| Pilot 결과 | Scale |
|------------|-------|
| S1·S2 **통과** · S3·S4 **통과** | **전면 진입** |
| S1·S2 **통과** · S3 또는 S4 **Pause·조건부** | **제한 진입** — 리스크 **문서화** |
| H1 **Stop** | **진입 불가** |
| O3 · O8 | Scale **1차 관측** 대상 |

**Scale Readiness Review**는 **별도** 문서 — 본 Charter **산출 P4**를 **입력**으로 사용.

### 6.4 A5 전체 성공과의 구분

| 구분 | Pilot 종료 | A5 전체 |
|------|------------|---------|
| **판정** | Pilot 성공 (§6.2) | Gate Review S1~S4 **전부** |
| **Assumption** | **후보** 방향 | **Supported** 최종 |
| **50k** | **비목표** | 경로·운영 **기각 아님** |

---

## 7. 미포함 (의도적)

| 항목 | 이유 |
|------|------|
| 합격 **수치** · net insert **하한** | 본 Charter **금지** · Pilot 착수 전 **별도** |
| 관측 **기간** · 배치 **크기** | 실행 계획 **범위 밖** |
| 신규 도구 **구현** | [a5-pilot-charter.md](a5-pilot-charter.md) X-P4 |
| 데이터 **수집 실행** | 본 Charter **금지** |

---

## 8. 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-verification-charter.md](a5-verification-charter.md) | **본 문서** — 관측·판정 방법론 |
| [a5-pilot-charter.md](a5-pilot-charter.md) | Pilot 범위 |
| [a5-gate-review.md](a5-gate-review.md) | Gate · M/S 조건 |
| [a5-question-register.md](a5-question-register.md) | O1~O14 |
| [a5-hypothesis-map.md](a5-hypothesis-map.md) | H1~H5 |
| [a5-pilot-readiness-review.md](a5-pilot-readiness-review.md) | PILOT GO |

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — Verification 방법론 (실행·수치·합격선·수집 없음) |
