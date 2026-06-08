# Search Workload Profile

> **목표:** 구현이 아니라 **가정 명시**
>
> Search Bottleneck Validation은 **인프라 병목**(파일·메모리·parse·latency)을 실측했다.
> 이 문서는 **사용자가 실제로 어떤 검색을 하는가**를 정의한다.
>
> Architecture Options의 장단점은 검색 workload에 따라 달라진다.
> workload를 먼저 명확히 한 뒤에야
> "어떤 기술이 좋은가"가 아니라 **"어떤 기술이 AKASHA 검색 workload에 맞는가"**를 비교할 수 있다.

선행 문서:

- [search-index-validation-plan.md](search-index-validation-plan.md) — 인프라 Validation ✅
- [search-index-architecture-options.md](search-index-architecture-options.md) — 후보 비교 (workload 미반영 → 본 문서로 보완)

---

## 1. 현재 AKASHA 검색 계약 (구현 기준)

코드 기준 (`registry_search_utils.dart` · `works_registry.dart` · `buildWorkSearchTokens`):

| 항목 | 동작 |
|------|------|
| 쿼리 정규화 | 소문자 + **공백 제거** (`normalizeRegistryQuery`) |
| 매칭 | `searchToken.contains(query)` — **substring contains** |
| 인덱스 토큰 | title · titles(다국어) · aliases · creator · tags — 각각 원문 + 정규화본 |
| 랭킹 | `qualityScore` 내림차순 → title 오름차순 |
| shard 로딩 | search_index 선형 스캔 → 매칭 shard만 on-demand |
| 오타 허용 | **없음** |
| prefix 전용 | **없음** (contains가 prefix를 포함) |
| FTS / 형태소 | **없음** |

**핵심:** AKASHA가 오늘 풀고 있는 검색 문제는 **다국어 substring contains over precomputed tokens**이다.

---

## 2. Workload 유형 정의

### 2.1 유형 목록

| ID | 유형 | 설명 | 예시 (AKASHA 맥락) |
|----|------|------|-------------------|
| **W1** | exact_title | 제목 전체 또는 거의 전체 | `Monster`, `Neon Genesis Evangelion` |
| **W2** | partial_title | 제목 일부 (contains) | `monst`, `evangel`, `進撃` |
| **W3** | alias | 공식 별칭·시노님 | `NGE`, `モンスター`, `Samurai X` |
| **W4** | abbreviation | 약어·팬 약칭 | `Eva`, `WHR`, `HachiKuro` |
| **W5** | creator | 제작사·작가·감독 | `Madhouse`, `우라사와 나오키` |
| **W6** | tag | 장르·태그 | `SF`, `명작`, `미스터리` |
| **W7** | multilingual_cross | 다른 문자계로 검색 | en 제목 작품에 `モンスター` 입력 |
| **W8** | typo_tolerance | 철자 오류·1-edit | `Mosnter`, `Evangleion` |
| **W9** | prefix_autocomplete | 입력 중 접두만 (UX) | `Mon` → `Monster` 제안 |
| **W10** | workId_direct | ID 직접 | `wk_000000418` |

### 2.2 유형 ↔ 인덱스 구조 적합성 (이론)

| 유형 | Trie | Inverted (token) | Trigram | SQLite FTS |
|------|------|------------------|---------|------------|
| W1 exact_title | △ | ✅ | ✅ | ✅ |
| W2 partial_title | ❌ | △ | ✅ | ✅ |
| W3 alias | △ | ✅ | ✅ | ✅ |
| W4 abbreviation | ✅ | ✅ | △ | △ |
| W5 creator | △ | ✅ | ✅ | ✅ |
| W6 tag | △ | ✅ | △ | ✅ |
| W7 multilingual | △ | ✅* | ✅ | ⚠️ tokenizer |
| W8 typo | ❌ | ❌ | △ | △~✅ |
| W9 prefix | ✅ | △ | △ | ✅ |
| W10 workId | ✅ hash | ✅ | △ | △ |

\* token이 사전에 있어야 함

**현재 구현과 정합:** W1–W7은 contains로 **커버**. W8·W9는 **미지원**.

---

## 3. Workload 비율 가정 (v0 — 미실측)

> ⚠️ 아래 비율은 **텔레메트리 없음**. 제품 가정 + 서브컬처 카탈로그 UX 추론.
> Search Workload Validation으로 **대체·수정**해야 한다.

### 3.1 Primary: Fusion Search Dialog (작품 추가·검색)

사용자가 작품을 찾아 볼트에 추가하는 **주 검색 경로**.

| ID | 유형 | 가정 비율 | 근거 |
|----|------|-----------|------|
| W2 | partial_title | **30%** | 타이핑 중간에 멈추는 패턴, contains와 정합 |
| W1 | exact_title | **20%** | 제목을 알고 붙여넣기·완전 입력 |
| W3 | alias | **18%** | 일본어·로컬라이즈명으로 검색 |
| W4 | abbreviation | **12%** | 팬덤 약어 (Eva, NGE) |
| W5 | creator | **8%** | "이 감독 작품 뭐였지" |
| W7 | multilingual_cross | **7%** | ko UI에서 ja/en 제목 혼용 |
| W6 | tag | **3%** | 태그 단독 검색은 드묾 |
| W9 | prefix_autocomplete | **2%** | UX 개선 여지, 현재 미구현 |
| W8 | typo_tolerance | **0%** | **현재 요구 없음** (v0) |
| W10 | workId_direct | **0%** | 내부·디버그용 |

**v0 합계:** 100%

### 3.2 Secondary: Browse / Filter (도메인·카테고리)

검색어 없이 필터만 — **search_index 스캔 아님** (`shardIdsForFilters`).

| 패턴 | 가정 비율 (전체 세션 대비) |
|------|---------------------------|
| 카테고리 필터만 | ~40% 홈 세션 |
| 검색 + 필터 조합 | ~15% |

Architecture Options 평가 시 **검색 workload**와 **필터 workload**를 분리한다.

### 3.3 Future (1M Registry · 미확정)

| ID | 유형 | 가정 변화 |
|----|------|-----------|
| W2 partial_title | **↑** | 후보 수 증가 → contains 비용 증가 |
| W8 typo_tolerance | **0→5%?** | 규모 커지면 오타 허용 요구 가능 |
| W9 prefix_autocomplete | **↑** | 1M에서 타이핑 UX 필수 후보 |

**Future 비율은 v0 확정 후 재검토.**

---

## 4. AKASHA가 풀어야 하는 검색 문제 (명시)

### 4.1 Must (오늘 · v1)

| # | 문제 | workload |
|---|------|----------|
| M1 | 알고 있는 제목으로 작품 찾기 | W1, W2 |
| M2 | 별칭·다국어 이름으로 찾기 | W3, W7 |
| M3 | 약어로 찾기 | W4 |
| M4 | substring contains (현재 계약) | W2 전반 |
| M5 | 찾은 뒤 quality 기반 정렬 | 전 유형 |

### 4.2 Should (1M 전 · 미구현)

| # | 문제 | workload |
|---|------|----------|
| S1 | 입력 중 빠른 제안 (autocomplete) | W9 |
| S2 | 1M에서도 < 50ms 검색 응답 | W2, W1 |

### 4.3 Could (장기 · 가정만)

| # | 문제 | workload |
|---|------|----------|
| C1 | 오타 1-edit 허용 | W8 |
| C2 | 형태소·CJK 세분화 | W7 |

### 4.4 Won't (v0)

| # | 제외 | 이유 |
|---|------|------|
| X1 | 시놉시스 full-text | Data Policy — description 비필수 |
| X2 | AniList ID로 사용자 검색 | externalIds는 참조, 정체성은 wk_ |

---

## 5. Workload → Architecture Options 재평가

[Architecture Options](search-index-architecture-options.md) 후보를 **v0 workload**로 재스코어링한다.

가중치: v0 비율 × 유형별 적합도 (✅=1, △=0.5, ❌=0)

| 후보 | v0 workload 적합 (가설) | 약점 (v0 기준) |
|------|-------------------------|----------------|
| **A Shard Index** | 중상 — Git·lazy | W2 contains 미해결 |
| **B Inverted + trigram** | **상** — W2·W3·W7 | 빌드·hot token |
| **C SQLite FTS** | 중상 — W1·W2·W5 | Git·CJK tokenizer |
| **D Trie** | **하** — W9만 | W2 contains 불가 |
| **E Hybrid** | **상** — 조합으로 보완 | 복잡도 |

**v0 결론 (가설, POC 전):**

- **Trie 단독**은 workload 불일치 — 제외 또는 W9 보조만
- **핵심 workload(W2 partial + W3 alias + W7 multilingual)** 는 **trigram 또는 FTS급 contains** 필요
- **Shard Index 단독**은 인프라 병목만 해결, workload latency 미해결
- **POC 우선순위:** B(trigram) 또는 E1(A+B) — **Workload Profile 기준**

---

## 6. Search Workload Validation (다음 단계)

인프라 Validation과 **분리**된 실험. 구현 최소.

| # | 실험 | 산출 |
|---|------|------|
| **SW1** | **Global Search Workload Validation** — [global-search-validation-plan.md](global-search-validation-plan.md) · 쿼리 95건 | recall@10/@20 · 카테고리별 갭 리포트 |
| SW2 | **Architecture POC** — SW1과 **동일 스위트** | 후보별 recall·latency |
| SW3 | (선택) **가설 비율 교정** — 내부 dogfood 로그 | v0 비율 → v1 비율 |

SW1 시나리오 상세: [global-search-query-set.md](global-search-query-set.md)  
결과 저장: `pipeline/artifacts/global_search_validation/` (gitignored)

---

## 7. 타임라인

```
[완료] Search Index Bottleneck Validation (인프라)
[완료] Architecture Options (후보 비교)
[본 문서] Search Workload Profile (가정 v0)
[완료] SW1 계획 + 쿼리 스위트 — [global-search-validation-plan.md](global-search-validation-plan.md)
[다음] SW1-A 402 baseline 실행
[다음] Architecture Options POC (workload 기준)
[보류] Search Index Refactor
```

---

## 8. 상태 요약

| 항목 | 상태 |
|------|------|
| Search Bottleneck Validation | ✅ 완료 |
| **Search Workload Profile** | ✅ 가정 v0 (본 문서) |
| **SW1 Global Search Validation** | 🔶 계획·스위트 ✅ · baseline ⏳ |
| Architecture Options | ✅ (workload 연동은 본 문서 이후) |
| Refactor | ⏸ 미착수 |

---

## 9. 원칙

- **100만 작품 Registry** 목표 유지
- 인프라 병목 실측 ≠ **검색 workload** 실측
- 비율 v0는 **가정** — 교정 전까지 Architecture **선택** 금지
- 구현보다 **가정 명시 → 시나리오 검증 → POC** 순서

> 다음 질문은 "Trie가 좋은가?"가 아니라
> **"AKASHA 사용자의 30% partial_title 검색을 누가 가장 잘 처리하는가?"** 이다.
