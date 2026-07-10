# SA-03 — Derived Index Persistence Decision

> **Status:** Windows cache batch-rebuild/source-sync and trust-state prototype passed; benchmark and app lifecycle wiring pending
> **Date:** 2026-07-10
> **Related:** [SA_02_HOME_WORK_SUMMARY_BOUNDARY.md](SA_02_HOME_WORK_SUMMARY_BOUNDARY.md) · [SCALE_ACCESS_PATH_INVENTORY.md](SCALE_ACCESS_PATH_INVENTORY.md#sa-03--bounded-index-persistence-next) · [AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md](AKASHA_VAULT_FORMAT_SPECIFICATION_V3.md)

## 1. Decision Proposal

For unbounded interactive queries, AKASHA should use a **local, rebuildable
derived index store outside the user Vault**. The recommended storage class is
a transactional local database with indexed, cursor-based queries; the exact
Flutter package/runtime is not selected until a Windows Steam prototype and
fixture benchmark succeed.

This store is not a second archive, sync target, evidence source, or authority.
Markdown, assets, and durable `system/` files remain the only canonical user
archive. Deleting the derived store must be safe; the application can enter a
visible rebuilding state and recreate it from the Vault.

## 2. Why the Store Is Outside the Vault

| Constraint | Consequence |
| --- | --- |
| The user owns and may sync/copy the Vault folder directly. | The canonical folder must stay portable and intelligible without application-specific database files. |
| `.akasha/` is specified as fully disposable. | A cache placed there is allowable only if it is never required for recovery; current JSON indexes remain legacy rebuildable artifacts during migration. |
| Cloud-sync and external-drive folders can expose interrupted, duplicated, or divergent files. | A multi-file database/WAL inside that folder would create avoidable sync conflict and partial-state risk. |
| AI and external tools must understand the archive without AKASHA. | They read Markdown/YAML and assets; they do not need the app's query cache. |
| A million-record query needs indexed page, filter, and one-record update operations. | The query cache must be allowed to optimize access without changing the user-visible source format. |

The first implementation may key a local cache by normalized Vault root path.
Moving or copying a Vault can therefore trigger a rebuild, which is safe. A
durable Vault identity is deliberately not added in this slice because it would
change the canonical Vault contract and needs its own decision.

## 3. Required Store Properties

| Property | Requirement |
| --- | --- |
| Rebuildability | A missing, corrupt, or incompatible cache can be discarded and rebuilt from canonical sources. |
| Bounded read | Work summary page, stable-ID lookup, and filter query read only relevant indexed rows/pages, not all Markdown or all index rows. |
| Bounded mutation | One source-path upsert/delete changes only affected rows and secondary index entries in one transaction. |
| Cursor safety | Cursor ordering is deterministic and uses a stable-ID tie-breaker. No host-local time ordering. |
| Revision awareness | Indexed source revision is stored only to decide freshness; it never authorizes a canonical write. |
| Failure visibility | Cache open/migration/rebuild failure creates an explicit repair state. It must not silently call `loadAllItems` or treat source records as deleted. |
| Privacy | The cache stays on the user's local machine and carries no network or analytics behavior. Clear/rebuild must be available. |
| Non-authority | User export, backup, sharing, external-tool access, and P0 recovery rely on the Vault, not this store. |

## 4. Options Considered

| Option | Strength | Failure at AKASHA scale | Decision |
| --- | --- | --- | --- |
| Keep monolithic `record_index.json` | No new runtime; easy inspection. | Every read and write is O(all summaries); does not satisfy SA-02. | Reject for interactive query path. |
| Sharded JSON inside `.akasha/` | Human-readable and rebuildable. | Needs custom cursor, filter, secondary-index, cross-shard transaction, compaction, and sync-conflict design; complexity moves into AKASHA code. | Do not choose before benchmark; reserve as a fallback only if database packaging fails. |
| Transactional local database outside Vault | Native row/index queries, cursor paging, atomic multi-index mutation, and a clear rebuild boundary. | Adds a platform/runtime dependency and cache migration work. | Recommended, subject to Windows Steam prototype and fixture gate. |
| Database as canonical Vault | Fast access. | Violates user-owned portable Markdown, AI/tool accessibility, and direct file-sync goals. | Reject. |

## 5. Minimal Derived Schema Shape

This is a derived implementation shape, not a Universal Record schema and not
a Markdown migration.

- `source_files`: relative path, canonical `record_id` when available, durable
  `entity_id`/Work ID, record kind, observed revision, indexed revision, and
  readability/repair state.
- `work_summaries`: the SA-02 browse projection and deterministic sort keys.
- filter/index tables: category, display statuses, normalized tags, and future
  link/taste lookup keys.
- rebuild metadata: cache format version, canonical Vault root binding,
  rebuild generation, and last successful source scan marker.

Provenance, evidence, unknown YAML fields, body text, and canonical relation
assertions remain in Markdown. The cache may carry searchable projections later
but cannot become the only copy of any of them.

## 6. Rebuild and External-Change Model

```text
canonical Markdown / assets / system
          │
          ├── initial or explicit repair scan ──> local derived cache
          │
          └── SA-01 precise change batch ───────> one-path transactional update

cache failure or reconciliationRequired
          └── visible repair state ─────────────> deliberate rebuild
```

A normal page query never falls back to a full Vault scan. A newly opened cache
is `rebuild required`; a full rebuild first marks it `rebuilding`, and it is
queryable only after every batch and stale-source prune complete as `ready`.
An interruption or unexpected incremental-sync failure marks it `repair
required`, so even partial committed rows are not presented as an archive
result. A user-triggered repair may scan the Vault with progress and
cancellation; unreadable sources must be reported rather than skipped.

## 7. Prototype and Measurement Gate

The first Windows prototype uses `sqflite_common_ffi` as the local SQLite
runtime. It verifies a Vault-path-hashed cache location outside the Vault,
schema creation/migration, transaction rollback, cache deletion, clean
recreation, one-Work upsert/delete, cursor continuation, and category/status/
tag filtering. It now streams an explicit `works/` rebuild in bounded cache
write batches, quarantines partial results until the generation completes, and
handles one precise source path as indexed, deleted, unreadable, or ignored.
It does not yet run from app startup/watch lifecycle or serve Home.

Before connecting the runtime to the shipped query path, run it against the
SA-02 fixture profiles on the Steam target platform.

1. Open an empty cache and rebuild from 100, 10,000, and 1,000,000 synthetic
   summaries without changing canonical files.
2. Measure cold/open page, cursor continuation, stable-ID hydration lookup,
   category/status/tag filtering, and one-path upsert/delete.
3. Interrupt cache mutation/rebuild and verify the cache can be discarded while
   the Vault remains readable and P0 recovery is unaffected.
4. Verify an externally modified Markdown file produces a one-path cache update
   through SA-01; verify ambiguous watch state shows repair rather than a
   silent full read.
5. Verify package licensing, Windows packaging, no required network service,
   and cache clear/rebuild UX before committing to a concrete runtime.

## 8. Non-Decisions

- No canonical Markdown/YAML, v3 schema, serializer, or migration changes.
- No durable Vault ID field yet.
- No Universal Record, relationship-assertion, sharing, or AI-agent model.
- No claim that cache contents are safe to sync, export, or use as evidence.
- No Home UI migration until this bounded-store gate passes.
