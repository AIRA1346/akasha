# AKASHA 포스터 URL 정책

> 마스터 정책: [docs/akasha-db-policy.md](../docs/akasha-db-policy.md)

AKASHA 레지스트리(`akasha-db`)와 앱은 **이미지 바이너리를 저장·배포하지 않습니다.**  
포스터는 항상 **외부 URL 링크 참조**만 사용합니다. (Steam·앱스토어 배포 정책과 동일)

**self-hosted 금지:** `akasha-db/posters/` 등에 이미지를 커밋하지 않습니다.

## 채택하지 않음

- 구글 이미지 검색 결과를 **자동 수집·등록**하는 방식
- 이 레포 또는 앱 번들에 포스터 파일 커밋·호스팅 (**self-hosted**)
- `posterProvenance` 전수 장부 (v1 필수 아님; `extensions.posterSource` 태그만 선택)
- 출처를 확인하지 않은 임의 핫링크
- **신규 PR:** JustWatch, AniList bulk 파이프라인, `anilistcdn` 등 [금지 CDN](../docs/akasha-db-policy.md#42-v1에서-피할-것)

구글 검색은 **찾기 도구**로만 사용하고, 최종 URL은 아래 티어에 맞는 공식·메타데이터 소스로 **교차 확인**합니다.

## 출처 티어 (우선순위)

| 티어 | 용도 | 허용 CDN 예 |
|------|------|-------------|
| **A** | 공식 홍보·스토어 | Steam `store_item_assets`, Nintendo/eShop 공식 (URL 검증 시) |
| **B** | 작품 매칭 메타 DB | [AniList](https://anilist.co) (만화·애니), [TMDB](https://www.themoviedb.org) (영화·드라마), [IGDB](https://www.igdb.com) (게임), [Open Library](https://openlibrary.org) (도서 ISBN) |
| **C** | 라이선스 명시 위키 | Wikimedia Commons·en.wikipedia **공정 이용** 포스터 (영화 등, URL·라이선스 확인) |
| **—** | 불확실 | `posterPath: null` 유지 (플레이스홀더 표시) |

매체에 맞는 소스를 사용합니다. (예: 만화 작품에 애니 커버 ID 사용 금지)

## 기여자·사용자

- **크라우드 기여**: 샤드 JSON의 `posterPath`에 티어 A~C URL을 **수동 등록**
- **사용자 UGC**: 앱에서 커스텀 URL 또는 vault `posters/` 로컬 경로 허용
- Registry 기본 CDN URL은 vault 마크다운에 **저장하지 않음** (런타임 UI Fusion)

## search_index와 lazy 샤드

`registry_builder`는 유효한 `posterPath`를 `search_index.json`에 복제합니다.  
lazy 샤드가 아직 로드되지 않아도 앱이 포스터 URL을 알 수 있게 하기 위함입니다.

## URL 등록 체크리스트

- [ ] 작품·매체와 일치하는 메타 DB ID로 확인했는가?
- [ ] URL이 `http://` 또는 `https://`로 시작하는가?
- [ ] 앱에서 로드 실패 시 `null`로 되돌릴 수 있는가? (깨진 링크는 PR에서 수정)
- [ ] 불확실하면 `null` — 플레이스홀더가 더 낫습니다

## 앱 동작 요약

- `Image.network`로만 외부 URL 표시 (디스크 다운로드 없음)
- `WorksRegistry.resolvePosterPath(workId)` — 로드된 샤드 → search_index 순으로 해석
- 사용자 지정 `poster:` YAML 값이 registry 기본값보다 우선
