import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../core/app_vault.dart';
import '../core/ports/user_catalog_port.dart';
import '../core/ports/vault_change.dart';
import '../core/ports/vault_port.dart';
import '../models/akasha_item.dart';
import 'archive_candidate_store.dart';
import 'entity_path_index_service.dart';
import 'event_ledger_service.dart';
import 'record_link_index_service.dart';
import 'record_path_index_service.dart';
import 'record_summary_index_service.dart';
import 'taste_index_service.dart';
import 'title_alias_index_service.dart';

enum ArchiveIndexRebuildStatus { rebuilt, partial, failed }

class ArchiveIndexRebuildEntry {
  const ArchiveIndexRebuildEntry({
    required this.indexName,
    required this.status,
    required this.durationMs,
    this.outputPath,
    this.stats = const {},
    this.error,
  });

  final String indexName;
  final ArchiveIndexRebuildStatus status;
  final int durationMs;
  final String? outputPath;
  final Map<String, dynamic> stats;
  final String? error;

  bool get succeeded => status == ArchiveIndexRebuildStatus.rebuilt;
  bool get partial => status == ArchiveIndexRebuildStatus.partial;

  Map<String, dynamic> toJson() => {
    'indexName': indexName,
    'status': status.name,
    'durationMs': durationMs,
    if (outputPath != null && outputPath!.isNotEmpty) 'outputPath': outputPath,
    if (stats.isNotEmpty) 'stats': stats,
    if (error != null && error!.isNotEmpty) 'error': error,
  };
}

class ArchiveIndexRebuildResult {
  const ArchiveIndexRebuildResult({
    required this.startedAt,
    required this.finishedAt,
    required this.entries,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final List<ArchiveIndexRebuildEntry> entries;

  bool get succeeded => entries.every((entry) => entry.succeeded);

  ArchiveIndexRebuildEntry? entry(String indexName) {
    for (final entry in entries) {
      if (entry.indexName == indexName) return entry;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt.toUtc().toIso8601String(),
    'succeeded': succeeded,
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };
}

/// Coordinates disposable derived index rebuilds for tools and maintenance.
///
/// This class intentionally does not write archive records. Markdown remains
/// the source of truth; every index rebuilt here can be deleted and recreated.
class ArchiveIndexManager {
  ArchiveIndexManager({
    RecordSummaryIndexService? recordIndex,
    RecordPathIndexService? recordPathIndex,
    EntityPathIndexService? entityPathIndex,
    TitleAliasIndexService? titleAliasIndex,
    RecordLinkIndexService? linkIndex,
    ArchiveCandidateStore? candidateStore,
    TasteIndexService? tasteIndex,
  }) : _recordIndex = recordIndex ?? RecordSummaryIndexService(),
       _recordPathIndex = recordPathIndex ?? const RecordPathIndexService(),
       _entityPathIndex = entityPathIndex ?? EntityPathIndexService(),
       _titleAliasIndex = titleAliasIndex ?? TitleAliasIndexService(),
       _linkIndex = linkIndex,
       _candidateStore = candidateStore ?? ArchiveCandidateStore(),
       _tasteIndex = tasteIndex ?? TasteIndexService();

  static const String recordIndexName = 'record';
  static const String recordPathIndexName = 'recordPath';
  static const String entityPathIndexName = 'entityPath';
  static const String titleAliasIndexName = 'titleAlias';
  static const String linkIndexName = 'link';
  static const String candidateIndexName = 'candidate';
  static const String tasteIndexName = 'taste';

  final RecordSummaryIndexService _recordIndex;
  final RecordPathIndexService _recordPathIndex;
  final EntityPathIndexService _entityPathIndex;
  final TitleAliasIndexService _titleAliasIndex;
  final RecordLinkIndexService? _linkIndex;
  final ArchiveCandidateStore _candidateStore;
  final TasteIndexService _tasteIndex;

  Future<ArchiveIndexRebuildResult> rebuildAll({
    required String vaultPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {
    final startedAt = DateTime.now().toUtc();
    final entries = <ArchiveIndexRebuildEntry>[];

    if (vaultPath.trim().isEmpty) {
      final now = DateTime.now().toUtc();
      return ArchiveIndexRebuildResult(
        startedAt: startedAt,
        finishedAt: now,
        entries: [
          const ArchiveIndexRebuildEntry(
            indexName: 'vault',
            status: ArchiveIndexRebuildStatus.failed,
            durationMs: 0,
            error: 'vault_path_required',
          ),
        ],
      );
    }

    await _run(
      entries,
      indexName: recordIndexName,
      outputPath: p.join(
        vaultPath,
        RecordSummaryIndexService.indexDirName,
        RecordSummaryIndexService.indexFileName,
      ),
      action: () async {
        await _recordIndex.rebuildFromVault(vaultPath);
        final records = await _recordIndex.load(vaultPath);
        return {'records': records.length};
      },
    );

    await _run(
      entries,
      indexName: recordPathIndexName,
      outputPath: p.join(
        vaultPath,
        RecordPathIndexService.akashaDirName,
        RecordPathIndexService.indexDirName,
      ),
      action: () async =>
          (await _recordPathIndex.rebuildFromVault(vaultPath)).toJson(),
    );

    await _runEntityPathMutation(
      entries,
      indexName: entityPathIndexName,
      outputPath: p.join(
        vaultPath,
        EntityPathIndexService.indexDirName,
        EntityPathIndexService.indexFileName,
      ),
      action: () => _entityPathIndex.rebuildFromVaultDetailed(vaultPath),
      statsFor: (result) => {
        ...result.toJson(),
        'entities': result.indexedEntries,
      },
    );

    await _run(
      entries,
      indexName: titleAliasIndexName,
      outputPath: p.join(
        vaultPath,
        TitleAliasIndexService.akashaDirName,
        TitleAliasIndexService.indexDirName,
      ),
      action: () async {
        final stats = await _titleAliasIndex.rebuildFromVault(vaultPath);
        return stats.toJson();
      },
    );

    await _run(
      entries,
      indexName: linkIndexName,
      outputPath: p.join(
        vaultPath,
        RecordLinkIndexService.indexDirName,
        RecordLinkIndexService.indexFileName,
      ),
      action: () async {
        var stats = <String, dynamic>{};
        await _linkIndexFor(vaultPath).rebuildIndex(
          userCatalog: userCatalog,
          vaultItems: vaultItems,
          onRebuilt: (rebuiltStats) async {
            stats = Map<String, dynamic>.from(rebuiltStats);
          },
        );
        return stats;
      },
    );

    await _run(
      entries,
      indexName: candidateIndexName,
      outputPath: p.join(
        vaultPath,
        ArchiveCandidateStore.systemDirName,
        ArchiveCandidateStore.candidateDirName,
      ),
      action: () async {
        final stats = await _candidateStore.rebuildDerivedIndexes(vaultPath);
        return stats.toJson();
      },
    );

    await _run(
      entries,
      indexName: tasteIndexName,
      outputPath: p.join(
        vaultPath,
        TasteIndexService.akashaDirName,
        TasteIndexService.indexesDirName,
        TasteIndexService.indexFileName,
      ),
      action: () async {
        final index = await _tasteIndex.rebuildFromVault(vaultPath);
        return {
          'signals': index.signals.length,
          'targets': index.signals
              .map((signal) => signal.targetId)
              .toSet()
              .length,
        };
      },
    );

    return ArchiveIndexRebuildResult(
      startedAt: startedAt,
      finishedAt: DateTime.now().toUtc(),
      entries: entries,
    );
  }

  Future<ArchiveIndexRebuildResult> updateChangedRecord({
    required String vaultPath,
    required String absolutePath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {
    final startedAt = DateTime.now().toUtc();
    final entries = <ArchiveIndexRebuildEntry>[];

    final missingPath = vaultPath.trim().isEmpty || absolutePath.trim().isEmpty;
    if (missingPath || !_isWithinVault(vaultPath, absolutePath)) {
      final now = DateTime.now().toUtc();
      return ArchiveIndexRebuildResult(
        startedAt: startedAt,
        finishedAt: now,
        entries: [
          ArchiveIndexRebuildEntry(
            indexName: 'record',
            status: ArchiveIndexRebuildStatus.failed,
            durationMs: 0,
            error: missingPath
                ? 'record_path_required'
                : 'record_path_outside_vault',
          ),
        ],
      );
    }

    await _run(
      entries,
      indexName: recordIndexName,
      outputPath: p.join(
        vaultPath,
        RecordSummaryIndexService.indexDirName,
        RecordSummaryIndexService.indexFileName,
      ),
      action: () async {
        final summary = await _recordIndex.upsertMarkdownFile(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        return {
          'mode': 'incremental',
          if (summary != null) 'recordId': summary.id,
          'changedPath': _relativePath(vaultPath, absolutePath),
        };
      },
    );

    await _run(
      entries,
      indexName: recordPathIndexName,
      outputPath: p.join(
        vaultPath,
        RecordPathIndexService.akashaDirName,
        RecordPathIndexService.indexDirName,
      ),
      action: () async {
        final recordId = await _recordPathIndex.upsertMarkdownFile(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        return {
          'mode': 'incremental',
          if (recordId != null && recordId.isNotEmpty) 'recordId': recordId,
          'changedPath': _relativePath(vaultPath, absolutePath),
        };
      },
    );

    await _runEntityPathMutation(
      entries,
      indexName: entityPathIndexName,
      outputPath: p.join(
        vaultPath,
        EntityPathIndexService.indexDirName,
        EntityPathIndexService.indexFileName,
      ),
      action: () => _entityPathIndex.upsertMarkdownFileDetailed(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      ),
      statsFor: (result) => {
        ...result.toJson(),
        'mode': 'incremental',
        'changedPath': _relativePath(vaultPath, absolutePath),
      },
    );

    await _run(
      entries,
      indexName: titleAliasIndexName,
      outputPath: p.join(
        vaultPath,
        TitleAliasIndexService.akashaDirName,
        TitleAliasIndexService.indexDirName,
      ),
      action: () async {
        final entries = await _titleAliasIndex.upsertMarkdownFile(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        return {
          'mode': 'incremental',
          'lookupEntries': entries.length,
          'changedPath': _relativePath(vaultPath, absolutePath),
        };
      },
    );

    await _run(
      entries,
      indexName: linkIndexName,
      outputPath: p.join(
        vaultPath,
        RecordLinkIndexService.indexDirName,
        RecordLinkIndexService.indexFileName,
      ),
      action: () async {
        final links = await _linkIndexFor(vaultPath).upsertMarkdownFile(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
          userCatalog: userCatalog,
          vaultItems: vaultItems,
        );
        return {
          'mode': 'incremental',
          'outgoingLinks': links.length,
          'changedPath': _relativePath(vaultPath, absolutePath),
        };
      },
    );

    await _run(
      entries,
      indexName: tasteIndexName,
      outputPath: p.join(
        vaultPath,
        TasteIndexService.akashaDirName,
        TasteIndexService.indexesDirName,
        TasteIndexService.indexFileName,
      ),
      action: () async {
        final signals = await _tasteIndex.upsertMarkdownFile(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        return {
          'mode': 'incremental',
          'signals': signals.length,
          'changedPath': _relativePath(vaultPath, absolutePath),
        };
      },
    );

    return ArchiveIndexRebuildResult(
      startedAt: startedAt,
      finishedAt: DateTime.now().toUtc(),
      entries: entries,
    );
  }

  Future<ArchiveIndexRebuildResult> removeRecord({
    required String vaultPath,
    required String absolutePath,
    String? sourceRecordId,
    String? entityId,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final entries = <ArchiveIndexRebuildEntry>[];

    final missingPath = vaultPath.trim().isEmpty || absolutePath.trim().isEmpty;
    if (missingPath || !_isWithinVault(vaultPath, absolutePath)) {
      final now = DateTime.now().toUtc();
      return ArchiveIndexRebuildResult(
        startedAt: startedAt,
        finishedAt: now,
        entries: [
          ArchiveIndexRebuildEntry(
            indexName: 'record',
            status: ArchiveIndexRebuildStatus.failed,
            durationMs: 0,
            error: missingPath
                ? 'record_path_required'
                : 'record_path_outside_vault',
          ),
        ],
      );
    }

    await _run(
      entries,
      indexName: recordIndexName,
      outputPath: p.join(
        vaultPath,
        RecordSummaryIndexService.indexDirName,
        RecordSummaryIndexService.indexFileName,
      ),
      action: () async {
        await _recordIndex.removeByAbsolutePath(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        return {
          'mode': 'incrementalRemove',
          'removedPath': _relativePath(vaultPath, absolutePath),
        };
      },
    );

    await _run(
      entries,
      indexName: recordPathIndexName,
      outputPath: p.join(
        vaultPath,
        RecordPathIndexService.akashaDirName,
        RecordPathIndexService.indexDirName,
      ),
      action: () async {
        final removed = await _recordPathIndex.removeByAbsolutePath(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        return {
          'mode': 'incrementalRemove',
          'removedPath': _relativePath(vaultPath, absolutePath),
          if (removed != null && removed.isNotEmpty) 'recordId': removed,
        };
      },
    );

    await _run(
      entries,
      indexName: entityPathIndexName,
      outputPath: p.join(
        vaultPath,
        EntityPathIndexService.indexDirName,
        EntityPathIndexService.indexFileName,
      ),
      action: () async {
        final targetEntityId = entityId?.trim();
        String? removedEntityId;
        if (targetEntityId != null && targetEntityId.isNotEmpty) {
          await _entityPathIndex.remove(
            vaultPath: vaultPath,
            entityId: targetEntityId,
          );
          removedEntityId = targetEntityId;
        } else {
          removedEntityId = await _entityPathIndex.removeByAbsolutePath(
            vaultPath: vaultPath,
            absolutePath: absolutePath,
          );
        }
        return {
          'mode': 'incrementalRemove',
          'removedPath': _relativePath(vaultPath, absolutePath),
          if (removedEntityId != null && removedEntityId.isNotEmpty)
            'entityId': removedEntityId,
        };
      },
    );

    await _run(
      entries,
      indexName: titleAliasIndexName,
      outputPath: p.join(
        vaultPath,
        TitleAliasIndexService.akashaDirName,
        TitleAliasIndexService.indexDirName,
      ),
      action: () async {
        final removed = await _titleAliasIndex.removeByAbsolutePath(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        return {
          'mode': 'incrementalRemove',
          'removedPath': _relativePath(vaultPath, absolutePath),
          'lookupEntriesRemoved': removed,
        };
      },
    );

    await _run(
      entries,
      indexName: linkIndexName,
      outputPath: p.join(
        vaultPath,
        RecordLinkIndexService.indexDirName,
        RecordLinkIndexService.indexFileName,
      ),
      action: () async {
        await _linkIndexFor(
          vaultPath,
        ).removeBySourcePath(vaultPath: vaultPath, absolutePath: absolutePath);
        return {
          'mode': 'incrementalRemove',
          'removedPath': _relativePath(vaultPath, absolutePath),
        };
      },
    );

    await _run(
      entries,
      indexName: tasteIndexName,
      outputPath: p.join(
        vaultPath,
        TasteIndexService.akashaDirName,
        TasteIndexService.indexesDirName,
        TasteIndexService.indexFileName,
      ),
      action: () async {
        await _tasteIndex.removeByEvidencePath(
          vaultPath: vaultPath,
          absolutePath: absolutePath,
        );
        final source = sourceRecordId?.trim();
        if (source != null && source.isNotEmpty) {
          await _tasteIndex.removeBySourceRecord(
            vaultPath: vaultPath,
            sourceRecordId: source,
          );
        }
        return {
          'mode': 'incrementalRemove',
          'removedPath': _relativePath(vaultPath, absolutePath),
          if (source != null && source.isNotEmpty) 'sourceRecordId': source,
        };
      },
    );

    return ArchiveIndexRebuildResult(
      startedAt: startedAt,
      finishedAt: DateTime.now().toUtc(),
      entries: entries,
    );
  }

  RecordLinkIndexService _linkIndexFor(String vaultPath) {
    final injected = _linkIndex;
    if (injected != null) return injected;
    final appPath = AppVault.port.vaultPath;
    if (appPath != null &&
        appPath.isNotEmpty &&
        p.equals(p.normalize(appPath), p.normalize(vaultPath))) {
      return RecordLinkIndexService.shared;
    }
    final fixedVault = _FixedVaultPathPort(vaultPath);
    return RecordLinkIndexService(
      vault: fixedVault,
      eventLedger: EventLedgerService(vault: fixedVault),
    );
  }

  Future<void> _run(
    List<ArchiveIndexRebuildEntry> entries, {
    required String indexName,
    required String outputPath,
    required Future<Map<String, dynamic>> Function() action,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final stats = await action();
      stopwatch.stop();
      entries.add(
        ArchiveIndexRebuildEntry(
          indexName: indexName,
          status: ArchiveIndexRebuildStatus.rebuilt,
          durationMs: stopwatch.elapsedMilliseconds,
          outputPath: outputPath,
          stats: stats,
        ),
      );
    } catch (error) {
      stopwatch.stop();
      entries.add(
        ArchiveIndexRebuildEntry(
          indexName: indexName,
          status: ArchiveIndexRebuildStatus.failed,
          durationMs: stopwatch.elapsedMilliseconds,
          outputPath: outputPath,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _runEntityPathMutation(
    List<ArchiveIndexRebuildEntry> entries, {
    required String indexName,
    required String outputPath,
    required Future<EntityPathIndexMutationResult> Function() action,
    required Map<String, dynamic> Function(EntityPathIndexMutationResult result)
    statsFor,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      final status = result.succeeded
          ? ArchiveIndexRebuildStatus.rebuilt
          : result.partialSuccess
          ? ArchiveIndexRebuildStatus.partial
          : ArchiveIndexRebuildStatus.failed;
      entries.add(
        ArchiveIndexRebuildEntry(
          indexName: indexName,
          status: status,
          durationMs: stopwatch.elapsedMilliseconds,
          outputPath: outputPath,
          stats: statsFor(result),
          error: switch (status) {
            ArchiveIndexRebuildStatus.rebuilt => null,
            ArchiveIndexRebuildStatus.partial => 'entity_path_index_partial',
            ArchiveIndexRebuildStatus.failed => 'entity_path_index_failed',
          },
        ),
      );
    } catch (error) {
      stopwatch.stop();
      entries.add(
        ArchiveIndexRebuildEntry(
          indexName: indexName,
          status: ArchiveIndexRebuildStatus.failed,
          durationMs: stopwatch.elapsedMilliseconds,
          outputPath: outputPath,
          error: error.toString(),
        ),
      );
    }
  }

  static String _relativePath(String vaultPath, String absolutePath) =>
      p.relative(absolutePath, from: vaultPath).replaceAll('\\', '/');

  static bool _isWithinVault(String vaultPath, String absolutePath) {
    final vaultRoot = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(absolutePath));
    final relative = p.relative(target, from: vaultRoot);
    if (relative == '.') return true;
    if (p.isAbsolute(relative)) return false;
    return relative != '..' && !relative.startsWith('..${p.separator}');
  }
}

class _FixedVaultPathPort implements VaultPort {
  _FixedVaultPathPort(this._vaultPath);

  final String _vaultPath;

  @override
  Future<void> init() async {}

  @override
  String? get vaultPath => _vaultPath;

  @override
  Future<void> setVaultPath(String path) async {}

  @override
  Future<bool> isVaultPathValid() async => _vaultPath.isNotEmpty;

  @override
  bool isArchivedInVault(AkashaItem item) => false;

  @override
  Future<List<AkashaItem>> loadAllItems() async => const [];

  @override
  Future<AkashaItem?> loadItemByRelativePath(String relativePath) async => null;

  @override
  Future<int> countMarkdownFiles() async => 0;

  @override
  Future<void> saveItem(AkashaItem item, {String? oldTitle}) async {}

  @override
  Future<bool> deleteItem(AkashaItem item) async => false;

  @override
  Future<String?> importPosterImage(String sourceFilePath) async => null;

  @override
  Future<String?> importPosterImageFromBytes(
    Uint8List bytes, {
    String extension = 'png',
  }) async => null;

  @override
  Future<String?> importPosterImageBytesDeduped(
    Uint8List bytes, {
    required String extension,
  }) async => null;

  @override
  Future<void> signalVaultChanged() async {}

  @override
  Future<void> signalVaultChange(VaultChangeBatch change) async {}

  @override
  Stream<void> get onVaultUpdated => const Stream.empty();

  @override
  Stream<VaultChangeBatch> get onVaultChanges => const Stream.empty();

  @override
  Map<String, AkashaItem> get inMemoryCache => const {};
}
