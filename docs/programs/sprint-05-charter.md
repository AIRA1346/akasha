# Sprint 05 Charter — M2 Steam + Catalog Growth

> **기간:** 2026-06-10 ~ 출시 전  
> **북극성:** Steam v1 (Windows) Q3 2026 + **글로벌 사전 G1 진입**  
> **확장 SSOT:** [catalog-growth-charter.md](catalog-growth-charter.md) — SD2.6 hold **해제**

---

## Executive Summary

| 트랙 | 목표 | 상태 |
|------|------|:----:|
| **M2 제품** | Steamworks 스토어·빌드·IAP | 진행 |
| **Catalog G1** | 만화 주류 밴드·검색 Gap 축소 | **진행** |
| **P1 UX** | 나만의 서재 테마/IAP | 완료 |
| **Q1 품질** | Scale probe 필터 | 완료 |

---

## Scope

### In scope

1. **M2** Release 빌드 · 스토어 페이지 · depot · IAP
2. **G1-A** Wikidata manga — shadow → trial insert ([sprint-05-manga-expansion.md](sprint-05-manga-expansion.md))
3. **G1-B** Maintainer / Expansion A급 supply (`--max-add 2` · gate)
4. **G1-C** search_index·dedupe 부하 관측 (1k/5k)
5. P1·Q1 (완료)

### Out of scope

- AniList API bulk
- gate 우회 · 무검증 bulk
- Search index **교체 POC** (측정만)
- Discover · Timeline · Recall

---

## 다음 작업

| # | 작업 |
|---|------|
| 1 | `shadow_write --live --channel wikidata_manga` |
| 2 | trial batch insert (100건·gate) |
| 3 | `a5_scale_supply_batch` 재개 |
| 4 | M2 스토어·depot |
| 5 | O8 governance — **매 insert 배치 후** |

---

## 검증

```bash
dart run tool/preflight_check.dart
dart run tool/ci_registry_check.dart
dart run tool/discovery_manifest_check.dart
```

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | Charter — M2 + P1/Q1 |
| 2026-06-10 | **SD2.6 해제** — Catalog Growth In scope · O3 게이트 제거 |
