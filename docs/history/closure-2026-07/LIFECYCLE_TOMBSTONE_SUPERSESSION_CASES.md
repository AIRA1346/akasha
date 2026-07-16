# Lifecycle, Tombstone, and Supersession Cases

> **Status:** Semantic regression fixtures for
> [LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md](../../active/LIFECYCLE_TOMBSTONE_SUPERSESSION_ADR.md).
> They are not product models, serializers, migrations, retention policy, or
> secure-erasure instructions.

## Case 1 — Moving a Record to `.trash` is reversible storage safety

The user deletes a Work file through the current application UI. AKASHA writes
a trash manifest and moves the Markdown file to `.trash`.

Required result:

- the file is absent from ordinary Vault scans and is available for restore;
- no Record/Entity tombstone, retraction, supersession, or merge is inferred;
- restoring the file restores physical availability only;
- if the user had separately retracted a Relationship Assertion about the Work,
  restore does not undo that assertion transition.

## Case 2 — Permanent purge does not force a tombstone

The user permanently removes a sensitive Journal and explicitly does not want a
durable identifier or reason left behind.

Required result:

- AKASHA does not manufacture a tombstone, source record, or lifecycle reason;
- a future purge flow discloses related trash/recovery/draft/export copies
  instead of claiming that deleting one path securely erased every copy;
- other Records that once linked to it may become unresolved references, but
  AKASHA does not rewrite them silently.

## Case 3 — A corrected AI interpretation supersedes an older one

An AI-derived summary `rec_summary_a` was based on Journal revisions A and B.
Later, the user authorizes a new summary `rec_summary_b` from revisions C and
D and decides the newer summary should be preferred.

Required result:

- both summaries remain separate Records with their own input provenance;
- an explicit lifecycle transition states `rec_summary_a → rec_summary_b` for
  the stated summary purpose;
- creating `rec_summary_b` alone would not have superseded `rec_summary_a`;
- the old summary is not overwritten or physically deleted.

## Case 4 — A later diary entry is not a supersession

The user writes a new Journal entry that changes their mind about a film.

Required result:

- both Journals remain current historical Records by default;
- the later entry may link to or discuss the earlier entry;
- no supersession is inferred merely because the opinions conflict;
- the user may explicitly retract a prior claim if that is what they mean.

## Case 5 — A Relationship Assertion is retracted without deleting evidence

The user once preserved "Person P `created_by` Work W" as a Relationship
Assertion, then discovers the credited source was unreliable.

Required result:

- the assertion is explicitly retracted with claimant, reason/evidence, and
  transition time;
- the source Record and original assertion remain inspectable unless separately
  redacted or purged;
- a Canvas view and its edge do not disappear automatically;
- another assertion with better evidence may coexist or later supersede it.

## Case 6 — Candidate dismissal is not Record retraction

An AI proposes a Person candidate from a Work Journal. The user dismisses it.

Required result:

- the candidate enters its existing `dismissed` proposal state;
- the source Journal is unchanged and not retracted;
- no Entity/Record tombstone is created because no canonical Entity was made;
- a later user/tool may create a new candidate with fresh evidence.

## Case 7 — Duplicate suggestion is not a merge

Two imported Records have similar titles and text. A detector suggests that they
may be duplicates.

Required result:

- AKASHA keeps both Records current and separate;
- the suggestion may be stored as non-canonical review information;
- only an explicit merge transition can name a surviving canonical target;
- a textual match never authorizes data loss or rewrites linked records.

## Case 8 — A Canvas edge can be deleted freely

The user removes a `canvas_only` `u:rival_of` edge to declutter a Canvas.

Required result:

- the layout changes and no semantic lifecycle transition occurs;
- if a separate Tier 3 Relationship Assertion exists, it remains untouched;
- a UI may later show its status, but Canvas is never the lifecycle owner.

## Case 9 — External deletion is not an authorized tombstone

An external editor or AI with raw folder access removes a Markdown file.

Required result:

- AKASHA observes a missing external file and may surface it as unavailable;
- it does not fabricate an actor, semantic deletion, tombstone, retraction, or
  purge receipt;
- recovery, restore, or explicit user lifecycle action remains possible under
  the user's control.

## Case 10 — Legacy records remain lifecycle-unknown

An old record has a changed title, a newer `updated_at`, and no lifecycle
extension.

Required result:

- it remains current/unknown lifecycle state;
- no supersession or merge is inferred from title, path, or timestamp changes;
- a future explicit transition may cite it using its stable ID;
- unknown legacy YAML survives the future extension save path.

## Case 11 — Tombstone is a deliberate locator

In a future shared/imported workflow, the user removes an obsolete public
identifier but wants future imports to know that it was intentionally retired.

Required result:

- the user explicitly chooses a minimal tombstone and sees the retained ID,
  status, and reason before it is written;
- the original content is not copied into the tombstone by default;
- a reader can distinguish intentional retirement from a missing/corrupt file;
- this case does not weaken the user's separate option of full local removal
  with no tombstone.
