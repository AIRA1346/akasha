# Phase 2 Late-Stage Plan — 남은 검증 질문

> **역할:** [phase2-mid-review.md](phase2-mid-review.md) 이후 **Phase 2 종료까지** 남은 검증 질문·우선순위를 정의한다.  
> **성격:** 계획·질문 인벤토리 — **실험 실행·enrich·신규 ADR·구조 제안 없음**.  
> **전제:** [phase2-charter.md](phase2-charter.md) · [assumption-register.md](assumption-register.md) §10 · Registry **402작**  
> **기준일:** 2026-06-09

**목표:** Sprint 04 착수 전, Phase 2 **종료 경로**를 명확히 한다.

**Phase 2 후반 핵심 질문 (Mid-Review 합의):**

> *「Coverage가 가능한가?」* → **검증 완료**  
> *「Coverage를 어떤 품질 관리 체계로 유지할 것인가?」* · *「잔여 축 Economics는 감당 가능한가?」* → **미검증**

---

## 1. 이미 검증된 것

Mid-Review · Sprint 01~03 · Phase 1 실측만 근거. **추가 실험 불필요.**

| # | 영역 | 검증 결론 | 근거 |
|---|------|-----------|------|
| **1** | **구조** | Registry · Franchise · Stub-first · 5k 합성 **Supported** | Phase 1 SIM-A/B/C/D · URV-A · [phase1-final-review.md](phase1-final-review.md) |
| **2** | **Coverage 원인** | 실패 직접 원인 = **표면형 미부착** (MISSING_TOKEN / MISSING_LOCALE) | SW1-A GAP 진단 · URV-A · Sprint 01 |
| **3** | **GAP remediation** | **17 Work** minimal enrich → GAP/SW1/URV **100%** · 구조 무변경 | Sprint 01 · panel **100%** 유지 (Sprint 03) |
| **4** | **titles.en Economics** | Sprint 02 추정(**22.9h/+101작**) vs 실측 human-eq **~11.6h** · wall **~1분대** | Sprint 02~03 · [phase2-mid-review.md](phase2-mid-review.md) §4 |
| **5** | **자동화 실효성 (titles.en)** | auto+semi **100%** (성공작) · TMDB 단독은 **품질 사고** 31건 | Sprint 03 · fallback 필수 |
| **6** | **대량 enrich 회귀** | titles.en **91.5%** 후 SW1/URV/GAP **100%** | Sprint 03 |
| **7** | **A3 등급** | **Supported (Operational Dependency)** — KPI·회귀 전제 | [assumption-register.md](assumption-register.md) §10 |

**의미:** Phase 2 **전반부(Coverage 가능성·titles.en Economics)** 는 종료. 이후는 **품질 관리·잔여 축 Economics·운영 모델** 검증.

---

## 2. 아직 검증되지 않은 것

| # | 검증 질문 | 현재 상태 (Sprint 03 후) | Phase 2 연계 |
|---|-----------|-------------------------|--------------|
| **Q1** | **zh Coverage Economics** | zh **~1%** (4/402) · Sprint 02: +358작·자동화율 **낮음** 가정 | G3 전 **30%** (Charter §4.2) |
| **Q2** | **externalId Coverage Economics** | externalId **~15%** (60/402) · +302작→90% 추정 잔여 | Charter §5 **#4: G2 ≥50%** |
| **Q3** | **composite Coverage Economics** | Sprint 02 **~60.1h** composite · **titles.en binding 완화** · 타 축 미실측 | Sprint 04 재정의 대상 |
| **Q4** | **QA / 품질 거버넌스** | TMDB **31건** 오염 · heuristic enrich 다수 · **CI 게이트 없음** | A3 운영 전제 · G1 insert 전제 |
| **Q5** | **A5 (50k 운영 가능성)** | **미검증** — SIM-A throughput만 · G1 실측 insert·human queue 없음 | Phase 2 §5 #4와 **별축** · 중기 가정 |

**보조 백로그 (Phase 2 종료의 blocking은 아님):**

| 항목 | 상태 | 비고 |
|------|------|------|
| season KPI | ~43% (anim+drama) | Charter milestone 60% — Sprint 04 범위 밖 가능 |
| alias field (registry-wide) | ~4% | panel은 100% |
| G1 insert · stub 희석 (A2) | 미실측 | Coverage Sprint와 **독립** 게이트 |
| 5k 자동화율 extrapolation | 미검증 | 402 실측만 존재 |

---

## 3. 항목별 검증 설계

> 아래 「필요한 실험」은 **계획 정의**이며, 본 문서 작성 시점에 **실행하지 않는다**.

### Q1 — zh Coverage Economics

| | 내용 |
|---|------|
| **왜 중요한가** | GAP panel CJK 4건 · `titles.zh` 전무에 가까움. Sprint 02는 zh 자동화율 **최저 축**으로 분류. composite 60.1h의 **잔여 binding** 후보. |
| **필요한 실험** | **Economics Sprint 04 (zh cohort):** Sprint 02 tier 모델로 zh 마일스톤(예: 10%→30%) 작업량·단가 추정 → 소규모 cohort enrich **실측** (wall · human-eq · method mix) · `coverage_dashboard` · SW1/URV 회귀. 기존 도구 패턴 확장 또는 `coverage_sprint_02_economics` zh 축 분리 — **구조 변경 없음**. |
| **성공 조건** | ① zh rate **측정 가능한 상승** (중간 목표 예: **≥10%** 파일럿) ② SW1/URV/GAP panel **≥ Phase 2 하한** ③ Sprint 02 zh 추정 vs 실측 **Δ 문서화** (과대/과소 여부) |
| **실패 시 의미** | zh ramp **비용이 예상 이상** → Phase 2 zh 30% 목표 **일정 조정** 또는 G3로 이관. **구조 반박 아님** — 운영·공급 경로 문제. CJK 검색 가치는 **장기 백로그**로 명시. |

---

### Q2 — externalId Coverage Economics

| | 내용 |
|---|------|
| **왜 중요한가** | Phase 2 Charter §5 **성공 조건 #4** — **externalId ≥50% (G2)**. 현 **~15%**. variant-only stub·B-3/B-4 fallback에 직접 연결. Sprint 02: +302작·자동화 **제한적**. |
| **필요한 실험** | **Economics Sprint 04 (externalId cohort):** missing 342작 중 G2 50% 목표(+141작) cohort 선정 · tmdb/steam/igdb/openlibrary 등 **기존 externalId 소스** 반자동 attach 실측 · 작업당 wall/human-eq · `coverage_dashboard` externalId KPI · SW1 exactId·variant 축 회귀. |
| **성공 조건** | ① externalId **≥50%** (201/402) ② SW1/URV **≥ Sprint 03 baseline** ③ Economics: Sprint 02 externalId 잔여 추정 vs 실측 비교 ④ exactId ingress **100%** 유지 (URV-A) |
| **실패 시 의미** | **Phase 2 §5 미달** — Phase 2 **종료 불가** (Charter 기준). enrich로도 50% 불가 시 Charter §3.2 예외 #1 검토 — **Coverage로 해결 불가** 여부만 판단 (구조 변경은 예외 절차). 비용만 초과 시 → **G2 목표 조정** 또는 **운영 투자 확대** (구조 아님). |

---

### Q3 — composite Coverage Economics

| | 내용 |
|---|------|
| **왜 중요한가** | Sprint 02 **~60.1h / 90% composite** 는 multi-axis 합산. Sprint 03이 titles.en binding을 **사실상 제거**했으므로, **잔여 composite 비용** 재추정 필요. Phase 2 **투자 의사결정**의 최종 Economics 질문. |
| **필요한 실험** | **Synthesis Sprint (문서+산술):** Q1·Q2 실측 + Sprint 03 titles.en 실측 + Sprint 02 잔여 축(season·alias field·zh) 추정을 **합산** · binding axis 식별 · 90% composite **갱신 추정** vs **실측 기반 하한/상한** 구간 제시. enrich 일괄 실행은 Q1/Q2 후. |
| **성공 조건** | ① composite 90% **갱신 비용 구간** (예: X–Y maintainer-hours) **문서화** ② binding axis **명시** (externalId · zh · season 등) ③ Sprint 02 60.1h 대비 **Δ%** · Phase 2 **운영 투자 가정** 갱신 가능 |
| **실패 시 의미** | composite 90% **여전히 ~60h+ 수준** → Coverage **가능하나 비용 상한 높음** — G1/G2 insert 속도·enrich SLA **조정**. **A3 강등 아님** — Operational Dependency **유지**, Economics **보수적** 운영 모델 채택. |

---

### Q4 — QA / 품질 거버넌스

| | 내용 |
|---|------|
| **왜 중요한가** | Sprint 03: enrich **성공 ≠ 품질 보증**. TMDB **31건** invalid `titles.en`. Mid-Review: Phase 2 후반 핵심 = **「어떤 품질 관리 체계로 유지할 것인가?」** G1 stub 유입 전 **필수 전제**. |
| **필요한 실험** | **Governance Validation (도구·프로세스):** ① `_isValidEnTitle` 등 **가드 규칙**을 enrich 파이프라인 **필수 게이트**로 고정 ② `coverage_dashboard` + **spot-check 샘플** (auto vs manual) 정의 ③ enrich 배치 후 **회귀 루틴** (registry_builder → dashboard → SW1 → URV) **체크리스트** ④ (선택) CI에 panel threshold **경고** — **스키마·ADR 변경 없음**. |
| **성공 조건** | ① auto enrich **오염 재발 0건** (동일 TMDB 패턴) ② 배치당 **회귀 4종** (panel · SW1 · URV · invalid-en scan) **문서화·실행 가능** ③ 품질 SLA 정의 (예: auto tier **spot-check N%** · semi **100% 샘플링 규칙**) |
| **실패 시 의미** | **수량 KPI만 달성**하고 검색 품질·신뢰 **저하** → SW1 쿼리 세트 확대 시 회귀 **가능**. **운영 실패** — A3 전제(KPI 유지) **위반 경로**. 구조 변경 전 **프로세스·가드** 우선. |

---

### Q5 — A5 (50k 운영 가능성)

| | 내용 |
|---|------|
| **왜 중요한가** | [assumption-register.md](assumption-register.md) A5 **미검증**. Contribution 없이 Maintainer+Pipeline만으로 **50k** 도달 가능 여부. Phase 2 Coverage와 **직교**하나 **성장 전략** 전제. SIM-A throughput(~~2,104/월)과 **burden fail** 공존. |
| **필요한 실험** | **G1 실측 파일럿 (Coverage Sprint 분리):** ① 월 **net insert** 실측 ② maintainer **분/건** (insert + enrich + dedupe) ③ stub 비율 vs Coverage KPI **상관** 추적. 50k 전용 시뮬은 **5k 통과 후** — Phase 2 late에서는 **402→G1 구간 실측**만. |
| **성공 조건** | ① G1 목표 **≥300 net/월** 경로 **1회 이상** 실측 또는 **명시적 불가** 기록 ② enrich·Coverage SLA와 **병행 가능** 여부 판정 ③ A5 등급 갱신 근거 (Supported / Contested / 미검증 유지) |
| **실패 시 의미** | **50k 공급 가정 붕괴** (중기) — Contribution 조기 개방·G2 목표 하향 검토. **402 Coverage·구조와 무관** — [contribution-model-strategy.md](contribution-model-strategy.md) 경로 재검토. Phase 2 **종료 조건과 분리** 판단 가능. |

---

## 4. Phase 2 종료와의 관계

[phase2-charter.md](phase2-charter.md) §5·§6 기준 **종료에 필요한 검증 매핑:**

| Charter 조건 | 검증 질문 | 상태 |
|--------------|-----------|------|
| GAP · alias · subtitle panel ≥90% | — (유지·회귀) | ✅ Sprint 01~03 |
| **externalId ≥50%** | **Q2** | ❌ 미검증 |
| SW1 · URV ≥ baseline | Q1~Q4 회귀 게이트 | ✅ (유지 감시) |
| §6 종료 (로마자 축 · 연속 2회 panel PASS) | romanized **~91%** · panel 안정 | △ 로마자 **PASS**는 Sprint 03 부수 달성 · **연속 2회** 미기록 |

**Phase 2 종료 최소 경로 (Coverage 축):**

1. **Q4** 품질 거버넌스 정의 (Sprint 04 **전제**)
2. **Q2** externalId G2 50% + Economics 실측
3. **Q1** zh Economics (Charter 30%는 **Phase 2 후반** — 전량 30%는 선택)
4. **Q3** composite 갱신 추정
5. **Q5** 병행 가능 — **Phase 2 종료 blocking 아님** (A5 별도 판정)

---

## 5. 추천 우선순위

| 순위 | 검증 질문 | 근거 | Sprint 04 매핑 |
|:----:|-----------|------|----------------|
| **P0** | **Q4 QA / 품질 거버넌스** | TMDB 31건 · G1 insert 전제 · A3 운영 전제 | Sprint 04 **착수 전** 체크리스트·가드 고정 |
| **P1** | **Q2 externalId Economics** | Charter §5 **#4 blocking** · dedupe·variant fallback | Sprint 04 **핵심 cohort** |
| **P2** | **Q1 zh Economics** | composite 잔여 binding · CJK panel | Sprint 04 **2차 cohort** (규모는 파일럿) |
| **P3** | **Q3 composite Economics** | Q1·Q2·Sprint 03 **합산** — 의사결정 마감 | Sprint 04 **마무리 산출** |
| **P4** | **Q5 A5 (G1 실측)** | Coverage와 독립 · 성장 가정 | Phase 2 **병행** 또는 Phase 2 completion 후 |

**Sprint 04 재정의 (실행 전 계획만):**

```
Sprint 04 = titles.en 연장 ❌
         → P0 가드 확인
         → P1 externalId cohort (Economics 실측)
         → P2 zh cohort (Economics 실측, 파일럿)
         → P3 composite synthesis
         + 매 단계: coverage_dashboard · SW1 · URV 회귀
```

**하지 않는 것:** 신규 ADR · Registry/Franchise/search_index 구조 변경 · 음악(A6) · SW2.

---

## 6. 문서 맵

| 문서 | Late-Stage 역할 |
|------|-----------------|
| [phase2-mid-review.md](phase2-mid-review.md) | Sprint 01~03 의사결정 · Economics 검증 완료 기록 |
| [phase2-charter.md](phase2-charter.md) | §5·§6 종료 조건 · 거버넌스 |
| [phase2-late-stage-plan.md](phase2-late-stage-plan.md) | **본 문서** — 남은 검증 질문·우선순위 |
| [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | KPI 정의 |
| [assumption-register.md](assumption-register.md) | A3 · A5 등급 갱신 (검증 후) |

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | 초안 — Mid-Review 이후 남은 검증 질문 (실험 미실행) |
