# Registry Design Baseline v1

> **목적:** 설계·전략 문서 세트를 **Baseline v1**으로 고정한다.  
> **상태:** **Validated through Phase 1** (2026-06-09)  
> **검증 종료:** [phase1-final-review.md](archive/phase1-final-review.md)  
> **다음:** [phase2-charter.md](phase2-charter.md) — Coverage Improvement Program (운영)  
> 기준일: 2026-06-09

---

## 1. 고정된 문서 세트 (Baseline v1)

| # | 문서 | 역할 | 상태 |
|---|------|------|------|
| ADR-001 | [adr/ADR-001-dual-layer-entity-model.md](adr/ADR-001-dual-layer-entity-model.md) | Work + Franchise Dual-layer | **승인** |
| ADR-002 | [adr/ADR-002-music-registry-model.md](adr/ADR-002-music-registry-model.md) | 음악 A안/B안 | **B안 가중 · 결정 보류** |
| ADR-003 | [adr/ADR-003-series-minimum-unit.md](adr/ADR-003-series-minimum-unit.md) | 시리즈 최소 단위 (에피소드 밖) | **원칙 승인** |
| ADR-004 | [adr/ADR-004-work-collection-policy.md](adr/ADR-004-work-collection-policy.md) | 수집 정책 (2차 창작 분리) | **원칙 승인** |
| ADR-005 | [adr/ADR-005-minimum-recordable-unit.md](adr/ADR-005-minimum-recordable-unit.md) | 매체별 최소 기록 단위 | **음악 외 승인** |
| ADR-006 | [adr/ADR-006-franchise-boundary-hierarchy.md](adr/ADR-006-franchise-boundary-hierarchy.md) | Franchise 경계·계층 (F1) | **승인** (§2) |
| SW1 | [global-search-validation-plan.md](global-search-validation-plan.md) · [global-search-query-set.md](global-search-query-set.md) | 글로벌 검색 recall | **SW1-A ✅** (402 baseline) |
| URV | [universal-registry-validation.md](universal-registry-validation.md) | 정체성·관계·dedupe | **URV-A ✅** (402 baseline) |
| Growth | [registry-growth-strategy.md]](../strategy/registry-growth-strategy.md) | 402→5M+ 성장·병목 | ✅ |
| Contribution | [contribution-model-strategy.md](contribution-model-strategy.md) | Registry→Platform·커뮤니티 | ✅ |
| Assumptions | [assumption-register.md](assumption-register.md) | Baseline v1 **핵심 가정** 인벤토리 | ✅ · Phase 1 판정 확정 |
| Phase 1 | [phase1-final-review.md](archive/phase1-final-review.md) | Baseline v1 **검증 종료** 보고서 | ✅ |
| Coverage | [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) | Identity Coverage KPI | ✅ · Phase 2 운영 |
| Phase 2 | [phase2-charter.md](phase2-charter.md) | Coverage Improvement Program | 🔶 진행 |

**고정 원칙:** Baseline v1 **설계 본문**은 Phase 1에서 반박되지 않았으므로 **불변** 유지. 변경은 검증 산출물 → ADR **개정**으로만 (신규 ADR 없음).

---

## 2. ADR-006 (F1) 최종 승인 상태 정리

사용자 승인 사항 (depth≤3 · parentFranchiseId 트리 · IP 1카드 유지) 반영.

| 항목 | 확정 |
|------|------|
| 모델 | **F1** — `members`는 `wk_`만 · 계층은 `parentFranchiseId` |
| 최대 깊이 | **3** (universe → subseries → collection) · depth 4+ linter 거부 |
| 그리드 anchor | 기본 **leaf subseries** · 사용자 설정 시 조상 승격 (장기) |
| 단순/복합 IP | **동일 스키마** · Pokémon=depth1, Marvel=depth2~3 |
| `members` 중첩 Franchise | **금지** (F2 기각) |
| 순환 | **금지** (linter) |
| 규모 방어 | 전수 강제 생성 금지 · tier·지연 생성 · 파일 분할 · members soft cap |

**상태: 승인.** 남은 것은 **구현 세부**(O1~O6: `fr_` ID·anchor UX·분할 키 등) — Baseline v1 범위 밖, 구현 단계로 이월.

---

## 3. ADR-002 음악 A/B 비교 결과 정리

| 기준 | A안 (앨범=Work) | B안 (곡=Work, 앨범=Container) |
|------|------------------|-------------------------------|
| 최소 기록 단위 | 앨범 | **곡** |
| 기록 시스템 정합 | 중 | **상** |
| 곡 정체성 (Bohemian Rhapsody 등) | 약 (앨범 종속) | **강** |
| Work 규모 | ~5M–15M | ~30M–100M+ |
| search_index 부담 | 유리 | **부담 (인프라 게이트)** |
| SW1 곡명 recall | 앨범 경유 | **직접 hit** |
| 운영 전제 | 릴리스 메타 | **tier·인기곡 우선 필수** |

**리뷰 결론 (Baseline v1):**

- **방향: B안 가중** — AKASHA가 작품 **기록** 시스템이라는 정체성과 정합.
- **조건부:** B안은 **tier 0/1/2 점진 커버리지** + **search_index 30M 인프라 게이트(SW2)** 를 전제로만 채택.
- **최종 확정 시점:** 음악 카테고리 실제 도입 전 (현재 402에 음악 0건 → **결정 비긴급**).
- **Baseline v1 표기:** ADR-005 음악 행은 **B안 잠정** · 비음악 매체는 확정.

→ 음악은 **5k 확장 범위에 포함하지 않음** (G1은 애니·만화·게임·영화·소설 주류). 따라서 5k 검증의 차단 요소 아님.

---

## 4. Phase 1 검증 요약

| 실험 | 결과 | 상세 |
|------|------|------|
| SIM-A/B/C/D | ✅ 완료 | [assumption-register.md](assumption-register.md) §6–7 |
| SW1-A | ✅ 81.6% recall@10 | [assumption-register.md](assumption-register.md) §8 |
| URV-A | ✅ 구조 Supported | [assumption-register.md](assumption-register.md) §9 |
| Coverage Dashboard | ✅ baseline | [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) |

**Phase 1 결론:** Registry **구조는 Supported**. 최대 과제는 **Canonical Identity Coverage** (운영·enrich).  
전체 보고: [phase1-final-review.md](archive/phase1-final-review.md).

---

## 5. 다음 단계 (Phase 2)

| 순위 | 작업 | 문서 |
|------|------|------|
| 1 | **Coverage Improvement Program** | [phase2-charter.md](phase2-charter.md) |
| 2 | GAP · alias · subtitle panel enrich | [canonical-identity-coverage-dashboard.md](canonical-identity-coverage-dashboard.md) |
| 3 | SW1-A / URV-A 회귀 | Phase 2 종료 조건 |

---

## 6. 원칙

1. **Phase 1 종료** — Registry · Franchise · Stub-first · 5k · Search/Identity **구조** 검증 완료.
2. **Phase 2** — [phase2-charter.md](phase2-charter.md): Coverage KPI 운영 · **신규 ADR·구조 변경 원칙적 금지** (예외 3조건은 Charter §3.2).
3. Baseline v1 설계 본문은 Phase 1 반박 없이 **불변**.
4. ADR-002 음악만 미확정 (B안 가중) — 비긴급, 5k 범위 밖.
