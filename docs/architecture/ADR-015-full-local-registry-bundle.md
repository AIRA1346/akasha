# ADR-015: 작품 레지스트리 전체 로컬 번들

> **상태:** Accepted (2026-07-18)  
> **대체:** [ADR-010: App Bundle — Eager Shards Only](../history/adr/ADR-010-bundle-eager-only.md)  
> **구현 단계:** Phase 0–2 완료

## Context

ADR-010은 앱 크기 증가를 제한하기 위해 eager shard만 동봉하고 나머지는 disk
cache 또는 CDN에서 가져오도록 결정했다. 현재 작품 레지스트리는 10,048개 작품,
v4 JSON shard 1,713개이며, 전체 shard의 패키징 증가량은 허용된 release 예산
안에 있다. 반면 검색 index와 CDN shard의 release가 달라질 수 있는 구조는 오프라인
동작과 데이터 provenance를 불명확하게 만든다.

## Decision

- production 작품 DB source는 고정 source revision에서 생성한 **전체 bundled
  registry**다.
- JSON v4 hash shard 구조와 현재 category search index를 유지한다.
- 앱 asset에는 manifest가 선언한 전체 1,713개 shard를 포함한다.
- 앱 시작 시에는 manifest, search metadata, eager shard만 읽고 전체 shard를 한꺼번에
  메모리에 올리지 않는다. 상세 레코드는 기존 lazy shard read를 유지한다.
- UI/domain 경계인 `RegistryPort`는 유지한다.
- 미래 remote source는 동일한 release 단위 provenance와 검증을 갖춘 optional
  provider로 격리한다. 파일별 bundle→remote 혼합 fallback은 정본 모델로 사용하지
  않는다.
- bundle 생성은 `akasha-db`를 읽기만 하는 별도 builder가 담당한다. source manifest와
  search index를 재생성하는 데이터 작업과 release bundle 생성은 분리한다.
- bundle root/search manifest에는 같은 `releaseId`, `sourceRevision`,
  `schemaVersion`, `bundleMode`를 기록한다. `generatedAt`은 source 값을 보존하고
  wall clock을 사용해 bundle만 다시 생성하지 않는다.
- bundle-only 첫 release에서는 사용자 Vault가 아니라 registry disk cache와 legacy
  registry cache만 한 번 무효화한다. Phase 2 migration은
  `<ApplicationDocuments>/registry_cache/**`, `local_works_registry.json`, registry 전용
  sync/URL preference만 삭제하고, 성공 flag로 멱등성을 보장한다.

## Phase boundary

Phase 0–1은 baseline, strict gate, 결정적 full-bundle builder, release/CI 검증을
구현했다. Phase 2는 `RegistrySource`를 도입하고 production dependency graph에서 remote
sync, CDN fallback, registry cache read/write, sync UI를 제거했다. 검색·browse·category·상세
조회는 `BundledRegistrySource` 하나만 사용한다. 번들 누락·JSON 오류·manifest/SHA·schema·
provenance 오류는 typed exception으로 보고하며 remote로 우회하지 않는다.

Cloudflare Pages/CDN 설정과 외부 데이터 서비스는 이 결정만으로 삭제하지 않는다.
독립 source 배포나 미래 remote provider 검증에 필요할 수 있으므로 운영 중단은 별도
결정으로 다룬다.

## Bundle allowlist

포함 대상은 다음으로 제한한다.

- `manifest.json`
- `search_index/manifest.json`과 선언된 category search index
- 현재 runtime master fallback인 `search_index.json`
- `legacy_aliases.json`, `franchise_groups.json`
- root manifest가 선언하고 선택한 mode에 해당하는 shard

`.git`, `pipeline`, schema 문서, migration 도구, `id_registry.json`,
`works_registry.json`과 기타 source-only 파일은 앱 bundle에 포함하지 않는다.

## Scale gate

현재 release baseline은 작품 10,048개, shard 1,713개, eager shard 53개, schema v4다.
현재 release 수치는 검토 후 명시적으로 갱신할 수 있으며, architecture hard gate와
분리한다.

- 작품 50,000개 초과
- v4 category shard 1,792개 초과
- registry bundle 64 MiB 초과
- master search index 32 MiB 초과

hard gate를 넘으면 search representation 재설계와 remote source 또는 별도 data pack을
재검토한다. 이 ADR은 SQLite나 단일 archive 또는 data pack을 현재 도입하지 않는다.

## Consequences

전체 작품 검색과 상세 열기는 네트워크 없이 동작한다. 패키지와
Steam depot 크기는 증가하지만 JSON shard 단위 patch locality는 유지된다. 데이터
release provenance와 source/bundle 경계가 명확해지는 대신, 데이터 변경은 source
commit과 결정적 bundle 생성·검증 순서를 지켜야 한다.
