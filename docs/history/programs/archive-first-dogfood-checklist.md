# Archive-First Dogfood Checklist — R5 Gate

> **목적:** Archive-First R1~R3 Exit Gate · Wave 5 Connection E2E 포함  
> **갱신:** 2026-06-19  
> **선행:** [archive-first-realignment-plan.md](archive-first-realignment-plan.md) **R1 코드 Exit**  
> **대체:** [wave5-dogfood-checklist.md](wave5-dogfood-checklist.md) (Wave 4 catalog-first — **legacy**)

---

## 환경

| 항목 | 값 |
|------|-----|
| 커밋 | R1 Exit 커밋 이상 |
| 볼트 | 테스트용 Sanctum 폴더 (`works/` · `entities/` · `catalog/`) |
| 선행 | R1: Person 추가 기본 `.md` · UI 「catalog」 0건 |

---

## 시나리오 A — Person 아카이브 (Archive-First 핵심)

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| A1 | Fusion → 직접 추가 → Person → 「나츠키 스바루」 | **기본** `entities/person/나츠키 스바루.md` 생성 | ☐ | catalog-only ❌ |
| A2 | SnackBar / 피드백 | 「**아카이브에 추가됨**」 (catalog ❌) | ☐ | |
| A3 | Entity Sheet | journal 편집 가능 | ☐ | |
| A4 | `catalog/user_entities.json` | `pe_u_*` 존재 (배경) | ☐ | 사용자 UI 노출 ❌ |
| A5 | 기록 → Entity 탭 | 나츠키 스바루 표시 | ☐ | R2: 서재 optional |
| A6 | Discovery strip | archived Person tile (journal 있는 것만) | ☐ | R2 |

---

## 시나리오 B — Work → Person 링크 · navigate (Wave 5)

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| B1 | A1 Person 아카이브 완료 | `pe_u_*` in frontmatter | ☐ | |
| B2 | Work journal 본문 `[[pe_u_xxx\|작가]]` · 저장 | `.md` persist | ☐ | |
| B3 | link index rebuild | `.akasha/link_index.json` | ☐ | |
| B4 | Sanctum 보기 · 링크 tap | Entity Sheet (Person) | ☐ | |
| B5 | «링크한 Record» | work path 1건 | ☐ | |
| B6 | incoming tap | workbench reopen | ☐ | |

---

## 시나리오 C — Concept · title-only · catalog-only 예외

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| C1 | **고급** 「이름만 등록」→ Concept `Tiger` | catalog only · `.md` 없음 | ☐ | 기본 flow ❌ |
| C2 | Fusion hit Tiger | 「**아카이브되지 않음**」+ 「아카이브하기」 CTA | ☐ | R1-5 |
| C3 | Work 본문 `[[Tiger]]` · Tiger **아카이브 후** | titleOnly resolve → Entity Sheet | ☐ | |
| C4 | sameDay (W5-5) | Entity Sheet «같은 날 기록» | ☐ | optional |

---

## 시나리오 D — 회귀

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| D1 | Work 직접 추가 | `.md` + workbench (기존) | ☐ | |
| D2 | 일반 markdown `[url](https://…)` | 외부 링크 정상 | ☐ | |
| D3 | code block 내 `[[pe_u_xxx]]` | index **미포함** | ☐ | |
| D4 | Browse Work 그리드 | Person 포스터 tile **없음** | ☐ | Work-first |
| D5 | UI grep 「catalog」 user-facing | **0건** | ☐ | R1-3 |

---

## Friction log

| ID | 심각 | 관찰 | Phase 이관 |
|----|:----:|------|------------|
| F1 | | | |
| F2 | | | |

---

## Gate (R5)

- [ ] A1~A6 Pass (Archive-First Person)
- [ ] B1~B6 Pass (Connection)
- [ ] C2 Pass (catalog-only CTA)
- [ ] D5 Pass (카피)
- [ ] Friction 0건 **또는** R1~R3 backlog spec 반영

**통과 시:** [entity-centric-roadmap.md](entity-centric-roadmap.md) Wave 4~5 Gate 🟢 검토 · Wave 6 착수 가능.

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Archive-First R5 dogfood · wave5 checklist supersede |
