# Sprint 05 — 만화 카탈로그 확장 (Wikidata)

> **상태:** Phase B → C · **2026-06-10**  
> **전제:** [catalog-growth-charter.md](catalog-growth-charter.md) — SD2.6 hold **해제**  
> **소스:** [discovery-source-decision.md](../discovery-source-decision.md)

---

## 1. 소스 전략

| 소스 | 만화 확장 | 법무 |
|------|-----------|------|
| **Wikidata SPARQL** | ✅ 1차 | CC0 Facts |
| **수동 PR / Contribution** | ✅ 항상 | AKASHA 작성 |
| **AniList API → Git** | ❌ | ToS |
| **Open Library** | 🔜 book/라노벨 | 선별 ingest |

---

## 2. 채널

`manifest.json`: `wikidata_manga` · `patchStatus: active_trial` · `enabled: false` (수동 trial)  
**Spine SSOT:** [wikidata-spine-plan.md](../strategy/wikidata-spine-plan.md) · Q 검증 gate ✅ (code)

---

## 3. 실행

```bash
dart run tool/discovery/shadow_write.dart --live --channel wikidata_manga
dart run tool/discovery/registry_impact_test.dart --live --channel wikidata_manga
# trial insert — gate 통과 후 수동
```

---

## 4. Registry Fact

`title` · `titles` · `releaseYear` · `creator` · `externalIds.wikidata` — description/poster **없음**

---

## 5. 단계

| Phase | 내용 | 상태 |
|-------|------|:----:|
| A | 파이프라인 | ✅ |
| B | live shadow 100 | ✅ [wikidata-manga-shadow-2026-06-10.md](wikidata-manga-shadow-2026-06-10.md) |
| C | Impact · Product Value | ⏳ |
| D | **trial batch insert** | ⏳ (hold **없음** — per-batch gate만) |

---

## 6. G1 목표 (개념)

Steam 체감 전 **만화 주류 밴드** 검색 Gap 축소 — 정확 수치는 Impact 리포트 후 갱신.
