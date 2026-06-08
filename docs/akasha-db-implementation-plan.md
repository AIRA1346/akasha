# AKASHA 사전(akasha-db) 구현 계획

> 마스터 정책: [akasha-db-policy.md](akasha-db-policy.md)  
> **v4 마이그레이션 (Steam 게이트):** [v4-migration-plan.md](v4-migration-plan.md) ← **현재 우선**  
> 기준일: 2026-06-08

---

## 목표

1. **v4 런타임** — Steam 출시 전 `wk_` ID + 해시 샤딩 + dedupe CI 완료  
2. **자체 DB** — API bulk 없이 엄선 카탈로그 유지·확장  
3. **포스터** — URL 링크만 (self-hosted ❌), CI denylist  
4. **앱** — 번들·캐시 무효화 · v4 loader/sync

---

## Phase 1 — 정책·문서 (완료)

| 작업 | 상태 |
|------|------|
| `docs/akasha-db-policy.md` 마스터 정책 | ✅ |
| `catalog-ownership.md` 포스터 문구 정렬 | ✅ |
| `POSTER_POLICY.md` / `SCHEMA.md` 링크 | ✅ |
| `docs/akasha-db-implementation-plan.md` (이 문서) | ✅ |
| README / ROADMAP / akasha-db README 링크 | ✅ |

---

## Phase 2 — CI·빌드 도구

| 작업 | 파일 | 상태 |
|------|------|------|
| 포스터 denylist 공통 모듈 | `tool/poster_url_policy.dart` | ✅ |
| CI: justwatch·self-hosted 즉시 실패 | `tool/ci_registry_check.dart` | ✅ |
| CI: `anilistcdn` baseline 초과 시 실패 | `akasha-db/poster_url_baseline.json` | ✅ |
| registry_builder 포스터 검증 연동 | `tool/registry_builder.dart` | ✅ |
| baseline 갱신 | `dart run tool/ci_registry_check.dart --update-poster-baseline` | 수동 |

**규칙 요약**

- `justwatch` — 카탈로그 전체 0건
- `anilistcdn` — 기존 N건 유지 가능, **N 초과 추가만** CI 실패
- 신규 PR 권장 URL: Steam, Open Library, 공식 홍보, TMDB 등 ([POSTER_POLICY.md](../akasha-db/POSTER_POLICY.md))

---

## Phase 3 — 앱 캐시 무효화

| 작업 | 파일 | 상태 |
|------|------|------|
| 번들 `generatedAt` > 캐시 시 디스크 캐시 삭제 | `registry_shard_loader.dart` | ✅ |
| `WorksRegistry.init()` stale 분기 | `works_registry.dart` | ✅ |
| 원격 sync 후 메모리 레지스트리 재로드 | `registry_sync_service.dart` | ✅ |
| 단위 테스트 | `test/registry_shard_loader_test.dart` | ✅ |

**동작**

```
앱 시작
  → 번들 manifest 로드
  → 캐시 manifest.generatedAt 비교
      → 번들이 더 최신: registry_cache 삭제 (옛 1009작 방지)
      → 캐시가 같거나 더 최신: 캐시 샤드 병합
원격 sync (manifest 변경)
  → 캐시 갱신 후 WorksRegistry.reloadAfterRemoteSync()
```

---

## Phase 4 — README / ROADMAP 정리

| 작업 | 상태 |
|------|------|
| README — 엄선 325작·링크 포스터·정책 링크 | ✅ |
| ROADMAP — ~1,000작·M1 push 구식 항목 수정 | ✅ |
| akasha-db README v3·정책 링크 | ✅ |
| CONTRIBUTING — 정책·신규 포스터 규칙 | ✅ |

---

## Phase 5 — 카탈로그 확장 (애니·만화 우선)

> 상세 계획: [catalog-expansion-plan.md](catalog-expansion-plan.md)  
> **법무:** 메타 직접 작성 · 포스터 URL만 · API bulk·anilistcdn 신규 금지

| 마일스톤 | manga + animation | 총 카탈로그 | 상태 |
|----------|-------------------|------------|------|
| AM1 | 115 → **180** (+45) | **370** | ✅ |
| AM2 | 180 → **220** (+40) | ~410 | 🔲 |
| AM3 | 220 → **250** (+30) | ~450 | 🔲 |

| 작업 | 우선순위 |
|------|----------|
| `seed_expansion_batch5.dart` + 큐레이션 백로그 | **높** |
| `catalog_stats.dart` | ✅ |
| ~~기존 `anilistcdn` URL 교체~~ | ✅ baseline 0 |
| `locale_linter` PR 검증 | 중 |
| `sanitize_borrowed_metadata.dart` 정리 범위 확정 | 낮 |
| 샤드 v3 전량 `migrate_registry_v3` | 중 (신규만 v3 우선) |

---

## Phase v4 — Steam 출시 게이트 (진행 예정)

> **마스터:** [v4-migration-plan.md](v4-migration-plan.md)

| Phase | 핵심 도구 | 상태 |
|-------|-----------|------|
| A | `assign_wk_ids.dart`, `id_registry.json` | ❌ |
| B | `WorkIdCodec`, loader alias | ❌ |
| C | `dedupe_linter.dart` | ❌ |
| D | `migrate_shards_v3_to_v4_hash.dart`, manifest v4 | ❌ |

---

## 검증 명령

```bash
dart run tool/ci_registry_check.dart
dart run tool/registry_builder.dart --sync-assets
.\scripts\dogfood_precheck.ps1
```
