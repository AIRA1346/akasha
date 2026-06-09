# Sprint 04-R2 Phase C — E1 Cohort Resolution (G2 달성)

> **단계:** Sprint 04-R2 Phase C — E1 잔여 15건 disposition **실행**  
> **실행일:** 2026-06-10 · Registry **430 works**  
> **도구:** `dart run tool/coverage_sprint_04_e1_resolution.dart --apply`  
> **선행:** [sprint-04-e1-post-gate-audit.md](sprint-04-e1-post-gate-audit.md) · [sprint-04-high-risk-disposition.md](sprint-04-high-risk-disposition.md)  
> **승인:** REVIEW 7건 일괄 · 스카이림 분리 정정 · 니케 포스터 제거 — maintainer 승인 (2026-06-10)

---

## Executive Summary

| 지표 | before | after |
|------|-------:|------:|
| externalId | 201/430 (46.74%) | **215/430 (50.00%)** |
| **G2 (≥50% · 215작)** | -14 | **달성 (정확히 215)** |
| E1 cohort 잔여 | 15 (REVIEW 7 · BLOCK 8) | **0** |
| 게이트 | — | 전부 **PASS** (아래 §4) |

---

## 1. 외부 검증 — 내부 disposition과의 차이

apply 전 Steam 실데이터 검증에서 [disposition](sprint-04-high-risk-disposition.md)의 가정 3건이 정정됨:

| work | 내부 가정 | 실측 (2026-06-10) | 영향 |
|------|----------|-------------------|------|
| wk_000000277 니케 | appId `2358720` = NIKKE listing | **`2358720` = Black Myth: Wukong** · NIKKE는 Steam **미출시** (전용 런처) | steam attach **불가** → identity 복구만. **wk_075의 기존 attach는 정상** (재검토 불필요) |
| wk_000000266 블루 아카이브 | poster appId는 정합 가능 | **`3511790` = Songs of Conquest DLC** (poster도 오염) · 실제 Blue Archive = **`3557620`** (2025-07 Steam 출시) | poster 제거 + `3557620` attach |
| wk_000000144 스카이림 | wk_111과 duplicate → merge 검토 | 144는 **원판(2011)** work — 원판 listing **`72850`**이 SE(`489830`)와 **별도 존재** | merge 불요 — **분리 정정** 후 `72850` attach (E3/E5 해소) |

---

## 2. 실행 웨이브

| 웨이브 | work | 조치 | Δ |
|--------|------|------|:--:|
| **W1** REVIEW 승인 | 143 포털2 `620` · 145 스타듀 `413150` · 146 위처3 `292030` · 276 니어 `524220` · 278 옥토패스 `921570` · 279 P5R `1687950` · 289 용과같이0 `638970` | attach (appId 전건 실측 정합 · E4 false REVIEW) | +7 |
| **W2** E2 정리 | 267 셀레스테 `504230` · 268 단간론파 `413410` · 275 몬헌월드 `582010` · 286 언더테일 `391540` | `titles.en` 프로모 배너(`Save n% on…`) → 정식 영문명 + attach | +4 |
| **W3** 블루 아카이브 | 266 | en=`Blue Archive` · 오염 poster **제거** (공식 library 자산 미제공 — header만 존재) · attach `3557620` | +1 |
| **W4** FFXIV | 270 | en=`FINAL FANTASY XIV Online` (`Site Error` 복구) · attach `39210` | +1 |
| **W5** 스카이림 분리 | 144 | en=`The Elder Scrolls V: Skyrim` · poster → `72850` 자산 (HTTP 200 확인) · attach `72850` | +1 |
| **W6** 니케 identity | 277 | en=`GODDESS OF VICTORY: NIKKE` · Wukong poster **제거** · attach 없음 | 0 |
| **합계** | 15건 | | **+14 → 215** |

**Provenance:** 적용 전건 `extensions.coverageSprint04R2Fix` = 웨이브 라벨 · attach 건 `coverageSprint04ExternalId: steam` · `qualitySignals.externalIdVerified: true`.

**러너 가드:** ① titles.en 기대 prefix 불일치 시 skip ② 기존 externalIds 보유 시 attach 차단 ③ E3/E5 — candidate appId의 타 work 보유 시 차단.

---

## 3. 잔여 없음 확인

`coverage_sprint_04_e1_post_gate` 재실행: cohort **0** · AUTO 0 · REVIEW 0 · BLOCK 0 · `meetsG2: true`.

---

## 4. 게이트 재검증 (@215/430)

| 도구 | 결과 |
|------|:----:|
| `registry_builder --sync-assets` | **PASS** — 430 works · 351 shards · 번들 동기화 |
| `quality_gate --strict` | **PASS** — invalid_en 0 · source_breakage 0 · external_id **0.5000** |
| `coverage_dashboard` | external_id **215/430 (50.00%)** |
| `ci_registry_check` | **전 단계 PASS** (dedupe 0 · data_policy 0 · poster policy OK) |
| `sw1_a_validation` | recall@10 **1.0** (87/87) |
| `urv_a_validation` | 5축 PASS · exactId **215/215** |
| `flutter test` | **160/160** |

**부수 수정:** `steam_v1_bundle_test` 핀 갱신 (402→430 · webtoon 2→5) — Scale 이후 번들 미동기화로 잠복했던 불일치가 본 재빌드에서 표면화.  
**data policy:** `allowedExtensionsKeys`에 `coverageSprint04R2Fix` 추가.

---

## 5. 후속 (범위 외)

| # | 항목 | 비고 |
|---|------|------|
| 1 | E4 범위 재정의 | post-gate 감사 권고 — 한·영 로컬라이즈 false REVIEW 100% ([sprint-04-e4-effectiveness-review.md](sprint-04-e4-effectiveness-review.md)) |
| 2 | 266·277 poster 재확보 | Steam library 자산 부재 — 대체 소스 검토 시 |
| 3 | A5 sub_* 스텁 노출 | webtoon 필터에 Scale probe 스텁 3건 노출 — Steam v1 전 사용자 노출 정책 검토 |

---

## 6. 재현

```bash
dart run tool/coverage_sprint_04_e1_resolution.dart           # dry-run
dart run tool/coverage_sprint_04_e1_resolution.dart --apply
dart run tool/coverage_sprint_04_e1_post_gate.dart --write-json
```

---

## 7. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-10 | Phase C 실행 — E1 15건 resolution · G2 50.00% 달성 |
