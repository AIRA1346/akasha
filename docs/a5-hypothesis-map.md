# A5 Hypothesis Map — O1~O14 상위 가설 구조

> **목적:** Open Question O1~O14를 **독립 질문**이 아니라 **A5 검증 가설**로 묶어 정리.  
> **질문:** *「O1~O14가 사실 어떤 핵심 가설들을 검증하려는 것인가?」*  
> **전제:** [a5-discovery-charter.md](a5-discovery-charter.md) · [a5-question-register.md](a5-question-register.md) · A5 **Deferred**  
> **기준일:** 2026-06-09

**금지:** 질문에 **답** · 실험 설계 · 수치 **추정**.

---

## Executive Summary

O1~O14는 **14개의 독립 과제**가 아니라 **5개 Top-Level Hypothesis**를 검증하기 위한 **관측 질문**이다.

| 가설 | 한 줄 |
|------|------|
| **H1** | Contribution 없이 **공급 경로**가 G1→G2까지 **지속 가능**하다 |
| **H2** | 대량 유입 시 **데이터 무결성**(dedupe)이 **유지**된다 |
| **H3** | 규모 확대 시 **Identity·Coverage**가 **통제**된다 (A2·A3) |
| **H4** | 규모 확대 시 **품질·거버넌스**가 **유지**된다 |
| **H5** | **플랫폼·인적 운영** 부담이 **구조 변경 없이** 감당 가능하다 |

**선행 검증:** **H1 → H2** (공급·무결성) → **H3** → **H4** · **H5**는 H1·H3와 **부분 병행** 가능.

---

## 1. Top-Level Hypotheses

### H1 — Supply Without Contribution

**명제:** Maintainer + 반자동 Import + Expansion Pipeline만으로 **G1(5k) → G2(50k)** 공급이 **끊기지 않는다**. 사용자 add(B) **없이** G2 경로가 **성립**한다.

| | |
|---|---|
| **A5 연결** | assumption-register **A5** 원문 · Discovery §1.2 **P1** |
| **실패 시** | A5 **Unsupported** 후보 · Contribution 조기 개방 또는 G2 목표 하향 |
| **Phase 2와의 관계** | 402 Coverage **가능** — **공급 throughput**은 **미검증** |

---

### H2 — Ingest Integrity

**명제:** 배치·파이프라인 유입 시 **중복·오염 stub**이 **선제 통제**되거나 **수용 가능한 수준**으로 **사후 복구**된다. **구조 변경 없이** dedupe **운영**이 가능하다.

| | |
|---|---|
| **A5 연결** | Discovery §1.2 **P4** (dedupe) · scale-5k Top 2 |
| **실패 시** | insert **중단** 또는 ingest 게이트·merge train **필수** (운영·도구 과제) |
| **Phase 2와의 관계** | 402에서 dedupe **알고리즘** 문제 없음 — **유입 게이트** 미성숙 |

---

### H3 — Identity & Coverage Under Scale

**명제:** stub-first **대량 유입**에도 **Coverage KPI·SW1/URV**가 **Phase 2 하한**을 **유지**할 수 있다. enrich **backlog**가 insert를 **追い越하지 않는** 운영 **균형**이 존재한다.

| | |
|---|---|
| **A5 연결** | Discovery §1.2 **P2** · **A2** · **A3** Operational Dependency |
| **실패 시** | A2·A3 **402 한정 Supported** — 검색·Identity **점진 저하** (구조 아님) |
| **Phase 2와의 관계** | 402에서 enrich·회귀 **100%** — **규모 extrapolation** 미검증 |

---

### H4 — Quality & Governance Under Scale

**명제:** 규모가 커져도 **Quality KPI·감사·release block**이 **운영 가능한 주기·샘플**로 **유지**된다. syntactic gate **밖** enrich 오류도 **관측·통제** 가능하다.

| | |
|---|---|
| **A5 연결** | Discovery §1.2 **P3** |
| **실패 시** | Coverage **수량만** PASS · **신뢰 붕괴** — 감사·semantic QA **강제** |
| **Phase 2와의 관계** | Quality Gate MVP **402 PASS** — **50k 주기·샘플** 미정 |

---

### H5 — Platform & Curator Load

**명제:** **search_index·shard·registry_builder**와 **franchise·merge 등 인적 큐**가 5k·50k에서 **구조 변경 없이** **운영 부담으로만** 존재한다. **성능·노동**이 **예산·일정** 안에 들어온다.

| | |
|---|---|
| **A5 연결** | Discovery §1.2 **P4** (인프라) · **P5** (인적 큐) |
| **실패 시** | SW2·headcount·도구 **선행** — A5와 **별축**이나 **일정 연동** |
| **Phase 2와의 관계** | 5k **성능** 리스크 낮음 (문서) — **50k·인력** 미검증 |

---

## 2. 질문 매핑 (O1~O14 → H1~H5)

| ID | 질문 (요약) | 가설 | 역할 |
|----|-------------|:----:|------|
| **O1** | G1 insert rate (수동 vs 파이프라인) | **H1** | H1 **핵심 관측** |
| **O2** | 5k 도달 wall·인력 · SIM-A extrapolation | **H1** | H1 **G1 구간** |
| **O3** | 50k 도달 경로 throughput | **H1** | H1 **G2 구간** |
| **O14** | fix-only·import만으로 G2 지속 가능 | **H1** | H1 **정체성** (A5 원문) |
| **O4** | pre-insert dedupe precision | **H2** | H2 **핵심 관측** |
| **O5** | stub 희석 시 Coverage 하한 | **H3** | H3 **KPI** |
| **O6** | 5k·50k 축별 enrich Economics extrapolation | **H3** | H3 **비용·SLA** |
| **O7** | enrich backlog > insert 임계 | **H3** | H3 **퇴화 조건** |
| **O10** | SW1/URV 쿼리 확대 시 recall | **H3** | H3 **회귀 검증** |
| **O8** | 50k quality_gate·감사 주기·샘플 | **H4** | H4 **운영 주기** |
| **O9** | Semantic enrich 오류율 | **H4** | H4 **신뢰 층** |
| **O11** | search_index 50k latency·크기 | **H5** | H5 **성능** |
| **O12** | franchise 수동 큐 시간/건 | **H5** | H5 **인적 큐** |
| **O13** | registry_builder 50k wall clock | **H5** | H5 **도구 부담** |

### 가설별 질문 집합

| 가설 | 질문 | 개수 |
|------|------|:----:|
| **H1** Supply | O1 · O2 · O3 · O14 | **4** |
| **H2** Integrity | O4 | **1** |
| **H3** Identity & Coverage | O5 · O6 · O7 · O10 | **4** |
| **H4** Quality & Governance | O8 · O9 | **2** |
| **H5** Platform & Curator | O11 · O12 · O13 | **3** |

**전체:** 14 — **누락·중복 없음**.

---

## 3. 가설 간 의존성

### 3.1 의존 그래프

```
        H1 (Supply)
       /    \
      v      v
     H2      H3 (Coverage / Identity)
   (Integrity)   |
                 v
                H4 (Quality / Governance)
                 
H1 ─────────────┬──────────> H5 (Platform / Curator)
H3 ─────────────┘
```

### 3.2 의존 관계 표

| 가설 | 선행 가설 | 이유 |
|------|-----------|------|
| **H2** | **H1** | 유입 **경로·속도** 없이 dedupe **배치 조건** 정의 불가 |
| **H3** | **H1** | insert **규모·stub 비율**이 Coverage 입력 |
| **H3** | **H2** (권장) | 오염 stub 유입 시 Coverage·회귀 **왜곡** |
| **H4** | **H3** (부분) | enrich **볼륨**이 감사·gate **부하** 결정 |
| **H5** | **H1** | 작품 수가 rebuild·franchise 큐 **입력** |
| **H5** | **H3** (부분) | enrich·merge **볼륨**이 인적 큐와 연동 |

**독립에 가까움:** **H5/O11** (search_index 50k) — H1과 **개념적 병행** 가능 ([a5-question-register](a5-question-register.md) O11).

**강결합:** **H1 ↔ O14** — O14는 H1의 **필요·충분 조건**이 아니라 **A5 명제 자체**.

---

## 4. 검증 순서 — 어떤 가설이 먼저인가

| 순서 | 가설 | 근거 |
|:----:|------|------|
| **1** | **H1** | scale-5k **Top 1 = 공급** · O1 선행 · A5 **정체** |
| **2** | **H2** | 대량 Pilot **전** 무결성 **전제** · O4 P0 |
| **3** | **H3** | A2·A3 **50k 전제** · insert 후 **즉시** 희석·backlog |
| **4** | **H4** | enrich **볼륨** 확정 후 gate·감사 **설계** |
| **5** | **H5** | H1·H3 **입력** 확보 후 · O11은 **1단계와 병행** 가능 |

### 가설 내 질문 순서 (참고 — 답 아님)

| 가설 | 권장 질문 순서 |
|------|----------------|
| **H1** | O14 (범위 명확화) → **O1** → O2 → O3 |
| **H2** | **O4** |
| **H3** | **O7** → O5 → O6 → O10 |
| **H4** | O9 → **O8** |
| **H5** | O11 ∥ O13 → **O12** |

---

## 5. 실패 시 영향 범위

가설 **실패**는 **질문에 대한 답**이 아니라, 해당 가설이 **기각될 때** 파급 범위다.

| 실패 가설 | 직접 영향 | 연쇄 영향 | A5·Assumption |
|-----------|-----------|-----------|---------------|
| **H1** | G1·G2 **일정·경로** 무효 | H2~H5 **검증 전제 소멸** | A5 **Unsupported** 강한 후보 |
| **H2** | **배치 insert 중단** | H3·H4 **실측 오염** · Pilot **보류** | A5 **지연** (구조 아님) |
| **H3** | SW1/URV·Coverage **하한 미달** | H4 **의미 퇴색** (수량만 PASS) | A2·A3 **규모 한정** |
| **H4** | **신뢰·release** 불가 | H3 KPI **달성해도** 운영 **불가** | A3 **Operational Dependency** **붕괴** |
| **H5** | **도구·인력** 병목 | H1 **속도 상한** · H3 **backlog 악화** | A5 **부분 실패** — A4·인프라 **별도 과제** |

### 영향 범위 요약

```
H1 실패 ──► A5 전체 검증 라인 중단
H2 실패 ──► H3·H4 Pilot 신뢰도 상실
H3 실패 ──► Identity 운영 모델 규모 한정 (402는 유지)
H4 실패 ──► Coverage 성과와 무관하게 배포·신뢰 불가
H5 실패 ──► A5 일부 지연 · H1·H3 속도 제약 (A5 전면 기각은 아님)
```

---

## 6. 가설 ↔ Discovery 증명 대상 (P1~P5)

[a5-discovery-charter.md](a5-discovery-charter.md) §1.2와 **1:1 대응**.

| Discovery P# | Top-Level Hypothesis |
|:------------:|----------------------|
| P1 공급 throughput | **H1** |
| P2 Coverage·backlog | **H3** |
| P3 Quality·Governance | **H4** |
| P4 search·shard·dedupe | **H2** + **H5** (dedupe → H2 · 인프라 → H5) |
| P5 인적 큐 | **H5** |

---

## 7. 한 줄 정리

| 질문 | 답 (구조만 — 실측 아님) |
|------|-------------------------|
| O1~O14는 무엇을 검증하나? | **H1~H5** — Contribution 없는 **50k 운영 확장성** |
| 가장 먼저 검증할 가설은? | **H1** (공급) + **H2** (무결성) |
| A5 원문과 가장 가까운 가설은? | **H1** — **O14**가 명제, **O1·O3**가 관측 |
| Phase 2가 이미 닫은 것은? | **H3·H4의 402 버전** — **규모 버전**은 미검증 |

---

## 8. 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-hypothesis-map.md](a5-hypothesis-map.md) | **본 문서** — 상위 가설 구조 |
| [a5-question-register.md](a5-question-register.md) | O1~O14 · P0~P3 |
| [a5-discovery-charter.md](a5-discovery-charter.md) | A5 범위 · P1~P5 |

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — H1~H5 · O1~O14 매핑 (답·실험·추정 없음) |
