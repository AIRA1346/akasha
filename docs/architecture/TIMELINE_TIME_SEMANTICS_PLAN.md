# UA-116: Timeline Time Semantics — Audit & Plan

## 1. Purpose
*   본 문서는 `UA-115`에서 시스템 타임스탬프(`createdAt`, `updatedAt`, `addedAt`)를 UTC instant 계약으로 정렬한 이후, 타임라인 이벤트 시간 정보인 `occurredAt`과 `timeAnchor` 필드의 의미론을 분석하고, 장기적인 시간 아카이빙 방향성을 수립하기 위한 감사 리포트입니다.
*   본 단계에서는 코드 수정, 리팩토링, 마이그레이션 및 LocalDate/PartialDate의 물리적 구현을 배제하며, 오직 설계상의 정의와 향후 로드맵을 정리하는 데 집중합니다.

---

## 2. Current Fields

### A. occurredAt
*   **현재 정의**: 타임라인 엔트리가 가리키는 사건의 발생 날짜/시각.
*   **용도**: 타임라인 정렬의 기준값 및 UI 표시 문자열의 소스.
*   **성격**: 사용자의 주관적 경험/기억에 기반한 시간 정보이며, 현재 코드상으로는 Dart `DateTime`으로 파싱되고 있어 타임존 해석에 따라 다른 시간으로 노출될 여지가 있습니다.

### B. timeAnchor
*   **현재 정의**: 서로 다른 레코드 모델(`AkashaItem`, `JournalEntry`, `TimelineEntry`)을 시간축 상에 단일 정렬하기 위한 인메모리 앵커 필드.
*   **용도**: `ArchiveRecord`에 매핑될 때 사용됨. 
    *   Work 및 Journal의 경우 생성/기록일인 `addedAt`이 바인딩됨.
    *   Timeline의 경우 사건 시각인 `occurredAt`이 바인딩됨.

### C. addedAt / createdAt / updatedAt (UA-115 정렬 완료)
*   **AddedAt**: 레코드가 볼트에 처음 들어간 시스템 시각. (UA-115에 의해 system timestamp로 분류 확정 및 UTC 정규화 완료)
*   **CreatedAt**: YAML 파일의 `created_at` 필드로 기재되는 시스템 시각. (Z-suffix UTC로 저장)
*   **UpdatedAt**: YAML 파일의 `updated_at` 필드로 기재되는 시스템 최종 수정 시각. (Z-suffix UTC로 저장)
*   *주의*: 이 3개 필드는 이번 UA-116 분석 대상에서 제외되며, 현재의 UTC instant 계약을 그대로 승계합니다.

---

## 3. Current Read Paths

| Field | File | Parser | Current Behavior | Risk |
| :--- | :--- | :--- | :--- | :--- |
| `occurredAt` | [timeline_entry_parser.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/timeline_entry_parser.dart#L33-L36) | `_parseDateTime` → `DateTime.tryParse` | YAML의 `occurred_at` 문자열 파싱. 없으면 `createdAt` 및 `DateTime.now()`로 폴백 | **P1**: Z 없는 문자열을 직접 파싱하므로, 로드하는 기기의 로컬 타임존에 따라 노출 시각이 달라질 수 있습니다 |
| `timeAnchor` | [timeline_vault_store.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/timeline_vault_store.dart#L68) | `record.timeAnchor ?? DateTime.now()` | 인메모리 `ArchiveRecord`에서 `timeAnchor`를 꺼내 `occurredAt`으로 재할당 | **P2**: 명시적인 검증 없이 UI에서 전달받은 DateTime에 의존하며, null 시 로컬 `DateTime.now()` 적용 |

---

## 4. Current Write Paths

| Field | File | Writer | Current Serialized Form | Risk |
| :--- | :--- | :--- | :--- | :--- |
| `occurredAt` | [timeline_entry_parser.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/timeline_entry_parser.dart#L72) | `formatDateTime` → `value.toIso8601String()` | `occurred_at: "2026-07-05T22:30:00.000"` (Z 없음) | **P1**: 타임존 지정이 배제된 문자열로 직렬화되어, 다른 장치에서 읽을 때 해석 기준이 달라질 수 있습니다 |
| `timeAnchor` | [timeline_vault_store.dart](file:///C:/Users/rkdwl/RuneAtelier/akasha/lib/services/timeline_vault_store.dart#L108) | `TimelineEntryParser.serialize`로 전달 | 파일에는 직접 직렬화되지 않음. `occurred_at`으로 바인딩되어 간접 저장 | **P2**: 저장 흐름이 `occurredAt`에 전적으로 의존하므로, 향후 의도하지 않은 시계열 꼬임 가능성이 있습니다 |

---

## 5. Current Usage

### 5.1 같은 날 기록 찾기 (`SameDayRecordService`)
*   `occurredAt` 혹은 `addedAt`에 대해 `DateTime.toLocal()`을 적용한 뒤, 년/월/일을 비교합니다.
*   **유의 요인**: 기기의 타임존이 바뀌면(예: 해외 이동 시) `toLocal()` 결과가 달라져 동일한 날짜로 분류되던 타임라인과 저널 그룹이 어긋나 보일 수 있습니다.

### 5.2 타임라인 정렬
*   `TimelineVaultLoader`에서 `entries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt))`를 사용하여 최신순 정렬을 수행합니다.
*   **유의 요인**: 파싱 단계에서 타임존 해석 방식에 따라 순서가 의도와 다르게 보일 수 있습니다.

### 5.3 UI 표시
*   `timeline_view.dart`에서 `_formatWhen(entry.occurredAt)`을 사용해 `DateTime.toLocal()` 기준으로 `YYYY-MM-DD HH:mm`을 화면에 렌더링합니다.
*   **유의 요인**: 사용자는 "7월 5일 낮 12시"로 기억하고 입력한 타임라인이 타임존 이동 후 다른 일시로 밀려 표시될 수 있어 아카이브 기록의 일관성이 저해될 우려가 있습니다.

---

## 6. Semantic Options

### Option A. Exact Instant
*   **방안**: 타임라인 발생 시각도 system timestamp처럼 absolute UTC instant로 간주하여 저장 및 파싱을 처리합니다.
*   **장점**: 
    *   구현이 비교적 간결하며 `ArchiveRecordContract.parseSystemTimestamp`를 재활용할 수 있습니다.
*   **단점**: 
    *   사용자의 인지 날짜를 보존하기 어렵습니다. 타임존 이동 시 기록 날짜가 밀려 정렬이 어긋날 수 있습니다.
*   **적합한 경우**: 서버 로그 시스템이나 실시간 채팅 등 물리적 전후 관계의 정밀도가 중요한 제품.

### Option B. Semantic Local DateTime
*   **방안**: 타임존 정보를 배제하고 Wall-Clock 숫자 그대로(`2026-07-05 12:00:00`) 다루며, 어느 타임존에서 읽든 동일한 일시로 표현하도록 제한합니다.
*   **장점**:
    *   기기를 들고 타임존을 이동하더라도 사용자가 입력한 날짜와 시간이 변하지 않고 표시될 수 있습니다.
*   **단점**:
    *   물리적 전후 관계를 엄밀하게 파악하기 어렵고, Dart `DateTime`은 기본적으로 local/utc 컨텍스트를 지니기 때문에 Wall-Clock만을 다루는 레이어 처리가 까다로울 수 있습니다.
*   **적합한 경우**: 일기장이나 감상 로그처럼 작성자의 인지 시각이 중요한 개인 아카이브 도구.

### Option C. Split Model (장기 지향점)
*   **방안**: 시간 정보를 인지 날짜와 물리적 순간으로 분리하여 처리합니다.
    *   `occurredDate`: `YYYY-MM-DD` (달력 날짜, 필수)
    *   `occurredTime`: `HH:mm` (시각 정보, 옵션)
    *   `occurredAt`: exact instant (물리 순간 타임스탬프, 옵션)
    *   `timeAnchor`: 대략적인 시대나 세기를 지정할 수 있는 앵커 정보
*   **장점**:
    *   사용자의 인지 날짜를 보존하면서도 물리적 시차 순서까지 추적할 수 있어 장기적으로 더 안전한 구조일 가능성이 높습니다.
*   **단점**:
    *   YAML 스키마를 대대적으로 변경해야 하며, 기존 데이터에 대한 마이그레이션이 필요합니다.
*   **적합한 경우**: 장기 보존 및 복잡한 시간 구조(대략적 날짜 포함)를 다루는 전문 아카이브 시스템.

---

## 7. Recommended Decision

*   **최소 범위 확정 및 권고안**: **장기적으로는 Option C (Split Model)로 이행하는 로드맵을 검토**하되, v1의 안정적인 릴리즈를 위해 즉각적인 스키마 파괴나 리팩토링은 피합니다.
*   **단기 가드레일 제안 (UA-116 이후 타겟)**: 
    *   현재의 `occurredAt`을 **Semantic Local DateTime (Option B)**으로 취급하도록 유도합니다.
    *   차기 단계에서 `occurredAt` 파싱 및 직렬화 경로를 개선하여 로컬 타임존 변환 문제를 줄이는 방향을 고려합니다.

---

## 8. Risk Classification

*   **P1 (의미 모호성 리스크)**: `occurredAt`이 로드하는 기기의 타임존에 따라 UI 표시 시각 및 `SameDayRecordService`의 같은 날 그룹 판정이 흔들리는 위험이 있습니다.
*   **P2 (설계 미비 리스크)**: `timeAnchor`가 인메모리에서 다형적으로 사용되고 있으나, 이에 대한 명확한 규칙이나 유효성 검증 테스트가 다소 부족합니다.
*   **P3 (영향 없음)**: system timestamp 영역은 UA-115에서 UTC 정규화 계약이 적용되어 현재 감사 기준에서는 P3로 분류됩니다.

---

## 9. Non-goals

*   `LocalDate` 또는 `PartialDate` 전용 클래스 구현
*   YAML frontmatter 스키마의 물리적 수정 및 timeline entry 모델 리팩토링
*   `SameDayRecordService` 코드 수정 및 기존 데이터의 일괄 마이그레이션
*   모든 `DateTime` 사용처의 일괄 교체

---

## 10. Proposed Next Step

*   구현 전 schema decision과 UX 의미 확인이 필요합니다. 당장 코드 변경은 하지 않고, UA-116 결과를 backlog로 보관합니다.
