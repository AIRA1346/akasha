# 카탈로그 기여 (User Contributions)

유저·운영자 제안은 **GitHub akasha-db 안**에서만 상태를 관리합니다 (서버비 0원).  
앱은 Cloudflare CDN으로 `contributions/status.json` 만 **읽기** (v2+).

> 장기 로드맵: [docs/catalog-contribution-roadmap.md](../../docs/catalog-contribution-roadmap.md) · [docs/contribution-model-strategy.md](../../docs/contribution-model-strategy.md)

## 두 파이프라인

| | Contribution (이 폴더) | Catalog Expansion (장기) |
|--|------------------------|---------------------------|
| 역할 | 유저 수정·소량 추가 **보조** | 운영자·AI **대량** 후보 |
| 병목 | 검수량 (유저 多 → 큐 폭발) | **작품 확보 속도** |

## 디렉터리 (GitHub = Source of Truth)

```
contributions/
  status.json              ← 앱 CDN poll (id → status, path)
  add/
    pending/ | accepted/ | rejected/ | merged/
  fix/
    pending/ | accepted/ | rejected/ | merged/
```

레거시 `inbox/` 는 사용하지 않습니다.

## status 생명주기

| status | 폴더 | 의미 |
|--------|------|------|
| `submitted` | pending | 앱 export · import 직후 |
| `ai_verified` | pending | AI 검증 통과 (confidence 부여, v3) |
| `accepted` | accepted | 운영자 승인 |
| `rejected` | rejected | 반려 (`statusNote` 권장) |
| `merged` | merged | 샤드 반영 완료 |

## 앱 → Maintainer 흐름

```
앱 제안 (status: submitted)
  → 로컬 큐 → bundle v2 export
  → apply_catalog_contributions --import
  → contributions/{add|fix}/pending/{id}.json
  → status.json entries 갱신
  → 검수 → 폴더 이동 + status 변경
  → 샤드 merge → merged
```

## JSON (제안 1건 · bundle v2)

```json
{
  "id": "contrib_abc123",
  "kind": "fixWork",
  "status": "submitted",
  "createdAt": "2026-06-08T12:00:00.000Z",
  "fixWork": {
    "targetWorkId": "wk_000000329",
    "issue": "포스터가 다른 작품",
    "fields": { "posterPath": "https://...", "releaseYear": 2016 }
  }
}
```

```json
{
  "version": 2,
  "exportedAt": "...",
  "appVersion": "1.0.0",
  "contributions": [ { "...": "..." } ]
}
```

## status.json (CDN)

```json
{
  "version": 1,
  "generatedAt": "2026-06-08T12:00:00.000Z",
  "entries": {
    "contrib_abc123": {
      "status": "submitted",
      "kind": "fixWork",
      "path": "contributions/fix/pending/contrib_abc123.json",
      "updatedAt": "2026-06-08T12:00:00.000Z"
    }
  }
}
```

앱 URL (예): `https://raw.githubusercontent.com/AIRA1346/akasha-db/main/contributions/status.json`

## Maintainer 명령

```bash
cd ..   # akasha 앱 루트
dart run tool/apply_catalog_contributions.dart --validate bundle.json
dart run tool/apply_catalog_contributions.dart --import bundle.json
```

## 구현 순서

1. ✅ **status** + 폴더 골격 + bundle v2  
2. ⏳ contribution 구조 커밋  
3. ⏳ add/fix 운영 분리 (이미 폴더 분리됨 — Issue·SLA 분리)  
4. ⏳ AI Validation Pipeline  
5. ⏳ Catalog Expansion Pipeline  

## 정책

- [POSTER_POLICY.md](../POSTER_POLICY.md)
- [canonicalization-policy.md](../../docs/canonicalization-policy.md)
- API bulk Git 저장 금지 — Expansion 도 **후보·검수**만
