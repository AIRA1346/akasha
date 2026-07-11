# AKASHA Vault Format Specification (v3)

This document defines the canonical filesystem layout, record constraints, metadata schema, and integration principles for an **AKASHA Vault**.

The AKASHA Vault format is an open, human-readable, offline-first specification designed to guarantee:
1. **Eternity**: Thought and knowledge logs are stored in plain UTF-8 Markdown and YAML, readable by any system or editor over decades.
2. **Structure**: Thoughts, links, and contexts are structured consistently, allowing future AI agents to parse and reason without schema degradation.
3. **User Ownership**: The files on the disk represent the single source of truth (SSOT). All indexes and databases are secondary, fully reconstructible derivatives.

---

## 1. Directory Layout

A compliant AKASHA Vault folder MUST organize its files according to the following structure:

```text
{vault_root}/
├── catalog/
│   └── user_entities.json          # Cached local catalog metadata (work & entity indexes)
├── posters/                        # Media/Item image assets
├── works/
│   └── {category}/
│       └── {wk_id}.md              # Work journal records (e.g. works/manga/wk_u_12345.md)
├── entities/
│   ├── person/
│   ├── event/
│   ├── concept/
│   ├── place/
│   ├── organization/
│   └── object/                     # Tangible things/physical possessions
├── timeline/                       # Timeline entries (timelineEntry)
├── journal/                        # Freeform daily logs (freeformJournal)
├── system/                         # Permanent management data (never delete)
│   ├── logs/
│   │   └── event_ledger.jsonl      # Immutable vault event append log
│   ├── ops/
│   │   └── applied.jsonl           # Idempotency log for archive operations
│   ├── candidates/                 # Agent-extracted entity candidates with lifecycle state
│   ├── collectible_collections.json # User-created collection shelf definitions
│   └── personal_libraries.json    # User-created personal library shelf definitions
├── .trash/                         # Isolated safety bin for deleted files; not a semantic tombstone
└── .akasha/                        # Application index cache (fully rebuildable — safe to delete)
    ├── spec/
    │   └── spec_v3.md              # Copy of this specification (Self-Describing Vault)
    ├── entity_path_index.json      # Maps entity_id to relative file paths
    ├── record_index.json           # Registry of all files, kinds, and titles
    ├── link_index.json             # Outgoing and incoming relation graph
    └── indexes/
        └── taste_index.json        # User preference/taste signal index
```

- **`{category}`** in `works/` MUST be a recognized `MediaCategory` (e.g., `manga`, `anime`, `novel`, `game`, `drama`, `movie`, `book`).
- **Hidden directories** (starting with `.`), except `.akasha` and `.trash`, MUST be ignored by conforming readers.
- All files under `.akasha/` are **derived and fully disposable**; the entire directory can be deleted and rebuilt by scanning all Markdown files and rerunning index services. No permanent data resides under `.akasha/`.
- The `system/` directory contains **permanent management data** that cannot be reconstructed from Markdown content. It MUST NOT be deleted.

---

## 2. Record Format & Frontmatter

Conforming files MUST be encoded in **UTF-8** Markdown.
Each record file MUST begin with a YAML frontmatter block demarcated by `---` lines.

### 2.1 Frontmatter Metadata Contract (v3)

Conforming v3 records MUST declare the following fields in their frontmatter:

| Field | Type | Required | Description |
|---|---|---|---|
| `schema_version` | Integer | **Yes** | Schema version of the record contract. MUST be `3`. |
| `record_id` | String | **Yes** | Globally unique identifier for this file, formatted as `rec_{prefix}_{8-char-base32}`. |
| `record_kind` | String | **Yes** | Enum: `workJournal`, `entityJournal`, `timelineEntry`, `freeformJournal`. |
| `entity_type` | String | **Yes*** | Upper-level ontology type: `work`, `person`, `event`, `place`, `concept`, `organization`, `object`. |
| `entity_id` | String | **Yes*** | Durable identifier of the represented entity. (e.g. `pe_u_xxxxxxxx`, `wk_u_xxxxxxxx`). |
| `title` | String | **Yes** | Display title. |
| `created_at` | String | **Yes** | ISO-8601 UTC timestamp of creation. |
| `updated_at` | String | **Yes** | ISO-8601 UTC timestamp of last update. |
| `source` | String | **Yes** | Creation channel of this Record. Enum: `user`, `app`, `agent`, `importTool`, `script`; it is not original authorship or full derivation provenance. |
| `added_at` | String | No | Legacy timestamp for backward compatibility (replaces `created_at` in v1/v2). |
| `occurred_at` | String | No | Semantic local (wall-clock) time the recorded event was experienced (`timelineEntry`). See §2.3. |
| `entity_subtype` | String | No | Namespace-prefixed folksonomy classification (e.g., `u:pet`, `u:camera`). |
| `aliases` | List<String>| No | Alternative names for link resolution. |
| `original_title` | String | No | Original language/native title. |
| `external_ids` | Map | No | Mapping of external database keys (e.g., `anilist: "123"`). |
| `evidence` | List<String>| No | Human-readable source citation strings. It does not declare exact input revision or derivation. |
| `links` | List<Map> | No | Structured outgoing relationship definitions. |
| `source_operation_id`| String| No | ID of the initial `ArchiveOperation` that generated this record; not a complete operation or transformation history. |

**\*** `entity_type` and `entity_id` are required for **entity-anchored kinds** (`workJournal`, `entityJournal`). For `timelineEntry` and `freeformJournal` they are optional: a freeform diary or a timeline moment may exist without pointing at any entity.

---

### 2.2 System Timestamp Constraint (UTC ISO-8601)

All system timestamps (`created_at`, `updated_at`) MUST strictly use the UTC representation ending in **`Z`** (e.g., `2026-07-06T12:00:00.000Z`).
This isolates the vault from local machine timezone drift and ensures consistent chronological parsing across different AI agents and systems. Fields anchored to human experience (`occurred_at`) follow §2.3 instead.

### 2.3 Semantic Local Time Constraint (`occurred_at`)

System timestamps record when a machine wrote a file; semantic local timestamps record when a **human experienced** something. The two follow different rules because a memory of "July 5th, 10 PM" must stay "July 5th, 10 PM" forever, even if the user later reads the archive in another timezone.

1. Semantic local timestamps MUST be written as **timezone-less ISO-8601 wall-clock strings** — no `Z` suffix, no UTC offset (e.g., `2026-07-05T22:30:00.000`).
2. Conforming readers MUST render the wall-clock digits **as written**, without timezone conversion.
3. Conforming readers MUST still accept legacy or foreign values carrying `Z`/offsets; writers normalize them to the local experienced wall-clock form on the next save, preserving the physical instant.
4. Semantic local timestamps order records within the user's experienced chronology. They are **not** exact physical instants; tools MUST NOT use them for cross-timezone physical ordering (use `created_at` for machine ordering).

---

## 3. Entity Anchor Types & ID Rules

Conforming vaults enforce stable ID prefixes to maintain ontological clarity:

| Entity Type | Prefix | ID Format | Example |
|---|---|---|---|
| **Work** | `wk` | `wk_{id}` or `wk_u_{8-char}` | `wk_00000123`, `wk_u_abc12345` |
| **Person** | `pe` | `pe_{id}` or `pe_u_{8-char}` | `pe_u_abc12345` |
| **Event** | `ev` | `ev_{id}` or `ev_u_{8-char}` | `ev_u_abc12345` |
| **Place** | `pl` | `pl_{id}` or `pl_u_{8-char}` | `pl_u_abc12345` |
| **Concept** | `co` | `co_{id}` or `co_u_{8-char}` | `co_u_abc12345` |
| **Organization**| `or` | `or_{id}` or `or_u_{8-char}` | `or_u_abc12345` |
| **Object** | `ob` | `ob_{id}` or `ob_u_{8-char}` | `ob_u_abc12345` |

- **`u_`** designates a **user-local entity** created within the vault. Non-prefixed IDs represent globally registry-synced entities.
- Conforming parsers MUST treat legacy custom ID prefix `cu_` as `ob` (Object) for backward compatibility.
- Unknown/unsupported prefixes MUST be parsed as `unknown` (returning the `unknown` EntityAnchorType) to prevent silent misclassification.

---

## 4. Link Grammar

Conforming readers MUST parse wiki-style links in the Markdown body to construct the relation graph:

- Format: `[[entity_id|Display Label]]` or `[[entity_id]]`
- Examples:
  - `[[pe_u_abc12345|John Doe]]` creates an outgoing link pointing to `pe_u_abc12345` with label "John Doe".
  - `[[wk_u_xyz98765]]` creates an outgoing link pointing to `wk_u_xyz98765`.

### 4.1 Relation Vocabulary

Structured frontmatter links (`links[].relation`) carry directed, Record-scoped
relation context. They are not independent Relationship Assertions: they do
not by themselves preserve a claimant, evidence revision, validity time,
conflict, or lifecycle. To keep the link vocabulary machine-reasonable over
decades, the relation string is controlled:

| Relation | Direction (source → target) |
|---|---|
| `related` | Generic association (default). |
| `about` | Source discusses/covers the target topic. |
| `appears_in` | Person/place/object appears in the target work. |
| `created_by` | Work/object was created by the target person/organization. |
| `part_of` | Source is a component of the target. |
| `member_of` | Person belongs to the target group/organization. |
| `located_in` | Source is physically located in the target place. |
| `inspired_by` | Source draws influence from the target. |

- In this table, **source** means the owning Record's context, not a global
  relationship fact. The explicit subject of a future Relationship Assertion
  may be different and must be stored independently.
- User-defined relations MUST use the **`u:` namespace** with token format `u:[a-z0-9_]{1,40}` (e.g., `u:voiced_by`). This prevents collisions with future core vocabulary.
- Conforming writers MUST NOT emit new relations outside the core vocabulary or the `u:` namespace.
- Conforming readers MUST preserve unrecognized legacy relation strings as-is (Additive-Only Evolution, §5).
- The core vocabulary grows only through spec revisions.

---

## 5. Evolution Rules

To guarantee **Eternity**, the AKASHA Vault format evolves only under **Additive-Only Evolution Rules**:
1. Conforming tools MUST NOT delete deprecated schema fields; they must read them as fallbacks.
2. New fields added in newer versions of the specification MUST be optional.
3. If an incompatible structural change is required, the `schema_version` number MUST be incremented, and conforming applications MUST provide automatic upgrade tools to convert older vaults.

---

## 6. Binary Assets

Binary files (`posters/`, image attachments) live outside the plain-text eternity guarantee of Markdown records. To minimize long-term risk:

1. Writers SHOULD store images in widely standardized, patent-unencumbered formats with decades of tooling support (**PNG**, **JPEG**). Proprietary or short-lived formats put the asset's future readability at risk.
2. Records MUST reference assets by **vault-relative paths** (e.g., `posters/example.png`) so the vault remains relocatable as a single folder.
3. A missing or renamed asset MUST NOT invalidate the referencing record; conforming readers degrade gracefully by rendering the record without the asset.
4. Binary assets are user-owned content. Conforming tools MUST NOT rewrite, recompress, or deduplicate them without explicit user action.
