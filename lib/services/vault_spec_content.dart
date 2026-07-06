/// Template for `spec_v3.md` to be packaged in every vault under `.akasha/spec/spec_v3.md`.
abstract final class VaultSpecContent {
  static const String content = '''# AKASHA Vault Format Specification (v3)

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
├── .trash/                         # Isolated safety bin for deleted files
└── .akasha/                        # Application index directory (fully regeneratable)
    ├── spec/
    │   └── spec_v3.md              # Copy of this specification (Self-Describing Vault)
    ├── entity_path_index.json      # Maps entity_id to relative file paths
    ├── record_index.json           # Registry of all files, kinds, and titles
    ├── link_index.json             # Outgoing and incoming relation graph
    └── event_ledger.jsonl          # Immutable record operation append log
```

- **`{category}`** in `works/` MUST be a recognized `MediaCategory` (e.g., `manga`, `anime`, `novel`, `game`, `drama`, `movie`, `book`).
- **Hidden directories** (starting with `.`), except `.akasha` and `.trash`, MUST be ignored by conforming readers.
- All files under `.akasha/` are derived and disposable; they can be deleted and rebuilt by scanning all Markdown files in the vault.

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
| `entity_type` | String | **Yes** | Upper-level ontology type: `work`, `person`, `event`, `place`, `concept`, `organization`, `object`. |
| `entity_id` | String | **Yes** | Durable identifier of the represented entity. (e.g. `pe_u_xxxxxxxx`, `wk_u_xxxxxxxx`). |
| `title` | String | **Yes** | Display title. |
| `created_at` | String | **Yes** | ISO-8601 UTC timestamp of creation. |
| `updated_at` | String | **Yes** | ISO-8601 UTC timestamp of last update. |
| `source` | String | **Yes** | Provenance of the write. Enum: `user`, `app`, `agent`, `importTool`, `script`. |
| `added_at` | String | No | Legacy timestamp for backward compatibility (replaces `created_at` in v1/v2). |
| `entity_subtype` | String | No | Namespace-prefixed folksonomy classification (e.g., `u:pet`, `u:camera`). |
| `aliases` | List<String>| No | Alternative names for link resolution. |
| `original_title` | String | No | Original language/native title. |
| `external_ids` | Map | No | Mapping of external database keys (e.g., `anilist: "123"`). |
| `evidence` | List<String>| No | Source citation strings for agent-originated writes. |
| `links` | List<Map> | No | Structured outgoing relationship definitions. |
| `source_operation_id`| String| No | ID of the `ArchiveOperation` that generated this record. |

---

### 2.2 System Timestamp Constraint (UTC ISO-8601)

All timestamps (`created_at`, `updated_at`, `occurred_at`) MUST strictly use the UTC representation ending in **`Z`** (e.g., `2026-07-06T12:00:00.000Z`).
This isolates the vault from local machine timezone drift and ensures consistent chronological parsing across different AI agents and systems.

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
- Unknown/unsupported prefixes MUST be parsed as `unknown` to prevent silent misclassification.

---

## 4. Link Grammar

Conforming readers MUST parse wiki-style links in the Markdown body to construct the relation graph:

- Format: `[[entity_id|Display Label]]` or `[[entity_id]]`
- Examples:
  - `[[pe_u_abc12345|John Doe]]` creates an outgoing link pointing to `pe_u_abc12345` with label "John Doe".
  - `[[wk_u_xyz98765]]` creates an outgoing link pointing to `wk_u_xyz98765`.

---

## 5. Evolution Rules

To guarantee **Eternity**, the AKASHA Vault format evolves only under **Additive-Only Evolution Rules**:
1. Conforming tools MUST NOT delete deprecated schema fields; they must read them as fallbacks.
2. New fields added in newer versions of the specification MUST be optional.
3. If an incompatible structural change is required, the `schema_version` number MUST be incremented, and conforming applications MUST provide automatic upgrade tools to convert older vaults.
''';
}
