# Relation Tiers and Relationship Assertion Cases

> **Status:** Semantic regression fixtures for
> [RELATION_TIERS_AND_ASSERTIONS_ADR.md](RELATION_TIERS_AND_ASSERTIONS_ADR.md).
> They are not product models, serializers, migrations, graph data, or API
> payloads.

## Case 1 — A Journal wiki link is a reference

A Journal says, "After watching `[[wk_u_a|A]]`, I was reminded of
`[[wk_u_b|B]]`."

Required result:

- both links are Tier 1 references for navigation/backlinks;
- the Journal remains the Record that supplies their context;
- no `inspired_by`, similarity, sequel, or other global relationship assertion
  is created;
- an AI may use the Journal as evidence only if the user later asks it to
  propose a specific claim.

## Case 2 — A structured link is still Record-scoped

A Work Record contains:

```yaml
links:
  - relation: "created_by"
    target_id: "pe_u_creator01"
    label: "credited creator"
```

Required result:

- this is a Tier 2 structured link owned by the Work Record;
- it can improve targeted discovery and display for that Record;
- it is not automatically an assertion that survives as a separately
  adjudicable fact if the link is removed or corrected;
- a later assertion may cite this Work Record, but must add its own claimant,
  evidence, revision, and lifecycle meaning.

## Case 3 — A user preserves a durable authorship claim

The user wants the relation "Work A was created by Person P" to be reusable
outside one Work Record. They archive a credited source and intentionally
preserve the relation.

Required Tier 3 content:

- stable assertion ID;
- subject `wk_u_a`, predicate `created_by`, object `pe_u_p`;
- claimant/source Record and evidence reference, including exact Vault revision
  when the cited source is local;
- assertion time, and optional validity time only when it means something;
- independent lifecycle readiness.

The original structured link stays intact. It is not rewritten into the new
object.

## Case 4 — Competing assertions coexist

Two imported sources disagree about which person created a work.

Required result:

- AKASHA preserves two assertions with their own evidence, claimants, and
  provenance;
- neither is silently overwritten because subject/predicate are similar;
- a future user may mark one superseded or add a third qualifying assertion,
  but the prior evidence stays recoverable;
- a UI may present disagreement without declaring a winner.

## Case 5 — Validity time is not assertion time

A person was a member of an organization from 2018 to 2020. The user adds this
fact to AKASHA in 2026.

| Time | Meaning |
| --- | --- |
| 2018–2020 | Optional validity period of `member_of`. |
| 2026 | When the user/assertion entered AKASHA. |
| Source Record `created_at` | When that Document was saved; not either fact by itself. |

If the membership period is unknown, the assertion leaves it unknown. It must
not substitute the file save time.

## Case 6 — Canvas relation remains a layout choice

On a Canvas, the user connects two character nodes with `u:rival_of` and later
rearranges the board.

Required result:

- the `canvas_only` edge remains presentation/navigation data;
- its deletion does not retract a relationship assertion, because none exists;
- if the user explicitly promotes it, AKASHA resolves both nodes to stable
  entity IDs and records a separate Tier 3 claim with evidence/provenance;
- the promoted assertion may later be visualized on many Canvases without
  duplicating it.

## Case 7 — Canvas `canonical_view` is not an assertion

A Canvas edge with `edge_kind: canonical_view` references a Work Record's
structured link through `link_ref`.

Required result:

- it is a presentation of that Tier 2 link, despite the implementation label
  `canonical_view`;
- changing its position or visibility changes only the Canvas;
- it never becomes a global relationship assertion until a separate promotion
  supplies the Tier 3 requirements.

## Case 8 — AI proposes, but does not decide, a relation

An external AI reads two user-authorized source Records and proposes that
Concept A `inspired_by` Work B.

Required result:

- without explicit assertion-creation authority, the result is a candidate or
  proposal only;
- the proposal carries actor, source Record IDs/revisions, predicate, and
  evidence without changing the Records or Canvas;
- if authorized later, creation produces a distinct assertion rather than
  adding a link to the source Record;
- if an input revision changes, the proposal/application is stale and cannot
  be labelled as based on the new content.

## Case 9 — Title-only resolution cannot create a permanent edge

A legacy note contains `[[The Star]]`, and two Works share that title.

Required result:

- it remains a title-only Tier 1 reference;
- navigation may offer disambiguation;
- no assertion is emitted until a user/tool supplies a stable endpoint and
  explicit claim;
- a later resolver choice does not rewrite the original note merely to make a
  graph look complete.

## Case 10 — A broad `related` link stays lightweight

A user adds `relation: related` between two Records only to organize a reading
path.

Required result:

- Tier 2 is sufficient; it supports useful navigation without pretending the
  connection has a universal meaning;
- a Tier 3 `related` assertion would require a written rationale/scope and
  evidence, otherwise it adds durable ambiguity rather than durable knowledge.
