# Entity-Centric 로드맵 — 단계별 진행 SSOT

> **상태:** Wave 1 ✅ 코드 · Wave 2~4 **설계 진행 중** · 코드 Gate 전  
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
| **2** | W2 | Vault frontmatter v2 | ✅ v1 | ✅ | ⬜ | 🟡 |
| **3** | W3 | Timeline · journal UX | ✅ v1 | ⬜ | ⬜ | ⬜ |
| **4** | W4 | Person · Event · Concept | ✅ v1 | ⬜ | ⬜ | ⬜ |
| **5** | W5 | Connection | 📋 | ⬜ | ⬜ | ⬜ |
| **6** | W6 | Memory Core PoC | 📋 | ⬜ | ⬜ | ⬜ |

**현재 포커스:** Step 1 Gate 마무리 → Step 2 검토 완료 → Step 2 코드

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

## 4. Step 2 — Wave 2 (🔄 설계)

| # | 작업 | 문서 | 상태 |
|---|------|------|:----:|
| 2.1 | 구현 spec v1 | [wave2-vault-record-spec.md](wave2-vault-record-spec.md) | ✅ |
| 2.2 | Pre-implementation review | [wave2-pre-implementation-review.md](wave2-pre-implementation-review.md) | ✅ |
| 2.3 | EntityFrontmatter API 확정 | wave2 review §4 | ✅ |
| 2.4 | Test fixtures 정의 | wave2 spec §8 | ✅ |
| 2.5 | **코드 W2-0~6** | — | ⬜ Gate 후 |

**Gate 통과 조건:** 2.2 판정 🟢 · P0-W2 전부 결정 · Wave 1 regression plan.

---

## 5. Step 3 — Wave 3 (설계)

| # | 작업 | 문서 | 상태 |
|---|------|------|:----:|
| 3.1 | Timeline · journal spec | [wave3-timeline-journal-spec.md](wave3-timeline-journal-spec.md) | ✅ v1 |
| 3.2 | Phase 4.4b Entity link UI | wave3 spec §5 | 📝 |
| 3.3 | Home 「기록」축 | wave3 spec §6 | 📝 |
| 3.4 | **코드** | — | ⬜ W2 Exit 후 |

**의존:** Wave 2 (frontmatter v2 · ArchiveRecord round-trip).

---

## 6. Step 4 — Wave 4 (설계)

| # | 작업 | 문서 | 상태 |
|---|------|------|:----:|
| 4.1 | 7종 Type spec | [wave4-entity-types-spec.md](wave4-entity-types-spec.md) | ✅ v1 |
| 4.2 | Concept vs Person (철학) | [entity-type-philosophy.md](../policy/entity-type-philosophy.md) | ✅ |
| 4.3 | `EntityIdCodec` / catalog 일반화 | wave4 spec §4 | 📝 |
| 4.4 | Person MVP seed (Wikidata) | wave4 spec §6 | 📝 |
| 4.5 | **코드** | — | ⬜ W1+W2 Exit 후 |

**의존:** Wave 1 (catalog pattern) · Wave 2 (vault v2).

---

## 7. Step 5~6 — Connection · Core

| Step | SSOT | 상태 |
|------|------|:----:|
| W5 | entity-centric-evolution-plan §Wave 5 | 📋 outline only |
| W6 | entity-centric-evolution-plan §Wave 6 | 📋 non-blocking |

---

## 8. 문서 인덱스

| Wave | Spec | Review | 기타 |
|------|------|--------|------|
| 0 | evolution-plan W0 | [wave0-review](entity-centric-wave0-review.md) | ADR-011 |
| 1 | [wave1-spec](wave1-user-catalog-spec.md) | [wave1-exit](wave1-exit-review.md) | [dogfood](wave1-dogfood-checklist.md) |
| 2 | [wave2-spec](wave2-vault-record-spec.md) | [wave2-review](wave2-pre-implementation-review.md) | vault-layout-v2 |
| 3 | [wave3-spec](wave3-timeline-journal-spec.md) | — | |
| 4 | [wave4-spec](wave4-entity-types-spec.md) | — | entity-type-philosophy |
| — | [storage-masterplan](entity-record-storage-masterplan.md) | — | cross-cutting |

---

## 9. 다음 액션 (순서)

```
[지금]  Step 1.2 dogfood checklist 작성 ✅
        Step 2.2 wave2 pre-implementation review ✅
        Step 3.1 wave3 spec 초안 ✅
        Step 4.1 wave4 spec 초안 ✅

[다음]  Step 2.2 P0 결정 확정 → Wave 2 Gate 🟢
        Step 1.2 dogfood 1회 (사용자)

[그다음] Wave 2 코드 W2-0~6
```

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — 단계별 로드맵 SSOT |
