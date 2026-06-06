# AKASHA Registry Schema (v2)

## work_id 마스터 규칙

```
{domain}_{category}_{identifier}_{releaseYear}
```

| 세그먼트 | 값 |
|----------|-----|
| domain | `sub` (서브컬처) · `gen` (일반문화) |
| category | `manga` · `animation` · `game` · `book` · `movie` · `drama` |
| identifier | ISBN · `appid{숫자}` · 슬러그 · `custom_{token}` |
| releaseYear | 4자리 연도 (선택이지만 권장) |

예시:

- `sub_manga_kimetsu-no-yaiba_2016`
- `gen_game_appid1245620_2022`
- `sub_manga_custom_abc123_2026`

## 샤드 파일

경로: `shards/{category}/{shardId}.json`

```json
{
  "sub_manga_one-piece_1997": {
    "workId": "sub_manga_one-piece_1997",
    "title": "원피스",
    "category": "manga",
    "domain": "subculture",
    "creator": "오다 에이이치로",
    "releaseYear": 1997,
    "description": "2~3문장 요약",
    "tags": ["모험", "우정"],
    "posterPath": "https://..." 
  }
}
```

- `posterPath`: 공개 CDN URL 또는 `null` (이미지 파일 업로드 금지)
- map key와 `workId`는 반드시 일치

## manifest.json

샤드 목록과 `eager` 플래그(앱 기본 로드 여부)를 정의합니다.

## search_index.json

경량 검색용 배열. `registry_builder`가 자동 생성합니다.

```json
{
  "workId": "sub_manga_one-piece_1997",
  "title": "원피스",
  "shardId": "manga_O",
  "category": "manga",
  "domain": "subculture",
  "creator": "오다 에이이치로",
  "tags": ["모험"],
  "posterPath": "https://..."
}
```

- `posterPath`: 샤드에 URL이 있을 때만 포함 (lazy 샤드 미로드 시 포스터 fusion용)
- 출처 규칙: [POSTER_POLICY.md](POSTER_POLICY.md)

## legacy_aliases.json

구버전 work_id → 신규 master work_id 매핑.
