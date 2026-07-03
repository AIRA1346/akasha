# Agent Entity Creation & Infinite Taste Archive Architecture

> **Status:** Active ADR
> **Date:** 2026-06-30
> **Scope:** AKASHA as a personal taste archive that external tools and AI agents can read/write safely
> **Related:** [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md), [VISION.md](VISION.md), [AGENT_VAULT_PROTOCOL_V1.md](AGENT_VAULT_PROTOCOL_V1.md), [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md), [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 1. Boundary

AKASHA is not an AI agent, a player, or a tool orchestrator.

AKASHA is the user's durable personal taste archive:

- records works, people, places, concepts, events, songs, impressions, ratings, tags, and relationships
- keeps the human-readable vault as the long-term source of truth
- gives the Flutter app fast derived indexes for UI
- gives any external tool, script, or AI agent a stable schema to understand the user's taste

Out of scope:

- choosing which AI agent the user uses
- implementing an AI companion
- implementing music playback or media-player control
- assuming a specific MCP, SDK, HTTP server, or automation runtime

The design question is therefore not "how does AKASHA make an AI create things?"

The design question is:

> If a user allows an external AI/tool to create or edit many records, how should AKASHA preserve the vault, avoid noise, and remain fast for both app UI and external readers?

---

### 1.1 2026-07-03 Hardening Priority

[INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md) is the current execution plan for turning this ADR into a long-term archive contract.

The priority order is:

1. keep the vault `.md` records as source of truth
2. make derived indexes strict and rebuildable
3. model taste as evidence-backed signals, not opaque AI memory
4. require agent writes to use an explicit operation contract
5. move toward stable ID paths through the pre-release Vault Layout v3 audit or an explicit later migration

---

## 2. Source Of Truth

The vault `.md` files remain the durable source of truth.

Derived files under `.akasha/` are cache/index artifacts and may be rebuilt.

```text
{vault}/**/*.md                durable user records
{vault}/posters/**             user-owned local images
{vault}/catalog/**             lightweight mirrors / candidates
{vault}/.akasha/**             derived indexes, caches, ledgers
```

Rules:

- A record must remain useful when opened as plain Markdown.
- IDs are stable and must not be rewritten casually.
- Title changes should not imply identity changes.
- Indexes may accelerate lookup, but cannot become the only copy of user memory.
- External tools may read `.md`, but should prefer structured contracts when writing.

---

## 3. External Writer Model

An external writer can be a human, script, importer, AI agent, or future tool.

AKASHA should not depend on which one it is.

There are two write paths:

### 3.1 File Protocol

The writer creates or edits vault Markdown directly according to [VAULT_AGENT_GUIDE.md](VAULT_AGENT_GUIDE.md).

This is open and portable, but has higher risk:

- duplicate records
- malformed frontmatter
- path conflicts
- stale derived indexes

### 3.2 Structured Import / Edit Contract

The writer submits a structured request and AKASHA validates and persists it.

This is safer and should be the recommended path for high-volume creation.

Example shape:

```json
{
  "action": "create_record",
  "record_kind": "workJournal",
  "category": "music",
  "title": "Meltdown",
  "creator": "iroha",
  "tags": ["vocaloid", "electronic", "lonely"],
  "body": "# Memo\n..."
}
```

AKASHA responsibilities in this path:

- assign or validate `work_id` / `entity_id`
- normalize tags
- detect likely duplicates
- choose the storage path
- write the `.md`
- update or schedule index rebuilds

This contract is not an AI feature. It is a stable archive input surface that any external tool may use.

---

## 4. Entity Life Cycle

The vault must not create a full entity for every passing mention.

Use three levels:

| Level | Physical form | Purpose |
|-------|---------------|---------|
| Mention | plain text or wiki link in a record body | lightweight reference, no independent record yet |
| Candidate | lightweight metadata in a candidate/index file | possible future entity, dedupe review target |
| Archived | `entityJournal` or `workJournal` `.md` | durable first-class archive record |

Promotion rules:

- repeated mentions can become candidates
- user-confirmed or high-value candidates can become archived records
- archived records should receive stable IDs
- candidates must not pollute the main entity list by default
- high-volume candidate extraction writes to sharded `.akasha/candidates/*` storage with sharded name indexes, while legacy `catalog/candidates.json` remains read-compatible

This keeps high-volume AI-assisted extraction from turning the vault into noise.

---

## 5. Media Taxonomy

Keep first-class categories small.

Do not encode every genre, subgenre, mood, platform, or fandom as a hard-coded enum.

Recommended direction:

```text
category:
  manga
  webtoon
  animation
  game
  book
  movie
  drama
  music
```

Genres, moods, styles, fandom labels, and personal meanings belong in dynamic tags and links:

```yaml
category: music
tags: ["vocaloid", "ost", "electronic", "night", "lonely", "repeat"]
```

For Korean UI, the labels can be localized:

- `music` -> `음악`
- `vocaloid` -> `보컬로이드`
- `ost` -> `OST`
- `trot` -> `트로트`
- `electronic` -> `일렉트로`

The storage model should prefer stable normalized tag keys plus display labels where needed.

AKASHA should archive taste, not playback behavior. Playback links and player automation are out of scope unless a future user-facing product decision brings them back.

---

## 6. Music As Taste Record

Music records are works.

They should answer:

- what did the user like?
- why did the user like it?
- which moods, works, places, people, or concepts does it connect to?
- how strongly does the user value it?

Example:

```yaml
---
record_kind: workJournal
entity_type: work
work_id: "wk_u_abcd1234"
entity_id: "wk_u_abcd1234"
category: music
title: "Meltdown"
creator: "iroha"
rating: 5.0
status: "often"
my_status: "often"
tags: ["vocaloid", "electronic", "lonely", "night"]
added_at: "2026-06-30T20:45:00.000Z"
---

# Memo

The sound connects to a sharp, lonely night feeling.

# Links

[[co_u_solitude|solitude]]
[[pe_u_miku|Hatsune Miku]]
```

An external AI can later answer "what vocaloid songs do I like?" by querying:

- `category = music`
- `tags contains vocaloid`
- positive `rating` / `status`
- memo snippets and linked concepts

The actual act of playing music remains outside AKASHA.

---

## 7. Scale Requirement

Do not design around a single fixed target count.

Design around invariant access patterns:

- app startup must not parse the entire vault
- search must not require scanning every Markdown body
- record open may read one full `.md`
- record save should update one record and related indexes
- external tools should query indexes/summaries instead of ingesting the whole vault
- UI must virtualize long lists and load details on demand

This is how the archive can keep growing without changing the mental model.

---

## 8. Derived Index Model

Short term JSON indexes are acceptable while the vault is small.

Long term, a large vault needs a single local derived index store, likely:

```text
{vault}/.akasha/vault_index.db
```

This database is not the source of truth. It is rebuildable.

Suggested logical indexes:

| Index | Purpose |
|-------|---------|
| record index | id, kind, category, title, path, updated_at |
| tag index | normalized tag -> record ids |
| alias/title index | title and aliases for lookup |
| link graph | source id/path -> target id |
| incoming graph | target id -> source records |
| taste facets | rating, status, favorite flags, personal tags |
| full-text snippets | title/body snippets for search |

The current JSON files remain useful stepping stones:

- `.akasha/entity_path_index.json`
- `.akasha/record_index.json`
- `.akasha/link_index.json`

But they should be treated as transitional indexes for a future sharded or SQLite-backed index.

---

## 9. Path Strategy

Title-based paths are readable, but weak for high-volume external creation.

Problems:

- rename becomes path change
- duplicate titles collide
- non-ASCII and filesystem edge cases accumulate
- external tools must understand filename rules

Long-term direction:

```text
works/{category}/{id}.md
entities/{type}/{id}.md
```

or, for very large folders:

```text
works/{category}/{shard}/{id}.md
entities/{type}/{shard}/{id}.md
```

The display title belongs in frontmatter:

```yaml
title: "..."
```

This can be introduced as Vault Layout v3 before release if the migration is contained and tested; otherwise it remains an explicit later migration. Steam v1 should not churn existing vault paths accidentally.

---

## 10. Duplicate Control

High-volume external creation needs duplicate control before archive pollution.

Minimum duplicate signals:

- normalized title
- aliases
- creator
- category
- release year
- external ids if present
- same linked parent work/person/concept
- similar tags

Outcomes:

- exact match -> update/append existing record
- likely match -> candidate review
- no match -> create new user-local record

The app should prefer "merge or promote" flows over blindly creating new `.md` files.

---

## 11. Relationship Model

Taste is not only a list of records.

AKASHA should make relationships cheap to create and cheap to query.

Useful relation examples:

- song -> artist
- song -> source work
- OST -> movie
- character -> work
- place -> work
- concept -> many works
- user's emotion tag -> records

In Markdown, links can remain human-readable:

```markdown
[[wk_u_abcd1234|Meltdown]]
[[co_u_solitude|solitude]]
```

Derived indexes should make these relationships queryable without parsing every file.

---

## 12. Product Stance

For v1:

- keep `.md` as the user-facing record format
- keep AI/tool implementation out of AKASHA product scope
- keep music playback out of scope
- document the external writer contract
- avoid large path/index migrations before release
- dogfood with real records and observe friction

For post-v1:

- add `music` as a first-class category if dogfood confirms it
- add structured import/edit contract
- add incremental indexer
- move large derived indexes toward SQLite or sharded index files
- consider ID-based paths for new vault layouts
- provide fast query surfaces for external tools

---

## 13. Decision Summary

AKASHA should support AI-assisted and tool-assisted mass creation indirectly by being a robust archive, not by becoming the AI.

The stable architecture is:

```text
human-readable vault records
  + small stable taxonomy
  + dynamic tags and links
  + candidate promotion
  + derived indexes
  + structured import/edit contract
```

This keeps the app usable, keeps the vault portable, and lets any future AI/tool understand the user's taste without forcing AKASHA to own the AI layer.

For the active hardening roadmap, see [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md).
