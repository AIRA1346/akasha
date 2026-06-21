# Quality Gate MVP — `_isValidEnTitle` 기반

> **목적:** [coverage-quality-governance.md](coverage-quality-governance.md)의 **E7·R3**를 최소 코드로 연결한다.  
> **범위:** `titles.en` syntactic·placeholder 검증 — **신규 enrich · 구조 변경 없음**.  
> **기준일:** 2026-06-09 · Registry **402작**

**산출물**

| 항목 | 경로 |
|------|------|
| 규칙 라이브러리 | `tool/coverage_quality.dart` |
| CI·release 게이트 | `tool/quality_gate.dart` |
| Quality KPI 스냅샷 | `coverage_dashboard` → `coverage_snapshot.json` `quality` 섹션 |

---

## 1. 현재 `_isValidEnTitle` 규칙 (MVP 기준선)

Sprint 03 `coverage_sprint_03_titles_en.dart`에서 추출 → **`tool/coverage_quality.dart`** 로 공유.

| # | 규칙 | 조건 | `InvalidEnReason` |
|---|------|------|-------------------|
| R0 | null/empty | `trim().isEmpty` | `empty` (분모 제외) |
| R1 | 최소 길이 | `length < 2` | `too_short` |
| R2 | TMDB/템플릿 | `#=` · `dataItem` · `{{` | `placeholder` |
| R3 | 한글 in en | Hangul `\u3131–\uD79D` | `hangul_in_en` |
| R4 | 날짜형 only | `2024-01-15` · `2024/01` (연도만 `1984`는 **허용**) | `date_like` |
| R5 | malformed | 제어문자 `\x00-\x08` · `\x0b` · `\x0c` · `\x0e-\x1f` | `malformed` |
| R6 | literal placeholder | `TODO` · `TBD` · `null` · `undefined` (전체 일치, case-insensitive) | `placeholder` |

**통과:** R1–R6 모두 미해당.

```dart
// 요약 API
EnTitleValidation validateEnTitle(String? value);
bool isValidEnTitle(String? value);
```

---

## 2. 어떤 오류를 잡을 수 있는가

| 오류 클래스 | 예시 (Sprint 03) | MVP 규칙 | 한계 |
|-------------|------------------|----------|------|
| **TMDB HTML 파싱 오류** | `#= data.dataItem.date #` | R2 `placeholder` | **의미적 오매칭**(잘못된 작품명)은 **미검출** |
| **placeholder 문자열** | `{{title}}` · `dataItem` | R2 · R6 | 커스텀 placeholder 확장은 후속 |
| **날짜 문자열** | `2024-01-15` · `2024/01` only | R4 `date_like` | 연도 단독 `1984` · 제목 내 연도는 **허용** |
| **malformed title** | 제어문자 · 극단적 짧음 `a` | R1 · R5 | stylistic 오류(비공식 slug)는 **수동(M8)** |

**MVP가 잡지 못하는 것 (의도적 제외):**

- `legacy_slug` vs 공식 표기 불일치
- TMDB ID **잘못된 매핑** (제목은 문법적으로 valid)
- stale / source 변경 — **런타임 fetch 없음** (`source_breakage_count`는 **auto-tier 흔적**만 근사)

---

## 3. CI 통합 방식

### 3.1 명령

```bash
dart run tool/quality_gate.dart              # report only, exit 0
dart run tool/quality_gate.dart --strict     # invalid_en_count > 0 → exit 1
dart run tool/quality_gate.dart --release    # release block 규칙 (§5)
```

### 3.2 모드

| 모드 | 동작 | exit code |
|------|------|-----------|
| **default (report)** | invalid 목록·KPI 출력 | **0** |
| **`--warn`** | invalid 시 stderr WARNING, CI 녹색 유지 | **0** |
| **`--strict`** | `invalid_en_count > 0` → **FAIL** | **1** |
| **`--release`** | §5 Release Block 전부 적용 | **1** |

### 3.3 override

| 메커니즘 | 용도 |
|----------|------|
| **`--override`** CLI | maintainer가 **의도적 예외** 배치 시 1회 통과 (로그에 `OVERRIDE` 기록) |
| **`akasha-db/pipeline/quality_gate_override.json`** | `reason` · `expiresAt` · `approvedBy` — 파일 존재 시 strict/release **완화** (invalid 허용, **문서화된 예외**) |

**원칙:** override는 **수량 KPI 우회가 아님** — Quality FAIL을 **명시적으로 기록**한 채 진행.

### 3.4 CI 배치 (권장)

```
registry_builder (또는 enrich PR)
    ↓
dart run tool/coverage_dashboard.dart    # Coverage + Quality KPI
dart run tool/quality_gate.dart --strict # PR gate
    ↓
merge 후 release branch:
dart run tool/quality_gate.dart --release
```

**Phase 2 MVP:** `flutter test`와 병렬 — **신규 workflow 파일은 선택** (로컬·dogfood_precheck 선행).

---

## 4. Coverage Dashboard — Quality KPI

`coverage_snapshot.json`에 **`quality`** 섹션 추가.

| KPI | 필드 | 정의 |
|-----|------|------|
| **invalid_en_count** | `quality.invalid_en_count` | `titles.en` non-empty 중 `validateEnTitle` FAIL 건수 |
| **invalid_en_rate** | `quality.invalid_en_rate` | `invalid_en_count / titles_en_populated` |
| **source_breakage_count** | `quality.source_breakage_count` | invalid en **이면서** auto-source 흔적 (`extensions.coverageSprint03` ∈ `tmdb_fetch`·`steam_fetch` 또는 `externalIds.tmdb`·steam poster) |

**부가 출력**

- `quality.invalid_en_samples[]` — 최대 20건 (`workId` · `titles.en` · `reason` · `method`)
- `quality.status` — `PASS` if invalid_en_count == 0 else `FAIL`
- `quality.by_reason` — reason별 count

**Coverage vs Quality 출력 분리**

```
kpis.titles_en     → Coverage (있는가)
quality.*          → Quality (valid한가)
```

---

## 5. Release Blocking 규칙

| # | 규칙 | 조건 | MVP |
|---|------|------|:---:|
| RB1 | **invalid en** | `invalid_en_count > 0` | ✅ **Block** |
| RB2 | **source breakage** | `source_breakage_count > 0` | ✅ **Block** (auto-tier 오염) |
| RB3 | **회귀** | SW1/URV 하락 | 별도 도구 (MVP 미포함) |
| RB4 | **override 만료** | override json `expiresAt` 경과 | WARN |

**`--release` 판정**

```
BLOCK if (invalid_en_count > 0 OR source_breakage_count > 0)
        AND NOT (--override OR valid override.json)
else PASS
```

**Sprint 03 baseline:** remediate 후 **invalid_en_count = 0** 기대 — RB1·RB2 **PASS**가 release 전제.

---

## 6. 구현 계획 (MVP)

### 6.1 작업 목록

| 단계 | 작업 | 파일 | 상태 |
|:----:|------|------|:----:|
| 1 | 규칙 공유 모듈 | `tool/coverage_quality.dart` | ✅ |
| 2 | Sprint 03 import 전환 | `tool/coverage_sprint_03_titles_en.dart` | ✅ |
| 3 | Quality gate CLI | `tool/quality_gate.dart` | ✅ |
| 4 | Dashboard `quality` 섹션 | `tool/coverage_dashboard.dart` | ✅ |
| 5 | 본 문서 | `docs/policy/quality-gate-mvp.md` | ✅ |
| 6 | CI workflow 연동 | `.github/workflows/*` | ⏳ 후속 |
| 7 | `dogfood_precheck` 연동 | `scripts/dogfood_precheck.ps1` | ⏳ 후속 |

### 6.2 구현하지 않는 것 (MVP 밖)

- 신규 enrich · shard 수정
- `titles.zh` · alias 품질 규칙
- TMDB live fetch / source freshness probe
- Registry 스키마·ADR 변경

### 6.3 검증 (구현 후)

```bash
dart run tool/coverage_dashboard.dart
dart run tool/quality_gate.dart
dart run tool/quality_gate.dart --strict
dart run tool/quality_gate.dart --release
```

**기대:** Sprint 03 remediate 이후 **exit 0** · snapshot `quality.status = PASS`.

### 6.4 후속 (P0 완료 후)

| 항목 | 설명 |
|------|------|
| CI `--strict` on PR | enrich·registry 변경 시 필수 |
| Q3 spot-check 워크플로 | governance M1–M2 |
| `invalid_en` 추세 알림 | 2회 연속 >0 시 release block 강화 |

---

## 7. 문서 맵

| 문서 | 역할 |
|------|------|
| [coverage-quality-governance.md](coverage-quality-governance.md) | 거버넌스·게이트 정의 |
| [quality-gate-mvp.md]](../policy/quality-gate-mvp.md) | **본 문서** — MVP 규칙·CI·구현 |
| [phase2-late-stage-plan.md](archive/phase2-late-stage-plan.md) | P0 QA |

---

## 8. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-09 | MVP spec + 구현 계획 |
