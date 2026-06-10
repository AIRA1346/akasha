# Registry Bottleneck Validation Report

> 목표는 Architecture Change가 아니라 **Architecture Validation**이다.
>
> AKASHA는 400작품 프로젝트가 아니다. 최종 목표는 **세상 모든 작품의 Registry**다.
> 따라서 100만 작품 기준의 사고는 유지하되, 지금 할 일은 "100만 작품에서 위험할 것 같다"와
> "실제로 가장 먼저 깨질 것이다"를 구분하는 것이다.

이 문서는 현재 Registry 구현과 402작품 실측치를 바탕으로 병목 후보를 검증한다.
새 설계나 리팩터링을 제안하지 않고, **무엇이 먼저 깨지는지**만 판정한다.

---

## 1. 검증 대상

이번 Validation의 대상은 이전 Scaling Review에서 위험 후보로 잡힌 네 가지다.

| 후보 | 이전 가설 |
|------|-----------|
| `search_index` | 단일 파일·전량 메모리·선형 스캔이 가장 위험 |
| shard 구조 | `shardBits=8` 고정이면 100k~1M에서 shard가 비대화 |
| `franchise_groups` | 단일 파일보다 수동 큐레이션이 장기 위험 |
| quality 재빌드 | 공식은 안전하지만 전량 재계산이 CI 비용으로 증가 |

검증 질문:

> 100만 작품 시대에 **실제로 가장 먼저 깨지는 것은 무엇인가?**

---

## 2. 현재 실측 기준선

측정은 운영 파일을 쓰지 않는 방식으로 수행했다. `registry_builder`처럼 산출물을 다시 쓰는 명령은 실행하지 않았다.

| 항목 | 실측값 |
|------|--------|
| Registry 작품 수 | **402** |
| `search_index.json` | **268,835 bytes** |
| search index / 작품 | **668.7 bytes/work** |
| `manifest.json` | **76,717 bytes** |
| `franchise_groups.json` | **10,591 bytes** |
| shard 파일 수 | **331** |
| shard 전체 크기 | **237,669 bytes** |
| shard 평균 크기 | **718 bytes** |
| shard 최대 크기 | **2,545 bytes** |
| 평균 entries/shard | **1.21** |
| 최대 entries/shard | **3** |

읽기·스캔 측정 (PowerShell + UTF-8 JSON parse 기준, 절대 성능값보다 상대 순서가 중요):

| 작업 | 402작품 실측 |
|------|--------------|
| `search_index.json` parse | **29.61 ms** |
| `franchise_groups.json` parse | **15.57 ms** |
| 모든 shard parse | **89.12 ms** |
| search index 선형 scan 1회 | **3.90 ms** |
| quality 계산 proxy | **129.65 ms** |

주의:

- PowerShell JSON parse는 Flutter/Dart 런타임보다 느릴 수 있다.
- 따라서 ms 수치는 **절대 UX 예측**이 아니라 **병목 순서 검증용**이다.
- 파일 크기와 per-work 크기는 실제 파일에서 나온 값이므로 임계점 계산에 직접 사용한다.

---

## 3. 임계점 계산

### 3.1 `search_index`

현재:

- `search_index.json` = 268,835 bytes / 402 works
- **668.7 bytes/work**
- 앱은 `RegistryShardLoader._loadBundledSearchIndex()`에서 search index 전체를 읽고 파싱해 `_searchIndex` 리스트로 보관한다.
- 검색 shard 결정은 `shardIdsForQuery()`에서 `_searchIndex` 전체를 순회한다.

예상 크기:

| 규모 | 예상 `search_index.json` |
|------|--------------------------|
| 10k | **~6.4 MB** |
| 100k | **~63.8 MB** |
| 1M | **~637.7 MB** |

하드 리밋:

| 기준 | 임계 작품 수 |
|------|--------------|
| 50 MB 단일 파일 | ~78k |
| **100 MB GitHub 단일 파일 거부선** | **~157k** |
| 500 MB 런타임 asset | ~784k |

선형 스캔:

- 현재 402작품에서 1회 scan proxy: **3.90 ms**
- 구조상 O(n)이라 100k·1M에서 선형 증가한다.
- Dart 런타임이 PowerShell보다 빠르더라도, **전량 메모리 + 전량 스캔**이라는 구조는 변하지 않는다.

**검증 판정: search_index는 추정 위험이 아니라 실제 1차 병목이다.**

이유:

1. 파일 크기가 작품 수에 직접 비례한다.
2. 단일 파일이라 GitHub 100 MB 제한에 먼저 닿는다.
3. 앱 시작 시 전량 parse + 메모리 상주가 필요하다.
4. 검색 shard 결정도 전량 선형 스캔이다.

---

### 3.2 shard 구조

현재:

- shardBits = 8
- 카테고리당 최대 256 bucket
- 전체 카테고리 7개 기준 이론 상한 1,792 shard
- 현재 331 shard 사용
- 현재 평균 entries/shard = **1.21**
- 현재 최대 entries/shard = **3**

현재 shard 본문 기준:

- shard 전체 크기 = 237,669 bytes
- **591 bytes/work**

단순 extrapolation:

| 규모 | shard 전체 | 평균 entries/shard (`shardBits=8`) | 평균 shard 크기 |
|------|------------|------------------------------------|-----------------|
| 10k | ~5.6 MB | ~5.6 | ~3.1 KB |
| 100k | ~56.1 MB | ~55.8 | ~31 KB |
| 1M | ~564 MB | ~558 | ~315 KB |

검증:

- shard 전체 크기는 커지지만 **단일 shard 파일은 search_index보다 훨씬 늦게 커진다.**
- 1M에서도 평균 shard는 수백 KB 수준이다.
- on-demand 로딩의 효율은 떨어지지만, GitHub 100 MB 단일 파일 제한에는 먼저 닿지 않는다.
- `shardBits`가 이미 가변 함수로 구현되어 있어 경로 마이그레이션 가능성이 있다.

**검증 판정: shard 구조는 1차 병목이 아니다.**

정확한 성격:

- 10k: 안전
- 100k: 효율 저하 시작
- 1M: on-demand granularity 문제
- 그러나 **먼저 깨지는 것은 아니다.**

---

### 3.3 `franchise_groups`

현재:

- `franchise_groups.json` = 10,591 bytes
- 현재 파일 parse = 15.57 ms
- 구조는 단일 JSON map + members 배열

단순 크기 extrapolation:

| 규모 | 파일 크기 단순 추정 |
|------|---------------------|
| 10k | ~257 KB |
| 100k | ~2.6 MB |
| 1M | ~25.1 MB |

검증:

- 물리 파일 크기만 보면 1M에서도 search_index보다 훨씬 작다.
- GitHub 단일 파일 100 MB 제한에도 search_index보다 늦게 닿는다.
- 따라서 **파일 크기 병목으로는 1차가 아니다.**

하지만 운영 관점은 다르다:

- franchise grouping은 자동 사실 저장이 아니라 **큐레이션 판단**이다.
- 1M 작품에서 모든 프랜차이즈 관계를 완전하게 수동 관리하는 것은 인적으로 먼저 무너질 수 있다.
- 다만 이 병목은 현재 402작품 실측치만으로 정량 검증하기 어렵다.

**검증 판정: franchise_groups는 물리 1차 병목이 아니라 운영 장기 병목이다.**

즉:

- 실제 파일/런타임 병목: search_index가 먼저
- 실제 운영 병목: franchise 큐레이션이 별도 축에서 먼저 느껴질 가능성

---

### 3.4 quality 재빌드

현재 구조:

- shard에는 `qualityScore`를 저장하지 않는다.
- `registry_builder`가 search index 생성 시 모든 work에 대해 `computeQualityScore()`를 다시 수행한다.
- 공식은 O(1)/work.

실측 proxy:

- 402작품 quality proxy = **129.65 ms**
- 이 값에는 JSON parse와 PowerShell 객체 처리 비용이 포함되어 있어 Dart 실제 builder 시간과 같지는 않다.

구조 검증:

- quality 계산 자체는 간단한 필드 존재 여부 확인이다.
- 비용은 작품 수에 선형으로 증가한다.
- 하지만 결과적으로 `qualityScore`는 `search_index.json`에 들어간다.
- 즉 quality 재빌드는 독립 병목이라기보다 **search_index 재생성 비용의 일부**다.

**검증 판정: quality 재빌드는 첫 번째 병목이 아니다.**

정확한 성격:

- Runtime 병목 아님
- Repo hard limit 아님
- CI/build 병목
- 1M에서는 느려지지만, search_index 단일 파일 문제가 먼저 GitHub·런타임 양쪽에서 깨진다.

---

## 4. 병목 순위

### 4.1 종합 순위

| 순위 | 병목 | 유형 | 검증 결과 |
|------|------|------|-----------|
| **1** | **search_index** | Runtime + GitHub + memory + algorithm | **실제 첫 번째 병목** |
| 2 | shardBits=8 | Runtime granularity | 1차는 아님, 100k 이후 효율 문제 |
| 3 | quality 재빌드 | CI/build | search_index 재생성에 종속 |
| 4 | franchise_groups | Operations + curation | 물리 병목은 늦고, 운영 병목은 별도 축 |

### 4.2 병목 유형별 첫 번째

| 유형 | 가장 먼저 깨지는 항목 | 이유 |
|------|-----------------------|------|
| GitHub 저장소/파일 | **search_index** | 100 MB 단일 파일 제한에 ~157k에서 도달 |
| 앱 시작/메모리 | **search_index** | 전량 parse + 전량 메모리 상주 |
| 검색 latency | **search_index** | shard 결정 전 선형 스캔 |
| shard on-demand 효율 | shardBits=8 | 1M에서 shard당 평균 ~558작품 |
| CI build 시간 | quality + search_index 생성 | 전량 재계산·전량 재작성 |
| 운영 큐레이션 | franchise_groups | 수동 판단량이 선형 이상으로 증가 |

---

## 5. 가설별 검증 결과

| 가설 | 검증 결과 | 판정 |
|------|-----------|------|
| workId 안전 | 이전 결론 유지. 병목 후보 아님 | ✅ 확정 |
| externalIds 안전 | 이전 결론 유지. 병목 후보 아님 | ✅ 확정 |
| qualityScore 공식 안전 | 공식은 안전. 전량 빌드 전략만 비용 증가 | ✅/⚠️ |
| search_index 위험 | 파일 크기, 로딩, 검색 모두에서 실제 1차 병목 | ❌ 확정 |
| shardBits 조정 가능성 | 실제로는 search_index보다 늦게 깨짐. 효율 병목 | ⚠️ 2차 |
| franchise_groups 장기 위험 | 물리 병목보다 운영 병목. 정량 검증은 별도 필요 | ⚠️ 장기 |

---

## 6. 결론

### 실제 첫 번째 병목

**`search_index.json`이다.**

이전 Scaling Review의 가설은 검증 결과 유지된다. 다만 더 정확히 말하면:

- search_index는 **위험할 것 같은 항목**이 아니라 **실제로 가장 먼저 깨질 항목**이다.
- shardBits는 1M에서 불편해지지만, search_index보다 먼저 하드 리밋에 닿지 않는다.
- quality 재빌드는 CI 비용이지만, search_index 전체 생성·쓰기 문제의 일부다.
- franchise_groups는 파일 크기보다 큐레이션 운영이 문제다.

### 100만 작품 기준에서 지금 구분해야 할 것

**실제 병목**

- `search_index` 단일 파일
- `search_index` 전량 메모리 로딩
- `search_index` 선형 스캔
- GitHub 100 MB 단일 파일 제한

**추정/장기 병목**

- shardBits=8의 on-demand 효율 저하
- franchise_groups 수동 큐레이션
- quality 전량 재빌드

**아직 병목이 아닌 것**

- workId
- externalIds
- qualityScore 공식
- 해시 샤딩 원리

---

## 7. 다음 판단

### 7.1 Synthetic Validation 완료 (2026-06-08)

[Search Index Validation Plan](search-index-validation-plan.md)에 따라 synthetic 실측을 수행했다.

| scale | file | parse | RSS Δ | ms/query | Git 100MB |
|-------|------|-------|-------|----------|-----------|
| 402_real | 262 KB | 18 ms | 1.3 MB | 0.45 | OK |
| 100k | 64.9 MB | 769 ms | 342 MB | 106 | WARN |
| 300k | 196 MB | 2.5 s | 920 MB | 316 | **FAIL** |
| 1M | 655 MB | 7.7 s | 3.1 GB | 1,040 | **FAIL** |

**판정: search_index = 첫 번째 병목 — 가설에서 실측 확정으로 승격.**

- GitHub 100 MB: **300k**에서 최초 FAIL (추정 ~147k–300k 구간)
- UX 임계(search > 100ms): **100k**에서 도달
- shard·franchise·quality는 동일 규모에서 이 수치보다 늦게 또는 별도 축에서 문제

### 7.2 이후 단계

지금 필요한 것은 100만 대응 리팩터링이 아니다.

다음은 **구조 변경 논의**이며, 전제는 팀 합의다:

> Validation Gate 통과 — `Search Index Architecture Options` 문서 작성

즉, AKASHA는 여전히 **100만 작품 Registry**를 목표로 한다.
하지만 오늘의 결론은 100만 설계 변경이 아니라:

> **100만으로 가는 길에서 첫 번째로 무너질 구조는 search_index다.**

