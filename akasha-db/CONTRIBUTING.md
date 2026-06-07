# AKASHA-DB 기여 가이드

Rune Atelier **자체 작품 사전**을 수동 큐레이션·PR로 확장하는 저장소입니다.

> 마스터 정책: [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)
## 빠른 시작

1. `shards/{category}/` 아래 적절한 샤드 JSON 파일을 수정하거나 새 샤드를 추가합니다.
2. `work_id`는 [SCHEMA.md](SCHEMA.md) 마스터 규칙을 따릅니다.
3. 로컬에서 검증 및 인덱스 재생성:

```bash
cd ../  # akasha 앱 루트
dart run tool/registry_builder.dart --sync-assets
```

4. PR을 엽니다.

## 작품 1건 추가 체크리스트

- [ ] `work_id`가 기존 항목과 중복되지 않음
- [ ] `category` / `domain` enum 값 준수
- [ ] `description`은 2~3문장 요약 (장문 복제 금지)
- [ ] `posterPath`는 **https URL만** (repo·self-hosted 이미지 금지) — [POSTER_POLICY.md](POSTER_POLICY.md)
- [ ] 신규 작품에 **justwatch·anilistcdn** URL 사용 금지 (CI baseline 초과 시 실패)
- [ ] `registry_builder` 검증 통과

## 샤딩 규칙

| 카테고리 | 샤드 네이밍 예 |
|----------|----------------|
| manga | `manga_K.json` (슬러그 첫 글자) |
| animation | `animation_2020s.json` (연대) 또는 `animation_F.json` |
| game | `game_A.json` 또는 `game_steam_124.json` |
| book / movie / drama | 제목 슬러그 첫 글자 |

한 샤드 파일이 **~500KB**를 넘기면 분할 PR을 권장합니다.

## 저작권

- 메타데이터(제목, 작가, 태그, **자체 1~2문장 요약**)만 기록합니다.
- 포스터는 **외부 URL 링크 참조**만 (`posterPath`). 이미지 파일을 이 레포에 커밋하지 마세요.
- AniList/TMDB API로 메타·이미지를 **자동 수집**하지 마세요.
