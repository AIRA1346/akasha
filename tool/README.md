# AKASHA `tool/` — 운영 스크립트 인덱스

> **원칙:** 일상·CI에서 쓰는 스크립트는 `tool/` 루트에 둡니다.  
> 일회성 배치·완료된 마이그레이션은 `archive/`·`migrations/`로 옮기는 것을 권장합니다 (경로 변경 시 이 README를 갱신).

## 일상 운영 (active)

| 스크립트 | 용도 |
|----------|------|
| `steam_get_report.dart` | **Admin-only** Steam GetReport evidence (env key; not in client build) |
| `vault_format_validator.dart` | **Vault Format Spec v3 적합성 검증** — `dart run tool/vault_format_validator.dart <vault> [--strict]` (앱 코드 무의존; 명세가 기준) |
| `preflight_check.dart` | registry 변경 후 4종 gate 일괄 |
| `ci_registry_check.dart` | CI — 레지스트리·프랜차이즈·Fact-only 정책 |
| `quality_gate.dart` | 품질 게이트 (`--strict`, `--release`, `--locale-minimum`) |
| `registry_builder.dart` | 샤드 빌드 · `--sync-assets` · `--bundle-eager-only` |
| `dedupe_linter.dart` | 중복 작품 검사 |
| `catalog_scale_baseline.dart` | 번들 크기·15MB 게이트 |
| `coverage_dashboard.dart` | titles_ko/en 커버리지 리포트 |
| `sw1_a_validation.dart` | 검색 Recall@10 검증 |
| `pre_insert_dedupe_gate.dart` | insert 전 dedupe |
| `apply_catalog_contributions.dart` | 카탈로그 기여 import |
| `franchise_linter.dart` | 프랜차이즈 그룹 검증 |

`preflight_check.dart`와 `ci_registry_check.dart`는 상위 스크립트에서 이미
실행한 단계를 재사용할 수 있도록 `--skip-builder`·`--skip-dedupe`를 지원합니다.

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

## 마이그레이션 (`migrations/`)

registry·데이터·Vault의 **완료된 전환** 스크립트. 상세 목록: [`migrations/README.md`](migrations/README.md)

```bash
dart run tool/migrations/migrate_registry_v3.dart --dry-run
```

## 아카이브 (`archive/`)

완료된 스프린트·실험 배치. **새 작업에 사용하지 마세요.** 상세 목록: [`archive/README.md`](archive/README.md)

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
| `strip_tier1_posters.dart` | 금지된 Tier 1 포스터 복구 제거 |
| `search_index_validation.dart` | search_index 검증 |
| `wk_id_utils.dart` | wk_ ID 헬퍼 (다른 스크립트에서 import) |

## CI에서 호출되는 경로

`.github/workflows/registry_check.yml`:

- `tool/preflight_check.dart`
- `tool/ci_registry_check.dart`
- `tool/catalog_scale_baseline.dart --strict`

**이 세 경로는 폴더 이동 시 CI를 반드시 함께 수정하세요.**
