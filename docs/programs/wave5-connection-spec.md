# Wave 5 — Connection 구현 스펙

> **상태:** W5-1~4 **MVP 코드** · dogfood ⬜  
> **갱신:** 2026-06-19  
> **선행:** Wave 3 ✅ · Wave 4 ✅ MVP  
> **SSOT:** [entity-centric-evolution-plan.md](entity-centric-evolution-plan.md) §Wave 5

---

## 1. 목표

Record 본문의 `[[…]]` 링크를 **1급 데이터**로 파싱·인덱싱하고, Entity/Record 간 **양방향 탐색**을 제공한다.

**MVP Exit:** Work journal 1건에서 Person·Concept로 링크 → 클릭 → catalog/journal 열기 E2E.

| 하지 않음 | 이유 |
|-----------|------|
| Graph DB / Neo4j | `.md` SSOT · vault scan 파생 |
| 3-hop+ 시각화 | MVP는 1-hop 패널 |
| AI link suggestion | Wave 6 |

---

## 2. 개념

```
Record (.md body)
    │
    ├─ [[wk_000000001|에이티식스]]     → RecordLink(targetEntityId, label)
    ├─ [[pe_u_abcd1234]]              → RecordLink (label = catalog title)
    └─ [[Tiger]]                      → RecordLink (title resolve via fusion)
```

| 타입 | 저장 | 인덱스 |
|------|------|--------|
| **RecordLink** | 파생 (vault scan) | `vault/.akasha/link_index.json` |
| **역방향** | 동일 인덱스 | `incoming[entityId][] → recordId` |

---

## 3. RecordLink 모델 (신규)

```dart
class RecordLink {
  final String sourceRecordId;   // storage path or stable record id
  final String targetEntityId;   // wk_* · pe_u_* · co_u_* …
  final String? displayLabel;    // wiki pipe label
  final RecordLinkKind kind;     // explicitId | titleOnly
}

enum RecordLinkKind { explicitId, titleOnly }
```

**파싱 규칙 (W5-1):**

| 패턴 | kind | target |
|------|------|--------|
| `[[entity_id\|label]]` | explicitId | entity_id |
| `[[entity_id]]` | explicitId | entity_id |
| `[[Title]]` | titleOnly | fusion resolve → entityId (best effort) |

기존 work wiki 링크와 **동일 regex family** — `MarkdownLinkParser` 확장 또는 `RecordLinkParser` 분리.

---

## 4. Link Index Service (W5-2)

### 4.1 스캔 범위

| 경로 | RecordKind |
|------|------------|
| `{vault}/works/**/*.md` | workJournal |
| `{vault}/entities/**/*.md` | entityJournal |
| `{vault}/timeline/*.md` | timelineEntry |
| `{vault}/journal/*.md` | freeformJournal |

### 4.2 인덱스 파일 (v1)

```json
{
  "version": 1,
  "generatedAt": "2026-06-19T…",
  "outgoing": {
    "C:/vault/works/foo.md": [
      {"targetEntityId": "pe_u_xxx", "label": "작가"}
    ]
  },
  "incoming": {
    "pe_u_xxx": ["C:/vault/works/foo.md"]
  }
}
```

- **Incremental:** `AkashaFileService` vault change signal → debounced rebuild (single file path hint when available)
- **Full rebuild:** vault connect · manual refresh

### 4.3 Port

```dart
abstract interface class RecordLinkPort {
  Future<void> rebuildIndex({String? changedPath});
  Future<List<RecordLink>> outgoingLinks(String sourcePath);
  Future<List<String>> incomingRecordPaths(String entityId);
}
```

---

## 5. UI (W5-3 · W5-5)

| Surface | MVP |
|---------|-----|
| Entity journal dialog | «이 Entity를 링크한 Record» 목록 |
| Work workbench | 본문 preview에서 `[[…]]` tap → navigate |
| Catalog entity browse | incoming count badge (optional) |

**Navigate 규칙:**

| target type | action |
|-------------|--------|
| work (`wk_*`) | open workbench |
| catalog entity | entity journal dialog |
| unresolved title | fusion search snackbar |

---

## 6. sameDay 휴리스틱 (W5-4 · optional)

Timeline/journal `added_at` / `time_anchor` 같은 **로컬 날짜** Record를 Entity detail sidebar에 «같은 날 기록»으로 표시. 링크 인덱스와 **독립** — Phase 5.1.

---

## 7. 작업 분할

| ID | 작업 | Exit |
|----|------|------|
| W5-0 | ADR-013 Connection & Link Index (초안) | 문서 |
| W5-1 | `RecordLinkParser` — `[[id\|label]]` · `[[id]]` · `[[title]]` | unit tests |
| W5-2 | `RecordLinkIndexService` + vault scan | round-trip JSON |
| W5-3 | Entity journal dialog «링크한 Record» 섹션 | UI smoke |
| W5-4 | Workbench wiki link tap → navigate | 1 E2E test |
| W5-5 | sameDay sidebar (optional) | dogfood |

---

## 8. Wave 5 Exit Checklist

- [x] W5-1 RecordLinkParser
- [x] W5-2 Link index rebuild + incremental (full rebuild MVP)
- [x] W5-3 incoming links on entity detail
- [x] W5-4 outbound link click navigate (preview tap)
- [ ] Work → Person · Concept link E2E dogfood

---

## 9. 의존성

```
Wave 3 (timeline/journal records) ✅
Wave 4 (multi-type entityId) ✅
EntityIdCodec.typeFromId ✅
FusionSearch (title resolve) ✅
```

---

## 10. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1.2 — W5-3~4 UI · vault link index auto-rebuild |
