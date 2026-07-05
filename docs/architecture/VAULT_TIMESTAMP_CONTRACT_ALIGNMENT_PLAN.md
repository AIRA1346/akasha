# UA-115: Vault Timestamp Contract Alignment — Implementation Plan

## 1. Purpose

AKASHA의 시스템 타임스탬프(`createdAt`, `updatedAt`, `addedAt`, `generatedAt`)가 **생성 → 직렬화 → 파일 저장 → 재파싱 → 인덱싱** 과정에서 동일한 UTC instant 계약을 따르도록 정렬한다.

UA-113에서 `record_summary_index` 경로(인덱싱 시 읽기)에만 가드를 장착했으나, vault 파일의 쓰기 경로 및 직접 파싱 경로에는 가드가 없는 상태다. 본 단계에서 이 불일치를 해소한다.

---

## 2. Current Problem

### 2.1 쓰기 경로: `Z` 없는 timestamp가 파일에 기록됨

vault store 3종(`journal_vault_store`, `timeline_vault_store`, `entity_vault_store`)이 신규 레코드 생성 시 `addedAt`을 다음과 같이 설정한다:

| Location | Code | `isUtc` |
| :--- | :--- | :--- |
| [journal_vault_store.dart:72](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/journal_vault_store.dart#L72) | `var addedAt = DateTime.now();` | **false** (local) |
| [timeline_vault_store.dart:74](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/timeline_vault_store.dart#L74) | `var addedAt = DateTime.now();` | **false** (local) |
| [akasha_item.dart:58](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/models/akasha_item.dart#L58) | `addedAt = addedAt ?? DateTime.now(),` | **false** (local) |

이 로컬 `DateTime`은 직렬화 경로를 거쳐 파일에 쓰인다:

```
vault_store → Parser.serialize(addedAt: localDateTime)
  → ArchiveRecordContract.formatDateTime(localDateTime)
    → localDateTime.toIso8601String()
    → "2026-07-05T22:30:00.000" (Z 없음)
```

`writeContractFields`도 이 `addedAt`을 `createdAt` 인자로 받아 `created_at` 필드에 동일하게 기록한다:

```
→ created_at: "2026-07-05T22:30:00.000" (Z 없음)
```

반면 `updatedAt`은 항상 `DateTime.now().toUtc()`로 생성되므로:

```
→ updated_at: "2026-07-05T13:30:00.000Z" (Z 있음, 안전)
```

### 2.2 읽기 경로: vault 파서 4종에 UTC 가드 없음

파일에서 다시 읽을 때 다음 경로를 탄다:

```
Parser.parse(content)
  → ArchiveRecordContract.createdAtFromYaml(yaml)
    → ArchiveRecordContract.parseDateTime(raw)
      → DateTime.tryParse("2026-07-05T22:30:00.000")
      → DateTime(isUtc: false)  ← 호스트 로컬 해석
```

*   **같은 타임존 기기**: 문제 없음 (쓰기와 읽기의 로컬 해석이 동일)
*   **다른 타임존 기기**: 시차 밀림 발생 (의도하지 않은 UTC 변환)
*   **record_summary_index 경로**: UA-113 `_parseVaultInstantAsUtc`가 적용되어 있어 안전
*   **vault 파서 4종 경로**: 가드 없음

### 2.3 계약 불일치 요약

| 경로 | `created_at` / `added_at` 파서 | `updated_at` 파서 | `created_at` writer |
| :--- | :--- | :--- | :--- |
| record_summary_index (인덱싱) | `_parseVaultInstantAsUtc` (UA-113 가드) | `_parseVaultInstantAsUtc` | N/A (읽기 전용) |
| timeline_entry_parser (vault 직접) | `ArchiveRecordContract.parseDateTime` (가드 없음) | `ArchiveRecordContract.parseDateTime` (가드 없음) | `formatDateTime(local)` → Z 없음 |
| entity_journal_parser (vault 직접) | 동일 | 동일 | 동일 |
| journal_entry_parser (vault 직접) | 동일 | 동일 | 동일 |
| markdown_parser (vault 직접) | 동일 | 동일 | N/A (파일 기반 직접 읽기) |

---

## 3. Current Read Paths

### 3.1 `ArchiveRecordContract.parseDateTime` (공통 진입로)

```dart
// archive_record_contract.dart:66-69
static DateTime? parseDateTime(Object? raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
  // → Z 없는 문자열 입력 시 isUtc == false
}
```

**호출자 목록:**

| 호출자 | 파일 | 대상 필드 |
| :--- | :--- | :--- |
| `createdAtFromYaml` | `archive_record_contract.dart:12` | `created_at`, `createdAt`, `added_at`, `addedAt` |
| `metadataFromYaml` | `archive_record_contract.dart:31` | `updated_at`, `updatedAt` |
| `TimelineEntryParser._parseDateTime` | `timeline_entry_parser.dart:108` | `occurred_at` (별도 로컬 래퍼) |

### 3.2 `createdAtFromYaml` 우선순위

```dart
// archive_record_contract.dart:12-18
static DateTime? createdAtFromYaml(Map<dynamic, dynamic> yaml) {
  return parseDateTime(
    yaml['created_at'] ??
        yaml['createdAt'] ??
        yaml['added_at'] ??
        yaml['addedAt'],
  );
}
```

*   `created_at` / `createdAt` / `added_at` / `addedAt`을 **구분 없이** 하나의 파서(`parseDateTime`)로 처리
*   UA-113의 record_summary_index 분기(`created_at` → UTC parser, `added_at` → legacy parser)와 **다름**

### 3.3 UA-113 `_parseVaultInstantAsUtc` (record_summary_index 전용)

```dart
// record_summary_index_parse_part.dart:114-142
DateTime? _parseVaultInstantAsUtc(Object? raw) {
  // 1. raw DateTime → .toUtc()
  // 2. parsed.isUtc == false → UTC wall-clock 복제
  // 3. parsed.isUtc == true → 그대로 유지
}
```

*   `record_summary_index`의 `fromYamlMap` 경로에서만 사용
*   `fromWorkItem`, `fromEntityEntry`, `fromJournalEntry`, `fromTimelineEntry` 경로는 vault 파서가 반환한 `DateTime` 객체를 **그대로 전달**하므로, vault 파서의 파싱 품질에 의존

---

## 4. Current Write Paths

### 4.1 `ArchiveRecordContract.formatDateTime`

```dart
// archive_record_contract.dart:179-181
static String formatDateTime(DateTime value) {
  return value.toIso8601String();
  // local DateTime → "2026-07-05T22:30:00.000" (Z 없음)
  // UTC DateTime   → "2026-07-05T13:30:00.000Z" (Z 있음)
}
```

### 4.2 `writeContractFields`

```dart
// archive_record_contract.dart:41-49
static void writeContractFields(
  StringBuffer buffer, {
  required DateTime createdAt,      // ← 로컬일 수 있음
  ArchiveRecordMetadata metadata,
}) {
  final updatedAt = metadata.updatedAt ?? DateTime.now().toUtc(); // ← 항상 UTC
  buffer
    ..writeln('created_at: "${formatDateTime(createdAt)}"')   // ← Z 없을 수 있음
    ..writeln('updated_at: "${formatDateTime(updatedAt)}"');   // ← Z 있음
}
```

### 4.3 vault store별 `addedAt` / `createdAt` 생성 지점

| Store | 신규 생성 시 addedAt 소스 | serialize의 createdAt 인자 | 결과 |
| :--- | :--- | :--- | :--- |
| `journal_vault_store.dart` | `DateTime.now()` (L72, local) | `added` (= addedAt, L53) | Z 없음 |
| `timeline_vault_store.dart` | `DateTime.now()` (L74, local) | `added` (= addedAt, L77 in parser) | Z 없음 |
| `entity_vault_store.dart` | `entity.addedAt` (L87) | `added` (= addedAt, L75 in parser) | entity 소스에 따라 다름 |
| `file_service_save.dart` | `item.addedAt` | `added` (= addedAt, markdown_parser serialize) | item 소스에 따라 다름 |

**`AkashaItem.addedAt` 기본값**: `DateTime.now()` (L58, local) — Z 없음
**`UserCatalogEntity.addedAt` 기본값**: `DateTime.now().toUtc()` (L90, UTC) — Z 있음

> `entity_vault_store`는 이미 안전할 가능성이 높다 (`UserCatalogEntity.create`가 `.toUtc()`를 사용하므로). 다만 외부에서 비-UTC `addedAt`을 전달받는 경로가 존재할 수 있다.

### 4.4 `updatedAt` 쓰기 경로

모든 vault store에서 `updatedAt: DateTime.now().toUtc()`로 생성. **안전**.

---

## 5. Contract Proposal

### 5.1 Writer 계약

> System timestamp는 저장 전 반드시 `.toUtc()`를 거치거나, 전용 writer를 통해 UTC ISO string(`Z` 접미사 포함)으로 직렬화한다.

**구체적 변경:**

1.  `ArchiveRecordContract.formatDateTime(DateTime value)` 변경:
    ```dart
    static String formatDateTime(DateTime value) {
      return value.toUtc().toIso8601String();
      // 항상 Z 접미사 포함 출력 보장
    }
    ```
    *   이 한 줄 변경으로 모든 vault store의 `created_at`, `added_at`, `updated_at`, `occurred_at` 직렬화가 UTC ISO 문자열로 통일됨
    *   단, `occurredAt`도 이 경로를 타므로 §10 Open Decision #2 참조

2.  vault store의 `addedAt` 초기값을 `DateTime.now().toUtc()`로 변경:
    *   `journal_vault_store.dart:72` → `var addedAt = DateTime.now().toUtc();`
    *   `timeline_vault_store.dart:74` → `var addedAt = DateTime.now().toUtc();`
    *   `timeline_vault_store.dart:68` → `final occurredAt = record.timeAnchor ?? DateTime.now().toUtc();` (Open Decision #2에 따라 변경 여부 결정)
    *   `akasha_item.dart:58` → `addedAt = addedAt ?? DateTime.now().toUtc(),`

### 5.2 Reader 계약

> System timestamp는 읽을 때 UA-113의 `parseVaultInstantAsUtc`와 동일한 정책을 따른다.

**구체적 변경:**

1.  `_parseVaultInstantAsUtc` 로직을 `ArchiveRecordContract`로 승격하여 `parseSystemTimestamp` (또는 동등한 이름)로 공개:
    ```dart
    static DateTime? parseSystemTimestamp(Object? raw) {
      // 1. raw DateTime → .toUtc()
      // 2. Z 없는 문자열 → UTC wall-clock 복제 (legacy 호환)
      // 3. Z 있는 문자열 → 그대로 UTC 유지
    }
    ```

2.  `ArchiveRecordContract.parseDateTime`은 non-system 필드용으로 유지하거나, 이름을 `parseDateTimeRaw`로 변경하여 system timestamp에 실수로 사용되는 것을 방지

3.  `createdAtFromYaml`을 `parseSystemTimestamp` 기반으로 변경:
    ```dart
    static DateTime? createdAtFromYaml(Map<dynamic, dynamic> yaml) {
      return parseSystemTimestamp(
        yaml['created_at'] ?? yaml['createdAt'] ??
        yaml['added_at'] ?? yaml['addedAt'],
      );
    }
    ```

4.  `metadataFromYaml`의 `updatedAt` 파싱도 `parseSystemTimestamp`로 변경:
    ```dart
    updatedAt: parseSystemTimestamp(yaml['updated_at'] ?? yaml['updatedAt']),
    ```

---

## 6. Affected Files

### 6.1 Writer 수정 (최소)

| File | Change | Risk |
| :--- | :--- | :--- |
| [archive_record_contract.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/core/archiving/archive_record_contract.dart) | `formatDateTime` → `.toUtc().toIso8601String()` | 낮음 — 기존 UTC DateTime 입력 시 동작 불변 |
| [journal_vault_store.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/journal_vault_store.dart) | L72 `DateTime.now()` → `DateTime.now().toUtc()` | 낮음 |
| [timeline_vault_store.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/timeline_vault_store.dart) | L74 `DateTime.now()` → `DateTime.now().toUtc()` | 낮음 |
| [timeline_vault_store.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/timeline_vault_store.dart) | L68 `DateTime.now()` → `DateTime.now().toUtc()` | **Open Decision #2** |
| [akasha_item.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/models/akasha_item.dart) | L58 `DateTime.now()` → `DateTime.now().toUtc()` | 낮음 — UI 표시 시 `.toLocal()` 변환 필요 여부 확인 필요 |

### 6.2 Reader 수정 (핵심)

| File | Change | Risk |
| :--- | :--- | :--- |
| [archive_record_contract.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/core/archiving/archive_record_contract.dart) | `parseSystemTimestamp` 신규 메서드 추가. `createdAtFromYaml`, `metadataFromYaml` 변경 | 중간 — 4개 vault 파서에 영향 |
| [record_summary_index_parse_part.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/record_summary_index_parse_part.dart) | `_parseVaultInstantAsUtc` → `ArchiveRecordContract.parseSystemTimestamp` 호출로 대체 | 낮음 — 동작 동일 |
| [record_summary_index_service.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/record_summary_index_service.dart) | `@visibleForTesting` wrapper가 새 위치를 가리키도록 변경 | 낮음 |

### 6.3 수정 불필요 (이미 안전)

| File | Reason |
| :--- | :--- |
| `entity_vault_store.dart` `updatedAt` | 항상 `DateTime.now().toUtc()` |
| `journal_vault_store.dart` `updatedAt` | 동일 |
| `timeline_vault_store.dart` `updatedAt` | 동일 |
| `taste_index_service.dart` | `DateTime.now().toUtc()` + `_date()` → `.toUtc()` |
| `record_link_index_service.dart` | `DateTime.now().toUtc().toIso8601String()` |
| `vault_readme_writer.dart` | `DateTime.now().toUtc().toIso8601String()` |
| `user_catalog_entity.dart` | `DateTime.now().toUtc()` |

---

## 7. Non-goals

이번 UA-115에서 다루지 않는 항목:

*   `occurredAt` / `timeAnchor`의 의미론 분류 확정 (별도 UA)
*   Semantic Local Date (`watchedDate`, `releaseDate` 등) 파서/모델 도입
*   Partial Date (`releaseYear` 등) 모델 도입
*   `LocalDate` value object 설계
*   기존 vault 파일의 일괄 마이그레이션 (Z 없는 기존 파일을 Z 있는 파일로 rewrite)
*   전체 `DateTime` 사용처 일괄 변경
*   `SameDayRecordService`의 `.toLocal()` 비교 로직 변경

---

## 8. Migration / Backward Compatibility

### 8.1 기존 vault 파일 호환성

`parseSystemTimestamp`의 핵심 로직은 "Z 없는 문자열 → UTC wall-clock 복제"다. 이것은:

*   **기존 Z 없는 파일**: `DateTime.tryParse` → `isUtc == false` → `DateTime.utc(wall-clock 복제)` → 기존과 동일한 숫자의 UTC DateTime. (legacy wall-clock 및 best-effort compatibility)
*   **신규 Z 있는 파일**: `DateTime.tryParse` → `isUtc == true` → 그대로 유지. **정확.**
*   **`+09:00` 같은 offset 포함 파일**: `DateTime.tryParse` → `isUtc == true` (Dart가 UTC로 정규화) → 그대로 유지. **정확.**

> [!WARNING]
> legacy timezone-less timestamp는 wall-clock 숫자를 보존한다.
> 다만 과거 local instant로 작성된 값의 absolute instant를 복원하지는 않는다.
> 기존 vault의 표시/정렬 영향은 별도 확인이 필요하다.
> 따라서 완전한 "하위 호환 보장"이라기보다는 "best-effort compatibility" 정책으로 해석해야 한다.

### 8.2 쓰기 변경의 영향

*   `formatDateTime`이 `.toUtc().toIso8601String()`으로 변경되면, 향후 새로 쓰거나 업데이트되는 파일부터 `Z` 접미사가 포함됨
*   기존 파일은 편집될 때 자연스럽게 `Z` 포함 형식으로 업데이트됨 (점진적 마이그레이션)
*   `git diff`에서 timestamp 형식 차이가 보일 수 있으나, 의미 변경은 없음

### 8.3 `addedAt`에서 `created_at`로의 중복 기록 문제

현재 vault 파서들은 serialize 시 `added_at`과 `created_at`을 **모두** 기록한다:
*   `added_at`: 파서 고유 직렬화 (L90 in entity_journal_parser, L74 in timeline_entry_parser, L53 in journal_entry_parser)
*   `created_at`: `writeContractFields`에서 `createdAt: added` (= addedAt)로 기록

즉 같은 값이 두 필드에 기록된다. 쓰기 경로에서 `addedAt`이 UTC가 되면 `created_at`도 자동으로 UTC가 된다.

### 8.4 `AkashaItem.addedAt` 기본값 변경 영향

*   `AkashaItem`은 markdown_parser가 파싱한 결과를 담는 모델
*   `addedAt` 기본값이 `DateTime.now()` → `DateTime.now().toUtc()`로 바뀌면, UI에서 `addedAt`을 **직접** 표시하는 곳에서 `.toLocal()` 변환이 누락되었을 경우 UTC 시각이 보일 수 있음
*   확인 필요: `addedAt`을 직접 UI에 표시하는 곳이 있는지 (현재 `.toLocal()` 변환 없이)

---

## 9. Test Plan

### 9.1 기존 테스트 현황

*   [parse_vault_instant_as_utc_test.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/test/parse_vault_instant_as_utc_test.dart) — 9개 시나리오. `_parseVaultInstantAsUtc` 검증 전용.
*   `ArchiveRecordContract.parseDateTime`에 대한 직접 테스트: **없음**
*   `formatDateTime`에 대한 직접 테스트: **없음**

### 9.2 신규 테스트 계획

#### A. Writer 테스트: `formatDateTime`이 항상 UTC `Z` string을 출력하는지

| # | Input | Expected Output |
| :--- | :--- | :--- |
| W1 | `DateTime.utc(2026, 7, 5, 12, 0)` | `"2026-07-05T12:00:00.000Z"` |
| W2 | `DateTime(2026, 7, 5, 21, 0)` (local KST) | `"2026-07-05T12:00:00.000Z"` (KST-9) |
| W3 | `DateTime.now()` (local) | 끝이 `Z`로 끝나는지 확인 |

#### B. Reader 테스트: `parseSystemTimestamp`가 timezone-less를 UTC wall-clock으로 복제하는지

| # | Input | Expected | Notes |
| :--- | :--- | :--- | :--- |
| R1 | `"2026-07-05T12:00:00.000Z"` | `DateTime.utc(2026, 7, 5, 12, 0)` | Z 있는 UTC |
| R2 | `"2026-07-05T12:00:00.000"` | `DateTime.utc(2026, 7, 5, 12, 0)` | Z 없는 legacy → wall-clock 복제 |
| R3 | `"2026-07-05T12:00:00.000+09:00"` | `DateTime.utc(2026, 7, 5, 3, 0)` | offset → absolute instant |
| R4 | `null` | `null` | null 처리 |
| R5 | `""` | `null` | 빈 문자열 |
| R6 | `"not-a-date"` | `null` | 잘못된 입력 |

#### C. `createdAtFromYaml` 통합 테스트

| # | YAML keys | Expected | Notes |
| :--- | :--- | :--- | :--- |
| C1 | `created_at: "2026-07-05T12:00:00.000"` | `DateTime.utc(2026, 7, 5, 12, 0)` | snake_case, Z 없음 → wall-clock 복제 |
| C2 | `createdAt: "2026-07-05T12:00:00.000Z"` | `DateTime.utc(2026, 7, 5, 12, 0)` | camelCase, Z 있음 |
| C3 | `added_at: "2026-07-05T09:00:00.000"` | `DateTime.utc(2026, 7, 5, 9, 0)` | added_at only |
| C4 | `created_at` + `added_at` 동시 존재 | `created_at` 값 사용 | 우선순위 확인 |

#### D. Roundtrip 테스트: serialize → parse가 동일한 UTC instant를 보존하는지

| # | 시나리오 | 검증 |
| :--- | :--- | :--- |
| D1 | `JournalEntryParser.serialize(addedAt: utcNow)` → `JournalEntryParser.parse(result)` | `.addedAt == utcNow` |
| D2 | `TimelineEntryParser.serialize(...)` → `TimelineEntryParser.parse(result)` | `.addedAt`, `.recordMetadata.updatedAt` 보존 |
| D3 | `EntityJournalParser.serialize(...)` → `EntityJournalParser.parse(result)` | 동일 |

#### E. Non-goals 검증: timeline `occurredAt`/`timeAnchor`가 변경되지 않는 것

| # | 시나리오 | 검증 |
| :--- | :--- | :--- |
| N1 | `occurredAt`의 파서가 `_parseDateTime` (별도 로컬 래퍼)를 유지하는지 | 코드 경로 확인 |
| N2 | `occurred_at` 필드의 직렬화 경로가 `formatDateTime`을 타더라도, `occurredAt`의 *읽기* 경로가 `parseSystemTimestamp`를 타지 않는지 | Open Decision #2에 의존 |

#### F. 기존 vault fixture 호환성 테스트

| # | 시나리오 | 검증 |
| :--- | :--- | :--- |
| F1 | Z 없는 `created_at` 기존 파일 → parse → 올바른 UTC instant | wall-clock 복제 동작 |
| F2 | Z 있는 `created_at` 신규 파일 → parse → 올바른 UTC instant | 직접 UTC 유지 |
| F3 | 전체 테스트 스위트 (`flutter test`) 통과 | 기존 테스트 회귀 없음 |

---

## 10. Open Decisions

### Decision 1: `addedAt`을 system timestamp로 확정할 것인가?

*   **현재 상태**: `_legacyAddedAtDate`로 격리되어 있음 (UA-113 유보)
*   **옵션 A**: System timestamp로 확정 → `parseSystemTimestamp` 적용
*   **옵션 B**: Semantic date 가능성을 남겨둠 → 별도 파서 유지
*   **영향**: `createdAtFromYaml`이 `created_at ?? createdAt ?? added_at ?? addedAt` 전부를 `parseSystemTimestamp`로 처리하게 되면, `added_at`도 system timestamp 계약을 따르게 됨
*   **권고**: 현재 모든 `addedAt` 쓰기 경로가 `DateTime.now()`로 시스템 시각을 생성하고 있으므로, 사실상 system timestamp에 해당. 단, 사용자가 수동으로 vault 파일의 `added_at`을 편집하여 semantic date로 활용할 가능성이 있다면 유보가 적절

### Decision 2: `occurredAt` / `timeAnchor`의 `formatDateTime` 경로

*   **현재 상태**: `occurredAt`은 `TimelineEntryParser.serialize`에서 `formatDateTime(occurredAt)`으로 직렬화됨 (L72)
*   **`formatDateTime`을 `.toUtc()`로 변경하면**: `occurredAt`도 자동으로 UTC 변환됨
*   **문제**: `occurredAt`이 "7월 5일에 이 영화를 봤다"라는 의미라면 UTC 변환이 날짜를 밀릴 수 있음 (KST 21:00 → UTC 12:00 같은 날이지만, 23:30 → UTC 다음 날 등)
*   **옵션 A**: `formatDateTime` 변경 시 `occurredAt`도 UTC로 통일. `SameDayRecordService.sameLocalDay`가 `.toLocal()`로 비교하므로 UI 표시에는 문제 없음
*   **옵션 B**: `occurredAt`에는 별도 `formatDateTimeRaw` (UTC 변환 없는 원본 보존)를 사용
*   **권고**: `formatDateTime`에서 `.toUtc()`를 적용하되, `occurredAt`의 *읽기* 경로에서도 `parseSystemTimestamp`를 적용하여 roundtrip을 보장하는 것이 일관됨. 다만 이 결정은 `occurredAt`의 의미론 확정과 연결되므로 주인님 결정 필요

### Decision 3: `parseVaultInstantAsUtc`의 위치

*   **현재**: `record_summary_index_parse_part.dart` 내 private 함수 + `RecordSummaryIndexService`의 `@visibleForTesting` wrapper
*   **옵션 A**: `ArchiveRecordContract.parseSystemTimestamp`로 승격 → 가장 자연스러운 위치. 모든 vault 파서가 이미 `ArchiveRecordContract`를 import
*   **옵션 B**: `lib/core/utils/vault_timestamp.dart` 별도 utility → 관심사 분리
*   **옵션 C**: `VaultTimestampCodec` 클래스 (read + write 캡슐화) → 과도한 추상화 가능성
*   **권고**: **옵션 A** — `ArchiveRecordContract`는 이미 vault frontmatter 계약의 중심이며, `parseDateTime`과 `formatDateTime`이 여기에 있으므로, system timestamp 전용 파서도 여기에 두는 것이 응집도 면에서 적절

### Decision 4: timestamp writer 위치

*   **현재**: `formatDateTime`이 `ArchiveRecordContract`에 있음
*   **변경 내용**: `.toUtc().toIso8601String()`로 한 줄 수정
*   **별도 writer가 필요한가?**: 현재 단계에서는 `formatDateTime` 변경만으로 충분. `VaultTimestampCodec` 같은 별도 클래스는 과도

---

## 완료 보고 (Readiness Assessment)

### ✅ Pass

| 항목 | 근거 |
| :--- | :--- |
| `updatedAt` 쓰기 경로 | 모든 vault store에서 `DateTime.now().toUtc()`. 안전 |
| `updatedAt` 인덱싱 읽기 경로 | `_parseVaultInstantAsUtc` 적용 (UA-113). 안전 |
| `generatedAt` (record/link index) | `DateTime.now().toUtc().toIso8601String()`. 안전 |
| `generatedAt` (taste index) | `DateTime.now().toUtc()` 생성 + `_date()` → `.toUtc()` 파싱. 안전 |
| `generatedAt` (registry) | 문자열로만 비교. `DateTime` 변환 안 함 |
| `lastSyncTime` | 메모리 전용. 영구 저장 안 됨 |
| 기존 vault 파일 호환 | `parseSystemTimestamp`의 wall-clock 복제가 하위 호환 보장 |

### 🔧 Needs Fix

| 항목 | 현재 문제 | 수정 방향 |
| :--- | :--- | :--- |
| `formatDateTime` | 로컬 DateTime → Z 없는 문자열 | `.toUtc().toIso8601String()` |
| `journal_vault_store.dart:72` | `DateTime.now()` (local) | `.toUtc()` 추가 |
| `timeline_vault_store.dart:74` | `DateTime.now()` (local) | `.toUtc()` 추가 |
| `akasha_item.dart:58` | `DateTime.now()` (local) | `.toUtc()` 추가 |
| `ArchiveRecordContract.parseDateTime` | 가드 없는 날것 `DateTime.tryParse` | `parseSystemTimestamp` 도입 후 `createdAtFromYaml`, `metadataFromYaml` 변경 |

### ❓ Needs Decision

| # | 결정 사항 | 영향 |
| :--- | :--- | :--- |
| D1 | `addedAt`을 system timestamp로 확정할 것인가? | `createdAtFromYaml`의 `added_at`/`addedAt` 파서 결정 |
| D2 | `occurredAt`/`timeAnchor`에 `formatDateTime` UTC 변환을 적용할 것인가? | `timeline_vault_store.dart:68`의 수정 여부 |
| D3 | `parseSystemTimestamp`의 위치 | `ArchiveRecordContract` vs 별도 utility |
| D4 | 기존 `parseDateTime`의 이름을 변경할 것인가? (실수 방지) | `parseDateTimeRaw` 등으로 rename 여부 |

### ⚠️ P0/P1 Risk

| Risk | Level | Description |
| :--- | :--- | :--- |
| vault 파서 4종의 `created_at`/`updated_at` 읽기 | **P1** | `ArchiveRecordContract.parseDateTime` 가드 없음. 다른 타임존 기기에서 재파싱 시 시차 밀림 |
| vault store 3종의 `addedAt` 쓰기 | **P1** | `DateTime.now()` (local) → `formatDateTime` → Z 없는 문자열 기록 |
| `AkashaItem.addedAt` 기본값 | **P1** | `DateTime.now()` (local). markdown_parser의 작품 레코드 경로 |

### 📐 추천되는 최소 수정 범위

1.  `ArchiveRecordContract.formatDateTime` — 1줄 수정 (`.toUtc()` 추가)
2.  `ArchiveRecordContract.parseSystemTimestamp` — 신규 메서드 (~20줄, `_parseVaultInstantAsUtc` 이식)
3.  `ArchiveRecordContract.createdAtFromYaml` — `parseDateTime` → `parseSystemTimestamp` 교체
4.  `ArchiveRecordContract.metadataFromYaml` — `updatedAt` 파싱 교체
5.  vault store 3개 + `akasha_item.dart` — `DateTime.now()` → `DateTime.now().toUtc()` (4줄)
6.  `record_summary_index_parse_part.dart` — `_parseVaultInstantAsUtc`를 `ArchiveRecordContract.parseSystemTimestamp` 호출로 대체
7.  테스트 — Writer/Reader/Roundtrip/호환성 (~20 케이스)

**총 예상 변경**: 소스 파일 6-7개, 코드 변경량 약 30줄, 테스트 약 20 케이스

### ✅ 구현 전 확인해야 할 결정사항

1.  **Decision 1** (`addedAt` 확정 여부) — 이것이 결정되어야 `createdAtFromYaml`에서 `added_at`/`addedAt` 소스키 처리 전략이 확정됨
2.  **Decision 2** (`occurredAt`에 UTC 변환 적용 여부) — `formatDateTime` 변경의 부수 효과 범위 결정
3.  **Decision 3** (`parseSystemTimestamp` 위치) — 파일 구조 결정
4.  `AkashaItem.addedAt`을 `.toUtc()`로 변경 시 UI에 직접 표시하는 곳이 있는지 확인

<parameter name="Description">UA-115 planning document with full read/write path analysis, contract proposal, affected files, test plan, and open decisions
