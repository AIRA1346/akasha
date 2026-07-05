# 🌌 AKASHA: Date Semantics Audit Report (UA-114)

## 1. Purpose
*   본 보고서는 `UA-113`에서 `createdAt`/`updatedAt` 시차 가드를 이식한 이후, AKASHA 프로젝트 전역의 날짜/시간 필드가 의미론적으로 올바르게 격리되어 있는지 정적 분석(Static Scan)을 통해 감사한 결과물입니다.
*   본 단계에서는 코드 수정, 리팩토링, 스키마 변경을 일절 수행하지 않습니다. 현황 파악과 리스크 분류만 기록합니다.

---

## 2. Date Semantic Classes

### A. Instant Timestamp
*   **정의**: 실제 시간 흐름 상의 특정 물리적 순간을 나타냅니다.
*   **저장/파싱 기준**: UTC instant로 정규화하여 저장합니다.
*   **원본 offset 보존**: Dart `DateTime`은 원본 timezone offset 문자열을 보존하지 않고 UTC로 정규화합니다. 만약 작성 시점의 로컬 타임존 정보(예: `+09:00`)가 영구 보존되어야 하는 경우, `rawTimestamp`, `sourceOffset`, `sourceTimezone` 등 별도 문자열 필드의 설계가 필요합니다. 본 감사에서는 설계 필요성만 기록하고 구현하지 않습니다.
*   **해당 필드**: `createdAt`, `updatedAt`, `addedAt`, `generatedAt`, `lastSyncTime`, `trashedAt`

### B. Semantic Local Date
*   **정의**: 감상 날짜, 출시일, 생일처럼 timezone 변환을 타면 안 되는 순수 달력 날짜입니다.
*   **보존 규칙**: `DateTime` 객체를 사용하지 않고, `YYYY-MM-DD` 문자열 또는 별도 value object로 유지합니다.
*   **해당 필드**: `watchedDate`, `startedDate`, `finishedDate`, `releaseDate`, `birthDate`, `deathDate`

### C. Ambiguous — Instant or Local Date (분류 미확정)
*   **해당 필드**: `occurredAt`, `timeAnchor`
*   **논점**: 타임라인 이벤트의 `occurredAt`("이 사건이 일어난 시점")은 두 가지로 해석할 수 있습니다.
    *   **Instant 해석**: "2026-07-05T15:30:00Z에 정확히 이 이벤트가 발생했다" → UTC 보존
    *   **Local Date 해석**: "7월 5일에 이 영화를 봤다" → 타임존 변환으로 날짜가 밀리면 안 됨
*   현재 코드에서는 `DateTime`으로 처리되고 있으나, 의미론적 분류가 확정되지 않았습니다. 이 분류는 설계 결정이 필요합니다.

### D. Partial / Approximate Date
*   **정의**: 연도만 있거나(`1994`), 연월만 있거나(`2026-07`), 불명확한 날짜입니다.
*   **보존 규칙**: `DateTime`으로 강제 변환하지 않습니다.
*   **해당 필드**: `releaseYear`, `year`

---

## 3. Field Inventory Table

### 3.1 Instant Timestamp 필드

| Field | Location | Current Parser | Risk | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `createdAt` / `created_at` | `record_summary_index_summary_part.dart` | `_parseVaultInstantAsUtc` | **P3** | UA-113에서 UTC 가드 장착 완료 |
| `updatedAt` / `updated_at` | `record_summary_index_summary_part.dart` | `_parseVaultInstantAsUtc` | **P3** | UA-113에서 UTC 가드 장착 완료 |
| `addedAt` (record_summary, `added_at` 소스키) | `record_summary_index_summary_part.dart` | `_legacyAddedAtDate` | **P1** | UA-113 유보. 시스템 타임스탬프 확정 시 승격 필요 |
| `addedAt` (vault 파서 4종) | `timeline_entry_parser.dart:37`, `entity_journal_parser.dart:35`, `journal_entry_parser.dart:24`, `markdown_parser.dart:277` | `ArchiveRecordContract.createdAtFromYaml` → `DateTime.tryParse` | **P1** | 아래 §3.1.1에서 상세 분석 |
| `generatedAt` (taste index) | `taste_signal.dart:76` | `_date()` → `DateTime.tryParse().toUtc()` | **P2** | 내부 캐시 전용. 항상 `DateTime.now().toUtc()` 로 생성하므로 파일에 ISO UTC 문자열로 저장됨. 재파싱 시 `toUtc()` 체이닝. 실질 리스크 낮음 |
| `generatedAt` (registry) | `registry_models.dart:62` | `json['generatedAt']?.toString()` | **P3** | 문자열로만 비교. `DateTime` 변환 안 함. 안전 |
| `generatedAt` (record/link index) | `record_summary_index_service.dart:252`, `record_link_index_service.dart:314` | `DateTime.now().toUtc().toIso8601String()` (쓰기 전용) | **P3** | 안전 |
| `lastSyncTime` | `registry_sync_service.dart:88` | 런타임 메모리 전용 (`DateTime?`) | **P3** | 영구 저장 안 됨 |
| `trashedAt` | `vault_trash_service.dart:33` | `DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)` (sentinel) | **P3** | sentinel 기본값. 실제 시각은 파일시스템에서 유래 |
| `diskMtime` | `work_detail_vault_sync.dart:23` | `file.lastModifiedSync()` | **P3** | 비교 전용. 볼트에 저장 안 됨 |
| `stat.modified` | `record_summary_index_summary_part.dart` | `stat?.modified.toUtc()` (updatedAt 폴백) | **P3** | OS 파일 시각 → `.toUtc()`. 안전 |

#### §3.1.1 Vault 파서 4종의 `addedAt` 경로 상세 분석

`ArchiveRecordContract.createdAtFromYaml`은 4개 vault 파서(timeline, entity journal, journal, markdown)가 공유하는 공통 진입로입니다. 내부적으로 `parseDateTime` → `DateTime.tryParse(raw.toString())`을 호출하며, UA-113 가드가 적용되어 있지 않습니다.

**그러나 실질 리스크를 정확히 평가하면:**

*   **쓰기 경로**: `writeContractFields` (L41-49)에서 `created_at`과 `updated_at`을 `formatDateTime(createdAt)` → `value.toIso8601String()`로 직렬화합니다.
    *   `createdAt` 인자는 vault store에서 `addedAt`으로 전달됩니다.
    *   vault store의 `addedAt`은 신규 생성 시 `DateTime.now()` (로컬 시각)이고, 기존 파일 업데이트 시 기존 `addedAt`을 그대로 보존합니다.
*   **핵심 문제**: `DateTime.now()`는 로컬 시각이고, 로컬 `DateTime`에 `.toIso8601String()`을 호출하면 **`Z` 접미사가 없는** `2026-07-05T22:30:00.000` 형태가 됩니다. 이 문자열을 나중에 `DateTime.tryParse()`로 재파싱하면 **다시 로컬 시각으로 해석**되어, 다른 타임존의 기기에서 읽을 때 시차가 밀립니다.
*   **리스크 등급**: **P1** (P0이 아닌 이유: 앱이 생성한 파일은 항상 같은 기기에서 읽히는 경향이 강하고, 기기 간 타임존이 다른 경우에만 문제가 발현됨. 하지만 장기적으로는 반드시 교정 필요)

### 3.2 분류 미확정 필드 (Ambiguous)

| Field | Location | Current Parser | Risk | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `occurredAt` | `timeline_entry_parser.dart:108-110` | `DateTime.tryParse(raw.toString())` | **P1** | 가드 없음. 다만 의미론 분류(Instant vs Local Date) 자체가 미확정이므로 가드 적용 전에 설계 결정이 선행되어야 함 |
| `timeAnchor` | `timeline_vault_store.dart:68` | `record.timeAnchor ?? DateTime.now()` | **P1** | UI에서 넘어오는 값. `occurredAt`의 소스 |

### 3.3 Semantic Local Date 필드

| Field | Status | Risk | Notes |
| :--- | :--- | :--- | :--- |
| `watchedDate` | 프로덕션 코드 미검출 | **P2** | 향후 도입 시 `DateTime` 사용 금지 규칙 필요 |
| `startedDate` | 프로덕션 코드 미검출 | **P2** | 동일 |
| `finishedDate` | 프로덕션 코드 미검출 | **P2** | 동일 |
| `releaseDate` | 프로덕션 코드 미검출 | **P2** | 동일 |
| `birthDate` | 프로덕션 코드 미검출 | **P2** | 동일 |
| `deathDate` | 프로덕션 코드 미검출 | **P2** | 동일 |

### 3.4 Partial / Approximate Date 필드

| Field | Location | Current Parser | Risk |
| :--- | :--- | :--- | :--- |
| `releaseYear` | `record_summary_index_summary_part.dart` 등 | `_int()` | **P3** |
| `year` (ID 내) | `work_id_codec.dart` | 문자열/정수 | **P3** |

### 3.5 검색 대상이었으나 프로덕션 코드에서 미검출된 필드

| Field | Status |
| :--- | :--- |
| `deletedAt` / `deleted_at` | 미검출 (doc comment 내 언급만) |
| `restoredAt` / `restored_at` | 미검출 |
| `indexedAt` / `indexed_at` | 미검출 |
| `importedAt` / `imported_at` | 미검출 |

---

## 4. Parser / Serializer Inventory

| Parser / API | Location | Target Fields | Mechanism | Risk | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `_parseVaultInstantAsUtc` | `record_summary_index_parse_part.dart` | `createdAt`, `updatedAt` | `parsed.isUtc` 분기 → UTC wall-clock 복제 | **P3** | UA-113 가드. 안전 |
| `_legacyAddedAtDate` | `record_summary_index_parse_part.dart` | `addedAt` (`added_at` 소스키) | `DateTime.tryParse().toUtc()` | **P1** | offset 없는 문자열을 로컬 해석 후 `.toUtc()` → 시차 밀림 가능 |
| `ArchiveRecordContract.parseDateTime` | `archive_record_contract.dart:66` | 공통 (4개 vault 파서 공유) | `DateTime.tryParse(raw.toString())` | **P1** | 가드 없음. `createdAtFromYaml`, `metadataFromYaml`에서 호출 |
| `ArchiveRecordContract.createdAtFromYaml` | `archive_record_contract.dart:12` | vault 파서 4종의 `addedAt` | `parseDateTime(created_at ?? createdAt ?? added_at ?? addedAt)` | **P1** | `parseDateTime` 경유. created_at/added_at 분기 없음 |
| `ArchiveRecordContract.formatDateTime` | `archive_record_contract.dart:179` | 직렬화 (쓰기) | `value.toIso8601String()` | **P1** | 로컬 `DateTime`이 입력되면 `Z` 없이 출력됨 → 재파싱 시 로컬 해석 |
| `ArchiveRecordContract.writeContractFields` | `archive_record_contract.dart:41` | `created_at`, `updated_at` 직렬화 | `formatDateTime(createdAt)` | **P1** | `createdAt` 인자가 로컬 시각이면 offset 없는 문자열 생성 |
| `TimelineEntryParser._parseDateTime` | `timeline_entry_parser.dart:108` | `occurredAt` | `DateTime.tryParse(raw.toString())` | **P1** | 가드 없음. 의미론 분류 미확정 |
| `taste_signal.dart _date` | `taste_signal.dart:153` | `generatedAt`, `updatedAt` | `DateTime.tryParse().toUtc()` | **P2** | 내부 캐시. 항상 UTC ISO 문자열로 저장되므로 실질 리스크 낮음 |
| `DateTime.now()` | 45개 파일, ~90+ 호출 | 다수 | 호스트 로컬 시각 생성 | 아래 §4.1 참조 | |
| `.toLocal()` | 13개 파일 | UI 표시 | UTC → 로컬 변환 | **P3** | 표시 전용. 저장에 영향 없음 |
| `.toIso8601String()` | 다수 | 직렬화 | DateTime → 문자열 | **조건부** | UTC `DateTime`에서 호출 시 안전. 로컬 `DateTime`에서 호출 시 `Z` 없는 문자열 생성 |
| `fromMillisecondsSinceEpoch` | 5개 지점 | sentinel 기본값 | epoch 0 | **P3** | sentinel. 실제 날짜 아님 |

#### §4.1 `DateTime.now()` 로컬 시각 직접 저장 지점

vault store 계열에서 신규 기록 생성 시 `addedAt = DateTime.now()` (로컬)를 대입한 뒤 `formatDateTime(added)` → `.toIso8601String()`으로 직렬화하는 경로가 존재합니다:

| Location | Line | Code | Impact |
| :--- | :--- | :--- | :--- |
| `journal_vault_store.dart` | L72 | `var addedAt = DateTime.now();` | 신규 journal의 `added_at` 필드에 로컬 시각이 `Z` 없이 기록됨 |
| `timeline_vault_store.dart` | L74 | `var addedAt = DateTime.now();` | 신규 timeline의 `added_at` 필드에 동일 |
| `timeline_vault_store.dart` | L68 | `final occurredAt = record.timeAnchor ?? DateTime.now();` | `timeAnchor` 없으면 `occurred_at`도 로컬 시각으로 기록됨 |

이 경로를 거치면 파일에 `added_at: "2026-07-05T22:30:00.000"` (Z 없음)이 기록되고, 다른 타임존 기기에서 재파싱 시 시차가 밀릴 수 있습니다. 단, `updatedAt`은 항상 `DateTime.now().toUtc()`로 생성되므로 안전합니다.

---

## 5. UA-113 Follow-up

### A. 해결 완료 (Landed)
*   `record_summary_index_summary_part.dart` 내 `createdAt`/`updatedAt` → `_parseVaultInstantAsUtc` 가드 장착
*   `created_at`/`createdAt` 소스키는 `addedAt` 필드에 저장되더라도 UTC instant parser를 경유
*   `created_at`이 `added_at`보다 우선하는 분기 로직 구현 및 테스트 검증 (테스트 #9)

### B. 유보 (Pending)
*   `addedAt`의 `added_at`/`addedAt` 소스키 → `_legacyAddedAtDate` 잔류. 의미 확정 후 승격 또는 분리 필요

### C. 신규 발견 — UA-113 가드의 적용 범위 한계
*   UA-113 가드(`_parseVaultInstantAsUtc`)는 `record_summary_index` 경로(색인 재구축 시 마크다운을 읽어 요약을 만드는 경로)에만 적용되어 있습니다.
*   **vault 파일을 직접 읽는 4개 파서 경로** (`timeline_entry_parser`, `entity_journal_parser`, `journal_entry_parser`, `markdown_parser`)는 `ArchiveRecordContract.parseDateTime` (날것 `DateTime.tryParse`)을 공유하며, 가드가 적용되어 있지 않습니다.
*   **쓰기 경로에서도** `DateTime.now()` (로컬)를 `formatDateTime` → `.toIso8601String()`으로 직렬화하면 `Z` 없는 문자열이 파일에 기록됩니다. 이것이 재파싱 시 시차 밀림의 근본 원인입니다.

---

## 6. Recommended Next Actions

> 아래는 코드 수정 없이 기록하는 권고사항입니다.

1.  **vault store 쓰기 경로의 `DateTime.now()` → `DateTime.now().toUtc()` 교정 검토** (P1)
    *   `journal_vault_store.dart:72`, `timeline_vault_store.dart:74` 등에서 `addedAt = DateTime.now()` → `DateTime.now().toUtc()`로 변경하면, `formatDateTime`이 `Z` 접미사를 포함한 UTC ISO 문자열을 출력합니다.
    *   이것만으로도 향후 재파싱 시 `DateTime.tryParse`가 `isUtc == true`로 해석하므로 시차 밀림이 원천 차단됩니다.
    *   **영향 범위**: vault store 3개 파일 내 `addedAt` 초기화 지점. `updatedAt`은 이미 `.toUtc()` 적용됨.

2.  **`occurredAt` / `timeAnchor`의 의미론 분류 확정** (설계 결정 필요)
    *   Instant("정확한 시점")인지 Semantic Local Date("그 날")인지 확정하면 파서 전략이 결정됩니다.
    *   현재 `SameDayRecordService`에서 `occurredAt.toLocal()`로 같은 날 비교를 수행하는 것으로 보아, "로컬 캘린더상의 날짜"로서의 성격이 강합니다.

3.  **`addedAt` 의미 확정** (UA-113 이월)
    *   볼트 사용 양상 분석을 통해 시스템 타임스탬프(Instant)인지 확정

4.  **Semantic Local Date parser/value object 설계** (P2, 향후)
    *   `watchedDate` 등 도입 시 `DateTime` 사용 금지 규칙 성문화

5.  **테스트 코드 내 `DateTime()` (로컬 생성자) 정리** (P2, 향후)
    *   `test/` 내 `DateTime(2024)`, `DateTime(2026, 6, 19, 23)` 등 로컬 생성자가 다수 사용됨. OS 타임존에 따라 flaky test 유발 가능

---

## 7. Raw Scan Evidence

### 사용한 검색 명령어
```bash
# 1. DateTime API 사용처 (lib, test)
git grep -n -I "DateTime\|tryParse\|parse(\|toUtc(\|toLocal(\|toIso8601String\|millisecondsSinceEpoch" -- lib test

# 2. 날짜 필드명 (lib, test)
git grep -n -I "createdAt\|created_at\|updatedAt\|updated_at\|addedAt\|added_at\|deletedAt\|restoredAt\|indexedAt\|importedAt\|generatedAt\|watchedDate\|startedDate\|finishedDate\|releaseDate\|birthDate\|deathDate\|timestamp\|date\|Date\|year\|month" -- lib test

# 3. scripts/ 및 docs/ 스캔
git grep -n -I "DateTime\|date\|Date\|timestamp\|year\|month" -- scripts docs

# 4. DateTime.now() 빈도 (lib)
git grep -c "DateTime\.now()" -- lib

# 5. DateTime.now() 상세 (vault 파서 계열)
git grep -n "DateTime\.now()" -- lib/services/timeline_entry_parser.dart lib/services/timeline_vault_store.dart lib/services/entity_vault_store.dart lib/services/journal_vault_store.dart lib/services/entity_journal_parser.dart lib/services/journal_entry_parser.dart

# 6. .toLocal() 사용처 (lib)
git grep -n "\.toLocal()" -- lib

# 7. epoch 기반 생성자 (lib, test)
git grep -n "fromMillisecondsSinceEpoch\|fromMicrosecondsSinceEpoch" -- lib test

# 8. createdAtFromYaml 호출 추적
git grep -n "createdAtFromYaml" -- lib

# 9. 미검출 필드 확인
git grep -n "deletedAt\|deleted_at\|restoredAt\|restored_at\|indexedAt\|indexed_at\|importedAt\|imported_at\|startedDate\|finishedDate\|birthDate\|deathDate" -- lib test

# 10. _date 헬퍼 추적 (taste_signal)
git grep -n "_date(" -- lib/core/archiving/taste_signal.dart
```

### 소스코드 직접 열람 확인 목록
| File | Lines | 확인 내용 |
| :--- | :--- | :--- |
| `timeline_entry_parser.dart` | 전체 (121줄) | `_parseDateTime` 가드 없음 확인. `occurredAt` 파싱 경로 확인 |
| `timeline_vault_store.dart` | L1-110 | `addedAt = DateTime.now()` (로컬) 확인. `occurredAt = record.timeAnchor ?? DateTime.now()` 확인 |
| `journal_entry_parser.dart` | 전체 (92줄) | `serialize`에서 `addedAt`을 `formatDateTime`으로 직렬화 확인 |
| `journal_vault_store.dart` | L60-105 | `addedAt = DateTime.now()` (로컬) 확인 |
| `archive_record_contract.dart` | L12-19, L41-49, L66-69, L179-181 | `createdAtFromYaml`, `writeContractFields`, `parseDateTime`, `formatDateTime` 전체 경로 확인 |
| `same_day_record_service.dart` | 전체 (83줄) | `occurredAt.toLocal()` 비교 — 의도적 로컬 날짜 비교 확인 |
| `taste_signal.dart` | L60-100, L150-157 | `_date` 헬퍼 → `DateTime.tryParse().toUtc()` 확인 |

### docs/ 스캔 결과
*   `docs/history/programs/r2e-phase3-collectible-collection-architecture-audit.md` — `DateTime createdAt`, `DateTime updatedAt` 설계 기술 존재. 현재 구현과 부합하나, UTC 보존 규칙에 대한 언급은 없음.
*   `docs/history/programs/r2e-phase1-entity-gallery-sort-audit.md` — `updatedAt` 필드 부재에 대한 분석 존재. entity catalog에 `updatedAt`이 없다는 점을 문서화.
*   `scripts/` — 날짜 관련 로직 미검출 (빌드/검증 스크립트만 존재).
