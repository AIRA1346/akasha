# Search Index Architecture Options

> **전제:** [Search Index Validation](search-index-validation-plan.md) 통과 — `search_index` = 첫 번째 병목 (실측 확정)
>
> **이 문서의 역할:** 해결책 **후보 비교** — 구현·리팩터링 아님
>
> AKASHA의 목표는 400작품 Registry가 아니라 **세상의 모든 작품을 담을 수 있는 Registry**다.
> Validation은 끝났고, **어떤 구조가 AKASHA에 맞는지**는 아직 검증되지 않았다.

**Workload 전제:** [search-workload-profile.md](search-workload-profile.md) — Architecture 적합도는 검색 workload에 따라 달라진다.

---

## 0. Validation에서 확인된 제약 (교체 대상)

현재 `search_index.json` 구조가 1M에서 깨지는 이유는 세 가지다.

| 제약 | 실측 근거 |
|------|-----------|
| GitHub 100 MB 단일 파일 | 300k=196 MB FAIL |
| 앱 시작 시 전량 메모리 로드 | 100k RSS +342 MB · 1M +3.1 GB |
| O(n) 선형 검색 | 100k 106 ms/query · 1M 1,040 ms/query |

**교체 후보는 위 세 가지를 동시에 완화해야 한다.**

현재 앱 동작 (`registry_shard_loader.dart` · `registry_search_utils.dart`):

1. bootstrap 시 `search_index.json` **전량** parse → `_searchIndex` 리스트
2. `shardIdsForQuery()`가 index **전체 선형 스캔** → shardId 집합
3. `ensureShardLoaded()`로 shard 본문만 on-demand 로드
4. 검색 매칭: `searchTokens`에 대한 **substring contains** (prefix 전용 아님)

새 구조도 **shard on-demand 본문 로딩**과 **다국어 substring 검색**을 유지해야 한다.

---

## 1. 평가 기준 (AKASHA 맥락)

| 기준 | 설명 | 1M 목표 |
|------|------|---------|
| **G1 Git 친화** | akasha-db PR·diff·CI·100MB/file | 필수 |
| **G2 Cold start** | bootstrap 메모리·parse | < 50 MB RSS, < 1 s |
| **G3 Query latency** | 사용자 검색 응답 | < 50 ms (p95) |
| **G4 Lazy shard** | 검색 → 필요한 shard만 로드 | 유지 |
| **G5 다국어·별칭** | ko/en/ja·aliases·contains | 유지 |
| **G6 증분 sync** | manifest sha256·부분 갱신 | 유지/개선 |
| **G7 빌드 단순성** | `registry_builder` 파이프라인 | 과도한 복잡도 회피 |
| **G8 오프라인 번들** | `assets/registry` 동봉 | 유지 |

**아직 검증하지 않은 것:** 위 기준을 각 후보가 실제로 만족하는지 — 본 문서는 **가설 비교**만 한다.

---

## 2. 후보 개요

| 후보 | 한 줄 요약 |
|------|------------|
| **A. Shard Index** | `search_index`를 category·hash prefix 등으로 **파일 분할** |
| **B. Inverted Index** | token → workId posting list (**전치 인덱스**) |
| **C. SQLite / FTS5** | 검색 전용 임베디드 DB, shard JSON은 본문 유지 |
| **D. Trie** | prefix tree 기반 자동완성·접두 검색 |
| **E. Hybrid** | 위 조합 (예: shard index + shard별 mini inverted) |

---

## 3. 후보별 비교

### A. Shard Index

`search_index`를 데이터 shard와 **동형 또는 유사**하게 분할.

예: `search/animation/03.json`, `search/manga/a5.json` — entry 메타만, 본문 shard와 1:1 또는 N:1.

| 기준 | 평가 | 메모 |
|------|------|------|
| G1 Git | ✅ 강함 | 파일당 수 MB 이하, 100MB 한계 회피 |
| G2 Cold start | ⚠️ 부분 | 전량 로드 대신 **category/eager만** 로드 가능 |
| G3 Query | ⚠️ | shard **내부**는 여전히 O(n) unless B 결합 |
| G4 Lazy shard | ✅ | search shard → data shard 매핑 자연스러움 |
| G5 다국어 | ✅ | 현재 entry 스키마 유지 가능 |
| G6 증분 sync | ✅ | manifest per-file sha256 확장 |
| G7 빌드 | ✅ | `registry_builder` 출력 분할만 |
| G8 번들 | ✅ | lazy load와 궁합 좋음 |

**장점:** 기존 v4 shard 모델·manifest·sync와 **정렬**이 가장 쉽다. Git workflow 변화 최소.

**단점:** 검색만으로는 O(n) 제거 불가. 1M에서 category당 ~140k면 **파일 하나가 여전히 90MB+** 가능 → **2차 분할**(hash prefix) 필수.

**AKASHA 적합도 (가설):** Git·sync 측면 **1순위 후보**. 단독으로는 검색 latency 미해결 → **B 또는 E와 결합** 가능성 높음.

**검증 필요:** category-only vs hash-prefix 분할 시 1M 파일 크기·cold load·query 실측.

---

### B. Inverted Index

`searchTokens` 각각에 대해 `workId` (및 선택적 score) posting list.

예: `index/tokens/mo.json` → `["wk_000000418", ...]` 또는 compact bitmap.

| 기준 | 평가 | 메모 |
|------|------|------|
| G1 Git | ⚠️ | 인기 token posting이 커질 수 있음 ("the", "a" 급) |
| G2 Cold start | ✅ | **전체 로드 불필요** — query token만 posting fetch |
| G3 Query | ✅ | O(posting size), 1M에서 이론상 최선 |
| G4 Lazy shard | ⚠️ | workId → shardId 역참조 테이블 필요 |
| G5 다국어 | ⚠️ | **substring contains**는 n-gram/trigram 인덱스 필요 |
| G6 증분 sync | ⚠️ | token 단위 diff 복잡 |
| G7 빌드 | ⚠️ | posting merge·압축 파이프라인 |
| G8 번들 | ✅ | mmap·lazy load 가능 |

**장점:** 1M query latency 문제를 **직접** 해결. 메모리도 query-bound.

**단점:**

- AKASHA는 `token.contains(q)` — **부분 문자열** 매칭. 순수 word inverted만으로는 부족 → **trigram/n-gram** 레이어 필요 (CJK 포함 시 설계 난이도 ↑).
- Git에 posting list를 두면 hot token 파일이 비대화할 수 있음.
- `registry_builder` 산출물이 JSON 배열에서 **검색 전용 2차 구조**로 분기.

**AKASHA 적합도 (가설):** 성능 측면 **핵심 후보**. Git·substring·빌드 복잡도는 **POC 검증 필수**.

**검증 필요:** trigram 인덱스 크기(1M), "モンスター"·"monster"·substring 쿼리 recall, posting hot spot.

---

### C. SQLite / FTS5

검색·필터·랭킹을 SQLite FTS5 테이블에 위임. shard JSON은 작품 **본문 SoT** 유지.

| 기준 | 평가 | 메모 |
|------|------|------|
| G1 Git | ❌ 약함 | 바이너리 DB — PR diff·100MB·텍스트 리뷰 어려움 |
| G2 Cold start | ✅ | mmap, partial init |
| G3 Query | ✅ | FTS5 tokenizer 설정 시 양호 |
| G4 Lazy shard | ✅ | FTS → workId → shard path |
| G5 다국어 | ⚠️ | `unicode61` vs custom tokenizer (CJK) |
| G6 증분 sync | ⚠️ | DB blob 교체 또는 ATTACH 증분 — 별도 정책 |
| G7 빌드 | ⚠️ | builder가 .db 산출 + CI 검증 |
| G8 번들 | ✅ | 단일 .db 또는 category별 .db |

**장점:** 검색 엔진 문제를 **검증된 구현**에 위임. 1M scale에서 업계 표준.

**단점:**

- akasha-db의 **Git-as-source-of-truth** 철학과 충돌. CDN sync가 JSON shard + binary index **이중 배포**가 됨.
- Contribution PR이 JSON shard만 수정할 때 FTS **재빌드** 누락 위험.
- Flutter: `sqlite3` / `drift` 의존성·플랫폼 바이너리.

**AKASHA 적합도 (가설):** 런타임 성능은 우수하나 **운영·Git workflow 비용**이 큼. 배포 채널이 Git-only에서 **CDN/R2 primary**로 전환될 때 재평가.

**검증 필요:** .db 크기(1M), CJK FTS recall, PR workflow mock, sync 무결성.

---

### D. Trie (Prefix Tree)

접두어 자동완성·prefix search 전용.

| 기준 | 평가 | 메모 |
|------|------|------|
| G1 Git | ⚠️ | 직렬화 형태에 따라 다름 |
| G2 Cold start | ⚠️ | full trie 로드 시 메모리 |
| G3 Query prefix | ✅ | 접두 검색 빠름 |
| G3 substring | ❌ | **중간 일치·contains 불가** (별도 suffix array 필요) |
| G5 다국어 | ⚠️ | Unicode codepoint trie — 메모리 |
| G7 빌드 | ⚠️ | |

**장점:** 검색창 autocomplete UX에 특화.

**단점:** AKASHA 현재 매칭은 `contains` — Trie **단독**은 요구사항 미충족. 1M × 다국어 alias에서 메모리 비효율.

**AKASHA 적합도 (가설):** **주력 후보 아님**. Hybrid에서 autocomplete **보조** 정도만 고려.

**검증 필요:** 없음 (요구사항 불일치로 우선순위 낮음).

---

### E. Hybrid Index

실무적으로 가장 현실적인 방향. 예시 조합:

| 조합 | 설명 |
|------|------|
| **E1 Shard Index + Inverted** | search 메타는 hash shard로 분할, 각 shard 내부 또는 별도 `index/{hh}/postings.bin` |
| **E2 Shard Index + SQLite FTS** | Git에는 JSON shard만, FTS .db는 **CI 빌드 산출물** (CDN only, Git LFS optional) |
| **E3 Category lazy + trigram** | category별 search shard lazy load + trigram inverted for contains |

| 기준 | 평가 |
|------|------|
| G1–G8 | 조합에 따라 **trade-off 조절** 가능 |
| 복잡도 | ⚠️ 가장 높음 — 단계적 도입 필요 |

**AKASHA 적합도 (가설):** 장기적으로 **E1 또는 E2**가 유력. 단, **한 번에 교체하지 않고** Validation → POC → 점진 전환.

**검증 필요:** E1 vs E2 prototype 10k/100k 벤치마크 + Git workflow 시뮬레이션.

---

## 4. 종합 비교표

| 후보 | G1 Git | G2 Cold | G3 Query 1M | G4 Lazy | G5 i18n contains | G7 빌드 | **POC 우선순위** |
|------|--------|---------|-------------|---------|------------------|---------|------------------|
| A Shard Index | ✅ | ⚠️ | ❌ 단독 | ✅ | ✅ | ✅ | **P1** |
| B Inverted | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ trigram | ⚠️ | **P1** |
| C SQLite FTS | ❌ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ | P2 |
| D Trie | ⚠️ | ⚠️ | ❌ substring | ⚠️ | ⚠️ | ⚠️ | P4 (보조) |
| E Hybrid | ⚠️~✅ | ✅ | ✅ | ✅ | ⚠️~✅ | ❌ | **P1 (최종)** |

**POC 우선순위:** 구현이 아니라 **다음 Validation 실험** 우선순위다.

---

## 5. Workload 연동 (Search Workload Profile)

[search-workload-profile.md](search-workload-profile.md) v0 가정 기준:

| AKASHA 주 workload | 비율 (가정) | Architecture 시사 |
|--------------------|-------------|-------------------|
| W2 partial_title (contains) | 30% | Trie ❌ · Trigram/FTS ✅ |
| W1 exact_title | 20% | Inverted/FTS ✅ |
| W3 alias + W7 multilingual | 25% | token 사전 + trigram |
| W4 abbreviation | 12% | Inverted ✅ |
| W8 typo | 0% (v0) | fuzzy 인덱스 **불필요** |

**재평가:** D(Trie) 단독 제외 · POC는 **B(trigram) 또는 E1** 우선 — workload 정합.

Workload 비율은 **미실측** → Search Workload Validation(SW1) 후 POC 순서 확정.

---

## 6. 권고 (결정 아님)

### 6.1 지금 당장 하지 않을 것

- search_index 구조 **전면 교체 구현**
- 앱 런타임 리팩터링
- SQLite 도입 커밋
- trie/autocomplete 전용 인프라

### 6.2 다음 Validation

**선행:** [Search Workload Validation](search-workload-profile.md) §6 SW1 시나리오 스위트

**이후:** Architecture Options POC

| 순서 | 실험 | 목적 |
|------|------|------|
| 1 | **A: hash-prefix search shard** 10k/100k/1M synthetic | Git 100MB·cold load |
| 2 | **B: trigram inverted** 동일 규모 | query latency·contains recall |
| 3 | **E1: A+B** 최소 결합 prototype | G1+G3 동시 충족 여부 |
| 4 | (선택) **C: FTS5** 100k bench | Git 비용 vs 성능 트레이드오프 정량화 |

각 POC는 `pipeline/artifacts/`에만 두고, **합격 후**에만 `registry_builder`·loader 변경 논의.

### 6.3 의사결정 게이트

구조 **선택**은 아래를 모두 만족한 뒤:

1. POC 1M synthetic에서 G1·G2·G3 **실측** pass
2. 다국어 substring recall **수동 시나리오** pass (Monster / モンスター / 進撃)
3. 증분 sync·Contribution PR 시나리오 **문서 시뮬레이션** pass
4. 팀 **명시적 Architecture Decision Record**

---

## 7. 장기 검증: Discovery Throughput

Search Index Validation은 **사용자 검색 경로**의 첫 병목을 확정했다.

Registry가 1M에 가면 **Discovery 경로**에서 병목이 이동할 가능성이 있다.

### 7.1 가설

| 규모 | Discovery batch 100건 | 예상 결과 |
|------|----------------------|-----------|
| **402 (현재)** | wouldCreate 비율 높음 | 신규 위주, dedupe 부담 낮음 |
| **1M (장기)** | 대부분 기존 작품 매칭 | mergeCandidate >> wouldCreate |

즉 100건 발견 → **소수만 신규** → Search보다 **Dedupe Throughput·Discovery Cost**가 지배적일 수 있다.

### 7.2 검증 항목 (미착수)

| 항목 | 질문 |
|------|------|
| **Dedupe throughput** | 1M registry에서 externalId·fuzzy dedupe 1건당 비용? |
| **Discovery cost** | Signal 100건 처리 시 CPU·메모리·I/O? |
| **Merge vs Create ratio** | 규모별 wouldCreate% 곡선? |
| **dedupe_index 메모리** | 전체 works in-memory index 크기? |

현재 `dedupe_linter`는 전 works 로드 + hash bucket + fuzzy pairwise — **1M에서 비용 미실측**.

### 7.3 문서화 상태

| Validation | 상태 |
|------------|------|
| Search Index Bottleneck | ✅ 완료 |
| Search Workload Profile | ✅ 가정 v0 |
| Search Workload Validation | ⏳ 권장 |
| Search Index Refactor | ⏸ 미착수 |
| Architecture Options (본 문서) | ✅ 후보 비교 |
| Architecture Options POC | ⏳ Workload Validation 후 |
| Discovery Cost vs Registry Growth | 📋 장기 backlog |

---

## 8. 타임라인 (검증 우선)

```
[완료] Registry Scaling Review
[완료] Bottleneck Validation Report
[완료] Search Index Validation (실측)
[완료] Search Index Architecture Options (본 문서)
[완료] Search Workload Profile (가정 v0)
[다음] Search Workload Validation (SW1 시나리오)
[다음] Architecture Options POC (A / B / E1) — Workload 기준
[보류] Search Index Refactor — POC + ADR 후
[장기] Discovery Throughput Validation
```

---

## 9. 원칙 (재확인)

- **100만 작품 목표** — 유지
- **search_index = 첫 병목** — Validation 통과
- **해결책** — 아직 미검증 · **구현 시작 안 함**
- **다음 산출물** — POC 실측 또는 ADR, **전면 리팩터링 아님**
- **장기** — Discovery Cost vs Registry Growth

> 우리가 만드는 것은 400작품용 앱이 아니라 **세상의 모든 작품을 담을 Registry**다.
> 지금도 **구현보다 검증이 우선**이다.

---

## 10. 관련 문서

| 문서 | 역할 |
|------|------|
| [registry-scaling-review.md](registry-scaling-review.md) | 규모별 가설 |
| [registry-bottleneck-validation-report.md](registry-bottleneck-validation-report.md) | 402 실측·병목 순위 |
| [search-index-validation-plan.md](search-index-validation-plan.md) | Synthetic 실측·Gate |
| [search-workload-profile.md](search-workload-profile.md) | 검색 workload 가정 |
| [discovery-policy.md](discovery-policy.md) | Discovery 철학·파이프라인 |
