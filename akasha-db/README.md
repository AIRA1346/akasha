# AKASHA-DB

AKASHA 앱의 **글로벌 작품 메타데이터 사전** (Tier 1 Registry).

누구나 자유롭게 데이터를 추가·수정하여 전 세계 서브컬처 및 대중 문화 작품 메타데이터를 확장할 수 있습니다.

## 구조 (v2 — 샤딩)

```
akasha-db/
├── manifest.json         # 샤드 카탈로그
├── search_index.json     # 경량 검색 인덱스 (자동 생성)
├── legacy_aliases.json   # 구 work_id 호환
├── works_registry.json   # (레거시) v1 단일 JSON — 하위 호환용
└── shards/
    ├── manga/
    ├── animation/
    ├── game/
    ├── book/
    ├── movie/
    └── drama/
```

> **v2 마이그레이션:** 신규 기여는 `shards/` JSON 샤드 방식을 사용합니다. `works_registry.json`은 구버전 앱 호환용으로만 유지됩니다.

현재 시드: **100작품** / 69샤드 (2026-06 batch2 확장). 재생성: `dart run tool/seed_expansion.dart` (이미 반영된 항목은 skip).

## 앱 동기화

앱은 다음 base URL에서 파일을 내려받습니다:

```
https://raw.githubusercontent.com/AIRA1346/akasha-db/main/
```

동기화 순서: `manifest.json` → `search_index.json` → `eager` 샤드 → (검색 시) 온디맨드 샤드

## 유지보수

```bash
# akasha 앱 루트에서
dart run tool/registry_builder.dart --sync-assets
```

자세한 규칙: [SCHEMA.md](SCHEMA.md) · [CONTRIBUTING.md](CONTRIBUTING.md) · [POSTER_POLICY.md](POSTER_POLICY.md)
