# SA-04 — Bounded Domain Read and Identity Contract

> **Status:** Implemented for the bounded local exact-Record command and
> Gateway source identity. No Universal Record serializer or Vault migration
> is introduced here.
> **Date:** 2026-07-12
> **Scope:** Replace scan-based read access one domain at a time without
> flattening Work, Entity, Journal, Timeline, Canvas, or future derived Records.
> **Related:** [Core Archive Ontology](P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md),
> [Provenance and Derived Input](../../active/PROVENANCE_AND_DERIVED_INPUT_ADR.md),
> [SA-03 Derived Index Persistence](SA_03_DERIVED_INDEX_PERSISTENCE_DECISION.md),
> [Local Agent Command Protocol](../../active/LOCAL_AGENT_COMMAND_PROTOCOL.md)

## 1. Decision

AKASHA has three different identifiers that must not be collapsed:

| Identifier | Meaning | Examples | May identify |
| --- | --- | --- | --- |
| `record_id` | Stable identity of one archival Record/Document file. | `rec_wk_u_…`, `jr_…`, `tl_…` | A source input, derived-from edge, Record read, revision, and lifecycle target. |
| `entity_id` / `work_id` | Persistent subject represented by one or more Records. | `pe_u_…`, `wk_u_…` | Entity navigation, title lookup, relationship target, and domain discovery. |
| Relative path | Current physical location of a Document. | `works/movie/…md` | An internal locator only; never durable identity. |

Every new bounded **Record** read, Gateway source reference, derivation input,
or future lifecycle operation MUST use physical v3 `record_id`. An entity/work
ID may be returned alongside it as context, but cannot replace it.

This preserves the possibility that one Entity has many Records: a source
record, a later Journal entry, imported material, and an AI-derived analysis
may all concern the same Work or Person while remaining independently
provenanced archival objects.

## 2. Why the current generic port is not the target abstraction

`ArchiveRecordPort` and `VaultArchiveRecordAdapter` are a legacy convenience
surface, not AKASHA's future universal Record model:

- `listRecords` loads whole Work/Journal/Timeline collections and sorts them in
  memory;
- `getById` scans those collections before finding one item;
- Work uses `work_id` as `ArchiveRecord.recordId`, while Journal/Timeline use
  physical `record_id`;
- it has no complete provenance, evidence, unknown-field, lifecycle,
  relationship-assertion, or Artifact contract; and
- it does not represent Entity journals or Canvas as their real semantic
  objects.

It MUST NOT be expanded into a catch-all serializer, global database row, or
external AI contract. Existing callers remain compatible until their own
bounded domain path is introduced.

## 3. Bounded read shape

A future domain projection may contain a compact locator such as:

```text
documentRecordId    // physical v3 record_id
recordKind          // workJournal, entityJournal, freeformJournal, timelineEntry
entityAnchor?       // entity_id/work_id when the Record concerns an Entity
relativePath        // internal, replaceable source locator
projection fields   // only fields safe for that one list/query
observedRevision?   // cache freshness diagnostic, never write authority
```

The projection is read-only. Opening it performs **selected canonical
hydration**: resolve `documentRecordId`, read the one current Markdown source,
verify identity, then hand the domain-specific complete object to preview or
editing code. The Gateway independently recomputes the revision immediately
before any write.

Canvas remains a composite Document (`canvas.md` + `layout.json`), not a
generic Record row. Canvas edges remain presentation state unless explicitly
promoted to a Relationship Assertion under its own contract.

## 4. Query families stay separate

| Family | Identity | Correct bounded result | Not allowed |
| --- | --- | --- | --- |
| Exact Record read | `record_id` | One Markdown source + exact returned-byte revision | Path input, ambiguous duplicate selection, or whole-Vault fallback. |
| Entity/Work discovery | `entity_id` / `work_id` | Entity/Work summary IDs and display fields | Pretending the Entity is the source Record. |
| Work Explore | `work_id` plus source `record_id` | Cursor-paged Work summaries | Editing a summary as a complete Work. |
| Journal/Timeline list | `record_id` | Domain-specific cursor projection with its own time semantics | Reusing Work sort/time rules. |
| Link/graph query | Source/target anchors plus link tier | Bounded navigation or assertion result | Treating wiki links as independent facts. |
| Taste/snippet query | Evidence source `record_id` + evidence location | Bounded derived signals/excerpts | Copying full bodies or opaque AI conclusions into an index. |

## 5. Legacy compatibility

Legacy v1/v2 documents that lack `record_id` remain readable, exportable, and
editable through existing compatibility paths. AKASHA MUST NOT silently rewrite
or invent a physical `record_id` merely to make a query succeed.

However, such a file is not eligible as a provenance-strength Gateway input or
derived-record input until an explicit, recoverable v3 migration writes its
stable `record_id`. A compatibility locator based on path/entity/work ID may
help the app display the file, but it must be marked as compatibility-only and
must not be recorded as if it were a durable Record input anchor.

## 6. Migration order

1. Make portable exact-lookup indexes map **physical `record_id`** to a path;
   title/alias lookup returns both the matched Entity/Work target and the
   Document `record_id` when present.
2. Make the local command and Gateway source references use that Document ID.
3. Introduce one bounded projection at a time: first a domain list contract,
   then its selected hydration, then its precise incremental maintenance.
4. Replace only the affected `ArchiveRecordPort` caller or legacy loader. Do
   not globally swap models or migrate unrelated domain screens.
5. Keep the legacy adapter until every named caller has an explicit replacement;
   deletion/write behavior remains domain-owned.

## 7. Gate before implementation is considered complete

- A v3 Work/Entity file with both `record_id` and Entity ID resolves by
  `record_id`, while title/entity lookup still returns the Entity context.
- Two different Records about the same Entity remain independently readable,
  revisable, and provenance-addressable.
- Move/rename changes only the locator, never the `record_id`.
- Duplicate `record_id` produces an explicit ambiguity/conflict result; no file
  is chosen silently.
- A v1/v2 file without `record_id` remains visible but cannot masquerade as a
  canonical Gateway source.
- No normal exact read, list page, save, or delete falls back to a recursive
  Vault scan or an all-record deserialization.
- Unknown YAML, P0 recovery, source creation channel, provenance, and each
  domain's own time semantics remain intact.
