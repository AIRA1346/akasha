import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../core/archiving/record_kind.dart';
import 'local_derived_index_store.dart';
import 'record_summary_index_service.dart';

/// Streams canonical Work Markdown into the rebuildable local query cache.
///
/// Rebuild is deliberate maintenance work. Ordinary external changes should
/// use [syncSourcePath], which reads only the reported path.
class LocalDerivedIndexSynchronizer {
  LocalDerivedIndexSynchronizer({LocalDerivedIndexStore? store})
    : _store = store ?? LocalDerivedIndexStore();

  static const int _issueSampleLimit = 100;
  static const int _progressInterval = 100;
  static const int _rebuildWriteBatchSize =
      LocalDerivedIndexStore.rebuildWriteBatchSize;

  final LocalDerivedIndexStore _store;

  Future<WorkSummaryRebuildResult> rebuildWorkSummaries({
    required String cacheRoot,
    required String vaultPath,
    void Function(WorkSummaryRebuildProgress progress)? onProgress,
  }) async {
    final normalizedVault = LocalDerivedIndexStore.normalizedVaultRoot(
      vaultPath,
    );
    final generation = _nextGeneration();
    final database = await _store.open(
      cacheRoot: cacheRoot,
      vaultPath: normalizedVault,
    );
    var scanned = 0;
    var indexed = 0;
    var unreadable = 0;
    var pruned = 0;
    final issues = <WorkSourceIssue>[];
    final pendingReadable = <VaultRecordSummary>[];
    final pendingUnreadable = <String, String>{};

    void reportProgress() {
      onProgress?.call(
        WorkSummaryRebuildProgress(
          scanned: scanned,
          indexed: indexed,
          unreadable: unreadable,
        ),
      );
    }

    Future<void> flushRebuildBatch() async {
      if (pendingReadable.isEmpty && pendingUnreadable.isEmpty) return;
      await _store.applyWorkSourceBatch(
        database: database,
        readable: pendingReadable,
        unreadable: pendingUnreadable,
        indexedGeneration: generation,
      );
      pendingReadable.clear();
      pendingUnreadable.clear();
    }

    try {
      await _store.beginWorkSummaryRebuild(
        database: database,
        generation: generation,
      );
      final worksRoot = Directory(p.join(normalizedVault, 'works'));
      if (await worksRoot.exists()) {
        await for (final entity in worksRoot.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File) continue;
          final relativePath = _relativeVaultPath(normalizedVault, entity.path);
          if (relativePath == null || !_isWorkMarkdown(relativePath)) continue;

          scanned++;
          final parsed = await VaultRecordSummary.parseMarkdownFile(
            vaultPath: normalizedVault,
            file: entity,
          );
          final summary = parsed.summary;
          if (summary != null && summary.recordKind == RecordKind.workJournal) {
            pendingReadable.add(summary);
            indexed++;
          } else {
            final reason = parsed.errorCode ?? 'expected_work_journal';
            pendingUnreadable[relativePath] = reason;
            unreadable++;
            if (issues.length < _issueSampleLimit) {
              issues.add(
                WorkSourceIssue(relativePath: relativePath, errorCode: reason),
              );
            }
          }

          if (pendingReadable.length + pendingUnreadable.length >=
              _rebuildWriteBatchSize) {
            await flushRebuildBatch();
          }
          if (scanned % _progressInterval == 0) reportProgress();
        }
      }

      await flushRebuildBatch();
      pruned = await _store.pruneWorkSourcesOutsideGeneration(
        database: database,
        generation: generation,
      );
      await _store.completeWorkSummaryRebuild(
        database: database,
        generation: generation,
      );
      reportProgress();
      return WorkSummaryRebuildResult(
        scanned: scanned,
        indexed: indexed,
        unreadable: unreadable,
        pruned: pruned,
        issueSamples: List.unmodifiable(issues),
      );
    } catch (_) {
      try {
        await _store.markWorkSummaryRepairRequired(
          database: database,
          generation: generation,
          failureReason: 'rebuild_interrupted',
        );
      } catch (_) {
        // Preserve the original rebuild failure; the derived cache remains
        // disposable even if its repair marker could not be written.
      }
      rethrow;
    } finally {
      await database.close();
    }
  }

  /// Applies one source-path event without scanning the rest of the Vault.
  Future<WorkSourceSyncResult> syncSourcePath({
    required String cacheRoot,
    required String vaultPath,
    required String absolutePath,
  }) async {
    final normalizedVault = LocalDerivedIndexStore.normalizedVaultRoot(
      vaultPath,
    );
    final relativePath = _relativeVaultPath(normalizedVault, absolutePath);
    if (relativePath == null || !_isWorkMarkdown(relativePath)) {
      return const WorkSourceSyncResult.ignored();
    }

    final database = await _store.open(
      cacheRoot: cacheRoot,
      vaultPath: normalizedVault,
    );
    try {
      final source = File(absolutePath);
      if (!await source.exists()) {
        await _store.removeBySourcePath(
          database: database,
          relativePath: relativePath,
        );
        return WorkSourceSyncResult.deleted(relativePath: relativePath);
      }

      final parsed = await VaultRecordSummary.parseMarkdownFile(
        vaultPath: normalizedVault,
        file: source,
      );
      final summary = parsed.summary;
      if (summary != null && summary.recordKind == RecordKind.workJournal) {
        await _store.upsertWorkSummary(database: database, summary: summary);
        return WorkSourceSyncResult.indexed(relativePath: relativePath);
      }

      final reason = parsed.errorCode ?? 'expected_work_journal';
      await _store.markSourceUnreadable(
        database: database,
        relativePath: relativePath,
        errorCode: reason,
      );
      return WorkSourceSyncResult.unreadable(
        relativePath: relativePath,
        errorCode: reason,
      );
    } catch (_) {
      try {
        await _store.markWorkSummaryRepairRequired(
          database: database,
          failureReason: 'one_path_sync_failed',
        );
      } catch (_) {
        // Preserve the original path-sync failure for the caller.
      }
      rethrow;
    } finally {
      await database.close();
    }
  }

  static String _nextGeneration() =>
      '${DateTime.now().toUtc().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

  static String? _relativeVaultPath(String vaultPath, String absolutePath) {
    final root = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(absolutePath));
    if (!p.isWithin(root, target)) return null;
    final relative = p.relative(target, from: root).replaceAll('\\', '/');
    return relative.isEmpty || relative == '.' ? null : relative;
  }

  static bool _isWorkMarkdown(String relativePath) {
    final normalized = p.normalize(relativePath);
    final parts = p.split(normalized);
    if (parts.length < 2 || parts.first != 'works') return false;
    if (parts.any((part) => part.startsWith('.'))) return false;
    return normalized.toLowerCase().endsWith('.md');
  }
}

class WorkSummaryRebuildProgress {
  const WorkSummaryRebuildProgress({
    required this.scanned,
    required this.indexed,
    required this.unreadable,
  });

  final int scanned;
  final int indexed;
  final int unreadable;
}

class WorkSummaryRebuildResult {
  const WorkSummaryRebuildResult({
    required this.scanned,
    required this.indexed,
    required this.unreadable,
    required this.pruned,
    required this.issueSamples,
  });

  final int scanned;
  final int indexed;
  final int unreadable;
  final int pruned;
  final List<WorkSourceIssue> issueSamples;

  bool get hasMoreIssues => unreadable > issueSamples.length;
}

class WorkSourceIssue {
  const WorkSourceIssue({required this.relativePath, required this.errorCode});

  final String relativePath;
  final String errorCode;
}

enum WorkSourceSyncStatus { indexed, deleted, unreadable, ignored }

class WorkSourceSyncResult {
  const WorkSourceSyncResult._({
    required this.status,
    this.relativePath,
    this.errorCode,
  });

  const WorkSourceSyncResult.indexed({required String relativePath})
    : this._(status: WorkSourceSyncStatus.indexed, relativePath: relativePath);

  const WorkSourceSyncResult.deleted({required String relativePath})
    : this._(status: WorkSourceSyncStatus.deleted, relativePath: relativePath);

  const WorkSourceSyncResult.unreadable({
    required String relativePath,
    required String errorCode,
  }) : this._(
         status: WorkSourceSyncStatus.unreadable,
         relativePath: relativePath,
         errorCode: errorCode,
       );

  const WorkSourceSyncResult.ignored()
    : this._(status: WorkSourceSyncStatus.ignored);

  final WorkSourceSyncStatus status;
  final String? relativePath;
  final String? errorCode;
}
