# Provenance and Derived-Input Cases

> **Status:** Semantic regression fixtures for
> [PROVENANCE_AND_DERIVED_INPUT_ADR.md](PROVENANCE_AND_DERIVED_INPUT_ADR.md).
> They are not API payloads, models, serializers, fixtures for product tests,
> or migration instructions.

## Case 1 — A user writes a Journal

The user creates a Journal Record about a concert.

| Fact | Required interpretation |
| --- | --- |
| `source: user` | The Record first entered AKASHA through the user. |
| `occurred_at` | It may preserve when the concert was experienced. |
| No derivation declaration | No previous Record or tool transformation is implied. |

The future system must not invent an AI actor, input record, or hidden prompt
because a later tool reads this Journal.

## Case 2 — An external review is imported, then the user responds

An importer brings a critic's review into the Vault. The user subsequently
writes a separate response Record.

| Record | Required provenance |
| --- | --- |
| Imported review | `source: importTool` for the Vault entry channel; original author/source citation and captured Artifact or external locator when known. |
| User response | A separate user-created Record. It may cite or link to the review, but is not automatically a derived Record. |

`importTool` never becomes a claim that the importer authored the review, and
the user's response never alters the imported source.

## Case 3 — An AI summarizes two stable input revisions

Inputs at the moment of the request:

```text
jr_2026_07_11_night   SHA-256 A, byte length A1
tl_2026_07_10_concert SHA-256 B, byte length B1
```

The user authorizes an AI to create a concise summary.

Required result:

- a new derived Record, never a rewrite of either input;
- both stable Record IDs plus the SHA-256 and byte length actually read;
- a declared `summary` transformation class;
- declared external actor descriptor, operation ID, and evidence references;
- a receipt with resulting output revision after a P0 recoverable write.

The output can remain useful after a source file moves because its stable input
ID and exact content revision do not depend on the old path.

## Case 4 — An input changes while an AI is working

The AI reads `jr_2026_07_11_night` at SHA-256 A. The user edits it to SHA-256
C before the AI requests application.

Expected result:

- AKASHA detects that the declared input revision is stale;
- it does not create a derived Record falsely labelled as based on C;
- it returns a conflict or preserves a non-canonical proposal according to the
  Gateway decision;
- the original and user edit remain untouched.

The AI can reread with fresh user authorization and submit a new operation.

## Case 5 — Interpretation is not a fact mutation

From several Journals, an AI proposes: “The user may prefer quiet nighttime
performances.”

| Property | Required result |
| --- | --- |
| Output kind | Separate derived Record. |
| Transformation | `interpretation`, explicitly labelled. |
| Inputs | Stable IDs and exact revisions of the journals read. |
| Original Journals | Unchanged. |
| Future disagreement | A user or another tool may create a different interpretation without deleting this one. |

No implementation may convert this sentence directly into an immutable user
preference field or silently treat it as a fact about the user.

## Case 6 — An external page was read but not captured

An external tool proposes a derived Record based partly on a web page that the
user did not save into the Vault.

Required result:

- the page is recorded only as an external citation/origin with retrieval
  context where the user allows it;
- AKASHA does not claim an exact local input revision or reproducibility it
  does not have;
- if durable exact provenance is necessary, the user/tool first archives the
  permitted source as an Artifact or Record and references its digest.

This avoids pretending that a URL alone is permanent source material.

## Case 7 — Identical words from different transformations coexist

Two external tools independently create the same one-line summary from the
same Record revisions.

Required result:

- their outputs remain distinct Records until the user explicitly decides
  otherwise;
- each preserves its own actor and operation provenance;
- textual equality may support a later duplicate suggestion, but cannot erase
  authorship, actor, or derivation history.

## Case 8 — A legacy Record has incomplete provenance

An old v3 Record has `source: agent`, an `evidence` string, and a wiki link,
but no actor descriptor or input revision.

Required result:

- the existing fields are preserved exactly;
- readers show the missing information as unknown/not declared;
- migration does not infer the actor, exact source content, transformation, or
  revision from surrounding data;
- a future user may add a new, explicit provenance declaration only with
  truthful information and P0 lossless preservation.

## Case 9 — Direct folder write remains honest

The user grants an AI ordinary filesystem access and it edits a Markdown file
outside the AKASHA Gateway.

Required result:

- the user-owned file remains preserved and may be reindexed as an external
  change;
- AKASHA does not fabricate a Gateway receipt, actor descriptor, input list,
  or exact derivation claim;
- malformed or conflicting content follows P0 quarantine/conflict behavior.

User ownership is preserved without treating an unobserved external edit as a
validated archival operation.
