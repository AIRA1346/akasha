# Sprint 05 Charter — M2 Steam Launch + v1 Polish

> **기간:** 2026-06-10 ~ 출시 전  
> **북극성:** Steam v1 (Windows) Q3 2026  
> **병행:** A5 Scale hold (insert 중단 · O3 **2026-07-09**)

---

## Executive Summary

| 트랙 | 목표 | 상태 |
|------|------|:----:|
| **M2 제품** | Steamworks 스토어·빌드·IAP | **진행** |
| **P1 UX** | 나만의 서재 테마/IAP 통합 | **완료** (2026-06-10) |
| **Q1 품질** | Scale probe 사용자 노출 차단 | **완료** (2026-06-10) |
| **A5 Scale** | hold 관측만 | hold |

---

## Scope

### In scope

1. **M2-A** Release 빌드 + dogfood 수동 검증
2. **M2-B** [m2-steam-store-page.md](m2-steam-store-page.md) — 스토어 copy·스크린샷·태그
3. **M2-C** Steam depot 빌드 업로드 (Partner)
4. **M2-D** IAP SKU 등록 (테마 팩 · 서포터)
5. **P1** 통합 홈 나만의 서재 — 테마 피커 · 필터 숨김 · 배경색
6. **Q1** maintainer Scale probe 카탈로그 필터

### Out of scope

- Registry insert / Scale SD2.6 해제 (O3 전)
- Search index POC
- Discover · Timeline · Recall
- EG namespace · Governance 문서 통합

---

## 완료 기록 (2026-06-10)

| ID | 산출 |
|----|------|
| P1 | `library_theme_picker.dart` · `HomeAppBar` 팔레트 · personal mode 테마 배경 |
| Q1 | `registry_catalog_filter.dart` · search/filter에서 probe 제외 |
| M2-B | `m2-steam-store-page.md` 초안 |

---

## 다음 작업

| 순서 | 작업 | 담당 |
|:--:|------|------|
| 1 | Release 빌드 + 스크린샷 5~8장 촬영 | dev |
| 2 | Steam Store Description 붙여넣기 (ko/en) | **Partner (본인)** |
| 3 | Depot 업로드 · Playtest/Coming Soon | **Partner** |
| 4 | IAP SKU 2종 등록 | **Partner** |
| 5 | Steam IAP 코드 연동 (`purchaseCosmetic`) | dev (M2-D 후반) |
| 6 | O3 checkpoint (7/9) — Scale insert 재개 여부 | data |

---

## 검증

```bash
.\scripts\dogfood_precheck.ps1
.\scripts\build_release.ps1
```

Gate: `flutter test` · `ci_registry_check` green 유지.

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | Sprint 05 Charter — M2 + P1/Q1 착수 |
