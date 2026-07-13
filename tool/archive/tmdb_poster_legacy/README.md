# TMDB poster legacy

2026-06-10 Fact-only 전환 전에 사용한 Tier 1 포스터 수집·검증 도구입니다.
현재 제품·Registry pipeline에서는 사용하지 않습니다.

- `externalIds.tmdb` 식별자는 Fact로 계속 허용합니다.
- TMDB API fetch, 포스터 URL 첨부, `posterPath` 저장은 금지됩니다.
- 이 폴더의 코드는 과거 작업 재현용이며 신규 데이터에 실행하지 않습니다.
- `fixtures/tmdb_poster_cache.json`과 `fixtures/poster_url_baseline.json`은
  과거 archive 스크립트의 재현성을 위한 legacy fixture입니다.
