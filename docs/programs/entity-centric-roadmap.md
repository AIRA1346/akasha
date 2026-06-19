# Entity-Centric 로드맵 — 단계별 진행 SSOT

> **상태:** Wave 1~5 ✅ MVP · **Phase A/B UX** ✅ · dogfood ⏳ (구현 완료 후)  
> **갱신:** 2026-06-19  
> **철학:** [entity-type-philosophy.md](../policy/entity-type-philosophy.md)  
> **실행:** [entity-centric-evolution-plan.md](entity-centric-evolution-plan.md)

---

## 1. 진행 원칙

| # | 원칙 |
|---|------|
| G1 | **문서·검토 → Gate → 코드** — Exit checklist green 전 착수 금지 |
| G2 | **한 Wave = 한 PR theme** — scope creep 금지 |
| G3 | **Breaking migration 없음** — lazy upgrade only |
| G4 | **Work-first UI** — Person/Concept UI는 Wave 4 |
| G5 | 신규 Entity Type — [entity-type-philosophy.md](../policy/entity-type-philosophy.md) §6.1 검증 |

---

## 2. 단계별 상태 (한 장)

| Step | Wave | 목표 | 설계 | 검토 | 코드 | Gate |
|:----:|------|------|:----:|:----:|:----:|:----:|
| **0** | W0 | Entity SSOT 문서 | ✅ | ✅ | — | ✅ |
| **1** | W1 | Work Tier 1.5 catalog | ✅ | ✅ | ✅ | 🟡 |
| **2** | W2 | Vault frontmatter v2 | ✅ v1 | ✅ | ✅ | 🟢 |
| **3** | W3 | Timeline · journal UX | ✅ v1 | ✅ | ✅ | 🟡 |
| **4** | W4 | Person · Event · Concept | ✅ v1 | ✅ | ✅ | 🟡 |
| **5** | W5 | Connection | ✅ v1 | ✅ | ✅ | 🟡 |
| **6** | W6 | Memory Core PoC | 📋 | ⬜ | ⬜ | ⬜ |

**현재 포커스:** Phase B Fusion type 섹션 · W4.2 Place/Org · ADR-013 ✅ · dogfood는 구현 완료 후 1회

---

## 3. Step 1 — Wave 1 Gate (🟡)

| # | 작업 | 문서 | 상태 |
|---|------|------|:----:|
| 1.1 | Exit review | [wave1-exit-review.md](wave1-exit-review.md) | ✅ |
| 1.2 | Dogfood checklist | [wave1-dogfood-checklist.md](wave1-dogfood-checklist.md) | 📝 |
| 1.3 | R1 upsert 순서 | wave2 spec W2-5 | → W2 |
| 1.4 | policy §10 | wave1-exit-review §3 | ✅ 코드 |

**Gate 통과 조건:** 1.2 실행 1회 · friction 0건 또는 W2 spec에 반영.

---

## 4. Step 2 — Wave 2 (✅ 코드 Exit)

| # | 작업 | 문서 | 상태 |
|---|------|------|:----:|
| 2.1 | 구현 spec v1 | [wave2-vault-record-spec.md](wave2-vault-record-spec.md) | ✅ |
| 2.2 | Pre-implementation review | [wave2-pre-implementation-review.md](wave2-pre-implementation-review.md) | ✅ |
| 2.3 | EntityFrontmatter API 확정 | wave2 review §4 | ✅ |
| 2.4 | Test fixtures 정의 | wave2 spec §8 | ✅ |
| 2.5 | **코드 W2-0~6** | — | ✅ |
| 2.6 | Exit review | [wave2-exit-review.md](wave2-exit-review.md) | ✅ |

**Exit:** 357 tests · legacy 호환 · R1 upsert fix.

---

## 5. Step 3 — Wave 3 (✅ MVP Exit)

| # | 작업 | 문서 | 상태 |
|---|------|------|:----:|
| 3.1 | Timeline · journal spec | [wave3-timeline-journal-spec.md](wave3-timeline-journal-spec.md) | ✅ |
| 3.2 | Pre-implementation review | [wave3-pre-implementation-review.md](wave3-pre-implementation-review.md) | ✅ |
| 3.3 | **코드 W3-0~J4 MVP** | — | ✅ |
| 3.4 | Exit review | [wave3-exit-review.md](wave3-exit-review.md) | ✅ |
| 3.5 | Workbench timeline tab | wave3 exit R-W3-1 | ⏳ |

**Exit:** 361 tests · 「기록」축 · journal E2E · timeline edit.

---

## 6. Step 4 — Wave 4 (✅ MVP Exit)

| # | 작업 | 문서 | 상태 |
|---|------|------|:----:|
| 4.1 | 7종 Type spec | [wave4-entity-types-spec.md](wave4-entity-types-spec.md) | ✅ v1 |
| 4.2 | Concept vs Person (철학) | [entity-type-philosophy.md](../policy/entity-type-philosophy.md) | ✅ |
| 4.3 | `EntityIdCodec` / catalog 일반화 | wave4 spec §4 | ✅ |
| 4.4 | Person MVP seed | wave4 spec §6 | ✅ (5 seed) |
| 4.5 | **코드 W4-0~9** | — | ✅ |
| 4.6 | Exit review | [wave4-exit-review.md](wave4-exit-review.md) | ✅ |

**Exit:** 373 tests · multi-type catalog · fusion · entity journal · browse filter.

**의존:** Wave 1 (catalog pattern) · Wave 2 (vault v2).

---

## 7. Step 5 — Wave 5 (✅ MVP Exit)

| # | 작업 | 문서 | 상태 |
|---|------|------|:----:|
| 5.1 | Connection spec v1 | [wave5-connection-spec.md](wave5-connection-spec.md) | ✅ |
| 5.2 | Exit review | [wave5-exit-review.md](wave5-exit-review.md) | ✅ |
| 5.3 | **코드 W5-1~4** | — | ✅ |
| 5.4 | Dogfood checklist | [wave5-dogfood-checklist.md](wave5-dogfood-checklist.md) | 📝 |
| 5.5 | ADR-013 Link Index | [ADR-013](../adr/ADR-013-connection-link-index.md) | ✅ |

**Exit:** 389 tests · wiki link parse/index · incoming UI · preview tap.

**Gate:** 5.4 dogfood 1회.

---

## 8. Step 6 — Wave 6 (PoC · non-blocking)

| Step | SSOT | 상태 |
|------|------|:----:|
| W6 | entity-centric-evolution-plan §Wave 6 | 📋 outline only |

---

## 9. 문서 인덱스

| Wave | Spec | Review | 기타 |
|------|------|--------|------|
| 0 | evolution-plan W0 | [wave0-review](entity-centric-wave0-review.md) | ADR-011 |
| 1 | [wave1-spec](wave1-user-catalog-spec.md) | [wave1-exit](wave1-exit-review.md) | [dogfood](wave1-dogfood-checklist.md) |
| 2 | [wave2-spec](wave2-vault-record-spec.md) | [wave2-review](wave2-pre-implementation-review.md) | vault-layout-v2 |
| 3 | [wave3-spec](wave3-timeline-journal-spec.md) | — | |
| 4 | [wave4-spec](wave4-entity-types-spec.md) | [wave4-exit](wave4-exit-review.md) | entity-type-philosophy |
| 5 | [wave5-spec](wave5-connection-spec.md) | [wave5-exit](wave5-exit-review.md) | [dogfood](wave5-dogfood-checklist.md) |
| — | [storage-masterplan](entity-record-storage-masterplan.md) | — | cross-cutting |

---

## 10. 다음 액션 (순서)

```
[지금]  Phase A Entity Discovery strip ✅ · Phase B Fusion sections ✅
        W4.2 Place/Organization catalog ✅ · ADR-013 ✅

[다음]  Wave 6 PoC scope 검토 (optional)
        dogfood 1회 — wave5-dogfood-checklist (구현 완료 후)
```

---

## 11. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v2 — Wave 5 MVP exit · dogfood checklist |
