# Infinite Archive Hardening Plan

> **Status:** Active architecture plan
> **Date:** 2026-07-03
> **Last architecture review:** 2026-07-10
> **Scope:** Make AKASHA safe for unbounded personal archiving and external AI/tool use without making AKASHA an AI service, media player, or orchestrator.
> **Related:** [P0_RECOVERABLE_VAULT_WRITE_GATE.md](../history/closure-2026-07/P0_RECOVERABLE_VAULT_WRITE_GATE.md) · [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](../history/closure-2026-07/ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md) · [VISION.md](VISION.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md](AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md) · [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md)

## 1. Decision

AKASHA already has the right foundation to become an ultimate archive:

- the user's vault Markdown remains the durable source of truth
- the app works without AI
- external agents/tools can read and assist through explicit contracts
- registry/catalog data stays separate from personal memory

The next architecture hardening target is not "add AI." The target is:

> Keep AKASHA as the archive substrate, then make indexes, taste signals, agent writes, and ID paths strict enough that the archive can grow without losing meaning, speed, or trust.

Pre-release note: because Steam v1 has not shipped yet, [ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md](../history/closure-2026-07/ULTIMATE_ARCHIVE_PRE_RELEASE_ARCHITECTURE_AUDIT.md) may override the earlier "post-v1 only" posture for ID paths and operation contracts if the migration is contained and well-tested.

## 2. Product Boundary

AKASHA is responsible for:

- preserving user-owned records in human-readable vault files
- making records easy to browse, edit, back up, and move
- exposing enough structure for external tools and AI agents to understand the archive
- accepting safe, validated archive writes from humans, apps, scripts, or agents

AKASHA is not responsible for:

- choosing or hosting the AI agent
- becoming a chat companion
- playing music/video or controlling media tools
- deciding final user taste without user-owned evidence
- turning every passing mention into a permanent archived entity

This boundary must remain true even when future AI workflows become powerful.

## 3. Non-Negotiable Invariants

| Invariant | Rule |
| --- | --- |
| Vault-first | `.md` records are the durable memory. Indexes are derived. |
| Works without AI | Every core archive workflow must remain usable by a human alone. |
| Stable identity | Durable records need stable IDs independent of title/path churn. |
| Rebuildable indexes | Anything under `.akasha/` must be disposable and rebuildable. |
| Evidence-backed taste | Taste is inferred from ratings, tags, status, notes, links, collections, quotes, and revisits, not from opaque model memory. |
| Agent-safe writes | Agents express intent through allowed operations, never arbitrary vault mutation. |
| Candidate before archive | High-volume extraction creates candidates first; user value promotes them into archived records. |
| Tool separation | Playback, recommendation execution, and external automation happen outside AKASHA. |

## 4. Hardening Tracks

### 4.0 P0 — Recoverable Vault Write Gate

Before any new archive feature, Universal Record work, or behavior evidence,
AKASHA must pass the release-blocking
[P0 Recoverable Vault Write Gate](../history/closure-2026-07/P0_RECOVERABLE_VAULT_WRITE_GATE.md).

The gate is intentionally stronger than an "atomic save" claim: it requires a
verified old or new copy after interruption, non-destructive conflict handling,
and lossless preservation of unknown user data on every durable write path.

**2026-07-10: P0 passed.** The shared manifest-first recovery protocol,
revision conflict checks, lossless frontmatter patching, Canvas two-file
recovery, direct-call audit, full analyzer, and full test suite are recorded
in the gate document. Subsequent feature work may resume only while preserving
that contract.

### 4.1 Vault Schema Freeze

The archive record schema should become the stable language shared by the app, vault, indexes, and external tools.

Priority fields:

- `id`
- `record_kind`
- `entity_type`
- `title`
- `aliases`
- `category`
- `tags`
- `rating`
- `status` / `my_status`
- `links`
- `created_at`
- `updated_at`
- `source` / `evidence`

Rules:

- Add fields conservatively; do not rename casually.
- Prefer additive schema evolution over migration churn.
- Treat frontmatter as the machine-readable surface and Markdown body as the human memory surface.
- Keep unknown frontmatter/body blocks round-trippable.

2026-07-04 code slice:

- `ArchiveRecordContract` defines the shared v3 metadata surface for Work, Entity, Journal, and Timeline records.
- New v3 writes emit `created_at`, `updated_at`, `source`, `aliases`, `original_title`, `external_ids`, `evidence`, and structured `links`.
- v1/v2 reads remain compatible by falling back from `created_at` to `added_at`.
- Work/Entity/Journal/Timeline app rewrites preserve additive metadata so external IDs, evidence, aliases, and relation hints are not lost.
- `ArchiveOperationValidator` treats provenance fields as app-owned and blocks direct payload mutation of `created_at`, `updated_at`, `source`, and `source_operation_id`.
- Existing Work, Entity, Journal, and Timeline edits preserve the original
  creation `source`; editing a record must not relabel an import or agent record
  as an app-created record.

### 4.2 Derived Index Layer

The current `.akasha/record_index.json` is the right first slice. Long term,
large vaults need stronger derived query stores: minimal portable shards may
remain under `.akasha/`, while transactional SQLite/WAL query caches belong
outside the syncable Vault root.

Required logical indexes:

| Index | Purpose |
| --- | --- |
| Record index | Fast list/detail loading without parsing the whole vault |
| Tag index | Taste, theme, mood, genre, and personal keyword lookup |
| Title/alias index | Natural language lookup and duplicate detection |
| Link index | Outgoing relationships between records |
| Incoming index | Backlinks and graph exploration |
| Taste index | Evidence-backed preference signals |
| Snippet index | Searchable excerpts, quotes, scenes, and notes |

Rules:

- App startup must not parse the entire vault.
- External tools should prefer indexes/summaries for discovery.
- Indexes must never become the only copy of user memory.
- Index format can evolve, but its rebuild command and schema version must be explicit.

#### 4.2.1 Current Scale Gap And Readiness Gate

The current derived indexes are a correct small-vault slice, but they are not
yet an unbounded-vault implementation. Some interactive paths still enumerate
and parse every Markdown file, and some incremental updates load and rewrite a
whole JSON index. This is an architectural limitation, not a Markdown failure.

Until this gate passes, the application must not represent the current index
layer as capable of millions of active records.

The scale readiness gate requires:

1. Interactive startup, record lookup, list pagination, search, and backlinks
   use a bounded derived query path. They must not recursively scan the Vault or
   deserialize all Records as a fallback.
2. Saving or deleting one Record performs bounded work in the affected index
   shard/table. It must not read and serialize every summary, link, or taste
   signal in the Vault.
3. A full Markdown scan remains available only as an explicit rebuild,
   validation, import, or repair operation with visible progress and result.
4. A malformed or unsupported source file remains preserved and is reported as
   an unreadable source item; it must not silently disappear from discovery.
5. Journal and Timeline storage may be partitioned by date or another stable
   layout only through an additive, opt-in migration. Existing flat paths remain
   readable until then.
6. The derived-store choice (shards, SQLite, or another local rebuildable
   format) is decided by measured fixtures and query/write profiles, not by
   preference for a storage technology.

This gate does not authorize a Universal Record model, Vault migration, or a
Markdown replacement. It constrains future read/write paths while preserving
the Vault as the user-owned source.

### 4.3 Taste Signal Model

Taste should be represented as derived, evidence-backed signals instead of hidden AI conclusions.

Suggested logical model:

```yaml
taste_signal:
  id: ts_...
  source_record_id: rec_...
  target_id: rec_or_entity_...
  target_kind: work | person | concept | music | tag | relation
  signal_type: rating | tag | status | collection | link | memo | quote | revisit
  value: "energetic orchestral action OST"
  weight: 0.0-1.0
  evidence_path: "works/movie/..."
  updated_at: "2026-07-03T00:00:00Z"
```

Rules:

- Taste signals are derived from user-owned records.
- A signal must point back to evidence.
- Multiple weak signals are better than one opaque strong conclusion.
- Agents may read taste signals, but AKASHA should preserve the evidence first.

Example future flow:

> User: "내가 좋아하는 액션영화 OST 틀어줘."
>
> External agent: reads AKASHA taste/index evidence, decides likely music preference, then uses a separate playback tool.
>
> AKASHA role: archive and expose the user's taste memory. It does not play music.

### 4.4 Agent Write Contract

Agent writes should be treated as archive operations, not file chaos.

Allowed operation vocabulary:

- `create_record`
- `update_frontmatter`
- `append_section`
- `set_rating`
- `set_status`
- `add_tags`
- `remove_tags`
- `add_link`
- `promote_candidate`
- `merge_duplicate`

Rules:

- [AI Archive Write Gateway ADR](AI_ARCHIVE_WRITE_GATEWAY_ADR.md) supersedes
  direct file mutation as AKASHA's recommended AI write path. Raw external
  editor writes remain a user-owned compatibility boundary, not an agent API.
- A structured Gateway contract is required before any general agent write,
  including pre-release work; it is not deferred merely because an AI is external.
- Every operation should validate schema, duplicate risk, path safety, and conflict risk.
- Agents must not directly edit `.akasha/` indexes, app state, registry manifests, or hidden runtime files.

2026-07-03 code slice:

- `ArchiveOperation` records user/app/agent/import/script write intent.
- `ArchiveOperationValidator` rejects unsafe IDs, direct path/runtime payloads, identity-field mutation, invalid rating/tag/link payloads, missing candidate promotion targets, and unsafe duplicate merges.
- `ArchiveOperationExecutor` executes the first safe operation path: `promoteCandidate` -> Entity journal -> catalog mirror -> candidate close -> applied log.
- `source_operation_id` marks operation-created Entity journals so retries can roll forward only when the surviving file belongs to the same operation.
- Future mutating operations should reuse the same validator, revision guard, source-operation marker, and applied-log pattern.

### 4.5 ID Path Strategy

Title-based paths are readable and worked well for early v1 development. Infinite archives need ID-stable paths so renames, duplicate titles, language changes, and external references do not break identity.

Long-term target shape:

```text
works/{category}/{id}.md
entities/{type}/{id}.md
journals/{yyyy}/{mm}/{id}.md
```

Rules:

- Keep titles in frontmatter, not as the source of identity.
- New canonical records should prefer ID paths once Vault Layout v3 is accepted.
- Existing vaults should migrate only through an explicit migration.
- Preserve human-readable display names in UI and indexes.
- Preserve human-readable aliases in frontmatter for ID-named files.
- Path migration must update indexes and backlinks atomically.

## 5. Roadmap

| Phase | Timing | Goal |
| --- | --- | --- |
| Phase 0 | Now | Align active docs and audit whether Vault Layout v3 should land before release |
| Phase 1 | Pre-release if contained, otherwise post-v1 | Add schema fixtures, validation docs, and agent operation examples |
| Phase 2 | Pre-release if contained, otherwise post-v1 | Make new Work/Entity paths ID-canonical |
| Phase 3 | Pre-release if contained, otherwise post-v1 | Add Candidate Store and validated promotion |
| Phase 4 | Post-v1 | Expand derived indexes into tag/link/incoming/taste/snippet surfaces |
| Phase 5 | Post-v1 | Introduce structured import/edit contract for batch agent writes |
| Phase 6 | Later | Expose stable local query surfaces for external agents/tools |

Phase 0 is documentation and decision alignment. It should not force risky vault migrations, but pre-release is the right time to decide whether new records should switch to Vault Layout v3.

## 6. Risks And Mitigations

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Title/path identity | Renames and duplicate titles break references | Stable IDs, future ID paths, path index |
| Large JSON indexes | Startup and writes degrade as vault grows | Versioned local DB or sharded indexes |
| AI-created noise | Agents can create low-value records too quickly | Candidate lifecycle, duplicate checks, user promotion |
| Opaque taste inference | "User likes X" becomes unverifiable | Evidence-backed taste signals |
| Conflict writes | App/user/agent edit the same record | Operation contract, backups, mtime/hash checks |
| Scope creep | AKASHA becomes AI/player/orchestrator | Keep archive boundary in VISION, ARCHITECTURE, and Agent docs |
| Privacy leakage | External tools may read more than needed | Explicit readable surfaces and future scoped query contracts |

## 7. Definition Of Done

The architecture is ready for unbounded archive growth when:

- every durable record has stable identity
- app list/search paths use bounded derived queries instead of full-vault parsing
- single-record saves update bounded index data instead of rewriting a whole Vault index
- tags, links, aliases, and taste evidence are queryable without opening every file
- unreadable source files are visible as preserved diagnostics, not silently omitted
- external writers have a documented operation vocabulary
- AI/tool workflows can help the archive without owning the archive
- a user can still open the vault folder and understand their memories without AKASHA or AI
