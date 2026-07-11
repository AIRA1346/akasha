# AI Archive Write Gateway ADR

> **Status:** Accepted architecture decision — contract and cases only; no product model, serializer, migration, transport, or AI service is introduced by this ADR.  
> **Date:** 2026-07-11  
> **Scope:** External AI, scripts, and tools writing to a user-owned AKASHA Vault.  
> **Related:** [VISION.md](VISION.md), [P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md](P1_A_CORE_ARCHIVE_ONTOLOGY_CASES.md), [P0_RECOVERABLE_VAULT_WRITE_GATE.md](P0_RECOVERABLE_VAULT_WRITE_GATE.md), [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md), [AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md](AGENT_ENTITY_CREATION_AND_SCALE_ARCHITECTURE.md)
> **Cases:** [AI_ARCHIVE_WRITE_GATEWAY_CASES.md](AI_ARCHIVE_WRITE_GATEWAY_CASES.md)

## 1. Decision

AKASHA is not an AI service, agent host, chat companion, or automation
orchestrator. It is the user's durable archive substrate.

The normal write path for an external AI is therefore **not** direct filesystem
mutation and is **not** an "AI Markdown import" feature.

```text
external AI / tool
  → structured archive intent
  → AKASHA Write Gateway
  → authorization · validation · duplicate/conflict decision
  → recoverable Vault write · bounded index update · durable receipt
  → user-owned canonical Vault
```

The Gateway accepts two deliberately distinct outcomes:

1. **Candidate creation** — the AI proposes a possible Entity, Record, or
   Relationship Assertion without changing canonical archive records.
2. **Authorized application** — an AI applies a declared archive operation only
   within permission the user has granted to that AI/tool.

This decision supersedes the *recommended agent write path* in
`AGENT_VAULT_PROTOCOL_V1.md` and `VAULT_AGENT_GUIDE.md`. Their direct-file
rules remain useful as an external-editor compatibility contract; they are not
the interface AKASHA should ask an AI to use.

## 2. Why direct raw file writes are not the default

The Vault is user-owned and must remain open to any editor. A user may still
give an external AI ordinary folder-write permission. AKASHA must observe that
as an external change, preserve the file, and reconcile/reindex it when
possible.

That is different from an AKASHA-authorized AI operation:

| Path | What it means | Guarantee |
| --- | --- | --- |
| Raw external file write | An editor/tool changes a `.md` file itself. | The app can observe and parse it, but cannot prove authority, input revision, intent, or provenance completeness. |
| Gateway candidate | An AI proposes something to the archive. | No canonical Record changes. Candidate lifecycle and evidence remain available for review. |
| Gateway authorized application | An AI asks AKASHA to perform a bounded operation. | Permission, stable-ID target resolution, revision check, recoverable write, provenance receipt, and index handling are enforced by AKASHA. |

Raw file access must never be silently represented to the user as a successful
Gateway operation. Conversely, the Gateway must never require users to stop
owning or editing their Vault directly.

## 3. Authority belongs to the user

AKASHA does not decide whether an AI should be trusted. The user grants a scope
to a specific external actor, for a task, session, or durable integration.

The required semantic scopes are:

| Scope | Effect | Default outcome |
| --- | --- | --- |
| `candidate.create` | Create a non-canonical proposal. | Allowed only when the user enables candidate intake. |
| `record.create` | Create a new canonical Record. | Requires explicit authorization. |
| `record.derive` | Create a separate AI-derived Record from declared inputs. | Requires explicit authorization; never mutates the input Record. |
| `record.append` | Add a declared section to one existing Record. | Requires target and expected revision. |
| `record.patch` | Change an allowed field/section of one existing Record. | Requires a narrower explicit grant and expected revision. |
| `candidate.promote` | Turn a candidate into an archived record. | User/app action by default; may be delegated explicitly later. |

These are permission semantics, not a decision to implement a particular
settings model, account system, MCP server, SDK, or HTTP API. Those choices are
deferred.

## 4. Record semantics

### 4.1 AI interpretation is a separate Record

When an AI summarizes, interprets, classifies, compares, or infers meaning from
one or more user/external records, its durable result is a **new derived
Record**. It does not rewrite the original merely because it was based on it.

The derived Record must retain, at minimum:

- the input Record IDs;
- the input revisions actually read;
- the actor/tool identity supplied by the caller;
- the operation ID;
- evidence references or an explicit statement that the result is an
  interpretation;
- creation time and source category.

`derived_from` and the exact provenance extension namespace are intentionally
not introduced here. P1's ontology decision remains valid: this must be an
additive contract, not an overloaded wiki link or a destructive rewrite of the
existing v3 schema.

### 4.2 Existing-record changes are explicit

An AI may append or patch an existing Record only when all of the following are
present:

1. a user grant covers that operation and target scope;
2. the operation addresses the Record by stable ID, never by a raw path alone;
3. it supplies the revision it read;
4. the requested change fits the allowed operation vocabulary;
5. AKASHA can preserve unknown data and recover a normal old/new copy through
   the P0 write protocol.

If the revision changed, AKASHA preserves the proposed result as conflict
evidence and returns a conflict. It never silently retries against new user
content or decides a merge on the user's behalf.

## 5. Gateway operation envelope

The existing `ArchiveOperation` is the starting point, not a completed Gateway.
It already has an operation ID, source, actor, target entity/record,
`expectedRevision`, and payload validation. Its executor currently applies only
`promoteCandidate`.

Before general AI application is enabled, an operation envelope must also carry
or resolve:

- the authority grant or one-shot user approval that authorized it;
- stable target Record ID(s), not storage paths;
- declared input Record IDs and revisions for derived work;
- evidence references;
- the requested operation vocabulary and bounded payload;
- an actor descriptor that identifies the external tool/agent without assuming
  AKASHA owns that agent.

The Gateway resolves paths internally, stamps app-owned timestamps/provenance,
uses the common recoverable writer, and emits exact Vault change information for
bounded derived-index updates. Callers must not set runtime paths, indexes,
`created_at`, `updated_at`, `source`, or `source_operation_id` themselves.

## 6. Durable receipts and idempotency

`system/ops/applied.jsonl` already records successful operation IDs and gives
the first idempotency guard. It is valuable but incomplete for the Gateway:
the current applied entry does not retain actor identity or input revisions.

The completed Gateway needs a durable receipt policy with these properties:

- one operation ID can apply at most once;
- a successful receipt identifies the affected canonical Record(s), actor,
  source category, input revisions, and resulting revision(s);
- a rejected/conflicted operation is not recorded as applied;
- its proposed content remains recoverable conflict evidence where P0 requires
  it, without being confused with a canonical Record;
- receipts live under user-owned `system/`, never under rebuildable `.akasha/`.

The exact receipt schema is deferred until the provenance ADR and extension
namespace ADR. It must be additive and must not make an operation log the only
copy of a user's memory.

## 7. Candidate boundary

Candidates are not lesser or disposable AI thoughts. They are non-canonical
operational proposals that prevent high-volume extraction from polluting the
archive before the user finds value in it.

Current foundation:

- `ArchiveCandidateStore` persists candidates under `system/candidates/`;
- candidates have `candidate`, `promoted`, `dismissed`, and `merged` states;
- `ArchiveOperationExecutor.promoteCandidate` is the only currently executable
  structured operation;
- candidate evidence is carried into the promoted Entity journal.

Missing before this becomes a real external-AI workflow:

- a user-facing candidate review/promote surface;
- a Gateway intake contract for candidate creation;
- actor and input-revision provenance on candidates;
- batch limits, duplicate-review policy, and scoped authorization.

## 8. AI Markdown is not an AI integration

The current clipboard flow parses pasted Markdown and stores a Work through the
normal Vault writer. It is a temporary manual import route, not an AI Gateway:

- it has no actor grant;
- it does not automatically distinguish agent provenance from generic import;
- it does not declare input revisions or derived provenance;
- it cannot express candidate versus authorized application semantics.

The product-facing **"AI Markdown import"** label, prompt-template UX, and
AI-specific flow are deprecated. They must be removed when the Gateway has a
minimum candidate/application intake path. A generic user-controlled external
Markdown import may remain as a separate compatibility/import feature.

## 9. Current state and implementation gate

| Capability | Current state | Gateway requirement |
| --- | --- | --- |
| Recoverable single/multi-file writes | Implemented by P0 | Reuse; no alternate AI writer. |
| Unknown YAML preservation | Implemented for app writes | Reuse for all Gateway writes. |
| Candidate store | Implemented | Add intake/review authority and provenance. |
| Operation validation | Implemented | Extend only after contract decisions. |
| Operation execution | `promoteCandidate` only | Add operations one at a time with fault/conflict tests. |
| AI authorization | Not implemented | Required before any direct application. |
| Derived provenance (`derived_from`) | Not implemented | Required before AI interpretation is persisted. |
| Generic AI transport | Not implemented | Deliberately deferred; external AI choice remains outside AKASHA. |

No generic `create_record`, `append_section`, or `update_frontmatter` executor
may be enabled until the following gate passes:

1. authority scope and explicit user approval semantics are fixed;
2. record-target revision reads are exposed without whole-Vault scanning;
3. receipt/provenance requirements are fixed additively;
4. each operation uses the shared P0 writer and preserves conflict evidence;
5. candidate, direct-create, derived-record, stale-revision, duplicate, and
   restart/fault cases have fixtures and tests;
6. the old AI Markdown product surface has a safe removal/migration plan.

## 10. Alternatives rejected

| Alternative | Decision | Reason |
| --- | --- | --- |
| AKASHA hosts its own AI/chat service | Rejected | AKASHA is the archive substrate, not the AI provider. |
| AI edits Vault files directly as the normal API | Rejected | It bypasses authority, input-revision, receipt, and app-owned write guarantees. |
| Candidate-only AI forever | Rejected | A user may intentionally authorize direct, bounded archive work. |
| AI interpretations overwrite source Records | Rejected | It destroys the distinction between an original record and a later interpretation. |
| AI Markdown paste as the integration contract | Rejected | It conflates transport text with authority, provenance, and archive semantics. |

## 11. Deferred decisions

This ADR intentionally does **not** decide:

- the physical schema/name for `derived_from` and full provenance extensions;
- permission storage, revocation, grant duration, or approval UI;
- MCP, CLI, local socket, file drop, SDK, or HTTP as the external transport;
- batch application limits and transaction grouping;
- the canonical Record kind/storage layout for derived analyses;
- Relationship Assertion serialization and lifecycle;
- sharing, collaboration, or any cloud service.

The follow-up ADR order is fixed:

1. provenance and derived-input contract;
2. relation tiers and Relationship Assertion contract;
3. lifecycle/tombstone/supersede contract;
4. extension namespace;
5. Gateway permission and receipt contract;
6. first candidate/application implementation slice.
