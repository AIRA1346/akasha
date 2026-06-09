# A5 Question Register — Open Questions O1~O14

> **목적:** [a5-discovery-charter.md](archive/a5-discovery-charter.md) Open Question **인벤토리** 및 **검증 우선순위** 결정.  
> **질문:** *「A5에서 가장 먼저 답해야 할 질문은 무엇인가?」*  
> **기준일:** 2026-06-09

**금지:** 실험 · 추정 · 구현 · **질문에 대한 답**.

**해결 시점 정의**

| 시점 | 의미 |
|------|------|
| **Discovery** | A5 Verification Charter 확정 **전** — 문서·기존 실측·소규모 dry-run **설계**로 답 가능한지 판단 (본 레지스터는 실행 없음) |
| **Pilot** | **5k 경로** 소량 실가동·합성·파일럿으로 답 |
| **Scale** | **50k 운영 가정** 하에서 답 (Pilot 결과·extrapolation 검증 포함) |

---

## 우선순위 요약

| 순위 | ID | 이유 (한 줄) |
|:----:|:---|-------------|
| **P0** | **O1** | 모든 A5 검증의 **입력** — 실제 insert rate 미측정 |
| **P0** | **O14** | A5 **핵심 가설** — add 없이 G2 지속 가능 여부 |
| **P0** | **O4** | 대량 유입 **전제** — dedupe ingest 안전성 |
| **P1** | **O7** | A2·A3 **퇴화 조건** — backlog vs insert |
| **P1** | **O2** | G1 **일정·인력** — O1 결과에 의존 |
| **P1** | **O5** | stub 희석 시 **Coverage 하한** |
| **P2** | **O6** | 축별 enrich **비용** — Pilot 실측 필요 |
| **P2** | **O3** | G2 throughput — **G1 이후** |
| **P2** | **O12** | franchise **인적 큐** — 5k에서 체감 시작 |
| **P3** | **O8** | 50k **거버넌스 주기** |
| **P3** | **O9** | **Semantic QA** — syntactic gate 밖 |
| **P3** | **O10** | SW1/URV **쿼리 세트** 재기준 |
| **P3** | **O11** | search_index **50k** 안전대 |
| **P3** | **O13** | registry_builder **50k wall** |

**P0 → P1 → P2 → P3** 순으로 답·검증 설계를 진행한다. 동일 순위 내에서는 **의존성 표** 순서를 따른다.

---

## 질문 레지스터

### O1 — G1 insert rate (net/월)

| 필드 | 내용 |
|------|------|
| **질문** | 실제 **G1 insert rate** (net/월)는 얼마인가? — **수동 PR** vs **파이프라인** 각각 |
| **영향도** | **High** |
| **해결 시점** | **Pilot** (Discovery에서는 측정 **방법**만 정의) |
| **의존성** | 없음 — **선행 질문** |
| **성공 시 의미** | A5 공급 경로가 **측정 가능** · G1·G2 일정 **산출 가능** |
| **실패 시 의미** | A5 **공급 가설 붕괴** — Contribution 조기 개방 또는 G2 목표 하향 검토 ([assumption-register](assumption-register.md) A5) |

---

### O2 — 5k 도달 wall·인력 · SIM-A extrapolation

| 필드 | 내용 |
|------|------|
| **질문** | **5k 도달**까지 걸리는 wall clock·인력은? — SIM-A extrapolation이 **유효한가**? |
| **영향도** | **High** |
| **해결 시점** | **Pilot** |
| **의존성** | **O1** (실측 insert rate) |
| **성공 시 의미** | G1 마일스톤 **운영 계획 수립 가능** · A1과 A5 **정합** |
| **실패 시 의미** | 합성 throughput **402·5k 이전 불가 extrapolation** — G1 일정·인력 **재산정** |

---

### O3 — 50k 도달 경로 throughput

| 필드 | 내용 |
|------|------|
| **질문** | **50k 도달** 경로의 throughput은? — 문서 가설 **~3k–5k건/월** **실측** 여부 |
| **영향도** | **High** |
| **해결 시점** | **Scale** (Pilot에서 **파이프라인 소량** 선행 가능) |
| **의존성** | **O1** · **O2** (G1 경로 확인 후) |
| **성공 시 의미** | A5 **G2 공급 가설** 유지 가능 |
| **실패 시 의미** | 50k **도달 불가 또는 기간 비현실** — A5 **Unsupported** 후보 |

---

### O4 — pre-insert dedupe precision

| 필드 | 내용 |
|------|------|
| **질문** | 배치 유입 시 **pre-insert dedupe** precision은? — 사후 `dedupe_linter`만으로 **충분한가**? |
| **영향도** | **High** |
| **해결 시점** | **Pilot** |
| **의존성** | **O1** (배치 유입 전제) · scale-5k Top 2 |
| **성공 시 의미** | 대량 insert **무결성 유지** · 구조 변경 **불필요** |
| **실패 시 의미** | 중복 stub **선유입** — ingest 게이트·merge train **필수** (운영·도구 과제, 구조 ADR 아님) |

---

### O5 — stub 희석 시 Coverage 하한

| 필드 | 내용 |
|------|------|
| **질문** | stub 비율 ↑ 시 **titles.en / zh / externalId** 비율 **하한**은? |
| **영향도** | **Medium** |
| **해결 시점** | **Pilot** |
| **의존성** | **O1** · **O7** (유입·backlog 동시) |
| **성공 시 의미** | A2·A3 **운영 SLA** 정의 가능 |
| **실패 시 의미** | SW1/URV **점진 저하** — enrich SLA **강제** 또는 insert 속도 **제한** |

---

### O6 — 5k·50k 축별 enrich Economics extrapolation

| 필드 | 내용 |
|------|------|
| **질문** | **5k·50k** 축별 enrich **human-eq·wall** — 402 Economics **extrapolation**은 유효한가? |
| **영향도** | **Medium** |
| **해결 시점** | **Pilot** (5k) · **Scale** (50k) |
| **의존성** | **O5** · Phase 2 Sprint 03·04 (402 baseline) |
| **성공 시 의미** | A5 **인력·도구 예산** 산출 가능 |
| **실패 시 의미** | 402 실측 **과소/과대 extrapolation** — 축별 **재실측** 필수 |

---

### O7 — enrich backlog > insert rate 임계 (A2 퇴화)

| 필드 | 내용 |
|------|------|
| **질문** | **enrich backlog > insert rate** 임계는? — A2 **퇴화 조건** |
| **영향도** | **High** |
| **해결 시점** | **Pilot** |
| **의존성** | **O1** · **O5** |
| **성공 시 의미** | insert·enrich **균형 운영 규칙** 확립 |
| **실패 시 의미** | A2 **Supported @402만** — 50k에서 **검색 가치 하락** (구조 아님 · 운영 실패) |

---

### O8 — 50k quality_gate·감사 주기·샘플

| 필드 | 내용 |
|------|------|
| **질문** | **50k**에서 `quality_gate`·감사 **주기·샘플 규모**는? |
| **영향도** | **Medium** |
| **해결 시점** | **Scale** |
| **의존성** | **O6** · Phase 2 Quality Gate MVP |
| **성공 시 의미** | A3 **Operational Dependency** **50k에서도** 유지 가능 |
| **실패 시 의미** | 수동 감사 **불가능** — gate 자동화·샘플 통계 **필수** (구현은 후속) |

---

### O9 — Semantic enrich 오류율

| 필드 | 내용 |
|------|------|
| **질문** | **Semantic** enrich 오류율은? — syntactic gate **밖** |
| **영향도** | **Medium** |
| **해결 시점** | **Pilot** (샘플) · **Scale** (체계) |
| **의존성** | Phase 2 Open Question · **O8** |
| **성공 시 의미** | Coverage 수량·신뢰 **분리 측정** 가능 |
| **실패 시 의미** | KPI PASS와 **신뢰 붕괴** 공존 — spot-check **운영 필수** |

---

### O10 — SW1/URV 쿼리 세트 확대 시 recall

| 필드 | 내용 |
|------|------|
| **질문** | SW1/URV **쿼리 세트 확대** 시 recall **하한**은? |
| **영향도** | **Low** |
| **해결 시점** | **Pilot** |
| **의존성** | **O5** · **O7** (Coverage 상태) |
| **성공 시 의미** | 402 baseline **유효 extrapolation** |
| **실패 시 의미** | 87쿼리 **과적합** — 5k/50k **재기준** 필요 |

---

### O11 — search_index 50k latency·크기

| 필드 | 내용 |
|------|------|
| **질문** | search_index **50k** latency·크기 — 5k **녹색 구간** 연장 여부 |
| **영향도** | **Low** |
| **해결 시점** | **Discovery** (5k 문서 근거 검토) · **Pilot** (실측 확인) |
| **의존성** | scale-5k-risk-analysis §3.5 |
| **성공 시 의미** | A5 **성능 축** — 구조 변경 **불필요** (50k 구간) |
| **실패 시 의미** | SW2·인프라 **선행** — A5와 **별축**이나 일정 **연동** |

---

### O12 — franchise 수동 큐 (5k·50k)

| 필드 | 내용 |
|------|------|
| **질문** | franchise **수동 큐** — 5k·50k **시간/건** |
| **영향도** | **Medium** |
| **해결 시점** | **Pilot** (5k) · **Scale** (50k) |
| **의존성** | **O1** (유입 규모) · A4 Supported |
| **성공 시 의미** | A4 **지연 생성** 정책 **50k에서도** 유지 가능 |
| **실패 시 의미** | franchise 큐 **포화** — headcount·정책 완화 **검토** (구조 아님) |

---

### O13 — registry_builder 50k wall clock

| 필드 | 내용 |
|------|------|
| **질문** | `registry_builder` · manifest rebuild **50k wall clock** |
| **영향도** | **Low** |
| **해결 시점** | **Pilot** (5k) · **Scale** (50k) |
| **의존성** | **O1** (작품 수) |
| **성공 시 의미** | 배치·CI **주기 설계** 가능 |
| **실패 시 의미** | rebuild **병목** — 증분·병렬 **도구 과제** (구조 변경 아님) |

---

### O14 — fix-only·import만으로 G2 지속 가능

| 필드 | 내용 |
|------|------|
| **질문** | Contribution **조기 개방 없이** fix-only·import만으로 **G2 지속 가능한가**? |
| **영향도** | **High** |
| **해결 시점** | **Discovery** (가설·범위 명확화) · **Pilot** (실증) |
| **의존성** | **O1** · **O3** · contribution-model R0→R1 |
| **성공 시 의미** | A5 **핵심 가설 유지** — add(B) **50k까지 불필요** |
| **실패 시 의미** | A5 **Unsupported 또는 Deferred 연장** — Contribution **R1/R2 조기** 검토 |

---

## 의존성 그래프 (요약)

```
O1 ──┬── O2 ── O3
     ├── O4
     ├── O5 ── O6
     │         O10
     ├── O7
     ├── O12
     ├── O13
     └── O14

O8 ← O6
O9 ← O8 (개념적)
O11 — (독립 · Discovery/Pilot 병행 가능)
```

**선행 블로킹:** **O1** 없이는 O2·O3·O4·O5·O7·O12·O13·O14 **검증 설계 불완전**.

---

## 영향도 × 시점 매트릭스

|  | Discovery | Pilot | Scale |
|--|:---------:|:-----:|:-----:|
| **High** | O14 (범위) | O1 · O2 · O4 · O7 | O3 |
| **Medium** | — | O5 · O6 · O9 · O12 | O8 |
| **Low** | O11 (문서) | O10 · O11 · O13 | — |

---

## A5에서 가장 먼저 답해야 할 질문

**1순위 (P0 — 동시 설계, 답 순서는 O1 → O4 → O14)**

| ID | 질문 (요약) |
|----|-------------|
| **O1** | 실제 G1 **insert rate**는? |
| **O4** | 배치 유입 **dedupe**는 안전한가? |
| **O14** | add 없이 **G2 경로**가 성립하는가? |

**이유:** [a5-discovery-charter.md](archive/a5-discovery-charter.md) · [scale-5k-risk-analysis.md](scale-5k-risk-analysis.md) — 50k의 1차 관문은 **공급·무결성**이며, A5 원문은 **Contribution 없이** G2 도달이다. O1·O4 없이 Pilot 설계 자체가 성립하지 않고, O14 없이 A5 검증 **목적**이 불명확하다.

**2순위 (P1 — Pilot 초기)**

| ID | 질문 (요약) |
|----|-------------|
| **O7** | enrich **backlog** 임계 |
| **O2** | **5k** 도달 인력·기간 |
| **O5** | **Coverage 희석** 하한 |

**3순위 이후:** O6 · O3 · O12 → O8 · O9 · O10 · O11 · O13

---

## 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-question-register.md](a5-question-register.md) | **본 문서** — O1~O14 · 우선순위 |
| [a5-discovery-charter.md](archive/a5-discovery-charter.md) | Open Question 출처 |
| [assumption-register.md](assumption-register.md) | A5 정의 |

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — O1~O14 레지스터 · P0~P3 우선순위 (실험·추정·구현 없음) |
