# AKASHA Docs

> **갱신:** 2026-06-10 · Registry **430** · [ROADMAP](../ROADMAP.md)

문서는 **루트 7개 + 하위 폴더**로 정리했다. 완료된 스프린트·리뷰·일회성 조사는 **`archive/`** (44건).

---

## 처음 읽는 순서

| # | 문서 | 내용 |
|:-:|------|------|
| 0 | [product-vision.md](product-vision.md) | 제품 북극성 |
| 1 | [../ROADMAP.md](../ROADMAP.md) | 출시 경로 |
| 2 | [project-status-snapshot.md](project-status-snapshot.md) | Gate·Registry **운영 SSOT** |
| 3 | [programs/catalog-growth-charter.md](programs/catalog-growth-charter.md) | **SD2.6 해제** · 병행 확장 SSOT |
| 4 | [programs/sprint-05-charter.md](programs/sprint-05-charter.md) | M2 Steam + Catalog G1 |

---

## 루트 (핵심 SSOT)

| 문서 | 역할 |
|------|------|
| [data-policy.md](data-policy.md) | 데이터 필드·법무 **최상위** |
| [discovery-policy.md](discovery-policy.md) | Discovery 경계 |
| [discovery-source-decision.md](discovery-source-decision.md) | 소스 결정 요약 |
| [policy/discovery-legal-baseline.md](policy/discovery-legal-baseline.md) | **Discovery 법무 SSOT** (코드·ToS 검토) |
| [akasha-db-policy.md](akasha-db-policy.md) | 사전 구축·ID·포스터 |
| [product-vision.md](product-vision.md) | Tier 1/2 제품 방향 |
| [project-status-snapshot.md](project-status-snapshot.md) | 현재 상태 스냅샷 |

---

## 하위 폴더

| 폴더 | 내용 | 대표 문서 |
|------|------|-----------|
| **[programs/](programs/)** | **진행 중** 스프린트·확장 | [catalog-growth-charter](programs/catalog-growth-charter.md) · [sprint-05-manga-expansion](programs/sprint-05-manga-expansion.md) · [m2-steam-store-page](programs/m2-steam-store-page.md) |
| **[policy/](policy/)** | 규격·게이트·**법무** | [discovery-legal-baseline](policy/discovery-legal-baseline.md) · [expansion-tool-grading](policy/expansion-tool-grading.md) |
| **[strategy/](strategy/)** | 장기 성장·아키텍처 | [registry-growth-strategy](strategy/registry-growth-strategy.md) · [data-architecture-redesign](strategy/data-architecture-redesign.md) |
| **[validation/](validation/)** | SW1·URV·search_index 검증 | [global-search-validation-plan](validation/global-search-validation-plan.md) · [universal-registry-validation](validation/universal-registry-validation.md) |
| **[product/](product/)** | 제품 UI 설계 | [my-library-design](product/my-library-design.md) |
| **[adr/](adr/)** | 아키텍처 결정 | [adr/README](adr/README.md) |
| **[archive/](archive/)** | 완료 프로그램·리뷰·감사 | [archive/README](archive/README.md) |

---

## 로컬 운영 도구

```bash
dart run tool/preflight_check.dart
dart run tool/ci_registry_check.dart
dart run tool/a5_scale_governance_observation.dart --apply
dart run tool/discovery_manifest_check.dart
```

---

## 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | IA 재편 — 루트 58→7 |
| 2026-06-10 | **SD2.6 해제** — catalog-growth-charter |
