# Ultimate Archive Pre-Release Architecture Audit

> **Status:** Active pre-release architecture audit
> **Date:** 2026-07-03
> **Scope:** Decide whether AKASHA should keep the current vault architecture, harden it, or migrate to a stronger canonical layout before Steam v1.
> **Related:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [VISION.md](VISION.md) · [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md)

## 1. Decision

Current AKASHA is qualified to become the ultimate archive, but the current architecture should not be treated as final.

The correct pre-release stance is:

> Keep the proven vault/index code, but promote a stricter **Vault Layout v3 Canonical** before release if validation shows the migration is contained.

The architecture should not be rewritten from zero. The strong parts are already real:

- local-first human-readable vault Markdown
- `RecordKind`, `ArchiveRecord`, and `EntityAnchor`
- stable `wk_*`, `wk_u_*`, `pe_u_*`, `co_u_*` ID codecs
- derived `.akasha/record_index.json`, `link_index.json`, and `entity_path_index.json`
- canonical wiki links by entity ID
- vault trash, backup export, and recovery drafts

The weak parts are also real:

- new Work and Entity records still use title-based file paths
- Work save goes through `VaultPort.saveItem`, while Timeline/Journal use `ArchiveRecordPort`
- Entity save goes through `EntityVaultStore`, separate from both
- agent writes are documented as operations, but not yet a first-class app-side operation model
- taste signals and candidate promotion are planned, not implemented
- indexes are fragmented JSON files and will need a stronger index manager later

So the answer is not "everything is perfect." The answer is:

> AKASHA has the right bones. Before release, we should lock a stricter canonical contract so future AI agents can help without corrupting the archive.

## 2. Current Architecture Grade

| Area | Current state | Grade | Pre-release decision |
| --- | --- | --- | --- |
| Vault SSOT | Markdown frontmatter + body is source of truth | Strong | Keep |
| Entity/Record model | Good domain foundation, but Work still relies on `AkashaItem` | Good | Keep and unify through operations |
| ID stability | IDs exist and are stable in frontmatter | Good | Make IDs path-canonical for new records |
| Path stability | Work/Entity paths are title-based | Risk | Replace as canonical v3 default |
| Indexes | Rebuildable JSON indexes exist | Good first slice | Keep, then wrap under index manager |
| Agent write | Protocol exists, implementation is file-level | Partial | Introduce operation contract as code model |
| Candidate lifecycle | Documented, not concrete | Partial | Add candidate store before bulk agent creation |
| Taste model | Documented, not concrete | Partial | Derive from evidence into taste index |
| Legacy compatibility | Strong | Good | Read forever, but stop using legacy as canonical |

## 3. Vault Layout v3 Canonical

The biggest pre-release change worth making is path identity.

### 3.1 Canonical Directory Shape

```text
{vault}/
  works/
    {category}/
      {work_id}.md

  entities/
    {type}/
      {entity_id}.md

  journals/
    {yyyy}/
      {record_id}.md

  timeline/
    {yyyy}/
      {record_id}.md

  posters/
    {content_hash}.{ext}

  catalog/
    user_entities.json

  .akasha/
    candidates/
      {entity_type}/{shard}.json
      name_index/{entity_type}/{shard}.json
    indexes/
      record_index.json
      link_index.json
      entity_path_index.json
      taste_index.json
    ops/
      inbox/
      applied.jsonl
    recovery/
    trash/
```

### 3.2 Why ID Paths

Title paths are pleasant for small vaults, but they are not strong enough as the canonical infinite archive layout.

They fail under:

- duplicate titles
- translated titles
- user renames
- safe filename collisions such as `A/B` vs `A_B`
- agent-created bulk records
- external references that outlive display titles

In v3, the display title belongs in frontmatter:

```yaml
---
record_kind: workJournal
entity_type: work
entity_id: "wk_u_abcd1234"
work_id: "wk_u_abcd1234"
title: "My Favorite Action Movie"
category: movie
---
```

The file path should preserve identity:

```text
works/movie/wk_u_abcd1234.md
```

## 4. Record Contract v3

Every durable archive file should share the same minimum contract.

```yaml
---
schema_version: 3
record_kind: workJournal
record_id: "rec_wk_u_abcd1234"
entity_type: work
entity_id: "wk_u_abcd1234"
title: "..."
aliases: []
tags: []
created_at: "2026-07-03T00:00:00Z"
updated_at: "2026-07-03T00:00:00Z"
source: user
---
```

Rules:

- `record_id` identifies the record.
- `entity_id` identifies the thing being archived.
- For Work v3, `record_id` may be derived as `rec_{work_id}` for one primary journal per work.
- For Person/Concept/Event, `record_id` may be derived as `rec_{entity_id}` for one primary journal per entity.
- For freeform journal and timeline, `record_id` is independent.
- `title` is display metadata, never identity.
- `work_id` remains as a Work compatibility alias.

## 5. Operation Contract v3

The future agent flow should not be "AI writes arbitrary Markdown." It should be:

```text
Agent/user intent
  -> ArchiveOperation
  -> validation
  -> vault write
  -> index update
  -> UI reload
```

Required operation vocabulary:

| Operation | Purpose |
| --- | --- |
| `create_record` | Create Work/Entity/Journal/Timeline record |
| `update_frontmatter` | Change title, rating, status, tags, poster, aliases |
| `append_section` | Add memo, quote, scene, reflection without destroying body |
| `add_link` | Add canonical `[[entity_id|Title]]` link |
| `extract_candidates` | Store possible people/concepts without polluting main archive |
| `promote_candidate` | Turn candidate into archived Entity record |
| `merge_duplicate` | Merge duplicate IDs/records with explicit user confirmation |
| `rebuild_indexes` | Rebuild derived `.akasha/indexes/*` |

Pre-release code target:

- keep the first `ArchiveOperation` model and `ArchiveOperationValidator` as the write-intent gate
- route Work/Entity/Journal/Timeline saves through one operation service over time
- keep direct file protocol as compatibility, not as the final internal model

## 6. Candidate Store

Agents will extract many names from works. Creating a full entity for every mention would pollute the archive.

v3 should add a candidate layer:

```json
{
  "version": 1,
  "candidates": [
    {
      "candidateId": "cand_pe_...",
      "entityType": "person",
      "title": "Character Name",
      "sourceRecordId": "rec_wk_u_abcd1234",
      "evidence": "mentioned in cast notes",
      "status": "candidate",
      "confidence": 0.72,
      "createdAt": "2026-07-03T00:00:00Z"
    }
  ]
}
```

Rules:

- candidates are not first-class archive records
- candidates do not appear as normal library items
- promotion creates `entities/{type}/{entity_id}.md`
- duplicate detection must run before promotion

2026-07-03 code slice:

- `ArchiveCandidate` stores extracted possible entities with `candidate`, `promoted`, `dismissed`, and `merged` states.
- `ArchiveCandidateStore` reads legacy `catalog/candidates.json`, then writes scalable candidate shards at `.akasha/candidates/{entityType}/{shard}.json`.
- Candidate duplicate lookup uses `.akasha/candidates/name_index/{entityType}/{shard}.json` instead of scanning one giant JSON file.
- `ArchiveCandidateValidator` blocks invalid candidate IDs, missing evidence/source records, confidence outside `0..1`, closed-candidate promotion, type mismatch, existing target IDs, and duplicate titles/aliases from catalog context.

## 7. Taste Index v3

Taste should remain evidence-backed and derived.

Recommended derived file:

```text
{vault}/.akasha/indexes/taste_index.json
```

Taste evidence sources:

- rating
- status / my_status
- tags
- Hall of Fame / favorite flags
- collections
- wiki links
- quotes
- repeated revisits
- memo sections

Example signal:

```json
{
  "signalId": "ts_...",
  "sourceRecordId": "rec_wk_u_abcd1234",
  "targetId": "tag:action-ost",
  "signalType": "tag",
  "value": "action OST",
  "weight": 0.8,
  "evidencePath": "works/movie/wk_u_abcd1234.md"
}
```

AKASHA should preserve this evidence. External agents can use it to choose tools, playlists, recommendations, or summaries.

2026-07-03 code slice:

- `TasteSignal` and `TasteIndexService` now define the first concrete taste index contract.
- Rebuild writes `{vault}/.akasha/indexes/taste_index.json`.
- The first extractor derives `rating`, `status`, `favorite`, `tag`, `memo`, `quote`, and `link` signals from vault Markdown.
- Every signal keeps `sourceRecordId`, `sourceRecordKind`, `targetId`, `targetKind`, `evidencePath`, and `evidenceField`.
- Memo and quote values are clipped to short snippets so the index stays a query surface, not a duplicate vault.

## 8. Migration Strategy

Because release has not happened yet, v3 can be made the default for new vault writes.

Safe migration order:

1. Add `VaultLayoutVersion` and one central `VaultRecordPathResolver`.
2. Make new Work/Entity saves use ID paths.
3. Keep v1/v2 title paths readable forever.
4. Add an optional migration tool for existing local dev vaults.
5. Update tests and agent fixtures to expect v3 canonical paths.
6. Add index rebuild validation for v1/v2/v3 mixed vaults.

Do not start by moving every file blindly.

Rules:

- if a record already has `filePath`, preserve it unless migration is explicit
- if a record is newly created, write to v3 ID path
- if migration runs, write a before/after path map
- update `record_index`, `entity_path_index`, and links after migration
- keep backups/trash active during migration

## 9. What To Keep

Keep these pieces:

- Markdown vault source of truth
- `works/`, `entities/`, `journal/timeline` conceptual separation
- `RecordKind`
- `EntityAnchor`
- `EntityIdCodec` and `WorkIdCodec`
- link identity policy with `[[entity_id|Title]]`
- derived `.akasha` index idea
- vault trash and backup flows
- current v1/v2 read compatibility

## 10. What To Change Before Release

If we choose the stronger pre-release architecture, these should happen before v1:

1. Centralize path resolution.
2. Switch new Work/Entity paths to ID filenames.
3. Add schema_version/record_id to serialized frontmatter.
4. Introduce operation model and validator, even if UI still calls old services.
5. Add candidate store schema.
6. Keep taste index schema evidence-backed and derived.
7. Update Agent docs from "post-v1 hardening" to "v3 canonical contract."

## 11. Final Recommendation

Do not rewrite AKASHA from scratch.

Do not ship title paths as the final canonical archive layout.

The best route is:

> **Pre-release Vault Layout v3:** keep existing behavior readable, but make new records ID-path canonical and make agent writes operation-based.

That gives AKASHA the property we actually need:

- human-readable vault
- stable machine identity
- safe agent assistance
- rebuildable indexes
- future taste intelligence without AKASHA becoming an AI service

## 12. Implementation Slice 2026-07-03

Vault Layout v3 feasibility has started in code.

Implemented:

- central `VaultRecordPathResolver`
- new Work journal paths prefer `works/{category}/{work_id}.md`
- new Entity journal paths prefer `entities/{type}/{entity_id}.md`
- existing `filePath` records remain readable and are not moved on ordinary save
- Work/Entity/Journal/Timeline serializers now write `schema_version: 3`
- Work primary journals now write `record_id: "rec_{work_id}"`; Entity primary journals write `record_id: "rec_{entity_id}"`
- focused path/index/vault tests updated for ID-path canonical behavior
- `ArchiveOperation` and `ArchiveOperationValidator` now define the first code-level write contract for user/app/agent/import/script intent
- validator blocks direct path payloads, identity-field mutation, unsafe IDs, invalid ratings/tags/links, missing candidate promotion targets, and unsafe duplicate merges
- `ArchiveCandidate`, `ArchiveCandidateStore`, and `ArchiveCandidateValidator` now isolate agent/import extraction before first-class archive promotion
- `ArchiveOperationExecutor` now executes validated `promoteCandidate` operations through Entity journal save, catalog mirror, candidate close, and existing index update paths
- `ArchiveOperationAppliedLog` now records successful operations at `.akasha/ops/applied.jsonl` so repeated `operationId` calls return `alreadyApplied` instead of duplicating writes
- `ArchiveRecordRevisionService` now defines `expectedRevision` as an opaque file revision based on mtime, length, and content hash; executable create/promote operations reject existing or stale target records with `operation_conflict`
- operation-created Entity journals now write `source_operation_id` so a retry can roll forward if the file write succeeded but the applied log append did not
- `promoteCandidate` retry recovery accepts only matching `source_operation_id`/`entity_id`/`entity_type`; mismatched partial files remain conflicts
- Work and Entity saves now reverse-lookup existing vault Markdown by `work_id`/`entity_id` before creating a new canonical path, preventing legacy-title duplicate files when path caches are missing
- Entity journals now serialize and parse `aliases: []`, preserving human-readable names for ID-based files and external Markdown tools
- Candidate duplicate guards now compare normalized title/alias variants, including bracket and punctuation differences
- `TasteIndexService` now rebuilds `.akasha/indexes/taste_index.json` from user-owned vault evidence and exposes target/source queries for external tools

Validated:

- `flutter test` focused vault/index/path suite: 34 pass
- `flutter test` archive operation/candidate/executor/revision contract suites: 34 pass
- `flutter test test/taste_index_service_test.dart`: 2 pass
- `flutter test`: 720 pass
- `flutter analyze lib`: 0 issues

Remaining before calling v3 complete:

- add index manager wrapper for coordinated rebuilds
- add collection/revisit/music-specific taste signal expansion
- decide whether to migrate existing local dev vault files or only use v3 for new records
