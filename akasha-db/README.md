# AKASHA-DB

AKASHA 앱의 **글로벌 작품 메타데이터 사전** (Tier 1 Registry).

**현재:** Steam v1 엄선 **~410작** · v3 슬러그 샤드  
**장기:** 세상의 모든 작품 사전 — [docs/data-architecture-redesign.md](../docs/data-architecture-redesign.md)

## 구조 (v3 — 샤딩)

> 정책: [docs/akasha-db-policy.md](../docs/akasha-db-policy.md) · 스키마: [SCHEMA.md](SCHEMA.md)

```
akasha-db/
├── manifest.json         # 샤드 카탈로그
├── search_index.json     # 경량 검색 인덱스 (자동 생성)
├── legacy_aliases.json   # 구 work_id 호환 (v4에서 wk_ 매핑 확장)
├── works_registry.json   # (레거시) v1 단일 JSON — 하위 호환용
└── shards/
    ├── manga/
    ├── animation/
    ├── game/
    ├── book/
    ├── movie/
    ├── drama/
    └── webtoon/
```

> **v3:** `titles` / `aliases` / `externalIds` / `posterPath` / `searchTokens`.  
> **v4 (계획):** `wk_` ID · `hash(wk_)%256` 샤드 — 슬러그 샤드 deprecated.

**API bulk 금지** — 확장은 수동 PR + (장기) Registry Pipeline + 사용자 직접 등록.  
포스터: **`posterPath` URL만** (이미지 파일 커밋 금지).

## 앱 동기화

```
https://raw.githubusercontent.com/AIRA1346/akasha-db/main/
```

동기화 순서: `manifest.json` → `search_index.json` → `eager` 샤드 → (검색 시) 온디맨드 샤드

## 유지보수

```bash
# akasha 앱 루트에서
dart run tool/registry_builder.dart --sync-assets
dart run tool/ci_registry_check.dart
```

[CONTRIBUTING.md](CONTRIBUTING.md) · [POSTER_POLICY.md](POSTER_POLICY.md) · [canonicalization-policy.md](../docs/canonicalization-policy.md)
