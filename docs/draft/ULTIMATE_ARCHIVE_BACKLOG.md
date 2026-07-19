# Ultimate Archive Backlog

> **Status:** Non-binding draft backlog
> **Date:** 2026-07-12 · header corrected 2026-07-19
> **Authority:** Not an active contract. Implementation facts: [CURRENT_STATE.md](../active/CURRENT_STATE.md). Active hardening plan: [INFINITE_ARCHIVE_HARDENING_PLAN.md](../active/INFINITE_ARCHIVE_HARDENING_PLAN.md).
> **Scope:** Remember architecture follow-ups discovered while hardening AKASHA as an ultimate archive substrate.
> **Boundary:** AKASHA is the durable archive layer. AI agents, media playback, recommendations, and external automation remain outside AKASHA unless they write/read through explicit archive contracts.
> **Related:** [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](../history/closure-2026-07/ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md) · [ROADMAP.md](../active/ROADMAP.md) · [PROJECT_STATUS.md](../history/closure-2026-07/PROJECT_STATUS.md) (historical)

## 1. Already Landed (summary)

Landed baseline is tracked in [CURRENT_STATE.md](../active/CURRENT_STATE.md) and [ARCHITECTURE_CLOSURE_AUDIT.md](../history/closure-2026-07/ARCHITECTURE_CLOSURE_AUDIT.md). Do not treat this backlog as the live SSOT for done work.

Compact ID list (details live in code + CURRENT_STATE):

- **Vault / ops:** UA-001–UA-009 · UA-102–UA-103 · UA-105a · UA-106 · UA-111–UA-120
- **Indexes:** UA-201 · UA-202a/b · UA-204 · UA-206a · UA-208 · UA-209/a
- **Taste / taxonomy seeds:** UA-301 · UA-107 · UA-108
- **Also landed from former §2:** UA-104 (candidate review UI) · UA-109 (mixed-vault validation)

## 2. P0 Pre-Release Architecture Work (open)

These should stay visible because they protect the archive before external/AI writes become powerful.

| ID | Work | Why It Matters | Suggested Next Slice |
| --- | --- | --- | --- |
| UA-105 | Candidate duplicate detection beyond exact title | Basic normalized title/alias guard is landed; stronger fuzzy merge review is still useful | Add similarity scoring and candidate merge suggestions instead of only hard rejects |
| UA-106 | Record contract schema freeze (follow-ups) | Base contract landed; future slices may extend relation semantics | Keep validators and fixtures aligned as new operation executors land |
| UA-110 | Explicit v3 migration command | Existing files should never move accidentally | Build opt-in migration that updates paths, indexes, and backlinks atomically |
| UA-121 | Extend conflict guards to future mutating operations | Update/append/link operations are validated but not executable yet | Reuse revision guard when those operation executors land |
| UA-122 | §7 implementation contract ADR | Constitution §7 principles are fixed; storage/revision/aggregate schema and promotion UX are not | **Deferred until implementation begins** — do not write the ADR before semantic history or behavioral aggregates work starts |

## 3. P1 Index And Scale Work

These are what make "infinite archive" fast instead of merely correct.

| ID | Work | Why It Matters | Suggested Direction |
| --- | --- | --- | --- |
| UA-201 | Index manager wrapper | Indexes were fragmented JSON services | Landed `ArchiveIndexManager`; continue expanding callers around it |
| UA-202 | Incremental index updates | Full scans will degrade as vault grows | Record/taste/link/entity-path/title-alias incremental paths are landed; keep full rebuild as recovery |
| UA-203 | Derived-query storage boundary | Work Explore uses an app-local SQLite projection; portable exact Record lookup is sharded in `.akasha/` | Done for Work and exact lookup. Add each future Record/Link/Taste/snippet projection by its own bounded contract; do not create a universal index table. |
| UA-204 | Title/alias index | AI and natural language lookup need fast title resolution | Done for bounded local exact lookup; fuzzy and semantic discovery remain separate contracts |
| UA-204b | Title/alias query integration | done | Local `record lookup` exposes exact title/alias matches; fuzzy/semantic search remains separate |
| UA-205 | Tag index expansion | Taste/theme/mood lookup should not parse all Markdown | Keep normalized tag -> record ids |
| UA-206 | Link and incoming graph hardening | Backlinks and graph exploration need stable relationship lookup | Incremental outgoing/incoming updates landed; next add validation/reporting for unresolved title links |
| UA-207 | Snippet/quote/scene index | Search should find meaningful passages without full-file reads | Store short derived excerpts with evidence paths |
| UA-208 | Index rebuild validator | Derived indexes must be disposable and trustworthy | Landed service validation for rebuild failures, duplicate IDs, stale record paths, missing title aliases, link drift, and taste evidence drift |
| UA-210 | Candidate merge/review query UX | Shards prevent IO blowups, but users still need reviewable duplicate clusters | Add paged candidate queries and merge suggestions backed by the name index |

## 4. P1 Taste And Preference Work

These turn archive records into evidence-backed taste memory.

| ID | Work | Why It Matters | Suggested Direction |
| --- | --- | --- | --- |
| UA-301 | Taste index schema | The user wants external agents to understand taste later | Landed first JSON slice via `TasteIndexService` and `TasteSignal` |
| UA-302 | Evidence-backed taste signals | Avoid opaque "AI thinks user likes X" claims | Keep extending the invariant: every future signal must keep `sourceRecordId`, `evidencePath`, and `evidenceField` |
| UA-303 | Taste signal extractor | Ratings/tags/status/collections/quotes/revisits should become queryable signals | First slice derives `rating`, `tag`, `status`, `favorite`, `memo`, `quote`, and `link`; add `collection` and `revisit` later |
| UA-304 | Music/OST taste signals | Prompt example depends on action movie OST preferences | Model soundtrack/music preference from works, tags, notes, quotes, and links |
| UA-305 | Taste privacy boundary | External tools should read only needed summaries | Bounded Record lookup/read now avoids path and Vault scans; per-signal/read-scope privacy policy remains deferred |

## 5. Agent And External Tool Work

These are post-launch unless the operation executor is kept very small.

| ID | Work | Why It Matters | Suggested Direction |
| --- | --- | --- | --- |
| UA-401 | Agent Vault Protocol implementation/dogfood | Minimal local loop is landed | Exact lookup -> stable-id read/revision -> candidate Gateway -> review; dogfood with real command-capable tools remains |
| UA-402 | Structured batch import contract | Large agent/import writes need safety | Batch validate all operations before applying |
| UA-403 | Scoped local query API | Narrow foundation done | `record lookup` + `record read` are bounded; tag, graph, snippet, and semantic query surfaces remain separate |
| UA-404 | Permission/scoping model | Candidate write authority is landed | Define future durable read scopes and later canonical-write scopes without treating local command invocation as identity proof |
| UA-405 | Agent conflict UX | User needs clear recovery when agent and app edits collide | Show reload/merge/retry states tied to operation failure |
| UA-406 | Operation examples and fixtures | Future agents need stable examples | Add JSON fixtures for create/update/append/link/promote/merge |

## 6. Markdown Contract Gaps

These fields were identified as useful but are not fully standardized everywhere yet.

| Field | Need | Status |
| --- | --- | --- |
| `aliases` | Natural lookup and duplicate detection | landed across v3 Work/Entity/Journal/Timeline metadata; title/alias index consumes it |
| `original_title` | Translated/localized title stability | landed in v3 metadata and title/alias lookup |
| `external_ids` | Wikidata/Steam/ISBN/etc. identity joins | landed as preserved v3 metadata map |
| `created_at` | Durable creation timestamp separate from `added_at` | landed; v1/v2 fall back to `added_at` |
| `updated_at` | Conflict checks and index freshness | landed; serializers/stores update and index summaries read it |
| `source` | user/app/agent/import/script provenance | creation source is standardized, but existing-record edits must preserve it; full provenance remains P1 work |
| `evidence` | Agent/candidate/taste claims need proof | landed as preserved v3 metadata list; candidate promotion writes evidence |
| `links` / `relations` | Structured relation layer beyond wiki body links | structured links are landed; [Relation Tier semantics](../active/RELATION_TIERS_AND_ASSERTIONS_ADR.md) are fixed, while physical Assertion storage remains P1 work |
| `entity_subtype` | character/creator/studio/franchise/track without exploding top-level types | planned |
| `source_operation_id` | Trace write back to operation | landed for operation-created entity journals; extend to future operation record types |
| lifecycle / tombstone / supersede | Preserve retirement and replacement without confusing them with deletion | [Semantic lifecycle contract](../active/LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md) is fixed; physical representation remains deferred |
| extension namespace | Add future AKASHA metadata without claiming user/tool YAML | [`x_akasha` contract](../active/EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md) is fixed; writer/spec update remains deferred |
| Gateway authority / receipts | Apply external archive operations only by user choice | [Default-deny grant and receipt contract](../active/GATEWAY_PERMISSION_AND_RECEIPT_ADR.md) is fixed; first candidate intake and bounded Record command are implemented |

## 7. Entity Taxonomy Follow-Ups

Top-level entity types are currently sufficient:

```text
work, person, event, place, concept, organization, object
```

Follow-ups:

- Keep `phenomenon` deprecated; prefer `concept` or `object`.
- Do not rush to add many top-level entity types.
- Prefer `entity_subtype` / `role` / `relations` for `character`, `actor`, `director`, `writer`, `studio`, `publisher`, `franchise`, `soundtrack`, `track`, `theme`.
- Decide whether `music` becomes a Work category or remains a taste/relation layer.

## 8. Explicitly Deferred Or Separate Work

These matter, but they are not the current ultimate-archive core.

| ID | Work | Note |
| --- | --- | --- |
| D-001 | Steam BuildID `24015480` Set Live / review update | Release/ops, not archive architecture |
| D-002 | Paid themes / IAP / Astra·Echo | [COMMERCE_CURRENCY_CONTRACT.md](../active/COMMERCE_CURRENCY_CONTRACT.md); flag off until P5–P6 verified |
| D-003 | Agent/player implementation layer | AKASHA must not become the player/orchestrator |
| D-004 | akasha-db ownership A/B/C decision | Repo/registry operations track — see [AKASHA_DB_OWNERSHIP_AUDIT.md](AKASHA_DB_OWNERSHIP_AUDIT.md) |
| D-005 | Registry manifest 4 generated files | Keep excluded from commit unless intentionally rebuilding registry |
| D-006 | Large UI cleanup hotspots | Separate code-health track: workbench/entity/home/editor files |

## 9. Current Next Step

**Architecture Closure:** [ARCHITECTURE_CLOSURE_AUDIT.md](../history/closure-2026-07/ARCHITECTURE_CLOSURE_AUDIT.md) — **declared**. Baseline numbers in that snapshot are historical; live quality gates are only in [CURRENT_STATE.md](../active/CURRENT_STATE.md).

**Product track:** [STEAM_SERVICE_RELEASE_READINESS.md](../active/STEAM_SERVICE_RELEASE_READINESS.md) — Steam-library transaction/recovery evidence · IAP honesty · [Astra/Echo commerce](../active/COMMERCE_CURRENCY_CONTRACT.md).

Former audit S1 rows are a **Steam stability checklist** only (fix when dogfood/ship blocks).

**Deferred (do not start):** SA-05 · UA-122 §7 ADR · Universal Record · Relationship Assertion storage.
