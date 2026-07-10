// ignore_for_file: avoid_print

// Measures the bounded local Work-summary cache without touching a real Vault.
//
// Examples:
//   flutter test tool/derived_index_scale_benchmark.dart
//   flutter test --dart-define=AKASHA_BENCHMARK_RECORDS=100,10000,1000000 tool/derived_index_scale_benchmark.dart
//   flutter test --dart-define=AKASHA_BENCHMARK_RECORDS=10000 --dart-define=AKASHA_BENCHMARK_OUTPUT=build/derived-index-10k.json tool/derived_index_scale_benchmark.dart
//
// The generated summaries are synthetic. This measures SQLite rebuild/query
// behavior, not Markdown parsing or canonical-record hydration throughput.
import 'dart:convert';
import 'dart:io';

import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/services/local_derived_index_store.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('derived index scale benchmark', () async {
    final config = _BenchmarkConfig.fromEnvironment();
    final reports = <Map<String, Object?>>[];
    for (final records in config.recordCounts) {
      reports.add(await _runProfile(records, keepSandbox: config.keepSandbox));
    }

    final report = <String, Object?>{
      'tool': 'derived_index_scale_benchmark',
      'measured_at_utc': DateTime.now().toUtc().toIso8601String(),
      'scope': <String, Object?>{
        'canonical_markdown_files_read': 0,
        'canonical_vault_files_written': 0,
        'note':
            'Synthetic summary-cache benchmark only; Markdown parse and canonical hydration are separate measurements.',
      },
      'profiles': reports,
    };
    final encoded = const JsonEncoder.withIndent('  ').convert(report);
    print(encoded);
    final outputPath = config.outputPath;
    if (outputPath != null) {
      final output = File(outputPath);
      await output.parent.create(recursive: true);
      await output.writeAsString('$encoded\n');
      stderr.writeln('Wrote benchmark report: ${output.path}');
    }
  }, timeout: const Timeout(Duration(hours: 1)));
}

Future<Map<String, Object?>> _runProfile(
  int records, {
  required bool keepSandbox,
}) async {
  final sandbox = await Directory.systemTemp.createTemp(
    'akasha_derived_index_benchmark_',
  );
  final cacheRoot = p.join(sandbox.path, 'cache');
  final virtualVaultPath = p.join(sandbox.path, 'synthetic-vault-$records');
  final store = LocalDerivedIndexStore();
  Database? database;

  try {
    final coldOpen = await _measure(() async {
      database = await store.open(
        cacheRoot: cacheRoot,
        vaultPath: virtualVaultPath,
      );
    });
    final activeDatabase = database!;
    final generation = 'benchmark-$records';
    final rebuild = await _measure(() async {
      await store.beginWorkSummaryRebuild(
        database: activeDatabase,
        generation: generation,
      );
      final batch = <VaultRecordSummary>[];
      for (var index = 0; index < records; index++) {
        batch.add(_summary(index));
        if (batch.length == LocalDerivedIndexStore.rebuildWriteBatchSize) {
          await store.applyWorkSourceBatch(
            database: activeDatabase,
            readable: batch,
            unreadable: const <String, String>{},
            indexedGeneration: generation,
          );
          batch.clear();
          _reportProgress(index + 1, records);
        }
      }
      if (batch.isNotEmpty) {
        await store.applyWorkSourceBatch(
          database: activeDatabase,
          readable: batch,
          unreadable: const <String, String>{},
          indexedGeneration: generation,
        );
      }
      await store.completeWorkSummaryRebuild(
        database: activeDatabase,
        generation: generation,
      );
    });

    final firstPage = await _measure(
      () => store.queryWorkSummaries(
        database: activeDatabase,
        query: const WorkSummaryQuery(limit: 50),
      ),
    );
    if (firstPage.value.summaries.length != records.clamp(0, 50)) {
      throw StateError('First page did not remain bounded at 50 summaries.');
    }
    final continuation = await _measure(() async {
      final cursor = firstPage.value.nextCursor;
      if (cursor == null) return const WorkSummaryPage(summaries: []);
      return store.queryWorkSummaries(
        database: activeDatabase,
        query: WorkSummaryQuery(limit: 50, cursor: cursor),
      );
    });
    final lookupIndex = records ~/ 2;
    final stableIdLookup = await _measure(
      () => store.findWorkSummaryById(
        database: activeDatabase,
        workId: _workId(lookupIndex),
      ),
    );
    if (stableIdLookup.value?.id != _workId(lookupIndex)) {
      throw StateError('Stable Work ID lookup returned an unexpected record.');
    }
    final filteredPage = await _measure(
      () => store.queryWorkSummaries(
        database: activeDatabase,
        query: const WorkSummaryQuery(
          limit: 50,
          categories: ['movie'],
          myStatuses: ['Finished'],
          tag: 'tag-0',
        ),
      ),
    );

    final changedIndex = records - 1;
    final changedSummary = _summary(changedIndex, title: 'Changed summary');
    final onePathUpsert = await _measure(
      () => store.upsertWorkSummary(
        database: activeDatabase,
        summary: changedSummary,
      ),
    );
    final changed = await store.findWorkSummaryById(
      database: activeDatabase,
      workId: changedSummary.id,
    );
    if (changed?.title != changedSummary.title) {
      throw StateError('One-path update did not replace the summary.');
    }
    final onePathDelete = await _measure(
      () => store.removeBySourcePath(
        database: activeDatabase,
        relativePath: changedSummary.relativePath,
      ),
    );
    final deleted = await store.findWorkSummaryById(
      database: activeDatabase,
      workId: changedSummary.id,
    );
    if (deleted != null) {
      throw StateError('One-path delete did not remove the summary.');
    }

    final cacheBytes = await _directoryBytes(Directory(cacheRoot));
    await activeDatabase.close();
    database = null;
    final warmOpen = await _measure(() async {
      final reopened = await store.open(
        cacheRoot: cacheRoot,
        vaultPath: virtualVaultPath,
      );
      await reopened.close();
    });

    return <String, Object?>{
      'records': records,
      'cache_bytes': cacheBytes,
      'write_batch_size': LocalDerivedIndexStore.rebuildWriteBatchSize,
      'timings_ms': <String, Object?>{
        'cold_open': coldOpen.elapsedMilliseconds,
        'synthetic_rebuild': rebuild.elapsedMilliseconds,
        'warm_open': warmOpen.elapsedMilliseconds,
        'first_page': firstPage.elapsedMilliseconds,
        'cursor_continuation': continuation.elapsedMilliseconds,
        'stable_id_lookup': stableIdLookup.elapsedMilliseconds,
        'category_status_tag_filter': filteredPage.elapsedMilliseconds,
        'one_path_upsert': onePathUpsert.elapsedMilliseconds,
        'one_path_delete': onePathDelete.elapsedMilliseconds,
      },
      'results': <String, Object?>{
        'first_page_count': firstPage.value.summaries.length,
        'continuation_count': continuation.value.summaries.length,
        'filtered_page_count': filteredPage.value.summaries.length,
      },
    };
  } finally {
    await database?.close();
    if (keepSandbox) {
      stderr.writeln('Kept benchmark sandbox: ${sandbox.path}');
    } else if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  }
}

void _reportProgress(int completed, int total) {
  if (total < 100000 || completed % 100000 != 0) return;
  stderr.writeln('Indexed $completed / $total synthetic summaries');
}

VaultRecordSummary _summary(int index, {String? title}) {
  const categories = ['movie', 'book', 'music', 'game'];
  const statuses = ['Finished', 'Watching', 'Planned'];
  final id = _workId(index);
  final updatedAt = DateTime.utc(2026, 1, 1).add(Duration(minutes: index));
  return VaultRecordSummary(
    id: id,
    recordKind: RecordKind.workJournal,
    entityType: 'work',
    title: title ?? 'Synthetic Work $index',
    relativePath: 'works/${categories[index % categories.length]}/$id.md',
    category: categories[index % categories.length],
    creator: 'Synthetic Creator ${index % 200}',
    releaseYear: 1980 + (index % 46),
    rating: (index % 50) / 10,
    workStatus: 'Completed',
    myStatus: statuses[index % statuses.length],
    tags: ['tag-${index % 10}', 'shared-${index % 5}'],
    addedAt: updatedAt.subtract(const Duration(days: 1)),
    updatedAt: updatedAt,
  );
}

String _workId(int index) => 'wk_u_${index.toString().padLeft(12, '0')}';

Future<_Measured<T>> _measure<T>(Future<T> Function() action) async {
  final stopwatch = Stopwatch()..start();
  final value = await action();
  stopwatch.stop();
  return _Measured(value, stopwatch.elapsedMilliseconds);
}

Future<int> _directoryBytes(Directory directory) async {
  var bytes = 0;
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File) bytes += await entity.length();
  }
  return bytes;
}

class _Measured<T> {
  const _Measured(this.value, this.elapsedMilliseconds);

  final T value;
  final int elapsedMilliseconds;
}

class _BenchmarkConfig {
  const _BenchmarkConfig({
    required this.recordCounts,
    required this.keepSandbox,
    this.outputPath,
  });

  final List<int> recordCounts;
  final bool keepSandbox;
  final String? outputPath;

  factory _BenchmarkConfig.fromEnvironment() {
    const recordsValue = String.fromEnvironment(
      'AKASHA_BENCHMARK_RECORDS',
      defaultValue: '100,10000',
    );
    const outputPath = String.fromEnvironment('AKASHA_BENCHMARK_OUTPUT');
    const keepSandbox = bool.fromEnvironment('AKASHA_BENCHMARK_KEEP_SANDBOX');
    final recordCounts = recordsValue
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .toList(growable: false);
    if (recordCounts.isEmpty ||
        recordCounts.any((value) => value == null || value <= 0)) {
      throw ArgumentError(
        '--records must be a comma-separated list of integers greater than zero',
      );
    }
    return _BenchmarkConfig(
      recordCounts: recordCounts.cast<int>(),
      keepSandbox: keepSandbox,
      outputPath: outputPath.isEmpty ? null : outputPath,
    );
  }
}
