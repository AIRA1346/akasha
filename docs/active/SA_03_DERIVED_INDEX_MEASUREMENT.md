# SA-03 — Derived Index Synthetic Measurement

> **Date:** 2026-07-11
> **Status:** Cache storage/query measurement gate passed; source-scan and app-lifecycle gates remain pending.

## Scope

This measurement constructs only synthetic `VaultRecordSummary` values in a
temporary local SQLite cache. It reads and writes **zero canonical Vault
Markdown files**. The temporary cache is deleted after each run; only the JSON
report under ignored `build/` is retained locally.

It therefore proves the bounded behavior of the proposed derived cache, not
Markdown parse throughput, selected-record canonical hydration, or the shipped
Steam runtime.

## Reproduction

Run the harness through Flutter's test runtime (the local direct-Dart FFI
compiler is not the supported measurement path here):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\flutter.ps1 test `
  --dart-define=AKASHA_BENCHMARK_RECORDS=100,10000,1000000 `
  --dart-define=AKASHA_BENCHMARK_OUTPUT=build/derived-index-benchmark.json `
  tool/derived_index_scale_benchmark.dart --no-pub --reporter compact
```

The tool uses a 250-summary write batch, creates a ready cache, then measures
first-page and cursor reads, stable Work-ID lookup, category/status/tag
filtering, and one-path upsert/delete. It does not silently fall back to a
Vault scan.

## Final Measurement

Windows development/test runtime, synthetic cache, one cold run per profile:

| Records | Cache bytes | Rebuild | Cold / warm open | First / cursor page | Work-ID lookup | Category/status/tag | Upsert / delete |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 | 135,168 | 206 ms | 74 / 6 ms | 7 / 4 ms | 2 ms | 1 ms | 5 / 4 ms |
| 10,000 | 10,043,392 | 6,821 ms | 11 / 5 ms | 2 / 1 ms | <1 ms | 1 ms | 4 / 3 ms |
| 1,000,000 | 1,030,615,040 | 626,787 ms | 72 / 10 ms | 7 / 3 ms | 1 ms | 3 ms | 10 / 9 ms |

The first version of the 1m run exposed two non-bounded reads: first/cursor
pages were about 0.9 s because `COALESCE` prevented sort-index use, and the tag
filter was 305 ms. Cache schema v5 materialized `sort_at_utc`; v6 added a
tag-plus-sort index. The final table above is the re-measured v6 result.

## Decision

The local SQLite derived cache is suitable for the **SA-03 cache storage/query
boundary**:

- browse page, cursor, stable-ID locator lookup, tag filter, and one-path
  mutation remained bounded at 1m synthetic records;
- a full rebuild takes about 10.4 minutes in this debug test environment, so it
  remains explicit maintenance/repair work with progress and cancellation,
  never an ordinary startup or browse fallback;
- the cache consumes about 1.03 GB for the synthetic 1m fixture and remains
  outside the Vault, disposable, and non-canonical.

## Still Required Before Home Migration

1. Run the same profile on the packaged Windows Steam target and record release
   measurements, local-cache clear/rebuild UX, and package licensing evidence.
2. Surface the already-wired lifecycle's rebuild progress, cancellation, repair
   reason, and cache clear/rebuild controls in the user interface; verify
   native external-watch delivery on the packaged Steam target.
3. Measure Markdown source scanning and selected canonical Work hydration
   separately; the synthetic cache measurement must not be misrepresented as
   source-read throughput.
4. Only then migrate the Work browse entry path. Dashboard, Canvas, graph,
   records, pickers, and other global `List<AkashaItem>` consumers remain on
   their separately audited paths.
