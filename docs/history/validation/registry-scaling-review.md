# Registry Scaling Review

> **질문은 단순하다.**
> "오늘 설계가 402작품에서는 잘 동작하지만, 100만 작품에서도 그대로 동작하는가?"
>
> Discovery는 이미 철학적으로 정당화됐다. 이제 병목은 Discovery가 아니라 **Registry 구조**다.
> 지금은 작품을 더 발견하는 것보다, 발견한 작품을 **10년 동안 담을 그릇**이 충분한지 검증하는 단계다.

이 문서는 **새 코드가 아니라 분석**이다. 구현은 검토 결과 합의 후 별도 단계로 진행한다.

---

## 0. 측정 기준선 (현재, 실측)

| 항목 | 값 | 근거 |
|------|-----|------|
| 등록 작품 수 | **402** | `manifest.json.entryCount` |
| `search_index.json` | **262.5 KB** | 실측 → **약 650 B/작품** |
| `manifest.json` | **74.9 KB** | 331 shard 엔트리 → 약 226 B/shard |
| shard 파일 수 | **331** | `shards/{category}/{hh}.json` (실측) |
| `franchise_groups.json` | **10.3 KB** | 약 30 프랜차이즈 × 2~3 멤버 |
| akasha-db 전체 | **0.78 MB** | shards + index + manifest |
| `.git` 전체 | **4.2 MB** | 누적 history 포함 |

**핵심 설계 상수**

| 영역 | 현재 설계 | 정의 위치 |
|------|-----------|-----------|
| workId | `wk_` + 9자리, 최대 **999,999,999** (~10억) | `wk_id_utils.dart` |
| shard 키 | `sha256(workId)[0] & 0xFF` → 256버킷/카테고리, `shardBits=8` | `registry_hash_utils.dart` |
| 카테고리 수 | 7 (animation·manga·webtoon·game·book·movie·drama) | `registry_builder.dart` |
| shard 이론 상한 | 256 × 7 = **1,792 버킷** | shardBits=8 |
| search_index | **단일 평면 JSON 배열, 앱 시작 시 전량 메모리 적재** | `registry_shard_loader.dart` |
| qualityScore | shard에 저장 안 함, **빌드 시 전량 재계산** | `quality_score_utils.dart` |

---

## 1. 규모별 종합 예측

per-work 비용을 보수적으로 **search_index 600 B/작품, shard 본문 약 1.0 KB/작품**으로 잡았다.
(현재 402작품은 엄선되어 tags/aliases가 풍부 → 실제 평균은 이보다 낮을 수 있으나, 성장 시 풍부해지므로 상향 추정)

| 지표 | 402 (현재) | 10k | 100k | 1M |
|------|-----------|-----|------|-----|
| **search_index.json** | 0.26 MB | ~6 MB | **~60 MB** | **~600 MB** |
| **shard 파일 수** | 331 / 1,792 | ~1,300 | 1,792 (포화) | 1,792 (포화) |
| **평균 작품/shard** | ~1.2 | ~6 | ~56 | **~558** |
| **최대 shard 파일 크기** | ~3 KB | ~10 KB | ~70 KB | **~700 KB** |
| **manifest.json** | 75 KB | ~280 KB | ~400 KB | ~400 KB |
| **quality 재빌드** | <1초 | 수초 | 수십초 | **수~십수분** |
| **franchise_groups** | 10 KB | ~250 KB | ~2.5 MB | **~25 MB** |
| **dedupe_index 메모리** | 미미 | ~수십 MB | ~수백 MB | **~수 GB** |
| **akasha-db 전체** | 0.78 MB | ~20 MB | ~200 MB | **~2 GB** |
| **GitHub 상태** | 여유 | 여유 | ⚠️ 경고대 진입 | ❌ 파일 한계 초과 |

---

## 2. 축별 분석

### 2.1 workId 체계 — ✅ 1M까지 안전

```dart
const wkMaxSequence = 999999999; // wk_000000001 .. wk_999999999
```

- **용량**: 10억까지 수용. 1M은 0.1% 사용에 불과.
- **불변성**: 순번 기반, 재정렬·리해시 불필요. shard 키는 workId 해시에서 파생되므로 **workId가 안 바뀌면 작품 위치도 안 바뀐다.**
- **충돌**: 순번 단조 증가 → 충돌 구조적으로 불가능.
- **10년 관점**: 연 10만 작품 추가해도 100년치 여유.

> **판정: 변경 불필요.** 9자리는 1M·10M·100M 모두 커버한다.

---

### 2.2 shard 분할 — ⚠️ 100k에서 재설계 필요

현재: `sha256(workId)[0] & 0xFF` → 카테고리당 256버킷, 균등 분포.

| 규모 | 카테고리당 평균 | 평가 |
|------|----------------|------|
| 402 | ~1.2작품/shard | 적정 (sparse) |
| 10k | ~6작품/shard | 적정 |
| 100k | **~56작품/shard** | shard 파일 ~70 KB — on-demand 효율 저하 시작 |
| 1M | **~558작품/shard** | shard 1개 로드 = 무관한 558작품 동시 적재 ❌ |

**문제의 핵심**: shardBits=8은 **버킷 수를 256으로 고정**한다. 작품이 늘어도 버킷이 안 늘고 **버킷당 작품 수만 증가**한다. on-demand 샤딩의 목적(필요한 작품만 로드)이 1M에서 무너진다.

**다행인 점**: 코드가 이미 가변 `shardBits`(최대 16비트=65,536버킷)를 지원한다.

```dart
int shardIndexForWorkId(String workId, {int shardBits = defaultShardBits}) {
  ...
  if (shardBits <= 8) return digest.bytes[0] & mask;
  final combined = (digest.bytes[0] << 8) | digest.bytes[1];
  return combined & mask;
}
```

- 100k → `shardBits=12` (4,096버킷/카테고리) 권장 → ~24작품/shard
- 1M → `shardBits=14` (16,384버킷/카테고리) 권장 → ~9작품/shard

**비용**: shardBits 변경 = **전체 리샤딩**(모든 작품 재배치 + manifest 재생성). workId·내용은 불변, 파일 경로만 이동. 이미 `migrate_shards_v3_to_v4_hash.dart` 류의 마이그레이션 패턴이 존재 → 같은 방식 재사용 가능.

> **판정: 10k까지는 그대로. 100k 진입 전 shardBits 상향 마이그레이션 필요.** 구조 자체는 견고(해시 균등), 파라미터만 조정.

---

### 2.3 search_index 구조 — ❌ 가장 큰 병목 (100k 이전 재설계)

**이것이 이번 리뷰의 1순위 리스크다.**

현재 동작 (`registry_shard_loader.dart`):

```dart
static const bundledSearchIndexAsset = 'assets/registry/search_index.json';
List<RegistrySearchIndexEntry> _searchIndex = []; // 전량 메모리 상주
```

- 앱 시작 시 `search_index.json` **전체를 파싱해 메모리에 상주**시킨다.
- shard는 on-demand인데, **search_index는 on-demand가 아니다.**
- 검색은 이 평면 배열을 **선형 스캔**한다 (인덱스 자료구조 없음).

| 규모 | search_index 크기 | 시작 시 파싱·메모리 | 검색(선형 스캔) |
|------|-------------------|---------------------|-----------------|
| 402 | 0.26 MB | 무시 가능 | 즉시 |
| 10k | ~6 MB | 모바일에서 수용 가능 | 수 ms |
| 100k | **~60 MB** | ⚠️ 시작 지연·메모리 압박 | 수십 ms |
| 1M | **~600 MB** | ❌ 모바일 OOM, 시작 불가 | ❌ 매 검색 수백 ms |

**또한 100 MB 단일 파일은 GitHub push가 거부된다 (§2.7).** search_index는 약 **150k 작품**에서 100 MB를 돌파한다 → 운영상 100k가 사실상 상한.

**필요 방향 (구현 아님, 설계 옵션)**:
1. search_index를 **샤드화** (prefix/category별 분할 + 지연 로드)
2. 또는 **전치 인덱스(inverted index)** 토큰→workId 구조로 전환, 검색 시 필요한 포스팅 리스트만 로드
3. 또는 임베디드 검색 엔진(SQLite FTS5 등) 도입 — 단일 파일 DB, 메모리 상주 불요

> **판정: 10k는 안전, 그러나 100k 도달 전 반드시 재설계.** "전량 메모리 적재 + 선형 스캔 + 단일 파일"이라는 3중 가정이 100k에서 동시에 무너진다.

---

### 2.4 qualityScore 계산 — ⚠️ 100k부터 증분화 필요

현재: shard에 score/tier 저장 안 함. `registry_builder`가 **빌드마다 전 작품 재계산** (`computeQualityScore`, O(n)).

| 규모 | 재빌드 시간(추정) | 평가 |
|------|------------------|------|
| 402 | <1초 | 무시 가능 |
| 10k | 수초 | 수용 가능 |
| 100k | 수십초 | CI에서 체감되기 시작 |
| 1M | **수~십수분** | 작품 1개 추가에 전체 재빌드 = 비효율 |

- 계산 자체는 **순수 함수·O(1)/작품**이라 알고리즘은 건전하다. 문제는 **"매번 전량"**이라는 빌드 전략.
- 1M에서 작품 1개 PR이 들어올 때마다 100만 건 재계산 + search_index 전체 재작성은 낭비.

**필요 방향**: 변경된 shard만 재계산하는 **증분 빌드**, 또는 score를 빌드 산출물에 캐시하고 입력 해시가 같으면 스킵.

> **판정: 알고리즘은 1M까지 유효. 빌드 파이프라인을 "전량 재빌드 → 증분 재빌드"로 전환 필요 (100k 시점).**

---

### 2.5 franchise_groups 성장 — ⚠️ 구조적 한계 (수동 큐레이션)

현재: 단일 JSON 맵, **수동 큐레이션**, 멤버 배열. `franchise_linter`가 누락 후보 탐지.

| 규모 | franchise_groups 추정 | 멤버↔그룹 역인덱스 | 평가 |
|------|----------------------|---------------------|------|
| 402 | 10 KB / ~30 그룹 | 미미 | 적정 |
| 10k | ~250 KB | 메모리 OK | 수용 가능 |
| 100k | ~2.5 MB | 전량 로드 부담 시작 | ⚠️ |
| 1M | **~25 MB 단일 파일** | 전량 로드 비현실 | ❌ |

**두 가지 문제**:
1. **물리적**: 단일 파일 → 1M에서 25 MB, 전량 로드·머지 충돌 빈발.
2. **운영적 (더 심각)**: franchise는 **사람이 직접 묶는다.** 작품이 1M이면 프랜차이즈 관계는 수십만 건 — 수동 큐레이션이 **인적으로 불가능**하다. `franchise_linter`는 후보를 제시할 뿐 결정은 사람 몫.

> **판정: 물리 구조는 분할(카테고리/이니셜별)로 해결 가능하나, "수동 큐레이션" 모델 자체가 100k에서 한계.** 프랜차이즈를 **선택적·지연 생성**(검색에서 실제로 충돌할 때만 그룹화)하는 정책 전환이 필요. 1M 전체에 프랜차이즈를 채우려 하지 말 것.

---

### 2.6 externalIds — ✅ 1M까지 안전

현재: 작품당 `{ anilist, steam, tmdb, isbn, ... }` 맵. dedupe는 `source:id` 키로 **해시 버킷** 그룹핑.

```dart
final byExternal = <String, List<_WorkRef>>{};
// key = "${source}:${id}" — O(n) 버킷, 버킷 내부만 pairwise
```

- 작품 내부 필드라 작품 수에 **선형**으로만 증가. 별도 전역 구조 없음.
- dedupe exact-match는 해시 버킷 → 사실상 O(n). O(n²) 아님.
- AKASHA 정체성은 `wk_`이고 externalIds는 **참조**일 뿐 → 외부 ID 폭증해도 모델 불변.

> **판정: 변경 불필요.** externalIds는 1M에서도 선형 비용.

---

### 2.7 alias 검색 + GitHub 저장소 한계

**alias 검색**: aliases·searchTokens는 빌드 시 생성되어 **search_index에 인라인**된다 → 검색 비용은 §2.3 search_index 문제에 **종속**된다. 별도 병목 아님. (1M에서 alias 다국어가 토큰 수를 부풀려 search_index를 더 키운다는 점만 주의 → §2.3 악화 요인.)

**GitHub 한계** (DB가 Git 저장소이므로 물리 상한이 존재):

| GitHub 제약 | 임계치 | 도달 규모 |
|-------------|--------|-----------|
| 단일 파일 push 거부 | **100 MB/파일** | search_index ≈ **150k 작품** |
| 권장 저장소 크기 | < 1 GB | akasha-db ≈ **400k 작품** |
| 경고/성능 저하 | > 5 GB | 1M 시 .git history 누적 포함 위험 |

- **단일 파일 100 MB가 사실상의 1차 하드 리밋이다.** search_index 또는 거대 shard가 먼저 막힌다.
- 1M 작품 = akasha-db 약 2 GB + git history → 일반 Git 저장소로는 부적합.

> **판정: 100 MB 단일 파일 한계가 search_index 재설계(§2.3)를 강제한다. 1M은 Git 단일 저장소 모델 자체를 재고해야 하는 규모 (LFS, 분할 저장소, 또는 비-Git 배포).**

---

## 3. 결론

### 🔴 100만 작품 기준에서 "지금 당장 바꿔야 하는 것"

> 정확히는 "지금 코드를 고치라"가 아니라, **이 가정들이 100k 이전에 깨지므로 100k 도달 전 반드시 해결해야 한다**는 의미. 현재 402에서는 동작하지만 **확장 경로가 막혀 있는** 항목들.

| 우선순위 | 항목 | 깨지는 지점 | 해결 방향 |
|---------|------|------------|-----------|
| **P0** | **search_index 단일 파일·전량 메모리·선형 스캔** (§2.3) | ~100k (메모리), ~150k (GitHub 100MB) | 샤드화 / inverted index / SQLite FTS |
| **P1** | **shardBits=8 고정** (§2.2) | ~100k (shard 비대화) | shardBits 12~14 리샤딩 마이그레이션 |
| **P1** | **quality 전량 재빌드** (§2.4) | ~100k (CI 시간) | 증분 빌드 / score 캐시 |
| **P2** | **franchise 수동 큐레이션 + 단일 파일** (§2.5) | ~100k (인적·물리) | 지연/선택적 그룹화 정책 + 파일 분할 |
| **P2** | **Git 단일 저장소 물리 한계** (§2.7) | ~150k~400k | LFS / 분할 / 비-Git 배포 검토 |

**한 줄 요약**: 1M으로 가는 길목의 진짜 벽은 **search_index 하나**다. 나머지(shardBits, 증분 빌드)는 파라미터·파이프라인 조정이고, search_index만 **아키텍처 교체**가 필요하다.

### 🟢 100만 작품이 되어도 "그대로 유지 가능한 것"

| 항목 | 이유 |
|------|------|
| **workId 체계** (§2.1) | 9자리 = 10억 용량, 불변·무충돌. 1M은 0.1% |
| **해시 샤딩 *원리*** (§2.2) | `sha256(workId)` 균등 분포는 그대로. **버킷 수(파라미터)만** 조정 |
| **externalIds 모델** (§2.6) | 작품 내부 필드, 선형 증가, 참조 역할 불변 |
| **qualityScore *공식*** (§2.4) | 순수 함수 O(1)/작품. 재빌드 *전략*만 바꾸면 됨 |
| **Minimal Core 철학** | wk_ = 정체성, 외부 ID = 참조. AKASHA 독립성은 규모와 무관 |
| **manifest.json + sha256 무결성** | 1,792~수만 shard에서도 ~수백 KB, 검증 모델 유지 |

---

## 4. 권고

1. **지금**: 추가 Discovery 기능·대량 시드를 멈춘 현재 판단은 옳다. 그릇(Registry)을 먼저 검증.
2. **다음 단계 (10k 도달 전)**: 본 리뷰의 P0(search_index)에 대한 **설계 결정 문서**(샤드화 vs inverted index vs SQLite FTS) 작성. 코드보다 결정이 먼저.
3. **마이그레이션 가능성 확보**: shardBits 변경·search_index 재설계는 **workId가 불변**이라 안전하게 수행 가능. 이 불변성이 AKASHA의 최대 자산이다.
4. **1M은 "Git DB"의 경계**: 100만 규모는 Git 저장소 배포 모델의 물리적 끝. 그 전에 배포 채널(LFS/CDN/DB) 전략을 분리 검토.

> **검토 대상이 1만·10만·100만이었지만, 결론은 명확하다.**
> 현재 설계는 **10k까지 무수정으로 안전**하고, **100k에서 search_index·shardBits·빌드 전략 3가지가 임계**에 닿으며, **1M은 search_index 아키텍처 교체 + Git 배포 모델 재고**를 요구한다.
> workId·해시 원리·externalIds·quality 공식은 **1M에서도 그대로 유효**하다 — 즉 *정체성 모델은 견고하고, 병목은 전부 "저장·인덱스 표현"에 있다.*
