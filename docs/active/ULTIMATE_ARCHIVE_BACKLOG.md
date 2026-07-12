# Ultimate Archive Backlog

> **Status:** Active backlog
> **Date:** 2026-07-12
> **Scope:** Do not forget the architecture work discovered while hardening AKASHA as an ultimate archive substrate.
> **Boundary:** AKASHA is the durable archive layer. AI agents, media playback, recommendations, and external automation remain outside AKASHA unless they write/read through explicit archive contracts.
> **Related:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) · [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md) · [ROADMAP.md](ROADMAP.md) · [PROJECT_STATUS.md](PROJECT_STATUS.md)

## 1. Already Landed

These are done enough to treat as current architecture baseline.

| ID | Work | Status | Anchor |
| --- | --- | --- | --- |
| UA-001 | Vault Layout v3 path identity for new Work/Entity records | ✅ done | `works/{category}/{work_id}.md`, `entities/{type}/{entity_id}.md` |
| UA-002 | `schema_version: 3` and `record_id` emitted for new archive serializers | ✅ done | Work/Entity/Journal/Timeline serializers |
| UA-003 | Central `VaultRecordPathResolver` | ✅ done | [vault_record_path_resolver.dart](../../lib/services/vault_record_path_resolver.dart) |
| UA-004 | `ArchiveOperation` write-intent model | ✅ done | [archive_operation.dart](../../lib/core/archiving/archive_operation.dart) |
| UA-005 | `ArchiveOperationValidator` safety gate | ✅ done | [archive_operation_validator.dart](../../lib/core/archiving/archive_operation_validator.dart) |
| UA-006 | `ArchiveCandidate` model and lifecycle | ✅ done | `candidate` · `promoted` · `dismissed` · `merged` |
| UA-007 | Durable Candidate Store | ✅ done | legacy `catalog/candidates.json` read compatibility plus sharded `system/candidates/*` writes |
| UA-008 | Candidate promotion validator | ✅ done | duplicate title/id · type mismatch · missing evidence/source |
| UA-009 | Operation execution service for `promoteCandidate` | ✅ done | [archive_operation_executor.dart](../../lib/services/archive_operation_executor.dart) |
| UA-102 | Operation idempotency and applied log | ✅ done | [archive_operation_applied_log.dart](../../lib/services/archive_operation_applied_log.dart) · `system/ops/applied.jsonl` |
| UA-103 | Operation conflict checks for executable operations | ✅ done | [archive_record_revision_service.dart](../../lib/services/archive_record_revision_service.dart) · `operation_conflict` |

| UA-105a | Candidate duplicate guard for normalized title/alias variants | done | strips bracket/punctuation noise and compares open candidate title/aliases |
| UA-118 | Operation crash recovery marker for `promoteCandidate` | done | `source_operation_id` roll-forward accepts matching partial writes and rejects mismatches |
| UA-119 | Reverse lookup before new Work/Entity path writes | done | same `work_id`/`entity_id` legacy files are reused when `filePath` or path index is missing |
| UA-120 | Entity journal alias frontmatter | done | `aliases: []` round-trips in entity journal Markdown and catalog sync |
| UA-106 | Record contract schema freeze | done | `ArchiveRecordContract` standardizes v3 metadata across Work/Entity/Journal/Timeline while preserving v1/v2 reads |
| UA-111 | Unicode NFC normalization guard | ✅ done | `UnicodeHelper.toNfc` composition handles macOS/Windows Hangul compatibility in files/indexes |
| UA-112 | YAML implicit casting bypass type guard | ✅ done | Prevents automatic conversion of unquoted values (e.g. `yes` to bool) to protect raw string data |
| UA-113 | System timestamp parsing timezone guard | ✅ done | `_parseVaultInstantAsUtc` isolates record summary indexing from local machine timezone drift |
| UA-114 | Date Semantics Audit | ✅ done | Whole-codebase audit report classifying date/time fields by instant, local date, and partial types |
| UA-115 | Vault Timestamp Contract Alignment | ✅ done | Aligned all parsers/stores (`ArchiveRecordContract` helper) to enforce strict UTC Z-suffix writing and parsing |
| UA-116 | Timeline Time Semantics Plan | ✅ done | Planning document detailing short-term local timezone guards and long-term split model for timeline occurredAt/timeAnchor |
| UA-117 | Entity Custom-to-Object Migration | ✅ done | Transformed `custom` entity type to `object` (`ob_` prefix) and added backward-compatible fallback for `cu_` IDs |
| UA-201 | Index manager wrapper | done | `ArchiveIndexManager` rebuilds record/record-path/entity/link/candidate/taste derived indexes with per-index results |
| UA-202a | Incremental record/taste index update API | done | `ArchiveIndexManager.updateChangedRecord/removeRecord` updates record, sharded record-path, and taste indexes for one Markdown path |
| UA-202b | Incremental index wiring into archive writes | done | Work/Entity/Journal/Timeline save/delete flows now call the manager instead of directly mutating record-only indexes |
| UA-206a | Link/entity-path incremental coverage | done | changed/deleted Markdown paths update link outgoing/incoming and entity path indexes through `ArchiveIndexManager` |
| UA-204 | Sharded title/alias lookup index | done | `.akasha/title_alias_index/names/{shard}.json` resolves normalized title/alias/original/localized names to stable IDs without Markdown scans |
| UA-208 | Index rebuild validator | done | `ArchiveIndexValidatorService` rebuilds and audits record/record-path/entity-path/title-alias/link/candidate/taste indexes against Markdown source |
| UA-209 | Candidate store sharded scale path | done | candidates write to `system/candidates/{type}/{shard}.json` with sharded name indexes |
| UA-209a | Candidate name index rebuild/fallback | done | candidate duplicate guard falls back to source shards and `rebuildDerivedIndexes` restores name indexes |
| UA-301 | Taste index schema and first extractor | done | `.akasha/indexes/taste_index.json` derives evidence-backed rating/status/favorite/tag/memo/quote/link signals |
| UA-107 | Entity subtype/role model | ✅ done | `entity_subtype` metadata support and structured relations parser/serializer validated |
| UA-108 | Music/OST representation decision | ✅ done | `MediaCategory.music` added and soundtrack/track structured relations mapping validated |

## 2. P0 Pre-Release Architecture Work

These should stay visible because they protect the archive before external/AI writes become powerful.

| ID | Work | Why It Matters | Suggested Next Slice |
| --- | --- | --- | --- |
| UA-104 | Candidate review/promotion UI | done | Candidate tab shows durable proposals, provenance, and promote/dismiss actions |
| UA-105 | Candidate duplicate detection beyond exact title | Basic normalized title/alias guard is landed; stronger fuzzy merge review is still useful | Add similarity scoring and candidate merge suggestions instead of only hard rejects |
| UA-106 | Record contract schema freeze | Base contract landed; future slices may extend relation semantics | Keep validators and fixtures aligned as new operation executors land |
| UA-109 | v1/v2/v3 mixed-vault validation | done | Mixed legacy/title/ID fixture rebuild and validation coverage is landed |
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
| `links` / `relations` | Structured relation layer beyond wiki body links | structured links are landed; [Relation Tier semantics](RELATION_TIERS_AND_ASSERTIONS_ADR.md) are fixed, while physical Assertion storage remains P1 work |
| `entity_subtype` | character/creator/studio/franchise/track without exploding top-level types | planned |
| `source_operation_id` | Trace write back to operation | landed for operation-created entity journals; extend to future operation record types |
| lifecycle / tombstone / supersede | Preserve retirement and replacement without confusing them with deletion | [Semantic lifecycle contract](LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md) is fixed; physical representation remains deferred |
| extension namespace | Add future AKASHA metadata without claiming user/tool YAML | [`x_akasha` contract](EXTENSION_NAMESPACE_AND_RESERVED_FIELDS_ADR.md) is fixed; writer/spec update remains deferred |
| Gateway authority / receipts | Apply external archive operations only by user choice | [Default-deny grant and receipt contract](GATEWAY_PERMISSION_AND_RECEIPT_ADR.md) is fixed; first candidate intake and bounded Record command are implemented |

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
| D-002 | Paid themes / IAP | Post-launch |
| D-003 | Agent/player implementation layer | AKASHA must not become the player/orchestrator |
| D-004 | akasha-db ownership A/B/C decision | Repo/registry operations track |
| D-005 | Registry manifest 4 generated files | Keep excluded from commit unless intentionally rebuilding registry |
| D-006 | Large UI cleanup hotspots | Separate code-health track: workbench/entity/home/editor files |

## 9. Current Next Step

**Product priority (after docs cleanup):** Steam M3 dogfood — fix issues found in real use first ([STEAM_RELEASE.md](STEAM_RELEASE.md)).

**Separate architecture slice (not interleaved with dogfood):**

> **[SA-05 Timeline projection gate](SA_05_TIMELINE_PROJECTION_DECISION.md):**
> measure the current Timeline loader and fix the exact cursor, preview, and
> unreadable-source contract before implementation. The first Timeline table
> must remain a derived local projection; Journal, Entity, Link/graph, Taste,
> and snippet queries must not be folded into it merely for convenience.

**Deferred prerequisite (no ADR until then):** UA-122 — §7 implementation contract ADR when semantic history or behavioral aggregates implementation begins.

Minimum done condition for SA-05 when that slice starts:

- choose one domain/query family rather than a Universal Record migration;
- write its bounded result and canonical-hydration contract before storage code;
- prove its index stays derived/rebuildable, preserves unreadable-source
  visibility, and never becomes a second user-data source of truth.
