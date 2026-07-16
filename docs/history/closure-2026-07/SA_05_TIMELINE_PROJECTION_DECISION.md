# SA-05 — First High-Cardinality Projection: Timeline

> **Status:** Architecture decision only. No Timeline index, serializer,
> migration, or UI implementation is introduced here.
> **Date:** 2026-07-12
> **Related:** [SA-04 Bounded Domain Read and Identity Contract](SA_04_BOUNDED_DOMAIN_READ_CONTRACT.md),
> [SA-03 Derived Index Persistence](SA_03_DERIVED_INDEX_PERSISTENCE_DECISION.md),
> [Core Archive Ontology](P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md)

## 1. Decision

The first post-Work high-cardinality projection should be the **Timeline
list**, not a universal Record table, Journal, or Entity browse projection.

It will be a local, rebuildable, cursor-paged projection whose rows are
read-only locators. Opening a row must hydrate exactly one canonical Markdown
Document by physical `record_id`; editing and deletion remain owned by the
Timeline domain store and P0 recoverable-write path.

No implementation begins until the projection's row shape, cursor encoding,
unreadable-source presentation, and source-sync measurements are accepted.

## 2. Current evidence

| Surface | Current loading path | Scale/meaning problem |
| --- | --- | --- |
| Timeline | `TimelineVaultLoader` lists every `timeline/*.md`, reads full Markdown bodies, parses every file, then sorts all entries by `occurredAt`. | Memory and startup work grow with all Timeline body sizes; parse failures are silently skipped; `occurred_at` is user-semantic local time. |
| Journal | `JournalVaultLoader` lists every `journal/*.md`, reads full bodies, then sorts by `addedAt`. | Also unbounded, but its primary ordering is an archival/system time and it has no separate experienced-time axis. |
| Entity | `EntityVaultLoader` recursively reads every Entity Document; the view also joins user catalog state. | Persistent-subject browsing, catalog coupling, posters, aliases, and relations need a different projection and cannot reuse Timeline semantics. |
| Work Explore | App-local SQLite already provides a cursor-paged Work projection and selected hydration. | It is Work-specific and keyed around `work_id`; it must not be generalized by silently flattening Timeline semantics. |

The current generic record-summary JSON cannot be promoted to the Timeline
projection: it is a whole-Vault JSON map, has mixed ID semantics for Work and
Entity, and does not store Timeline's semantic `occurred_at` or physical
Document identity as a first-class invariant.

## 3. Why Timeline comes first

1. It is a direct archival surface where a user can create very many small
   events, observations, memories, imports, and AI-selected archival entries.
2. Its primary ordering has a non-negotiable domain meaning: `occurred_at` is
   the time the user says the event happened, not the instant AKASHA wrote the
   file. A later import can therefore appear earlier in the Timeline.
3. It already has a dedicated visible list and detail flow, so a bounded row
   can replace a known all-body read without inventing a speculative product.
4. It proves the main anti-flattening rule early: system revision time,
   archival added time, and semantic event time cannot be reduced to one
   generic `time` column.

Journal is the next likely candidate after Timeline. Entity browsing remains a
separate decision because an Entity is a persistent subject, not merely an
event row.

## 4. Required Timeline row contract

The eventual derived row must contain only what the list needs:

| Field | Meaning | Rule |
| --- | --- | --- |
| `recordId` | Physical v3 Document `record_id`. | Primary source identity; never substitute `entity_id`, path, or title. |
| `occurredAtLocal` | User-semantic local timestamp from `occurred_at`. | Primary sort and cursor key; preserve local wall-clock meaning, not a guessed UTC conversion. |
| `addedAtUtc` | AKASHA archival/system creation instant. | Context only; never replace `occurredAtLocal` as Timeline order. |
| `title` | Timeline display title. | Safe list field. |
| `preview` | Explicitly bounded derived excerpt. | Never the full body and always marked derived. |
| `entityId?` | Optional contextual navigation target. | Does not turn the Timeline Record into the Entity. |
| `relativePath` | Current internal locator. | Rebuildable and replaceable; not a durable ID. |
| `observedRevision?` | Cache/source freshness diagnostic. | Cannot authorize writes; selected hydration recomputes the current source. |
| `readability` / `errorCode?` | Source parse/read failure visibility. | An unreadable source must remain reportable, not disappear from rebuild evidence. |

The minimal descending cursor is `(occurredAtLocal, recordId)`. Equal semantic
times must use `recordId` as a deterministic tie-breaker. The final cursor
encoding and treatment of invalid/missing `occurred_at` remain implementation
decisions; neither may silently sort by filesystem modification time.

## 5. Storage and synchronization boundary

The intended direction is a **new Timeline-specific table in the existing
app-local derived SQLite cache**, not a portable Vault database and not a
universal `records` table. SQLite is appropriate for a large, interactive,
cursor-paged list. Canonical Markdown remains the only user data source.

The portable `.akasha/` layer remains appropriate for narrow cross-process
exact locators such as physical `record_id -> path`. A command-capable external
tool must not open the app-local cache until a separate multiprocess ownership,
schema-version, freshness, and repair contract exists.

Initial synchronization must be folder-scoped to `timeline/`; it must not
trigger a full-Vault scan or rebuild Work/Entity projections. A changed source
updates one row, a deletion removes one row, and a malformed source creates
visible rebuild evidence rather than deleting an old valid row silently.

## 6. Explicit non-decisions

- No Universal Record serializer, global record table, or Markdown migration.
- No choice of preview length, FTS, semantic search, AI ranking, or external
  query API.
- No conversion of `occurred_at` to a globally asserted historical instant.
- No automatic Relationship Assertion from a Timeline `entity_id` or wiki link.
- No change to Journal or Entity loader/UI behavior in this slice.

## 7. Implementation gate

Before code is added, the design must specify and test:

1. Cursor paging for Timeline rows, including same-time tie cases and a source
   whose `occurred_at` changes between pages.
2. Selected canonical hydration by physical `record_id`, including a moved
   path, stale locator, duplicate ID, and source-revision change.
3. Independent display of `occurred_at`, `added_at`, and `updated_at` without
   accidental timezone or sort-order substitution.
4. Incremental change, deletion, failed parse, interrupted cache update, and
   explicit rebuild/repair behavior without a whole-Vault fallback on normal
   list navigation.
5. A scale measurement using realistic Timeline body sizes and date ranges;
   it must record cold rebuild time, incremental update time, page latency,
   cache size, and unreadable-source behavior.
6. Regression proof that Work Explore, Journal, Entity, Canvas, P0 recovery,
   unknown YAML preservation, and Gateway provenance remain unchanged.

Only after this gate can a Timeline projection implementation begin.
