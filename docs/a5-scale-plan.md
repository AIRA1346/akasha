# A5 Scale Plan — 규모 확장 단계

> **목적:** Pilot에서 **Deferred**로 남은 항목을 **실제 규모 확장**에서 관측·운영한다.  
> **질문:** *「410작 이후 A5를 어떻게 확장하고, 언제 Supported로 닫을 수 있는가?」*  
> **전제:** [a5-pilot-final-review.md](a5-pilot-final-review.md) **Pilot Success** · Scale Readiness **GO** · Assumption A5 **Deferred**  
> **기준일:** 2026-06-09 · Registry **410작** (Pilot 종료 시점)

**금지:** Pilot 문서 **재개** · Pilot 결과 **재판정** · 구조 변경 · add(B) 개방.

**문서 성격:** Scale **계획** — 목표·관측·전략·Gate 조건 정의. 실행·수치 확정은 **후속 운영 결정**.

---

## Executive Summary

| 항목 | 내용 |
|------|------|
| **Scale 위치** | Pilot **종료** → **규모 확장** — A5를 **검증**하는 단계가 **아니라** **확장**하는 단계 |
| **Scale 한 줄** | 410작에서 **G1(5k)·G2(50k) 운영 가정** 하에 insert·enrich·거버넌스를 **누적 관측** |
| **Pilot 이관** | O3 · O6 · O7 · O8 · O9 · O12 · Expansion cohort **대량 apply** |
| **유지 전제** | Maintainer 경로 · `pre_insert_dedupe_gate` · Phase 2 구조 · add(B) **미개방** |
| **종료 판정** | Gate Review §5 — **S1~S4** Scale 확정 → A5 **Supported** 후보 |

```
Pilot (검증·소량)  ──SUCCESS──►  Scale (확장·관측)  ──S1~S4──►  A5 Supported
     410작                              G1 → G2 신호
```

---

## 1. Scale 목표 정의

### 1.1 Scale이 하는 것 · 하지 않는 것

| Scale **목표** | Scale **비목표** |
|----------------|------------------|
| Registry **규모 확장** 운영 (insert + enrich **병행**) | Pilot 결과 **재검증** |
| Pilot **Deferred** 질문 **실측** (O3·O6·O7·O8·O9·O12) | Pilot Observation Log **갱신** |
| Expansion cohort **단계적 apply** (gate 선행) | Registry / shard **구조 변경** |
| G1 **5k 경로** 실측 ([a5-discovery-charter.md](a5-discovery-charter.md) R1) | 50k **전량 달성** 선언 (Discovery X8) |
| G2 **50k 경로** throughput **신호** 확보 (R2 · O3) | Contribution add(B) **개방** |
| A5 **Supported** 판정 **입력** 확보 (S1~S4) | 신규 아키텍처 · ADR |

### 1.2 규모 마일스톤 (개념)

| 마일스톤 | 의미 | Scale 역할 |
|----------|------|------------|
| **M0** | **410작** — Pilot 종료 baseline | **시작점** (재측정 아님) |
| **M1** | **G1 ~5k** — Maintainer·파이프라인 **실측 구간** | insert rate · enrich 균형 · Coverage **축별** 관측 |
| **M2** | **G2 신호** — 50k **도달 경로** throughput 관측 | O3 **핵심** · 문서 가설 ~3k–5k/월 **대비** |
| **M3** | **A5 종료** — S1~S4 Scale **확정** | Supported / Deferred 연장 / Unsupported |

**주의:** M2는 **50k 달성**이 아니라 **경로 존재·운영 가능성** 확정이다 ([a5-discovery-charter.md](a5-discovery-charter.md) R2).

### 1.3 Discovery 증명 대상(P1~P5) — Scale 매핑

| P | Discovery 증명 | Scale 확장 초점 |
|---|----------------|-----------------|
| **P1** | 공급 throughput 지속 | O3 · Expansion cohort · G1→G2 insert **누적** |
| **P2** | Coverage·backlog 통제 | O7 · O6 · O5(지속) |
| **P3** | Quality·Governance 유지 | O8 · O9 |
| **P4** | dedupe·search_index 부담 | H2 gate **유지** · O11·O13 **추적** (Pilot 기록 연장) |
| **P5** | 인적 큐 측정·예산 | O12 · O6 |

### 1.4 Scale 성공 (운영 관점)

Scale 단계 **자체**의 성공은 아래를 **관측 완료**하는 것이다. A5 **Supported**와는 **별도**이나 **입력**이 된다.

| # | Scale 운영 성공 | 관측 완료 조건 |
|---|-----------------|----------------|
| SC1 | **공급 확장** 재현 | insert **다회·다경로** · gate **0 우회** |
| SC2 | **enrich 병행** 가시화 | O7 backlog 추이 · O6 축별 비용 **기록** |
| SC3 | **거버넌스 주기** 가설 | O8·O9 **체계** 관측 (Pilot 샘플 → Scale 루틴) |
| SC4 | **Expansion** 단계 apply | cohort **BLOCK/ADD** 분리 전략 **실행·기록** |
| SC5 | **인적 큐** 예산 입력 | O12 franchise 큐 **시간/건** |

---

## 2. Scale 관측 항목

Pilot에서 **미관측·Deferred**인 질문만 Scale **핵심 관측**으로 승격한다. Pilot에서 **답한** O1·O4·O14 등은 **전제**로 유지하고 **재실험하지 않는다**.

### 2.1 관측 요약

| ID | 질문 (요약) | 가설 | 우선순위 | Pilot 전제 |
|----|-------------|------|:--------:|------------|
| **O3** | G2 **50k 경로** throughput | H1 | **P0** | O1·O2 Pilot **부분** — Scale에서 **확장** |
| **O7** | enrich **backlog > insert** 임계 | H3 | **P0** | Pilot **미관측** |
| **O6** | 5k·50k 축별 enrich **Economics** | H3 | **P1** | 402 extrapolation **한계** — Scale 실측 |
| **O8** | 50k `quality_gate`·감사 **주기·샘플** | H4 | **P1** | Pilot gate **동작** 확인됨 — **주기** 미정 |
| **O9** | **Semantic** enrich 오류율 | H4 | **P2** | Pilot **미집행** |
| **O12** | franchise **수동 큐** 시간/건 | H5 | **P2** | Pilot **미집계** |

### 2.2 O3 — G2 throughput (50k 경로)

| 필드 | Scale 관측 설계 |
|------|-----------------|
| **질문** | 50k 도달 경로의 **월 net insert**는 문서 가설 **~3k–5k/월**과 **정합**하는가? |
| **측정** | 경로별 net/기간 — Maintainer · Expansion **분리** · G1 구간 실측 → G2 **extrapolation 검증** |
| **증거** | 배치 로그 · `manifest.json` works 추이 · 경로별 ADD/BLOCK 집계 |
| **성공 신호** | G2 경로 **기각 아님** · throughput **측정 가능** · 일정·인력 **산출 가능** |
| **실패 신호** | G2 **도달 불가** 또는 기간 **비현실** → A5 **Unsupported** 후보 |
| **Gate** | **H1** · S1 Scale **확정** 입력 |

### 2.3 O6 — enrich Economics extrapolation

| 필드 | Scale 관측 설계 |
|------|-----------------|
| **질문** | 402 Sprint Economics가 **5k·50k cohort**에 **유효**한가? |
| **측정** | 축별 (titles.en · zh · externalId · composite) **human-eq·wall** — Economics runner **Scale cohort** |
| **증거** | Sprint 03·04 runner 확장 산출 · enrich 배치별 wall 기록 |
| **성공 신호** | 축별 비용 **예산 산출 가능** · 자동화율 **cohort 의존** 문서화 (E4) |
| **실패 신호** | 402 extrapolation **불가** — 축별 **재실측** 필수 |
| **Gate** | **H3** · S3 보조 · **O7**과 **연동** |

### 2.4 O7 — enrich backlog vs insert (A2 퇴화)

| 필드 | Scale 관측 설계 |
|------|-----------------|
| **질문** | enrich backlog가 insert rate를 **追い越す** 임계는? |
| **측정** | insert net vs enrich 완료 **시계열** · 축별 backlog **큐 깊이** |
| **증거** | 배치 간 Coverage dashboard · enrich Sprint 로그 |
| **성공 신호** | insert·enrich **균형 규칙** 확립 · titles_en·SW1 **퇴화 없음** |
| **실패 신호** | backlog **단조 증가** · Coverage **구조적 하락** → H3 **Pause** |
| **Gate** | **H3** · S3 Scale **확정** 핵심 |

### 2.5 O8 — 50k governance 주기·샘플

| 필드 | Scale 관측 설계 |
|------|-----------------|
| **질문** | 50k 운영 가정에서 gate·감사 **주기·샘플 규모**는? |
| **측정** | `quality_gate` · `coverage_dashboard` · SW1 · URV **실행 주기 vs wall** · Release Block 유효성 |
| **증거** | 주기별 PASS/FAIL · invalid_en · source_breakage 추이 |
| **성공 신호** | A3 **Operational Dependency** **50k 가정**에서 **유지 가능** |
| **실패 신호** | 수동 감사 **불가** — 자동화·샘플 통계 **필수** (구현은 후속) |
| **Gate** | **H4** · S4 Scale **확정** |

### 2.6 O9 — Semantic enrich 오류율

| 필드 | Scale 관측 설계 |
|------|-----------------|
| **질문** | syntactic gate **밖** enrich 오류율은? |
| **측정** | Scale **spot-check 체계** — 샘플 규모·축·오류 분류 (Pilot 미집행 보완) |
| **증거** | semantic 샘플 시트 · 오류율 · gate PASS와의 **괴리** |
| **성공 신호** | Coverage **수량·신뢰** 분리 측정 **가능** |
| **실패 신호** | KPI PASS + **신뢰 붕괴** 공존 |
| **Gate** | **H4** · S4 보조 |

### 2.7 O12 — franchise 수동 큐

| 필드 | Scale 관측 설계 |
|------|-----------------|
| **질문** | franchise **수동 연결** 큐 — 5k·50k **시간/건** |
| **측정** | 유입 규모 대비 franchise 그룹·미연결 건 · 처리 wall |
| **증거** | franchise 큐 스냅샷 · 처리 로그 |
| **성공 신호** | A4 **지연 생성** 정책 **50k 가정**에서 **유지 가능** |
| **실패 신호** | 큐 **포화** — headcount·정책 완화 검토 |
| **Gate** | **H5** (Informational) · S5 **기록** — 단독 Stop **아님** |

### 2.8 관측 의존·순서

```
insert 확장 (Expansion + Maintainer)
        │
        ├──► O3 (throughput) ──► H1 S1
        │
        ├──► O7 (backlog) ◄──► O6 (Economics)
        │         │
        │         └──► H3 S3
        │
        ├──► O8 (governance 주기) ──► O9 (semantic)
        │         │
        │         └──► H4 S4
        │
        └──► O12 (franchise 큐) ──► H5 S5
```

**배치 후 공통 검증** (Pilot과 동일 — **변경 없음**):

`registry_builder` · `quality_gate --strict` · `dedupe_linter` · `coverage_dashboard`

---

## 3. Expansion cohort 적용 전략

Pilot에서 확인된 사실을 **전제**로 Scale apply **전략**을 정의한다.

### 3.1 Pilot에서 확정된 전제 (재논의 없음)

| # | 사실 | Scale 함의 |
|---|------|------------|
| E1 | `pre_insert_dedupe_gate` — workId · legacyIds · fuzzyTitle | **모든** apply **전** gate **필수** |
| E2 | v4 `shardHexForWorkId` hex shard | Expansion 도구 **v4 경로만** |
| E3 | batch6 **40**건 — **37 BLOCK** (legacyIds→wk_) · **3 SKIP** | legacy 보유 cohort **재insert 불가** |
| E4 | batch5 **45**건 — **45 BLOCK** | 동일 |
| E5 | 소규모 Maintainer 배치 **반복 성공** (+6, 0 blocked) | **점진 확대** 패턴 **유효** |

### 3.2 cohort 분류

| 유형 | 정의 | Scale 처리 |
|------|------|------------|
| **A — Net-new** | registry에 **wk_/legacy 충돌 없음** | gate PASS → apply **우선** |
| **B — Legacy-blocked** | `legacyIds`가 기존 wk_에 **매핑됨** | **재insert 금지** — merge·canonical **별도 트랙** |
| **C — Fuzzy-blocked** | fuzzyTitle **기존 wk_** 충돌 | **BLOCK** — merge 또는 제외 |
| **D — Maintainer pilot** | `pilot-*` · `pilot-h1-*` 등 | **유지** — 중복 정리 **완료** |

### 3.3 단계적 apply 전략

```
[1단계] Dry-run 전수
    │  cohort별 ADD / BLOCK / SKIP 집계
    ▼
[2단계] Net-new 소량 apply
    │  Pilot 패턴 — 소배치 · 배치마다 4종 검증
    ▼
[3단계] Net-new 점진 확대
    │  blocked=0 구간에서만 규모 ↑ (--max-add 등 상한)
    ▼
[4단계] enrich 병행 시작
    │  O7·O6 동시 관측
    ▼
[5단계] Legacy-blocked cohort
    │  재insert **하지 않음** — merge·예외 **운영 결정** 후 별도
    ▼
[6단계] G1 구간 throughput 집계 → O3 G2 신호
```

| 단계 | 목적 | 중단 조건 |
|:----:|------|-----------|
| 1 | cohort **리스크 가시화** | gate 우회 시도 |
| 2 | H2 **Scale 재확인** | dedupe **>0** 신규 |
| 3 | H1 **공급 확장** | quality_gate **FAIL** |
| 4 | H3 **균형 관측** | backlog **단조 악화** |
| 5 | 무결성 **유지** | B유형 **강행 insert** |
| 6 | O3 **입력** | insert **측정 불가** |

### 3.4 경로 비중 (개념)

| 경로 | Scale 역할 | 비고 |
|------|------------|------|
| **Maintainer** (`a5_pilot_supply_batch` 패턴) | **안정 anchor** — 반복·측정 가능 | Pilot **검증 완료** |
| **Expansion** (`seed_expansion_batch5/6`) | **Net-new A유형** 점진 apply | legacy cohort **별도** |
| **Enrich** (Sprint runner) | insert와 **병행** — O7·O6 | insert만 **확장 금지** |

### 3.5 apply 금지

| 금지 | 근거 |
|------|------|
| gate **우회** apply | Pilot H2 Remediation |
| B유형 cohort **일괄 재insert** | Pilot batch5/6 BLOCK 실측 |
| 검증 **생략** 배치 | Pilot 운영 원칙 |
| v3 샤드 경로 | Pilot batch6 **실패·롤백** |

---

## 4. Scale 중 Continue / Pause / Stop 조건

[a5-gate-review.md](a5-gate-review.md) §3 · Pilot Gate Record를 Scale에 **적용**한다. Pilot 판정은 **변경하지 않는다**.

### 4.1 가설별 판정

| 가설 | Gate | Continue | Pause | Stop |
|------|------|----------|-------|------|
| **H1** | G-SUPPLY | insert **측정·지속** · G2 경로 **기각 아님** | — | 공급 경로 **붕괴** · G2 **불가** 확정 |
| **H2** | G-INTEGRITY | gate 통과 insert · dedupe **0** | 신규 duplicate · gate **우회** | — (H2는 Pilot 기준 **Pause**만) |
| **H3** | G-IDENTITY | Coverage·SW1·URV **Phase 2 하한** | backlog **追越** · KPI **구조적 하락** | — |
| **H4** | G-QUALITY | quality_gate **PASS** · invalid_en **0** | gate **FAIL** · semantic **기각 신호** | — |
| **H5** | G-PLATFORM | 부담 **기록** · 일정 조정 | — | **단독 Stop 없음** |

### 4.2 교차 규칙 (Scale)

| 규칙 | 조건 | Scale 조치 |
|------|------|------------|
| **R-S1** | H1 **Stop** | Scale **중단** · A5 **Unsupported** 후보 |
| **R-S2** | H2 **Pause** | insert **중단** · dedupe·gate **재확인** (Pilot Remediation **회귀**) |
| **R-S3** | H3 **Pause** | insert **감속** · enrich **우선** · O7 **집중** |
| **R-S4** | H4 **Pause** | enrich **감속** · O8·O9 **보강** |
| **R-S5** | H1 Continue + H3 Pause | **제한 확장** — net-new만 · backlog **해소 후** 재개 |
| **R-S6** | Critical **전부 Continue** | **정상 확장** — cohort 전략 §3 **진행** |

### 4.3 Scale 즉시 Stop

| 조건 | 출처 |
|------|------|
| H1 **완전 기각** — 공급 경로 없음 | Gate Review §3 |
| Contribution add **개방** — O14 전제 상실 | Discovery X7 |
| **구조 변경 예외** 발동 | Phase 2 Charter |
| gate **체계적 우회** | Pilot H2 Remediation **무효화** |

### 4.4 Scale Pause 후 재개

| Pause 원인 | 재개 전제 |
|------------|-----------|
| H2 dedupe | fuzzyTitle **0** · gate **PASS** insert 재개 |
| H3 backlog | enrich **추이 안정** · Coverage **하한** 회복 |
| H4 quality | quality_gate **PASS** · semantic 샘플 **수용** |

**재개 시:** Pilot 문서 **미갱신** · Scale Observation **별도 기록** (본 계획 범위 밖 형식).

---

## 5. A5 Supported 판정 조건

### 5.1 Gate Review §5 (전체 A5 성공)

```
A5 Supported 후보  IF  S1 AND S2 AND S3 AND S4
                    AND S5 기록됨
```

| # | 조건 | Pilot | Scale에서 **확정**할 것 |
|---|------|:-----:|-------------------------|
| **S1** | G-SUPPLY — G2 경로 **기각 아님** | **부분** (소량·반복) | O3 · G1 실측 · Expansion **Net-new** 누적 |
| **S2** | G-INTEGRITY — O4 **수용** | **충족** | Scale insert에서 **유지** (dedupe 0) |
| **S3** | G-IDENTITY — A2·A3 **규모 유지** | **Pilot 수준** | O7 · O6 · O5 **Scale 확정** |
| **S4** | G-QUALITY — 거버넌스 **규모 유지** | **Pilot 수준** | O8 · O9 **Scale 확정** |
| **S5** | G-PLATFORM **문서화** | **기록됨** | O12 · O11·O13 **Scale 갱신** |

### 5.2 Supported vs Deferred vs Unsupported

| 판정 | 조건 |
|------|------|
| **Supported** | S1~S4 **전부 Scale 확정** · 50k **경로·운영** 기각 아님 |
| **Deferred** (현재) | Pilot Success · Scale **미완** — S1·S3·S4 **Scale 입력 대기** |
| **Unsupported** | S1 **미충족** (공급·G2 붕괴) 또는 S2 **미충족** (무결성 **수용 불가**) |

### 5.3 Supported 선언 시 필수 증거 패키지 (개념)

| 패키지 | 포함 |
|--------|------|
| **공급** | O3 throughput · 경로별 insert 로그 · Expansion ADD/BLOCK 집계 |
| **무결성** | gate 적용률 **100%** · dedupe_linter **0** 유지 구간 |
| **Identity** | Coverage 축별 추이 · O7 backlog 곡선 · SW1·URV **하한** |
| **Quality** | O8 주기·샘플 · O9 semantic · quality_gate 연속 PASS |
| **Platform** | O12 franchise 큐 · rebuild·index **규모별** (O11·O13) |

### 5.4 Supported가 요구하지 않는 것

| 제외 | 근거 |
|------|------|
| Registry **50k 도달** | Discovery X8 · R2 = **경로 존재** |
| 402 Coverage **재증명** | Phase 2 COMPLETE |
| Pilot 문서 **개정** | Pilot **확정** |

---

## 6. Pilot과의 경계

| 항목 | Pilot (확정·유지) | Scale (본 계획) |
|------|-------------------|-----------------|
| 문서 | Observation Log · Gate Record · Final Review **동결** | Scale Plan · (후속) Scale 기록 |
| Registry | **410작** 종료 | **410+** 확장 |
| 질문 | O1·O4·O14 등 **답함** | O3·O6·O7·O8·O9·O12 |
| Gate | H1~H5 **Continue** | 동일 Gate **Scale 판정** |
| 도구 | gate · v4 shard · 4종 검증 | **동일** + Economics · enrich |

---

## 7. 후속 운영 결정 (본 계획 범위 밖)

[a5-operational-decisions.md](a5-operational-decisions.md) D1~D3 패턴 — Scale **착수 전** 확정 필요:

| ID | Scale 결정 영역 | 예시 |
|:--:|-----------------|------|
| **SD1** | Scale **관측 기간** · G1 구간 **목표 시점** | M1 도달 윈도 |
| **SD2** | 배치 **상한** · Expansion **max-add** · enrich **병행 비율** | 점진 확대 수치 |
| **SD3** | O7 Pause **임계** · Coverage **축별 하한** · O8 **주기** | Gate 판정 수치 |

**본 문서는 SD1~SD3 값을 확정하지 않는다.**

---

## 8. 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-scale-plan.md](a5-scale-plan.md) | **본 문서** — Scale 계획 |
| [a5-pilot-final-review.md](a5-pilot-final-review.md) | Pilot **종료·GO** (동결) |
| [a5-gate-review.md](a5-gate-review.md) | S1~S5 · Stop/Pause/Continue |
| [a5-question-register.md](a5-question-register.md) | O1~O14 · Scale 시점 |
| [a5-discovery-charter.md](a5-discovery-charter.md) | R1~R4 · P1~P5 |
| [a5-operational-decisions.md](a5-operational-decisions.md) | D1~D3 (Pilot) · SD1~SD3 **후속** |

---

## 9. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — Scale 목표·관측·Expansion 전략·Gate·Supported 조건 |
