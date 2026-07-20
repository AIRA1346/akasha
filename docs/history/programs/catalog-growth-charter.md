# Catalog Growth Charter — SD2.6 해제 · 병행 확장

> **결정일:** 2026-06-10  
> **지위:** Registry 확장·Steam 출시·Scale 프로그램의 **새 운영 SSOT**  
> **대체:** SD2.6 insert hold · “O3 전까지 멈춤” 가정

---

## 1. 결정 요약

| 항목 | 이전 | **지금** |
|------|------|----------|
| Registry @430 | Steam v1 **충분** 가정 | **불충분** — 출시 품질에 카탈로그 깊이 필수 |
| SD2.6 hold | insert **중단** (410→430 실험 후 정지) | **해제** — 잘못된 판단으로 **폐기** |
| O3 checkpoint | insert **재개 여부** 결정 게이트 | **텔레메트리만** — 월 N건 “허용치” 결정용 **아님** |
| Steam vs 데이터 | M2 우선 · insert Out of scope | **병행** — 제품 제출 + 카탈로그 확장 동시 |
| 장기 목표 | 430 엄선 → 나중에 확장 | **지금부터** 추가하며 **전 작품 규모 아키텍처** 검증 |

---

## 2. 북극성 (한 줄)

```
세상의 모든 작품 사전을 향해, 작품을 넣으면서 아키텍처를 증명한다.
멈춰서 한 달 기다리며 “월 몇 건”을 정하는 것이 아니다.
```

| 원칙 | 내용 |
|------|------|
| **제품** | ~400작으로는 Steam **서비스 수준 미달** — 검색·발견 가치가 핵심 |
| **구조** | insert마다 dedupe · search_index · gate 부담 **측정·개선** (O8 등은 **관측 지속**) |
| **안전** | gate 우회·bulk 미러링 **금지** 유지 — 무제한 ≠ 무검증 |
| **법무** | [discovery-legal-baseline.md](../policy/discovery-legal-baseline.md) — **확정 스택** · AniList 금지 |
| **Steam 시점** | 기능 M2와 **카탈로그 G1 진입**(만화 주류 밴드 등) **병행** — 430 고정 출시 ❌ |

---

## 3. SD2.6 폐기 근거

1. **측정 실험을 제품 목표보다 앞세움** — 사용자 검색 Gap 해소가 아니라 O3 rate 산출이 insert를 막음.
2. **430 = “엄선 완료” 착각** — Steam에서 글로벌 사전이 쓸모 있으려면 **수천~수만 밴드**가 필요.
3. **아키텍처 학습 정지** — hold 동안 search_index·dedupe·CDN 한계를 **실데이터로** 못 밀어봄.
4. **1인 스튜디오 현실** — 확장 속도는 **운영 텔레메트리**로 기록하되, **인위 상한**으로 막지 않음.

**SD2.1~SD2.5** (배치 상한 2·gate 선행·preflight)는 **유지**.  
**SD2.6** (410→430 +20 상한)만 **폐기**.

---

## 4. 운영 모드 (해제 후)

### 4.1 허용 경로 (A급)

| 경로 | 용도 |
|------|------|
| `a5_scale_supply_batch` | Maintainer net-new |
| `seed_expansion_batch7` + 신규 cohort | 카테고리별 net-new |
| 수동 PR / Contribution | 고가치·争議 작품 |
| Discovery trial insert | Wikidata manga — **배치당 gate** (§5) |

**매 배치 후 (`discovery_batch.ps1` 게이트):**

| 도구 | 역할 |
|------|------|
| `dedupe_linter` | 중복 0 |
| `quality_gate --strict` | titles.en 문법 |
| `ci_registry_check` | manifest·policy·dedupe |
| `preflight_check` | 4종 핵심 gate 일괄 |
| `catalog_scale_baseline --strict` | eager-only · 15MB 번들 |

SD3 pause: dedupe >0 · quality_gate FAIL · SW1 recall 하락

**wikidata_ko 표준 배치 (2026-06-17~):**

```powershell
.\scripts\discovery_batch.ps1              # 4 rounds · limit 20 · webtoon 제외
.\scripts\discovery_batch.ps1 -Rounds 6   # 라운드 수 조정
```

- Discovery apply 후 **`registry_builder --sync-assets --bundle-eager-only`** (ADR-010)

### 4.2 O3·O8·O9·O12 (재정의)

| ID | 역할 |
|----|------|
| **O3** | insert rate **기록** — G2 경로 가설 검증 입력 (insert **허용/거부 스위치 아님**) |
| **O8** | gate 번들 wall — **규모별** 병목 조기 발견 |
| **O9** | semantic spot-check — 품질 회귀 |
| **O12** | franchise 수동 큐 비용 |

`a5_scale_hold_observation.dart` → **거버넌스 스냅샷** (hold 게이트 아님).

### 4.3 Pause (SD3) — 유지

dedupe >0 · quality FAIL · SW1 recall 하락 시 **일시 감속** — 전면 hold와 다름.

---

## 5. Discovery · manifest

| 항목 | 값 |
|------|-----|
| `patchStatus` | **`active_trial`** — per-batch Product/Diff gate, **글로벌 hold 없음** |
| `wikidata_manga` | shadow → Impact → **trial insert** 병행 |
| bulk auto-sync | 여전히 ❌ — `enabled` 자동화는 G1 안정 후 |

---

## 6. Steam v1 재정의

| | 이전 | 지금 |
|--|------|------|
| 사전 규모 | 430 **고정** 출시 | **G1 진행 중** 출시 (만화·서브컬처 **주류 밴드** 목표) |
| 최소 체감 | 미정의 | 검색 0건 비율·대표 IP 커버 **체감 가능** (수치는 Sprint에서 갱신) |
| M2 | insert 금지 | M2 **+** catalog sprint **동시** |

---

## 7. 즉시 다음 작업

| # | 작업 |
|---|------|
| 1 | Wikidata live shadow 100 → Impact 샘플 |
| 2 | trial batch insert (100건 상한·수동 승인) |
| 3 | Maintainer supply 재개 (`--max-add 2`·gate) |
| 4 | search_index 증분 빌드 · 1k/5k 부하 재측정 |
| 5 | Steam 스토어 copy — “성장 중인 사전” 포지션 반영 |

---

## 8. 관련 문서

| 문서 | 변경 |
|------|------|
| [sprint-05-charter.md](sprint-05-charter.md) | Catalog Growth **In scope** |
| [sprint-05-manga-expansion.md](sprint-05-manga-expansion.md) | Phase D hold 조건 **삭제** |
| [a5-scale-operational-decisions.md](a5-scale-operational-decisions.md) | SD2.6 **폐기** |
| [../strategy/registry-growth-strategy.md](../strategy/registry-growth-strategy.md) | 병행 성장 프레임 |
| [../strategy/wikidata-spine-plan.md](../strategy/wikidata-spine-plan.md) | **Wikidata 1차 연동·그래프·확장 SSOT** |
| [../ROADMAP.md](../../active/ROADMAP.md) | 병행 트랙 |

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | SD2.6 해제 · 병행 확장 Charter 확정 |
| 2026-06-17 | **Option A** — `discovery_batch.ps1` · eager-only sync · baseline `--strict` |
