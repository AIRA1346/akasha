# Wikidata Manga — Live Shadow (2026-06-10)

> **채널:** `wikidata_manga` · offset **0** · batch **100**  
> **모드:** live SPARQL · Registry **미변경** (shadow only)

---

## KPI

| 지표 | 값 |
|------|-----|
| signalsFetched | 100 |
| **wouldCreate** | **60** |
| mergeCandidates | 40 |
| wouldMerge (externalId) | 0 |
| wouldReject | 0 |
| duplicateRate | 40% |
| mirroringIntegrityPassed | **true** |
| shadowPassed | **true** |
| qualityScore mean | 66.8 (min 50 · max 80) |
| registrySimulation | 430 → **490** (30ms) |
| maxShardConcentration | 3.3% |

---

## 해석

| 구분 | 의미 |
|------|------|
| **wouldCreate 60** | 신규 `wk_` + `externalIds.wikidata` 후보 |
| **mergeCandidates 40** | 제목 fuzzy로 **기존 Registry**와 매칭 — 신규 등록 아님 · `wikidata` **링크 큐** |
| policyRejected 0 | Fact-only gate 통과 |

### mergeCandidate 예 (기존 작품에 Q-id 연결 후보)

- Sundome → 기존 wk
- Strawberry Panic! → 기존 wk
- Karakuri Circus → 기존 wk

### wouldCreate 샘플

- Golden Time (Q101112850) · 2011 · Yuyuko Takemiya
- Attack No. 1 (Q100996676) · 1968 · Chikako Urano
- Bestiarius (Q101247262) · 2011 · Masasumi Kakizaki

---

## Manual Review (10건 샘플)

| 항목 | 결과 |
|------|------|
| readyForTrialWrite (auto) | **true** |
| User Value | high **10** / medium 0 / low 0 |
| policy 위반 | 0 |

---

## 다음 단계

| # | 작업 | 상태 |
|---|------|------|
| 1 | ~~live shadow 100~~ | ✅ 본 기록 |
| 2 | ~~review_report 10건~~ | ✅ auto PASS |
| 3 | **trial insert 60건** (`trial_apply --apply`) | ✅ wk_411–470 |
| 4 | insert 후 `registry_builder` · cursor offset→100 | ✅ 2026-06-10 |
| 5 | Boruto 등 **franchise 중복** 수동 확인 | ⚠️ 권장 |

---

## 실행 명령 (재현)

```bash
dart run tool/discovery/shadow_write.dart --live --channel wikidata_manga
dart run tool/discovery/review_report.dart --live --channel wikidata_manga
```
