# ADR-013: Connection & Link Index — RecordLink 파생 인덱스

| 항목 | 내용 |
|------|------|
| **상태** | **승인 (Accepted)** |
| **날짜** | 2026-06-19 |
| **상위** | [wave5-connection-spec.md](../programs/wave5-connection-spec.md) · [entity-centric-evolution-plan.md](../programs/entity-centric-evolution-plan.md) §Wave 5 |
| **선행** | [ADR-008](ADR-008-record-entity-time-model.md) · [ADR-011](ADR-011-entity-type-subtype.md) |

---

## 1. 맥락

Wave 5 Connection MVP는 Record 본문의 `[[entity_id|label]]` · `[[title]]` wiki 링크를 **1급 데이터**로 다룬다.  
`.md`가 SSOT이므로 Graph DB나 별도 relation store는 도입하지 않는다.  
대신 vault scan으로 **파생 인덱스**를 만들어 1-hop 양방향 탐색(incoming/outgoing)을 제공한다.

---

## 2. 결정

### 2.1 SSOT 불변

| 계층 | 역할 |
|------|------|
| **Tier 2 `.md` body** | 링크의 canonical source |
| **`vault/.akasha/link_index.json`** | 파생 · 재생성 가능 |
| **UI (Entity Sheet · preview tap)** | 인덱스 + catalog 조회 |

인덱스 손실 시 **full rebuild**로 복구 — 데이터 유실 아님.

### 2.2 RecordLink 모델

```dart
enum RecordLinkKind { explicitId, titleOnly }

class RecordLink {
  final String sourceRecordId;   // storage path
  final String targetEntityId;   // wk_* · pe_u_* · co_u_* …
  final String? displayLabel;
  final RecordLinkKind kind;
}
```

| 패턴 | kind | resolve |
|------|------|---------|
| `[[entity_id\|label]]` | explicitId | ID 그대로 |
| `[[entity_id]]` | explicitId | ID 그대로 |
| `[[Title]]` | titleOnly | catalog alias → vault work title (best effort) |

code block 내부 `[[…]]`는 **파싱 제외**.

### 2.3 인덱스 파일 (v1)

경로: `{vault}/.akasha/link_index.json`

```json
{
  "version": 1,
  "generatedAt": "2026-06-19T…",
  "outgoing": {
    "C:/vault/works/foo.md": [
      {"targetEntityId": "pe_u_xxx", "label": "작가", "kind": "explicitId"}
    ]
  },
  "incoming": {
    "pe_u_xxx": ["C:/vault/works/foo.md"]
  }
}
```

- **outgoing:** source path → targets
- **incoming:** entityId → source paths (역방향)

### 2.4 스캔 범위

| 경로 | RecordKind |
|------|------------|
| `{vault}/works/**/*.md` | workJournal |
| `{vault}/entities/**/*.md` | entityJournal |
| `{vault}/timeline/*.md` | timelineEntry |
| `{vault}/journal/*.md` | freeformJournal |

legacy `{category}/` 경로는 기존 vault loader와 동일하게 포함.

### 2.5 갱신 전략

| 트리거 | 동작 |
|--------|------|
| vault connect · loadItems | full rebuild |
| vault watch (debounce) | full rebuild (MVP) |
| single-file incremental | **defer** — W5.1 optional |

MVP는 **정확성 우선 full rebuild**. 볼트 규모(개인 vault)에서 debounce 1회로 충분.

### 2.6 Navigate 규칙

| target | UI action |
|--------|-----------|
| `wk_*` (archived work) | workbench open |
| catalog entity (`pe_u_*`, `co_u_*`, …) | Entity Sheet |
| titleOnly unresolved | SnackBar · Fusion search 유도 |

Fusion catalog hit · wiki tap · Browse Entity tile은 **동일 Entity Sheet** surface.

### 2.7 Port

```dart
abstract interface class RecordLinkPort {
  Future<void> rebuildIndex({String? changedPath});
  Future<List<RecordLink>> outgoingLinks(String sourcePath);
  Future<List<String>> incomingRecordPaths(String entityId);
}
```

구현: `RecordLinkIndexService` · coordinator: `HomeVaultCoordinator.linkIndex`.

---

## 3. 하지 않음 (Wave 5 scope)

| 항목 | 이유 |
|------|------|
| Graph DB / 3-hop viz | `.md` SSOT · MVP 1-hop |
| cross-vault link index | single vault per session |
| AI link suggestion | Wave 6 |
| sameDay sidebar | W5.5 optional · time index 별도 |

---

## 4. 구현 매핑

| 파일 | 역할 |
|------|------|
| `record_link_parser.dart` | body parse |
| `record_link_index_service.dart` | scan · JSON IO |
| `record_link_navigator.dart` | tap · title resolve |
| `record_link_markdown.dart` | preview preprocess |
| `entity_journal_dialog.dart` | incoming links UI |
| `home_vault_coordinator.dart` | auto rebuild on vault change |

---

## 5. 검증

- unit: `record_link_parser_test` · `record_link_index_test`
- E2E: [wave5-dogfood-checklist.md](../programs/wave5-dogfood-checklist.md) (구현 완료 후 1회)

---

## 6. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — Wave 5 MVP 코드 정합 · ADR-013 확정 |
