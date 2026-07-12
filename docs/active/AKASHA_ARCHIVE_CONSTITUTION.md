# AKASHA Archive Constitution

> **지위:** **Supreme SSOT** — 장기 원칙·아키텍처 거부 기준 (모든 제품·로드맵·구현 결정의 최상위)
> **한 문장:** AKASHA는 사용자가 소유한 개인 아카이브 프로토콜이다. 앱·Markdown·SQLite·AI는 인터페이스·현재 원본·탐색 계층·미래 활용자일 뿐, 본질이 아니다.
> **Status:** Supreme product and architecture constitution
> **Authority:** User-authored vision, consolidated on 2026-07-12 · §7 product
> decisions recorded 2026-07-12
> **Scope:** This document defines why AKASHA exists and the principles that
> decide future architecture. It does not introduce a schema, serializer,
> migration, AI service, or storage implementation.
> **Supersedes:** [PROJECT_CONSTITUTION.md](PROJECT_CONSTITUTION.md) (historical stub → [history](../history/PROJECT_CONSTITUTION.md))
> **Related:** [VISION.md](VISION.md) (v1 product scope),
> [CURRENT_STATE.md](CURRENT_STATE.md) (implementation reality),
> [docs README](../README.md) (document index),
> [INFINITE_ARCHIVE_HARDENING_PLAN.md](INFINITE_ARCHIVE_HARDENING_PLAN.md),
> [P0 Recoverable Vault Write Gate](P0_RECOVERABLE_VAULT_WRITE_GATE.md),
> [Provenance and Derived Input ADR](PROVENANCE_AND_DERIVED_INPUT_ADR.md)

## 1. Definition

**AKASHA is a user-owned personal archive protocol.**

It preserves a person's records, experiences, tastes, relationships, changing
thoughts, sources, and deliberately retained traces over a lifetime, so that
future people, tools, and AI can read, verify, interpret, and use them without
owning them.

The application is AKASHA's first interface. Markdown is the current durable
source format. SQLite and other indexes are current query mechanisms. AI is a
future reader or assistant. None of these is AKASHA's essence.

> The purpose is to let a person's records and their meaning remain alive,
> user-owned, and intelligible as technologies change.

## 2. The problem AKASHA answers

AKASHA is not a note-volume tool, a review service, a personal wiki, or an AI
chat product. It answers this question:

> How can one person's lifetime of memories, records, experiences, tastes,
> relationships, and changing thought remain usable decades later without
> losing ownership, provenance, or meaning?

Works are the first proving domain. The archive must eventually be able to
preserve people, events, concepts, journals, ideas, Timeline entries,
relationships, and media under the same preservation principles, without
forcing those domains to have the same semantics.

## 3. Non-negotiable principles

### 3.1 User ownership before platform ownership

- The user owns the canonical archive and can inspect, copy, back up, move,
  and export it.
- No AI provider, AKASHA cloud service, or application database is the sole
  keeper of the user's memory.
- GPT, Gemini, Claude, local models, scripts, and future tools are replaceable
  readers or assistants. AKASHA is not an AI host, agent supervisor, or chat
  service.
- Privacy is private-by-default and user-controlled. Future sharing must be an
  explicit user decision: the user may share an original, or create a separate
  shared representation, without making the private Vault public by default.

### 3.2 Original, import, and derivation must remain distinguishable

User writing, imported material, and an AI/tool-derived interpretation are all
valuable archival objects. AKASHA must not rank them by worth, but it must
preserve what each one is and where it came from.

- An AI interpretation never silently overwrites its input.
- An imported source is not relabelled as the user's expression.
- A user note remains readable as the user's note even after later AI use.
- A future reader can determine the declared input, source, actor, evidence,
  and transformation when those facts are known.

### 3.3 Preserve meaning, not only the newest result

A later rating, opinion, correction, or interpretation must not make an
earlier meaningful state disappear merely because the current view changed.
What matters can include why a person thought something, when it changed, and
the intervening context—not just the newest rating or summary.

This is a semantic-history requirement. P0 recovery backups protect against
loss or interrupted writes; they are **not by themselves** the user-facing,
long-term representation of changing thought. The product boundary for which
edits enter recoverable semantic history versus in-place Document edits is
decided in §7.1. Promotion of a preserved revision into an independent
historical Record or Timeline event is never automatic (§7.1).

### 3.4 Durable source and disposable query layers stay separate

The canonical Vault is a durable source layer. Query stores are derived
navigation layers.

| Layer | Responsibility | Required property |
| --- | --- | --- |
| User-owned Vault | Human-readable Documents, user files, and durable meaning. | Portable, inspectable, losslessly evolvable, never replaced by an index. |
| Derived query layer | SQLite projections, title/tag/link/snippet indexes, caches. | Rebuildable from the Vault, replaceable as technology changes, honest when stale or damaged. |
| Tool/AI integration | Narrow, user-authorized reads and writes. | Cannot silently become the owner, canonical store, or uncontrolled collector. |

The derived layer exists so millions of records remain usable through pages,
cursors, filters, and selected canonical hydration. It is a table of contents,
not a second personal archive.

### 3.5 Format is subordinate to preservation

Markdown is currently chosen for human readability, portability, ecosystem
compatibility, and long-lived accessibility. AKASHA is not committed to
Markdown at the expense of its purpose.

Any format evolution must demonstrate:

1. user ownership and direct inspectability;
2. a meaningful human-readable or user-accessible representation;
3. lossless, reversible, and verifiable migration or coexistence; and
4. preservation of data AKASHA does not yet understand.

No storage technology, database, or file format may be adopted simply because
it is fashionable or convenient for the current application.

### 3.6 Meaningful domains must not be flattened

AKASHA shares a thin preservation envelope where it is truly common—stable
identity, provenance, recovery, unknown-data preservation, source revisions,
and additive extensions. It does not force every domain into one giant model.

- A Work carries rating, status, and personal response.
- A Timeline entry carries the time an experience occurred.
- A Journal is freeform personal expression.
- An Entity is a persistent subject that Records may concern.
- A Canvas is a composite spatial Document; its edges are presentation by
  default.
- A Relationship Assertion is a separate, explicit claim only when someone
  needs its evidence, claimant, time, and lifecycle to stand independently.

Common infrastructure must preserve these distinctions rather than erase them.

## 4. Architectural consequences

### 4.1 Stable identity has different roles

An Entity/Work ID names *what something is*. A physical Record ID names *one
archival Document or independently preserved record*. A path names only where
the file currently lives.

One current Work Markdown file may carry both a Work ID and a Record ID without
forcing the user to split their thoughts into separate files. This gives the
same Document an Entity role and a Record role today, while retaining a safe
way to preserve future independent imports, user reflections, and derivations
about the same Work.

These identifiers are infrastructure, not a user-facing filing burden.

### 4.2 Trust requires recoverability and visible uncertainty

AKASHA must never quietly discard data, overwrite an external change, pretend
an incomplete cache is canonical, or convert an unreadable source into an
invisible absence. It must preserve recoverable originals, conflict evidence,
unknown fields, and explicit repair/error states.

### 4.3 Scale must not weaken ownership

Large archives require cursor-paged projections, selected-source hydration,
incremental updates, and explicit rebuild/repair states. They do **not**
require replacing the Vault with an opaque database.

The existing Work projection measurement demonstrates that a local derived
query layer can serve synthetic million-record-scale summaries quickly, while
full rebuild remains an explicit construction or repair action rather than a
normal interaction path. Every additional high-cardinality domain must earn
its own bounded projection contract before implementation.

### 4.4 Capture is not surveillance

AKASHA archives what a user or an authorized tool chooses to preserve. It does
not become a hidden observer of AI conversations, applications, or private
activity. Any future behavioral trace must have a clear capture policy,
ownership, visibility, export, deletion, and disablement rule.

## 5. Current architectural phase

### Completed foundation: records are not quietly lost

P0 establishes recoverable writes, conflict preservation, unknown-YAML
survival, and recoverable multi-file Documents. Its permanent contract is:

> AKASHA does not quietly lose the records entrusted to it.

### Current foundation: large archives remain usable

The next phase makes the Vault usable at scale without confusing a cache for
memory:

- changed files should not require reading the whole Vault;
- list views should consume summaries rather than complete Markdown bodies;
- opening or editing should hydrate one canonical source only;
- millions of records should remain pageable and queryable; and
- stale, damaged, or incomplete derived data must be visible as such.

The next planned scale gate is the Timeline projection contract and
measurement. It is not a Universal Record migration.

## 6. Deferred implementation, already constrained by principle

The following may become necessary, but must not be implemented merely because
they are architecturally interesting:

- durable provenance and AI-derived Records;
- independent Relationship Assertions;
- lifecycle, retraction, supersession, merge, tombstone, and redaction;
- selected behavioral evidence (subject to §7.2);
- additional AI/tool transports and permissions; and
- sharing and comparison between users.

When needed, they must be additive, user-owned, provenance-aware, recoverable,
and compatible with unknown-data preservation. No Universal Record migration
is justified until a concrete domain need proves that it is safer than separate
bounded contracts.

## 7. Product decisions (resolved 2026-07-12)

These decisions constrain future schema, UI, and tool contracts. Physical
storage formats remain separate ADRs; the principles below must not be
weakened by convenience.

### 7.1 Semantic-history boundary

**Meaning-preserving edits stay on the same Document.** Typo fixes, spelling,
punctuation, and wording cleanups that do not change the user's judgment are
in-place edits of the current Document.

**Meaning-changing updates must not silently erase the prior meaning.** When
rating, status, or a core judgment/reflection substantially changes, the earlier
meaningful state is preserved automatically in a **recoverable semantic
history** so it cannot disappear merely because the current view moved on.

**Recoverable history is not automatic first-class Record promotion.** Every
preserved revision does **not** become an independent archival Record or
Timeline event by default. Elevation to a standalone historical Record or
Timeline entry happens only by:

- explicit user choice;
- a user-defined archive policy; or
- a tool proposal that the user has approved.

Until a bounded history contract ships, writers must not invent silent
surveillance-style revision graphs that users cannot inspect, export, or
disable. P0 recovery remains the floor against write loss; §7.1 is the floor
against silent loss of prior *meaning*.

### 7.2 Behavioral-trace policy

**Minimal local aggregates may be collected by default.** Counts and
summaries that aid later interpretation—such as reopen count, last-viewed
time, and edit count—may be retained locally without leaving the user's
machine.

**User control is mandatory.** The user must be able to inspect, delete,
export, and disable these aggregates. They must not be transmitted externally
by default.

**Raw behavioral logs are not permanent by default.** Click streams, full
view-time sequences, and similar raw activity detail are not kept as durable
archive data unless the user explicitly consents or an approved user policy
allows it.

**Promotion of behavior into Records is gated.** Detailed behavioral history,
or turning behavioral evidence into a first-class Record, requires explicit
consent or an approved user policy—never silent elevation.

Capture remains archival choice, not surveillance (§4.4).

## 8. Decision test for every future feature

Before accepting a feature, implementation, migration, or external integration,
ask:

1. Does it make a user's archive more durable, understandable, usable, or
   portable over time?
2. Does it preserve user ownership and keep AI/tool providers replaceable?
3. Does it preserve the distinction between original, import, and derivation?
4. Does it retain each domain's real meaning instead of flattening it?
5. Can it grow without making a disposable index the source of truth?
6. Can the user inspect, export, delete, or disable it in a truthful way?

If the answer is no, the feature does not belong in AKASHA's core merely
because it is technically possible.
