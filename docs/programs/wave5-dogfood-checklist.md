# Wave 5 Dogfood Checklist — Connection E2E

> **상태:** **legacy** — Wave 4 **catalog-first** Add flow 기준  
> **갱신:** 2026-06-19  
> **대체 SSOT:** [archive-first-dogfood-checklist.md](archive-first-dogfood-checklist.md) (R5 Gate · R1 후 실행)  
> **상위:** [wave5-exit-review.md](wave5-exit-review.md)

> ⚠️ A1 「catalog에 Person 추가 · journal opt-in」은 [Archive-First UX debt](wave4-exit-review.md#4-known-ux-debt--archive-first-r1-대상)입니다.  
> dogfood는 **R1 Exit 후** `archive-first-dogfood-checklist.md`로 실행하세요.

---

## 환경

| 항목 | 값 |
|------|-----|
| 커밋 | `e0fefd3` 이상 |
| 볼트 | 테스트용 폴더 (works/ · entities/ · catalog/) |
| 선행 | Person/Concept catalog 1건씩 + work journal 1건 |

---

## 시나리오 A — Work → Person 링크 · navigate

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| A1 | catalog에 Person 추가 (`pe_u_*`) · journal opt-in | `entities/person/*.md` | ☐ | **→ R1: `.md` 기본** |
| A2 | Work journal 본문에 `[[pe_u_xxx\|작가]]` 작성 · 저장 | `.md` persist | ☐ | |
| A3 | 볼트 갱신 후 (또는 재시작) | `.akasha/link_index.json` 생성 | ☐ | |
| A4 | Sanctum **보기** 탭 · 링크 tap | Person journal dialog | ☐ | |
| A5 | dialog «링크한 Record» | work path 1건 표시 | ☐ | |
| A6 | incoming tap | workbench 해당 work 열림 | ☐ | |

---

## 시나리오 B — Concept title-only

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| B1 | catalog Concept `Tiger` (별칭 호랑이) | `co_u_*` | ☐ | |
| B2 | Work 본문 `[[Tiger]]` | titleOnly link | ☐ | |
| B3 | 보기 tap | Tiger entity dialog | ☐ | |

---

## 시나리오 C — 회귀

| # | 단계 | 기대 | Pass | 메모 |
|---|------|------|:----:|------|
| C1 | 일반 markdown `[url](https://…)` | 외부 링크 정상 | ☐ | |
| C2 | code block 내 `[[pe_u_xxx]]` | index **미포함** | ☐ | |
| C3 | Wave 4 Browse Entity filter | Person/Concept 목록 정상 | ☐ | |

---

## Friction log

| ID | 심각 | 관찰 | Wave 이관 |
|----|:----:|------|-----------|
| F1 | | | |
| F2 | | | |

---

## Gate

- [ ] **superseded** — [archive-first-dogfood-checklist.md](archive-first-dogfood-checklist.md) 사용

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 5 Connection dogfood |
| 2026-06-19 | **v1.1** — legacy 표시 · Archive-First checklist supersede |
