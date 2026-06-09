# 402 → 5,000 Scale Risk Analysis

> **질문:** 현재 설계로 402 → 5,000 작품까지 확장할 때 **가장 먼저 깨질 가능성이 높은 지점은 무엇인가?**
>
> **범위:** [Baseline v1](baseline-v1.md) 고정 후 첫 검증 (Growth 단계 **G0→G1**).  
> 구현 없음 — 리스크 평가 + 검증 계획만.

선행: [registry-growth-strategy.md](registry-growth-strategy.md) §6 · [registry-bottleneck-validation-report.md](registry-bottleneck-validation-report.md) · [contribution-model-strategy.md](contribution-model-strategy.md) · [assumption-register.md](assumption-register.md) (A1~A4)

---

## 1. 전제 — 5,000이라는 규모의 성격

| 지표 | 402 (실측) | 5,000 (선형 추정) | 임계 대비 |
|------|------------|-------------------|-----------|
| search_index | 262 KB | **~3.3 MB** | 100k WARN(60MB) 한참 아래 |
| ms/query | 0.45 ms | **~5 ms** | 무해 |
| shard 평균 작품/버킷 | 1.2 | **~15** | 256버킷 여유 |
| akasha-db 전체 | 0.78 MB | **~10 MB** | Git 여유 |
| franchise 그룹 | ~30 (member 123) | **~400~600** | 수동 큐 부담 시작 |
| 신규 등록 필요 | — | **~4,600건** | **공급이 핵심** |

**핵심:** 5,000은 **물리·성능 규모가 아니라 "공급·운영 규모"** 문제다.  
search_index·shard·저장소는 5k에서 **거의 무위험**. 위험은 **어떻게 4,600건을 넣고, 그 품질·중복·관계를 유지하느냐**다.

---

## 2. 현재 구현 사실 (근거)

| 영역 | 현재 상태 | 출처 |
|------|-----------|------|
| Expansion 파이프라인 | **shadow-write/dry-run만** · 채널 `enabled:false` · dailyLimit 500 | `pipeline/discovery/manifest.json` |
| 실제 insert 경로 | **수동 PR + `merge_catalog_contribution`** 만 | catalog-contribution-roadmap |
| dedupe | `dedupe_linter` **사후 전수** (externalId 버킷 + fuzzy) · auto-merge 없음 | ci_registry_check |
| franchise | `franchise_linter` **후보 제시** · 결정 수동 · min members 2 | ci output |
| alias/다국어 | titles.en **28%** · ja 21% · zh 0% | search_index 분석 |
| contribution | add/fix 골격 · status.json · **AI validator 미구현** · add는 50k까지 미개방 | contribution-model §2 |

---

## 3. 항목별 리스크 평가

### 3.1 데이터 수집 — **높음** 🔴

| 근거 | 내용 |
|------|------|
| 공급 경로 부재 | Expansion은 **dry-run·비활성** · 실제 insert는 수동뿐 |
| 필요량 | 12~18개월에 **~4,600건** (월 ~300~400) |
| 수동 한계 | maintainer 1인 기준 월 수백 건이 현실 상한 |
| 정책 제약 | bulk 미러링 금지 → Signal→Minimal Core 변환 **워크플로 미완** |

**왜 가장 먼저 깨지나:** 다른 모든 항목은 "작품이 들어온 뒤" 문제다. 5,000에 **도달하는 것 자체**가 1차 관문이며, 현재 그 경로(merge train·import)가 운영 수준으로 검증된 적 없다.

### 3.2 dedupe — **중간** 🟡 (수집과 결합 시 상향)

| 근거 | 내용 |
|------|------|
| 알고리즘 | externalId 해시 버킷 = O(n) · 5k에서 비용 무해 |
| 구조 공백 | **pre-insert 게이트 없음** — `dedupe_linter`는 사후 전수 검사 |
| 위험 시나리오 | 배치 import 시 기존 `wk_`와 중복 stub이 **먼저 들어간 뒤** 사후 적발 |
| 완화 요소 | shadow_write가 mergeCandidates 산출 (dry-run 단계에서 점검 가능) |

**평가:** 알고리즘은 안전하나 **ingest 게이트 미성숙** → 수집(3.1)과 결합하면 **중간→높음**으로 전이.

### 3.3 alias / 다국어 — **중간** 🟡

| 근거 | 내용 |
|------|------|
| 현 갭 | en 28% · zh 0% — 신규 stub이 같은 패턴이면 SW1 recall 저하 |
| 5k 영향 | "깨짐"보다 **검색 품질 점진 악화** (SW1-A가 측정) |
| 결합 | 존재 우선 대량 stub → alias enrich backlog 누적 |

**평가:** 5k에서 시스템을 멈추진 않으나, **SW1 recall의 직접 입력**이라 enrich 규율을 지금 세워야 함.

### 3.4 franchise — **중간** 🟡

| 근거 | 내용 |
|------|------|
| 수동 큐레이션 | linter는 후보만 · 묶음 결정은 사람 |
| 5k 추정 | franchise ~400~600 · multi-media 클러스터 급증 |
| 구조 | ADR-006 F1은 depth≤3 정의됨 · 그러나 **연결 작업량**은 선형 이상 |
| 완화 | 지연 생성·tier (5k에서 전수 불필요) |

**평가:** 물리 한계(100k)는 멀지만 **운영 노동량**이 5k에서 체감되기 시작 → 지연 생성 정책의 첫 시험대.

### 3.5 search_index — **낮음** 🟢

| 근거 | 내용 |
|------|------|
| 크기 | ~3.3 MB · 메모리·parse 무해 |
| latency | ~5 ms/query |
| 실측 | 병목은 100k WARN / 300k FAIL — 5k는 안전대 |

**평가:** 5k 구간에서 **사실상 무위험**. (중장기 SW2 과제와 분리)

### 3.6 contribution workflow — **중간** 🟡

| 근거 | 내용 |
|------|------|
| 성숙도 | AI validator·auto-merge **미구현** · 수동 검수 |
| 볼륨 | add는 50k까지 미개방 → 5k는 fix + maintainer import 위주 |
| 위험 | **import/merge train 운영 절차**가 미검증 (큐·상태·롤백) |
| 완화 | 볼륨 낮음 · status.json 골격 존재 |

**평가:** 사용자 기여 폭발은 5k에서 비현실적이나, **운영자 import 워크플로**가 3.1과 같은 미검증 경로라 중간.

---

## 4. 리스크 매트릭스 요약

| 항목 | 위험도 | 성격 | 5k에서 "깨지는" 모습 |
|------|:------:|------|----------------------|
| **데이터 수집** | 🔴 높음 | 공급 | 5,000 도달 실패 / 일정 붕괴 |
| **dedupe** | 🟡 중간(↑) | 무결성 | 배치 import 시 중복 `wk_` 오염 |
| **contribution workflow** | 🟡 중간 | 운영 | import/merge 절차 미검증 |
| **alias / 다국어** | 🟡 중간 | 품질 | SW1 recall 점진 저하 |
| **franchise** | 🟡 중간 | 운영 | 수동 연결 노동량 급증 |
| **search_index** | 🟢 낮음 | 성능 | (5k에선 문제 없음) |

---

## 5. Top 3 리스크 (먼저 검증해야 할 것)

### Top 1 — 데이터 수집 throughput 🔴

**가설:** 현재 insert 경로(수동 + dry-run 파이프라인)로는 월 ~300~400건 지속 공급이 검증되지 않았다.

**검증 (5k 시뮬레이션 A):**
- shadow-write 파이프라인을 **1채널 실가동(소량)** — Signal→Minimal Core 변환율 측정
- 합성 또는 실제 배치 500건 dry-run → **insert 가능 건수 / 정책 탈락률 / 수동 보정 시간** 기록
- **합격 기준:** 주간 배치로 **≥ 300 net 신규/월** 경로가 인적 부담 한도 내에서 성립

### Top 2 — dedupe ingest 게이트 🟡↑

**가설:** 사후 `dedupe_linter`만으로는 배치 유입 시 중복 stub이 먼저 들어간다.

**검증 (5k 시뮬레이션 B):**
- 기존 402 + 합성 4,600 중 **의도적 중복 N%** 삽입한 dry-run
- shadow_write `mergeCandidates` **precision/recall** 측정
- **합격 기준:** pre-insert 단계에서 중복 후보 **recall ≥ 90%** · 확정 중복 `wk_` 사후 잔존 **0**

### Top 3 — 메타/alias enrich 규율 🟡 (SW1 연동)

**가설:** 존재 우선 대량 stub이 en/ja titles 없이 쌓이면 5k에서 SW1 recall이 402 baseline보다 떨어진다.

**검증 (5k 시뮬레이션 C · SW1-A 연계):**
- 합성 5k에 **현 갭 비율(en 28%)** 그대로 vs **enrich 목표(en ≥ 70%)** 두 세트
- 동일 SW1 쿼리 스위트로 recall@10 **before/after** 비교
- **합격 기준:** enrich 세트가 baseline recall **유지 또는 개선** · enrich backlog 증가율 < 신규 등록율

> **franchise(중간)** 는 Top 3 직후 4순위 — 5k에서 즉시 깨지진 않으나 **지연 생성 정책**을 같은 시뮬레이션에서 관찰(연결 노동량 추정)할 것.

---

## 6. 5k 시뮬레이션 실행 계획 (구현 없음 · 절차만)

| 단계 | 입력 | 측정 | 산출 |
|------|------|------|------|
| **SIM-0** | 402 실측 고정 | baseline 지표 | 비교 기준 |
| **SIM-A (Top1)** | 배치 500건 dry-run | 변환율·탈락률·시간 | throughput 곡선 |
| **SIM-B (Top2)** | 402 + 합성 4,600 (+중복 N%) | dedupe precision/recall | ingest 게이트 필요성 판정 |
| **SIM-C (Top3)** | 합성 5k × {gap, enrich} | SW1 recall@10 | enrich 규율 효과 |
| **SIM-D (관찰)** | SIM-B 데이터 | franchise 연결 후보 수·노동 추정 | 지연 생성 정책 입력 |

- 합성 데이터: [search-index-validation](search-index-validation-plan.md) 생성기 재사용 (titles 쌍·중복·franchise 클러스터 주입)
- 저장 위치: `akasha-db/pipeline/artifacts/scale_5k_sim/` (gitignored)
- **고정 시드** — 반복·회귀 비교

---

## 7. 합격 / 게이트 (G1 진입)

| 게이트 | 조건 |
|--------|------|
| G1-1 (수집) | ≥ 300 net 신규/월 경로 검증 (SIM-A) |
| G1-2 (dedupe) | 중복 후보 recall ≥ 90% · 잔존 중복 0 (SIM-B) |
| G1-3 (품질) | enrich 세트 SW1 recall ≥ baseline (SIM-C) |
| G1-4 (관찰) | franchise 지연 생성 정책 수치화 (SIM-D) |

3개 게이트(G1-1~3) 통과 시 **402→5,000 실확장 착수**.

---

## 8. 결론

1. 5,000은 **성능 문제가 아니라 공급·무결성·품질 운영 문제**다.
2. **가장 먼저 깨질 지점 = 데이터 수집 throughput** (현 insert 경로 미검증).
3. 그 다음 = **dedupe ingest 게이트** (사후 검사만 존재) → 수집과 결합 시 위험 상향.
4. 동시에 **alias/다국어 enrich 규율** (SW1 recall 직접 입력).
5. search_index는 5k에서 **무위험** — 자원을 Top 3에 집중.
6. franchise는 **즉시 위험은 아니나** 지연 생성 정책을 이번에 관찰·수치화.

> 다음 행동: **새 문서 금지.** SIM-A/B/C 시뮬레이션 실행으로 Top 3 가설을 실측 검증.
