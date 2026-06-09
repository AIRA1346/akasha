# A5 Gate Review — 진행 Gate 정의

> **목적:** H1~H5 중 **어떤 가설이 A5 진행 여부를 결정하는 Gate인지** 정의.  
> **질문:** *「A5에서 무엇이 정말 통과되어야 하는가?」*  
> **전제:** [a5-hypothesis-map.md](a5-hypothesis-map.md) · [a5-discovery-charter.md](a5-discovery-charter.md) · A5 **Deferred**  
> **기준일:** 2026-06-09

**금지:** 가설 **검증** · 실험 설계 · 수치 **추정**.

**Gate 판정어**

| 판정 | 의미 |
|------|------|
| **Continue** | 해당 가설 **통과** 또는 **미결**이어도 A5 **다음 단계 진행** |
| **Pause** | **조건부 중단** — 선행 Gate·리스크 해소 후 **재개** |
| **Stop** | A5 **본선 중단** — Assumption **Unsupported** 또는 **범위 재정의** |

---

## Executive Summary

| Gate 유형 | 가설 | A5에서의 역할 |
|-----------|------|---------------|
| **Critical Gate** | **H1** · **H2** | **진행 자체**를 허용·거부 |
| **Supporting Gate** | **H3** · **H4** | A5 **성공 선언**에 필요 |
| **Informational Gate** | **H5** | **속도·일정·부담** 입력 — 단독 **Stop 아님** |

**한 줄:** A5는 **H1·H2가 통과되어야 시작·지속**되고, **H3·H4가 통과되어야 성공**한다. **H5**는 성공 **조건이 아니라** 운영 **현실성**을 알린다.

---

## 1. Gate Hypotheses

### 1.1 Critical Gate

**정의:** 이 가설이 **기각**되면 A5 검증 **본선을 계속할 수 없다**. Pilot·Scale **진입 또는 지속**이 **무의미**하거나 **위험**하다.

| 가설 | Gate 명 | 통과 시 의미 (구조만) |
|------|---------|----------------------|
| **H1** | **G-SUPPLY** | Contribution 없이 **공급 경로**가 **존재·측정 가능** |
| **H2** | **G-INTEGRITY** | 대량 유입 **전·중** **무결성**이 **수용 가능** |

**근거:** [a5-hypothesis-map.md](a5-hypothesis-map.md) — H1 실패 시 H2~H5 전제 소멸 · H2 실패 시 Pilot 신뢰도 상실 · scale-5k **Top 1·2**.

### 1.2 Supporting Gate

**정의:** Critical Gate **통과 후** A5를 **진행**할 수 있으나, 이 가설 **미통과** 시 A5는 **성공 선언 불가**. **Pause** 후 보완·재검증 가능.

| 가설 | Gate 명 | 통과 시 의미 (구조만) |
|------|---------|----------------------|
| **H3** | **G-IDENTITY** | 규모 확대 시 **A2·A3** (Coverage·회귀) **유지 가능** |
| **H4** | **G-QUALITY** | 규모 확대 시 **품질·거버넌스** **운영 가능** |

**근거:** Phase 2 **COMPLETE**는 **402** — A5 **성공**은 **규모에서** A2·A3·Governance **재확인**을 요구.

### 1.3 Informational Gate

**정의:** A5 **진행·성공 선언의 필수 통과 조건이 아님**. 결과는 **일정·인력·도구 투자** 판단에 사용. 실패 시 **Pause** 또는 **범위 조정** — **Stop**은 **H1 단독**으로 하지 않음.

| 가설 | Gate 명 | 역할 |
|------|---------|------|
| **H5** | **G-PLATFORM** | 인프라·인적 큐 **부담 가시화** |

**근거:** 5k **성능** 리스크 문서상 낮음 · H5 실패는 A5 **부분 지연** ([a5-hypothesis-map.md](a5-hypothesis-map.md) §5).

---

## 2. H1~H5 분류

| 가설 | Gate 유형 | Gate ID | 연결 질문 (O1~O14) | 검증 순서 (가설 맵) |
|------|-----------|---------|-------------------|---------------------|
| **H1** Supply Without Contribution | **Critical** | **G-SUPPLY** | O1 · O2 · O3 · O14 | 1 |
| **H2** Ingest Integrity | **Critical** | **G-INTEGRITY** | O4 | 2 |
| **H3** Identity & Coverage Under Scale | **Supporting** | **G-IDENTITY** | O5 · O6 · O7 · O10 | 3 |
| **H4** Quality & Governance Under Scale | **Supporting** | **G-QUALITY** | O8 · O9 | 4 |
| **H5** Platform & Curator Load | **Informational** | **G-PLATFORM** | O11 · O12 · O13 | 5 (∥ 일부) |

### Gate 계층

```
[ Critical ]     G-SUPPLY (H1) ──► G-INTEGRITY (H2)
                      │
                      ▼
[ Supporting ]   G-IDENTITY (H3) ──► G-QUALITY (H4)
                      │
                      ▼
[ Informational ] G-PLATFORM (H5)  ──► 일정·부담 입력 (필수 통과 아님)
```

---

## 3. 각 가설 실패 시 결과 (Continue / Pause / Stop)

> **가설 기각** 시 A5 프로그램에 대한 **운영 판정** — 실측 결과 아님.

| 가설 | Gate | 실패 시 판정 | A5·Assumption |
|------|------|:------------:|---------------|
| **H1** | G-SUPPLY | **Stop** | A5 **Unsupported** 강한 후보 · Contribution·G2 목표 **재검토** |
| **H2** | G-INTEGRITY | **Pause** | Pilot **보류** · ingest·dedupe **보완 후 재개** · 구조 변경 **필수 아님** |
| **H3** | G-IDENTITY | **Pause** | Scale **보류** · enrich SLA·insert 속도 **조정 후 재개** · A2·A3 **규모 한정** |
| **H4** | G-QUALITY | **Pause** | **성공 선언 불가** · gate·감사 **강화 후 재개** · A3 운영 전제 **미충족** |
| **H5** | G-PLATFORM | **Continue**¹ | A5 **본선 유지** · 일정·인력·도구 **조정** · SW2·headcount **별도 트랙** |

¹ **Continue** = A5 프로그램 **중단(Stop)하지 않음**. Pilot **일시 Pause**는 H1·H3 **속도 상한**으로 **가능**.

### Critical Gate 실패 — Stop vs Pause

| 상황 | 판정 |
|------|------|
| H1 **완전 기각** (공급 경로 없음) | **Stop** |
| H1 **부분 미달** (경로 있으나 G2 불가) | **Stop** 또는 A5 **범위를 G1(5k)로 축소** — **별도 결정** (본 문서는 판정만 정의) |
| H2 **기각** | **Pause** (H1 통과 전제) |

### Supporting Gate 실패 — 성공 선언

| 상황 | A5 성공 선언 |
|------|-------------|
| H3 또는 H4 **미통과** | **불가** — **Pause** |
| H3 **통과** · H4 **미통과** | **불가** |
| H5 **미통과** | 성공 선언 **가능** (단, **리스크·일정** 문서화 **전제**) |

---

## 4. A5 진행 최소 조건

**「A5 검증 프로그램을 시작·지속할 수 있는가?」** — Pilot·Scale **착수 Gate**.

| # | 조건 | Gate | 비고 |
|---|------|------|------|
| M1 | A5 **명제 범위** 합의 — Contribution 없이 G1→G2 **검증 대상** | (Discovery) | O14 **범위** · Charter 합의 |
| M2 | **G-SUPPLY** — 공급 경로 **존재·측정 가능** (기각 아님) | **H1** | O1 **관측 가능** 상태 |
| M3 | **G-INTEGRITY** — 배치 유입 **전** 무결성 **수용 가능** (기각 아님) | **H2** | O4 **Pilot 전** |
| M4 | Phase 2 **Governance 도구** baseline 존재 | (전제) | quality_gate · dashboard · SW1/URV |
| M5 | **구조 변경 예외** 미발동 | (전제) | Phase 2 Charter §3.2 |

**최소 진행 판정**

```
A5 진행 가능  IF  M1~M5
              AND G-SUPPLY ≠ Stop
              AND G-INTEGRITY ≠ Stop (H2는 Pause 허용 — Pilot 전 해소)
```

**H3·H4·H5 미통과**여도 A5 **진행 최소 조건**은 **충족 가능** — Supporting·Informational은 **성공** Gate.

**H1 Stop** → A5 **진행 불가**.

---

## 5. A5 성공 최소 조건

**「A5를 성공으로 닫을 수 있는가?」** — Assumption A5 **Supported** 후보 선언 Gate.

| # | 조건 | Gate | 연결 |
|---|------|------|------|
| S1 | **G-SUPPLY** **통과** — G2 **경로** 기각 아님 | **H1** | O1 · O2 · O3 · O14 |
| S2 | **G-INTEGRITY** **통과** | **H2** | O4 |
| S3 | **G-IDENTITY** **통과** — A2·A3 **규모에서** 유지 | **H3** | O5 · O6 · O7 · O10 |
| S4 | **G-QUALITY** **통과** — 품질·거버넌스 **규모에서** 유지 | **H4** | O8 · O9 |
| S5 | **G-PLATFORM** 결과 **문서화** | **H5** | O11 · O12 · O13 — **통과 필수 아님** |

**최소 성공 판정**

```
A5 성공  IF  S1 AND S2 AND S3 AND S4
         AND S5 기록됨 (통과/미통과·영향 명시)
```

| 결과 | Assumption A5 |
|------|---------------|
| S1~S4 **충족** | **Supported** 후보 |
| S1 **미충족** | **Unsupported** |
| S2~S4 **미충족** | **Deferred** 연장 또는 **조건부 Supported** — Verification Charter에서 **수치·범위** 확정 |

**50k 전량 달성**은 A5 Discovery **비목표** — 성공은 **경로·운영 가능성** 기각 아님 ([a5-discovery-charter.md](a5-discovery-charter.md) X8).

---

## 6. Gate 통과 흐름 (개념)

```
Discovery 합의 (M1)
        │
        ▼
   G-SUPPLY (H1) ──Stop──► A5 종료
        │ Pass
        ▼
 G-INTEGRITY (H2) ──Pause──► ingest 보완
        │ Pass
        ▼
   [ A5 Pilot·Scale 진행 최소 조건 충족 ]
        │
        ├── G-IDENTITY (H3) ──Pause──► SLA·속도 조정
        ├── G-QUALITY (H4)  ──Pause──► gate·감사 강화
        └── G-PLATFORM (H5) ──Continue──► 일정·부담 기록
        │
        ▼
   S1~S4 Pass + S5 문서화 ──► A5 성공 후보
```

---

## 7. Gate ↔ 질문 우선순위 (참고)

[a5-question-register.md](a5-question-register.md) P0~P3와 **정합**.

| Gate | P0 질문 |
|------|---------|
| G-SUPPLY | O1 · O14 |
| G-INTEGRITY | O4 |
| G-IDENTITY | O7 · O5 |
| G-QUALITY | O8 · O9 |
| G-PLATFORM | O11 · O12 · O13 |

---

## 8. 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-gate-review.md](a5-gate-review.md) | **본 문서** — Gate 정의 |
| [a5-hypothesis-map.md](a5-hypothesis-map.md) | H1~H5 |
| [a5-question-register.md](a5-question-register.md) | O1~O14 |
| [a5-discovery-charter.md](a5-discovery-charter.md) | A5 범위 |

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — Critical / Supporting / Informational Gate (검증·추정 없음) |
