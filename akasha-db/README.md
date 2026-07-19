# AKASHA-DB

AKASHA 앱의 **글로벌 작품 메타데이터 사전** (Tier 1 Registry).

**현재:** **10,048작** · **v4** — `wk_` 영구 ID · 해시 샤드 (비어 있지 않은 **1,713**개)
**장기:** 세상의 모든 작품 사전 — [VISION.md](../docs/active/VISION.md) · [CURRENT_STATE.md](../docs/active/CURRENT_STATE.md)

## 구조 (v4 — 해시 샤딩)

> 정책: [akasha-db-policy.md](../docs/history/policy/akasha-db-policy.md) · 스키마: [SCHEMA.md](SCHEMA.md) · 패키징: [ADR-015 full local bundle](../docs/architecture/ADR-015-full-local-registry-bundle.md)

```
akasha-db/
├── manifest.json         # 샤드 카탈로그 (sha256 · entryCount)
├── search_index.json     # 경량 검색 인덱스 (자동 생성)
├── id_registry.json      # wk_ 발급 대장
├── legacy_aliases.json   # 구 슬러그 work_id → wk_ 매핑
├── franchise_groups.json # IP 1카드 프랜차이즈 그룹
├── works_registry.json   # (레거시) v1 단일 JSON — 하위 호환용
├── contributions/        # add/fix 기여 큐 (status.json)
└── shards/{category}/{hh}.json   # hash(wk_)%256 — manga·animation·game·book·movie·drama·webtoon
```

> **v4:** `wk_000000042`(9자리 불변 ID) · `titles` / `aliases` / `externalIds` / `searchTokens`.
> **v1 Fact only:** `posterPath`·`description` **금지** — Sanctum vault만 ([POSTER_POLICY.md](POSTER_POLICY.md)).

구 슬러그 ID(`sub_manga_one-piece_1997` 등)는 `legacy_aliases.json`으로만 해석 — 신규 발급 금지.

**API bulk 금지** — 확장은 수동 PR + (장기) Registry Pipeline + 사용자 직접 등록.

## 앱 동기화 (production)

**Production read:** Git source → 결정적 full-bundle builder → 앱 asset (`BundledRegistrySource` only).
production 앱은 registry CDN/remote fallback을 사용하지 않는다 ([ADR-015](../docs/architecture/ADR-015-full-local-registry-bundle.md) · [CURRENT_STATE.md](../docs/active/CURRENT_STATE.md)).

공개 replica(미래 provider 검증·독립 데이터 배포용, production dependency 아님):

```
https://akasha-db.pages.dev/
```

**Write (Git):** 이 저장소 `main` — Pages 배포는 보존하되 앱은 CDN으로 fallback하지 않음.

## 유지보수

```bash
# akasha 앱 루트에서 — source/staging 갱신
dart run tool/registry_builder.dart

# production asset 번들 (full local bundle)
dart run tool/registry_bundle_builder.dart --bundle-all --source-rev <rev> ...
dart run tool/ci_registry_check.dart
```

[CONTRIBUTING.md](CONTRIBUTING.md) · [POSTER_POLICY.md](POSTER_POLICY.md) · [canonicalization-policy.md](../docs/history/policy/canonicalization-policy.md)
