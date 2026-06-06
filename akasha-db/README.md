# AKASHA-DB

AKASHA 앱의 **글로벌 작품 메타데이터 사전** (Tier 1 Registry).

## 구조

```
akasha-db/
├── manifest.json         # 샤드 카탈로그
├── search_index.json     # 경량 검색 인덱스 (자동 생성)
├── legacy_aliases.json   # 구 work_id 호환
└── shards/
    ├── manga/
    ├── animation/
    ├── game/
    ├── book/
    ├── movie/
    └── drama/
```

## 앱 동기화

앱은 다음 base URL에서 파일을 내려받습니다:

```
https://raw.githubusercontent.com/AIRA1346/akasha-db/main/
```

동기화 대상: `manifest.json` → `search_index.json` → `eager` 샤드 → (검색 시) 온디맨드 샤드

## 유지보수

```bash
# akasha 앱 루트에서
dart run tool/registry_builder.dart --sync-assets
```

자세한 규칙: [SCHEMA.md](SCHEMA.md) · [CONTRIBUTING.md](CONTRIBUTING.md)
