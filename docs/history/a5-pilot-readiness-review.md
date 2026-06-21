# A5 Pilot Readiness Review — Pilot 착수 판정

> **목적:** A5 Pilot **착수 가능 여부** 판정.  
> **질문:** *「A5 Pilot을 시작해도 되는가?」*  
> **근거:** A5 Discovery 문서 세트 **만** — 실측·실험·수치 **없음**  
> **기준일:** 2026-06-09 · Registry **402** (Phase 2 COMPLETE)

**금지:** Pilot **실행** · 실험 설계 · 수치 **추정**.

**판정 범위:** Discovery·Charter·Gate **문서 정합성** 및 [a5-gate-review.md](../a5-gate-review.md) **M1~M5** 전제 충족 여부. O1~O14 **답**은 본 판정 **대상 아님**.

---

## 최종 판정

# PILOT GO

A5 Discovery 산출물이 **완결**되었고, Gate·Pilot 범위·성공·중단 조건이 **문서 간 정합**한다. 구조 변경·Gate 충돌·조건 불명확으로 인한 **NO-GO 사유 없음**.  
Open Question O1~O14 **미답**은 Discovery **예상 상태**이며 Pilot **검증 대상**이다.

**Pilot 착수**는 본 판정으로 **허용**된다. **실측·배치**는 [a5-pilot-charter.md](../a5-pilot-charter.md) 및 후속 **A5 Verification Charter** 범위에서만 진행한다 (본 문서는 **실행 승인 아님**).

---

## 1. Discovery 산출물 점검

[a5-discovery-charter.md](a5-discovery-charter.md) §7 완료 조건: §1 증명 대상 · §2 후보 · §3 축 · §5 Open Question **합의**.

| 산출물 | 문서 | 점검 항목 | 결과 |
|--------|------|-----------|:----:|
| **Charter** | [a5-discovery-charter.md](a5-discovery-charter.md) | P1~P5 · 4축 · O1~O14 · 비목표 X1~X9 | **PASS** |
| **Question Register** | [a5-question-register.md](../a5-question-register.md) | O1~O14 전수 · P0~P3 · Pilot/Scale 시점 | **PASS** |
| **Hypothesis Map** | [a5-hypothesis-map.md](../a5-hypothesis-map.md) | H1~H5 · O 매핑 누락·중복 없음 · 의존 그래프 | **PASS** |
| **Gate Review** | [a5-gate-review.md](../a5-gate-review.md) | Critical/Supporting/Informational · M1~M5 · S1~S5 · Stop/Pause/Continue | **PASS** |
| **Pilot Charter** | [a5-pilot-charter.md](../a5-pilot-charter.md) | Pilot 목적·범위·비목표 · Gate 연결 · 성공·중단 | **PASS** |

### 1.1 교차 참조

| 연결 | 정합 |
|------|:----:|
| O1~O14 ↔ H1~H5 (가설 맵 §2) | **일치** |
| H1~H5 ↔ P1~P5 (가설 맵 §6) | **일치** |
| Gate ID ↔ Pilot Charter §4 | **일치** |
| Pilot 질문 ↔ Question Register Pilot 시점 | **일치** |
| 비목표 Discovery X* ↔ Pilot X-P* | **일치** |

### 1.2 Discovery 완료 조건

| 조건 | 상태 |
|------|:----:|
| 증명 대상 P1~P5 정의 | **충족** |
| 성공 기준 **후보** (수치 미확정) | **충족** — Verification Charter **이관** |
| 검증 4축 정의 | **충족** |
| Open Question 인벤토리 | **충족** |
| 실험 착수 **아님** | **준수** |

**판정:** Discovery 단계 **종료 가능** — Pilot Readiness 검토 **진행 적격**.

---

## 2. Gate 정합성 검토

[a5-gate-review.md](../a5-gate-review.md) 기준. 세 문서(가설 맵 · Gate Review · Pilot Charter) **교차 검증**.

| 가설 | Gate | 유형 | 실패 판정 | Pilot 역할 | 정합 |
|------|------|------|-----------|------------|:----:|
| **H1** | G-SUPPLY | Critical | **Stop** | 필수 통과 · O1·O2·O14 | **PASS** |
| **H2** | G-INTEGRITY | Critical | **Pause** | 필수 통과 · O4 · 유입 **전** | **PASS** |
| **H3** | G-IDENTITY | Supporting | **Pause** | 관측 · Scale 확정 | **PASS** |
| **H4** | G-QUALITY | Supporting | **Pause** | 관측 · Scale 확정 | **PASS** |
| **H5** | G-PLATFORM | Informational | **Continue** | 기록 · 단독 Stop 없음 | **PASS** |

### 2.1 의존성 정합

| 검토 | 가설 맵 | Gate Review | Pilot Charter | 결과 |
|------|---------|-------------|---------------|:----:|
| 선행 순서 H1→H2→H3→H4 | §3 · §4 | §6 흐름도 | §4.2 | **일치** |
| H5 병행 (O11) | §3.1 독립·병행 | Informational | §4.2 순서 5 | **일치** |
| H1 실패 → H2~H5 전제 소멸 | §5 | §3 Stop | §6.2 Stop | **일치** |
| H2 실패 → Pilot 보류 | §5 | §3 Pause | §6.1·§6.3 | **일치** |

### 2.2 Gate 충돌

| 잠재 충돌 | 검토 결과 |
|-----------|-----------|
| H1 Stop vs H5 Continue | **충돌 없음** — H5는 H1 **Stop 시** 본선 무의미 (가설 맵 §5) |
| Pilot S3·S4 “조건부” vs Gate Review S3·S4 “필수” | **충돌 없음** — Pilot **성공** ≠ A5 **전체 성공** (Pilot Charter §5.2) |
| O14 Discovery+P0 vs Pilot P0 | **충돌 없음** — 범위 **합의**(M1) vs **실증**(Pilot) 분리 |

**판정:** Gate 정의 **일관** — 충돌 **없음**.

---

## 3. Pilot 범위 검토

### 3.1 범위 충분성

| 검토 항목 | 근거 | 결과 |
|-----------|------|:----:|
| Pilot **목적** (G1 경로 관측) | Pilot Charter §1 | **충분** |
| H1~H5 **검증 역할** 구분 | Pilot Charter §1.2 | **충분** |
| 4축 In Scope | Pilot Charter §2.1 · Discovery §3 | **충분** |
| Pilot 해결 O vs Scale 이관 O | Pilot Charter §2.2 (O3·O8 → Scale) | **충분** |
| 전제 T1~T4 (402·add 미개방·구조 고정) | Pilot Charter §2.3 | **충분** |
| Gate ↔ 질문 순서 | Pilot Charter §4.3 · Question Register P0~P3 | **충분** |

**판정:** Pilot이 **무엇을** · **무엇까지** 검증하는지 **정의됨**.

### 3.2 비목표 명확성

| 비목표 | Discovery | Pilot Charter | 명확 |
|--------|-----------|---------------|:----:|
| 50k 달성 금지 | X8 | X-P1 | **예** |
| 구조 변경 금지 | X2 | X-P2 | **예** |
| 신규 아키텍처 금지 | X2·X3 | X-P3 | **예** |
| 신규 구현을 성공 조건으로 요구 금지 | X4 | X-P4 | **예** |
| Pilot 실행·수치·일정 금지 | X1·X9 | X-P7 | **예** |

**판정:** 비목표 **명확** — Pilot이 Discovery·Phase 2 **범위를 벗어날 여지** 문서상 **없음**.

---

## 4. 미해결 사항

Open Question **미답**은 실패가 **아님** ([a5-question-register.md](../a5-question-register.md)). Pilot 착수 **차단 사유 아님**.

### 4.1 Pilot 전 필수 (Gate Review M1~M5)

| # | 항목 | 문서 근거 | Readiness 상태 |
|---|------|-----------|:--------------:|
| M1 | A5 명제·O14 **범위 합의** | Gate Review §4 | **충족** — Discovery 세트 **합의 완료** |
| M2 | G-SUPPLY **기각 아님** (경로 **관측 가능**) | Gate Review §4 · Discovery §4.4 | **충족** — 수동 PR·merge·Expansion **경로 문서화** · O1 **미측정**은 Pilot **대상** |
| M3 | G-INTEGRITY **기각 아님** | Gate Review §4 | **충족** — O4 **미답** ≠ 기각 · Pilot **전** 판정 |
| M4 | Phase 2 Governance baseline | Gate Review §4 · phase2-summary | **충족** — quality_gate · dashboard · SW1/URV |
| M5 | 구조 변경 예외 **미발동** | Gate Review §4 · Discovery X2 | **충족** |

**후속 산출 (Pilot GO 후·실측 전):**

| 산출 | 역할 | NO-GO 여부 |
|------|------|:----------:|
| **A5 Verification Charter** | 합격 **수치**·측정 도구 확정 | **아님** — Discovery §7·Pilot Charter **예고** 산출 · Readiness **범위 밖** |

### 4.2 Pilot 중 확인 가능

| 우선순위 | ID | 가설 | Gate |
|:--------:|:---|------|------|
| P0 | O1 · O4 · O14 | H1 · H2 | G-SUPPLY · G-INTEGRITY |
| P1 | O7 · O2 · O5 | H3 · H1 | G-IDENTITY · G-SUPPLY |
| P2 | O6 · O12 | H3 · H5 | G-IDENTITY · G-PLATFORM |
| P3 | O9 · O10 · O11 · O13 | H4 · H3 · H5 | G-QUALITY · G-IDENTITY · G-PLATFORM |

**판정:** P0는 Pilot **초기** 관측 — 착수 **전 답** 요구 **아님** ([a5-question-register.md](../a5-question-register.md) §O1: Pilot 시점).

### 4.3 Scale 단계 이관

| ID | 질문 요약 | 가설 | 이유 |
|:---|-----------|------|------|
| **O3** | G2 throughput | H1 | G1 **이후** · Pilot Charter §2.2 |
| **O8** | 50k 거버넌스 주기 | H4 | 50k **체계** · Question Register P3 Scale |

**판정:** Scale 이관 **명시** — Pilot 범위 **과대 기대** 없음.

---

## 5. NO-GO 조건 검토

### 5.1 구조 변경 필요 여부

| 검토 | 근거 | 결과 |
|------|------|:----:|
| Pilot 범위가 구조 변경을 **요구**하는가 | Discovery X2 · Pilot X-P2·X-P3 | **아니오** |
| H2 Pause 시 구조 변경 **필수**인가 | Gate Review §3 — **운영·도구 보완** | **아니오** |
| Phase 2 §3.2 예외 **발동** 필요한가 | M5 · scale-5k 5k 성능 **낮음** | **아니오** |

**판정:** 구조 변경 **NO-GO 사유 없음**.

### 5.2 Gate 충돌 여부

§2.2 — **충돌 없음**.

### 5.3 성공 조건 불명확 여부

| 조건 | 정의 위치 | Pilot 적용 | 결과 |
|------|-----------|------------|:----:|
| 착수 M1~M5 | Gate Review §4 | Pilot Charter §5.1 | **명확** |
| Pilot 성공 S1·S2 필수 + S3·S4 조건부 + S5 | Gate Review §5 | Pilot Charter §5.2 | **명확** |
| A5 전체 성공 S1~S4 | Gate Review §5 | Pilot **단독 선언 불가** 명시 | **명확** |
| 합격 **수치** | Verification Charter **미작성** | Discovery **후보**만 존재 | **의도적 미확정** — Readiness **NO-GO 아님** |

**판정:** 성공 조건 **구조** 명확 — 수치는 **후속 Charter** (§4.1).

### 5.4 중단 조건 불명확 여부

| 조건 | 정의 위치 | 결과 |
|------|-----------|:----:|
| H1→Stop · H2~H4→Pause · H5→Continue | Gate Review §3 | **명확** |
| 즉시 Stop (H1 기각·M5·add 개방) | Pilot Charter §6.2 | **명확** |
| Pause 재개 전제 | Pilot Charter §6.3 | **명확** |

**판정:** 중단 조건 **명확**.

### 5.5 NO-GO 종합

| NO-GO 트리거 | 발동 |
|--------------|:----:|
| Discovery 산출 **누락** | **아니오** |
| Gate **충돌** | **아니오** |
| Pilot 범위·비목표 **불명확** | **아니오** |
| 구조 변경 **필수** | **아니오** |
| M1~M5 **문서상 불충족** | **아니오** |
| 성공·중단 조건 **불명확** | **아니오** |

**판정:** **PILOT NO-GO** 근거 **없음**.

---

## 6. 최종 판정 상세

### 6.1 판정표

| 항목 | 결과 |
|------|:----:|
| 1. Discovery 산출물 점검 | **PASS** |
| 2. Gate 정합성 (H1~H5) | **PASS** |
| 3. Pilot 범위·비목표 | **PASS** |
| 4. 미해결 사항 분류 | **PASS** |
| 5. NO-GO 조건 | **미발동** |

### 6.2 판정

```
┌─────────────────────────────────────┐
│           PILOT GO                  │
│  A5 Pilot 착수 — Discovery 기준 허용  │
└─────────────────────────────────────┘
```

### 6.3 판정 범위 한계 (명시)

| 본 판정이 **하는** 것 | 본 판정이 **하지 않는** 것 |
|----------------------|---------------------------|
| Discovery·Gate·Pilot Charter **정합성** 확인 | O1~O14 **답** 선언 |
| M1~M5 **문서·전제** 충족 확인 | G-SUPPLY · G-INTEGRITY **통과** 선언 |
| Pilot **프로그램 착수** 허용 | 배치 insert · enrich **실행** |
| Scale 이관·후속 Charter **구분** | 합격 **수치** 확정 |

### 6.4 PILOT GO 이후 (본 문서 범위 밖 — 이름만)

| 순서 | 산출 | 역할 |
|:----:|------|------|
| 1 | A5 Verification Charter | 측정·합격 수치 |
| 2 | Pilot **실측** | O1~O14 관측 |
| 3 | Pilot 종료 판정 | Gate Review S1~S5 |
| 4 | Scale Readiness (필요 시) | O3 · O8 |

---

## 7. 문서 맵

| 문서 | 역할 |
|------|------|
| [a5-pilot-readiness-review.md](a5-pilot-readiness-review.md) | **본 문서** — PILOT GO |
| [a5-discovery-charter.md](a5-discovery-charter.md) | Discovery 범위 |
| [a5-question-register.md](../a5-question-register.md) | O1~O14 |
| [a5-hypothesis-map.md](../a5-hypothesis-map.md) | H1~H5 |
| [a5-gate-review.md](../a5-gate-review.md) | Gate · M/S 조건 |
| [a5-pilot-charter.md](../a5-pilot-charter.md) | Pilot 범위 |

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — PILOT GO (Discovery 문서만 근거 · 실행·추정 없음) |
