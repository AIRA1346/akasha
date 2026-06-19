# Wave 6 — Memory Core PoC 스펙

> **상태:** W6-1 **PoC 코드** · W6-2~3 ⬜  
> **갱신:** 2026-06-19  
> **상위:** [entity-centric-evolution-plan.md](entity-centric-evolution-plan.md) §Wave 6

---

## 1. 목표

`.md` SSOT **위**에 append-only **event ledger**를 두고, 이후 SQLite read cache · MCP read tools로 확장한다.

**PoC Exit:** vault reload · link index rebuild · entity journal save가 `event_ledger.jsonl`에 기록됨.

| 하지 않음 | 이유 |
|-----------|------|
| SQLite full sync | W6-2 |
| MCP server | W6-3 |
| AI Record 생성 | Wave 6+ |

---

## 2. 파이프라인

```
Tier 2 .md (SSOT)
    ↓ vault watch / save hooks
.akasha/event_ledger.jsonl (append-only)
    ↓ (W6-2)
SQLite read cache
    ↓ (W6-3)
MCP read tools
```

---

## 3. Ledger 이벤트 (v1)

| type | 트리거 |
|------|--------|
| `vaultReloaded` | `HomeVaultCoordinator.loadItems` |
| `linkIndexRebuilt` | `RecordLinkIndexService.rebuildIndex` |
| `recordSaved` | entity journal save/update |
| `recordDeleted` | entity journal delete |
| `catalogUpdated` | defer (W6.1) |

파일: `{vault}/.akasha/event_ledger.jsonl` — JSON Lines, 1 event per line.

---

## 4. 작업 분할

| ID | 작업 | Exit |
|----|------|------|
| W6-0 | 본 spec | ✅ |
| W6-1 | `EventLedgerService` append | event_ledger_service_test |
| W6-2 | SQLite projector | ⬜ |
| W6-3 | MCP read PoC | ⬜ |

---

## 5. 의존성

Wave 5 Connection ✅ · ADR-013 ✅

---

## 6. 문서 이력

| 일자 | 변경 |
|------|------|
| 2026-06-19 | v1 — W6-1 ledger PoC |
