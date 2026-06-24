# AKASHA `tool/` — 운영 스크립트 인덱스

> **원칙:** 일상·CI에서 쓰는 스크립트는 `tool/` 루트에 둡니다.  
> 일회성 배치·완료된 마이그레이션은 `archive/`·`migrations/`로 옮기는 것을 권장합니다 (경로 변경 시 이 README를 갱신).

## 일상 운영 (active)

| 스크립트 | 용도 |
|----------|------|
| `preflight_check.dart` | registry 변경 후 4종 gate 일괄 |
| `ci_registry_check.dart` | CI — 레지스트리·프랜차이즈·포스터 denylist |
| `quality_gate.dart` | 품질 게이트 (`--strict`, `--release`, `--locale-minimum`) |
| `registry_builder.dart` | 샤드 빌드 · `--sync-assets` · `--bundle-eager-only` |
| `dedupe_linter.dart` | 중복 작품 검사 |
| `catalog_scale_baseline.dart` | 번들 크기·15MB 게이트 |
| `coverage_dashboard.dart` | titles_ko/en 커버리지 리포트 |
| `sw1_a_validation.dart` | 검색 Recall@10 검증 |
| `pre_insert_dedupe_gate.dart` | insert 전 dedupe |
| `apply_catalog_contributions.dart` | 카탈로그 기여 import |
| `franchise_linter.dart` | 프랜차이즈 그룹 검증 |

**빠른 시작**

```bash
dart run tool/preflight_check.dart
dart run tool/ci_registry_check.dart
dart run tool/registry_builder.dart --sync-assets --bundle-eager-only
```

## Discovery (`tool/discovery/`)

Wikidata·trial 채널 등 **카탈로그 확장** 배치. SSOT: `scripts/discovery_batch.ps1`

| 예시 | 용도 |
|------|------|
| `discovery/wikidata_ko_trial.dart` | wikidata_ko 채널 trial |
| `discovery/trial_apply.dart` | trial 적용·merge |

## 마이그레이션 (`migrations/` — 정리 예정)

v3→v4 등 **스키마 전환** 스크립트. 전환 완료 후 `archive/`로 이동.

| 스크립트 | 비고 |
|----------|------|
| `migrate_registry_v3.dart` | v3 monolithic → 샤드 |
| `migrate_shards_v3_to_v4_hash.dart` | v4 해시 샤딩 |
| `migrate_wk_pad9.dart` | wk_ ID 패딩 |
| `sync_legacy_works_registry.dart` | 구 works_registry 동기화 |
| `migrate_manga_to_webtoon.dart` | 카테고리 마이그레이션 |

## 아카이브 (`archive/` — 정리 예정)

완료된 스프린트·실험 배치. **새 작업에 사용하지 마세요.**

| 패턴 | 예시 |
|------|------|
| `seed_expansion_batch*` | 시드 확장 배치 5~7 |
| `coverage_sprint_*` | 커버리지 스프린트 |
| `a5_scale_*` | 5k 스케일 관측·supply |
| `fix_batch5_posters.dart` | 일회성 포스터 수정 |

## 유틸·정책

| 스크립트 | 용도 |
|----------|------|
| `data_policy_linter.dart` | Fact-only 정책 |
| `poster_url_policy.dart` | 포스터 URL 정책 |
| `search_index_validation.dart` | search_index 검증 |
| `wk_id_utils.dart` | wk_ ID 헬퍼 (다른 스크립트에서 import) |

## CI에서 호출되는 경로

`.github/workflows/flutter_ci.yml`:

- `tool/quality_gate.dart --strict`
- `tool/ci_registry_check.dart`
- `tool/catalog_scale_baseline.dart --strict`

**이 세 경로는 폴더 이동 시 CI를 반드시 함께 수정하세요.**
