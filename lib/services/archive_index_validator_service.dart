import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../core/archiving/record_kind.dart';
import '../core/archiving/record_link.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import 'archive_index_manager.dart';
import 'entity_path_index_service.dart';
import 'record_link_index_service.dart';
import 'record_path_index_service.dart';
import 'record_summary_index_service.dart';
import 'taste_index_service.dart';
import 'timeline_entry_parser.dart';
import 'title_alias_index_service.dart';

enum ArchiveIndexValidationSeverity { error, warning }

class ArchiveIndexValidationIssue {
  const ArchiveIndexValidationIssue({
    required this.severity,
    required this.indexName,
    required this.code,
    required this.message,
    this.recordId,
    this.path,
    this.details = const {},
  });

  final ArchiveIndexValidationSeverity severity;
  final String indexName;
  final String code;
  final String message;
  final String? recordId;
  final String? path;
  final Map<String, dynamic> details;

  bool get isError => severity == ArchiveIndexValidationSeverity.error;

  Map<String, dynamic> toJson() => {
    'severity': severity.name,
    'indexName': indexName,
    'code': code,
    'message': message,
    if (recordId != null && recordId!.isNotEmpty) 'recordId': recordId,
    if (path != null && path!.isNotEmpty) 'path': path,
    if (details.isNotEmpty) 'details': details,
  };
}

class ArchiveIndexValidationResult {
  const ArchiveIndexValidationResult({
    required this.startedAt,
    required this.finishedAt,
    required this.issues,
    required this.stats,
    this.rebuildResult,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final List<ArchiveIndexValidationIssue> issues;
  final Map<String, dynamic> stats;
  final ArchiveIndexRebuildResult? rebuildResult;

  bool get hasErrors => issues.any((issue) => issue.isError);
  bool get succeeded => !hasErrors && (rebuildResult?.succeeded ?? true);

  List<ArchiveIndexValidationIssue> get errors =>
      issues.where((issue) => issue.isError).toList(growable: false);

  List<ArchiveIndexValidationIssue> get warnings =>
      issues.where((issue) => !issue.isError).toList(growable: false);

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt.toUtc().toIso8601String(),
    'succeeded': succeeded,
    'stats': stats,
    if (rebuildResult != null) 'rebuild': rebuildResult!.toJson(),
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };
}

/// Validates that disposable `.akasha` indexes can be rebuilt from Markdown.
///
/// This service never writes archive records. With [rebuildFirst], it refreshes
/// derived indexes through [ArchiveIndexManager], then compares those indexes
/// against a direct Markdown scan to catch silent ID/path drift.
class ArchiveIndexValidatorService {
  ArchiveIndexValidatorService({
    ArchiveIndexManager? indexManager,
    RecordSummaryIndexService? recordIndex,
    RecordPathIndexService? recordPathIndex,
    EntityPathIndexService? entityPathIndex,
    TitleAliasIndexService? titleAliasIndex,
    TasteIndexService? tasteIndex,
  }) : _indexManager = indexManager ?? ArchiveIndexManager(),
       _recordIndex = recordIndex ?? RecordSummaryIndexService(),
       _recordPathIndex = recordPathIndex ?? const RecordPathIndexService(),
       _entityPathIndex = entityPathIndex ?? EntityPathIndexService(),
       _titleAliasIndex = titleAliasIndex ?? TitleAliasIndexService(),
       _tasteIndex = tasteIndex ?? TasteIndexService();

  static const Set<String> _scanSkipDirNames = {
    'posters',
    'catalog',
    'node_modules',
    '.git',
    '.obsidian',
    '.trash',
    '.cursor',
    '.akasha',
  };

  final ArchiveIndexManager _indexManager;
  final RecordSummaryIndexService _recordIndex;
  final RecordPathIndexService _recordPathIndex;
  final EntityPathIndexService _entityPathIndex;
  final TitleAliasIndexService _titleAliasIndex;
  final TasteIndexService _tasteIndex;

  Future<ArchiveIndexValidationResult> validate({
    required String vaultPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
    bool rebuildFirst = true,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final issues = <ArchiveIndexValidationIssue>[];
    final stats = <String, dynamic>{};

    if (vaultPath.trim().isEmpty) {
      _addIssue(
        issues,
        severity: ArchiveIndexValidationSeverity.error,
        indexName: 'vault',
        code: 'vault_path_required',
        message: 'Vault path is required.',
      );
      return ArchiveIndexValidationResult(
        startedAt: startedAt,
        finishedAt: DateTime.now().toUtc(),
        issues: issues,
        stats: _finalStats(stats, issues),
      );
    }

    if (userCatalog != null) {
      await userCatalog.load();
    }

    ArchiveIndexRebuildResult? rebuildResult;
    if (rebuildFirst) {
      rebuildResult = await _indexManager.rebuildAll(
        vaultPath: vaultPath,
        userCatalog: userCatalog,
        vaultItems: vaultItems,
      );
      for (final entry in rebuildResult.entries) {
        if (entry.succeeded) continue;
        if (entry.partial) {
          _addIssue(
            issues,
            severity: ArchiveIndexValidationSeverity.warning,
            indexName: entry.indexName,
            code: 'index_rebuild_partial',
            message:
                entry.error ?? 'Index rebuild completed with partial results.',
            path: entry.outputPath,
            details: entry.stats,
          );
          continue;
        }
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: entry.indexName,
          code: 'index_rebuild_failed',
          message: entry.error ?? 'Index rebuild failed.',
          path: entry.outputPath,
          details: entry.stats,
        );
      }
    }

    final sourceRecords = await _scanSourceRecords(vaultPath, issues);
    stats['sourceRecords'] = sourceRecords.length;
    stats['sourceRecordIds'] = sourceRecords.map((r) => r.id).toSet().length;

    await _validateRecordIndex(vaultPath, sourceRecords, issues, stats);
    await _validateRecordPathIndex(vaultPath, sourceRecords, issues, stats);
    await _validateEntityPathIndex(vaultPath, sourceRecords, issues, stats);
    await _validateTitleAliasIndex(vaultPath, sourceRecords, issues, stats);
    await _validateLinkIndex(
      vaultPath,
      sourceRecords,
      issues,
      stats,
      userCatalog: userCatalog,
      vaultItems: vaultItems,
    );
    await _validateTasteIndex(vaultPath, sourceRecords, issues, stats);

    return ArchiveIndexValidationResult(
      startedAt: startedAt,
      finishedAt: DateTime.now().toUtc(),
      rebuildResult: rebuildResult,
      issues: issues,
      stats: _finalStats(stats, issues),
    );
  }

  Future<void> _validateRecordIndex(
    String vaultPath,
    List<_SourceRecord> sourceRecords,
    List<ArchiveIndexValidationIssue> issues,
    Map<String, dynamic> stats,
  ) async {
    final records = await _recordIndex.load(vaultPath);
    stats['recordIndexRecords'] = records.length;

    final sourceById = _groupBy(sourceRecords, (record) => record.id);
    final sourcePaths = sourceRecords
        .map((record) => p.normalize(record.relativePath))
        .toSet();

    for (final entry in sourceById.entries) {
      if (entry.value.length <= 1) continue;
      _addIssue(
        issues,
        severity: ArchiveIndexValidationSeverity.error,
        indexName: ArchiveIndexManager.recordIndexName,
        code: 'source_duplicate_record_id',
        message: 'Multiple Markdown records use the same stable record id.',
        recordId: entry.key,
        details: {
          'paths': entry.value.map((record) => record.relativePath).toList(),
        },
      );
    }

    final indexedById = {for (final record in records) record.id: record};
    for (final entry in sourceById.entries) {
      final indexed = indexedById[entry.key];
      if (indexed == null) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.recordIndexName,
          code: 'record_index_missing_id',
          message: 'Record index is missing a Markdown record id.',
          recordId: entry.key,
          path: entry.value.first.relativePath,
        );
        continue;
      }
      final expectedPaths = entry.value
          .map((record) => p.normalize(record.relativePath))
          .toSet();
      if (!expectedPaths.contains(p.normalize(indexed.relativePath))) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.recordIndexName,
          code: 'record_index_path_mismatch',
          message: 'Record index path does not match Markdown source path.',
          recordId: entry.key,
          path: indexed.relativePath,
          details: {'expectedPaths': expectedPaths.toList()..sort()},
        );
      }
    }

    for (final indexed in records) {
      final indexedPath = p.normalize(indexed.relativePath);
      if (!sourceById.containsKey(indexed.id)) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.recordIndexName,
          code: 'record_index_stale_id',
          message: 'Record index contains an id not present in Markdown.',
          recordId: indexed.id,
          path: indexed.relativePath,
        );
      } else if (!sourcePaths.contains(indexedPath)) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.recordIndexName,
          code: 'record_index_stale_path',
          message: 'Record index points to a path not present in Markdown.',
          recordId: indexed.id,
          path: indexed.relativePath,
        );
      }
    }
  }

  Future<void> _validateRecordPathIndex(
    String vaultPath,
    List<_SourceRecord> sourceRecords,
    List<ArchiveIndexValidationIssue> issues,
    Map<String, dynamic> stats,
  ) async {
    final source = sourceRecords
        .where(
          (record) =>
              record.documentRecordId != null &&
              RecordPathIndexService.isStableRecordId(record.documentRecordId!),
        )
        .toList(growable: false);
    final entries = await _recordPathIndex.loadAllIdEntries(vaultPath);
    stats['recordPathIndexRecords'] = entries.length;

    final sourceById = _groupBy(source, (record) => record.documentRecordId!);
    final indexedById = _groupBy(entries, (entry) => entry.recordId);
    for (final entry in sourceById.entries) {
      final expectedPaths = entry.value
          .map((record) => p.normalize(record.relativePath))
          .toSet();
      final indexedPaths = (indexedById[entry.key] ?? const [])
          .map((record) => p.normalize(record.relativePath))
          .toSet();
      if (indexedPaths.isEmpty) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.recordPathIndexName,
          code: 'record_path_missing_id',
          message: 'Record path index is missing a stable Markdown record id.',
          recordId: entry.key,
          path: entry.value.first.relativePath,
        );
      } else if (!_sameStrings(expectedPaths, indexedPaths)) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.recordPathIndexName,
          code: 'record_path_mismatch',
          message: 'Record path index does not match Markdown source paths.',
          recordId: entry.key,
          details: {
            'expectedPaths': expectedPaths.toList()..sort(),
            'indexedPaths': indexedPaths.toList()..sort(),
          },
        );
      }
    }

    for (final entry in entries) {
      final sourceRecordsForId = sourceById[entry.recordId];
      if (sourceRecordsForId == null) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.recordPathIndexName,
          code: 'record_path_stale_id',
          message: 'Record path index contains an id not present in Markdown.',
          recordId: entry.recordId,
          path: entry.relativePath,
        );
        continue;
      }
      final expectedPaths = sourceRecordsForId
          .map((record) => p.normalize(record.relativePath))
          .toSet();
      if (!expectedPaths.contains(p.normalize(entry.relativePath))) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.recordPathIndexName,
          code: 'record_path_stale_path',
          message:
              'Record path index points to a path not present in Markdown.',
          recordId: entry.recordId,
          path: entry.relativePath,
        );
      }
    }
  }

  Future<void> _validateEntityPathIndex(
    String vaultPath,
    List<_SourceRecord> sourceRecords,
    List<ArchiveIndexValidationIssue> issues,
    Map<String, dynamic> stats,
  ) async {
    final entityRecords = sourceRecords
        .where((record) => record.recordKind == RecordKind.entityJournal)
        .toList(growable: false);
    final entityById = _groupBy(entityRecords, (record) => record.id);
    final paths = await _entityPathIndex.loadPaths(vaultPath);
    stats['entitySourceRecords'] = entityRecords.length;
    stats['entityPathIndexEntries'] = paths.length;

    for (final entry in entityById.entries) {
      final indexedPath = paths[entry.key];
      if (indexedPath == null || indexedPath.isEmpty) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.entityPathIndexName,
          code: 'entity_path_missing_id',
          message: 'Entity path index is missing an entity id.',
          recordId: entry.key,
          path: entry.value.first.relativePath,
        );
        continue;
      }
      final expectedPaths = entry.value
          .map((record) => p.normalize(record.relativePath))
          .toSet();
      if (!expectedPaths.contains(p.normalize(indexedPath))) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.entityPathIndexName,
          code: 'entity_path_mismatch',
          message: 'Entity path index path does not match entity Markdown.',
          recordId: entry.key,
          path: indexedPath,
          details: {'expectedPaths': expectedPaths.toList()..sort()},
        );
      }
    }

    final sourcePaths = entityRecords
        .map((record) => p.normalize(record.relativePath))
        .toSet();
    for (final entry in paths.entries) {
      if (!entityById.containsKey(entry.key)) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.entityPathIndexName,
          code: 'entity_path_stale_id',
          message: 'Entity path index contains an id not present in Markdown.',
          recordId: entry.key,
          path: entry.value,
        );
      } else if (!sourcePaths.contains(p.normalize(entry.value))) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.entityPathIndexName,
          code: 'entity_path_stale_path',
          message: 'Entity path index points to a non-source Markdown path.',
          recordId: entry.key,
          path: entry.value,
        );
      }
    }
  }

  Future<void> _validateTitleAliasIndex(
    String vaultPath,
    List<_SourceRecord> sourceRecords,
    List<ArchiveIndexValidationIssue> issues,
    Map<String, dynamic> stats,
  ) async {
    var expectedNames = 0;
    for (final record in sourceRecords) {
      for (final value in record.nameValues) {
        final normalized = TitleAliasIndexService.normalizeName(value.value);
        if (normalized.isEmpty) continue;
        expectedNames += 1;
        final hits = await _titleAliasIndex.lookup(vaultPath, value.value);
        final matched = hits.any(
          (hit) =>
              hit.targetId == record.id &&
              p.normalize(hit.relativePath) == p.normalize(record.relativePath),
        );
        if (!matched) {
          _addIssue(
            issues,
            severity: ArchiveIndexValidationSeverity.error,
            indexName: ArchiveIndexManager.titleAliasIndexName,
            code: 'title_alias_missing_name',
            message: 'Title/alias index is missing a Markdown name variant.',
            recordId: record.id,
            path: record.relativePath,
            details: {
              'field': value.field,
              'name': value.value,
              'normalized': normalized,
            },
          );
        }
      }
    }
    stats['titleAliasExpectedNames'] = expectedNames;

    final entries = await _loadTitleAliasEntries(vaultPath, issues);
    stats['titleAliasEntries'] = entries.length;
    final sourceIds = sourceRecords.map((record) => record.id).toSet();
    final sourcePaths = sourceRecords
        .map((record) => p.normalize(record.relativePath))
        .toSet();
    for (final entry in entries) {
      if (!sourcePaths.contains(p.normalize(entry.relativePath))) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.titleAliasIndexName,
          code: 'title_alias_stale_path',
          message:
              'Title/alias index points to a path not present in Markdown.',
          recordId: entry.targetId,
          path: entry.relativePath,
        );
      } else if (!sourceIds.contains(entry.targetId)) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.warning,
          indexName: ArchiveIndexManager.titleAliasIndexName,
          code: 'title_alias_unknown_target',
          message: 'Title/alias index target id is not present in Markdown.',
          recordId: entry.targetId,
          path: entry.relativePath,
        );
      }
    }
  }

  Future<void> _validateLinkIndex(
    String vaultPath,
    List<_SourceRecord> sourceRecords,
    List<ArchiveIndexValidationIssue> issues,
    Map<String, dynamic> stats, {
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {
    final index = await _loadLinkIndex(vaultPath, issues);
    stats['linkOutgoingSources'] = index.outgoing.length;
    stats['linkIncomingTargets'] = index.incoming.length;

    final sourceAbsolutePaths = sourceRecords
        .map((record) => p.normalize(record.absolutePath))
        .toSet();
    final sourceIds = sourceRecords.map((record) => record.id).toSet();

    for (final entry in index.outgoing.entries) {
      final sourcePath = p.normalize(entry.key);
      if (!sourceAbsolutePaths.contains(sourcePath)) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.linkIndexName,
          code: 'link_outgoing_stale_source',
          message: 'Link index has an outgoing source path not in Markdown.',
          path: entry.key,
        );
      }

      for (final link in entry.value) {
        if (link.kind == RecordLinkKind.explicitId) {
          final targetId = link.targetEntityId?.trim();
          if (targetId == null || targetId.isEmpty) continue;
          if (!_isKnownTarget(targetId, sourceIds, userCatalog, vaultItems)) {
            _addIssue(
              issues,
              severity: ArchiveIndexValidationSeverity.warning,
              indexName: ArchiveIndexManager.linkIndexName,
              code: 'link_target_missing_local',
              message:
                  'Explicit link target is not present in local Markdown/catalog context.',
              recordId: targetId,
              path: entry.key,
              details: {'raw': link.raw},
            );
          }
        } else {
          final title = (link.targetTitle ?? link.raw).trim();
          if (title.isEmpty) continue;
          final hits = await _titleAliasIndex.lookup(vaultPath, title);
          if (hits.isEmpty) {
            _addIssue(
              issues,
              severity: ArchiveIndexValidationSeverity.warning,
              indexName: ArchiveIndexManager.linkIndexName,
              code: 'link_title_unresolved',
              message:
                  'Title-only link could not be resolved by title/alias index.',
              path: entry.key,
              details: {'title': title, 'raw': link.raw},
            );
          }
        }
      }
    }

    for (final entry in index.incoming.entries) {
      if (!_isKnownTarget(entry.key, sourceIds, userCatalog, vaultItems)) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.warning,
          indexName: ArchiveIndexManager.linkIndexName,
          code: 'link_incoming_unknown_target',
          message:
              'Incoming link target is not present in local Markdown/catalog context.',
          recordId: entry.key,
        );
      }
      for (final sourcePath in entry.value) {
        if (!sourceAbsolutePaths.contains(p.normalize(sourcePath))) {
          _addIssue(
            issues,
            severity: ArchiveIndexValidationSeverity.error,
            indexName: ArchiveIndexManager.linkIndexName,
            code: 'link_incoming_stale_source',
            message: 'Incoming link source path is not present in Markdown.',
            recordId: entry.key,
            path: sourcePath,
          );
        }
      }
    }
  }

  Future<void> _validateTasteIndex(
    String vaultPath,
    List<_SourceRecord> sourceRecords,
    List<ArchiveIndexValidationIssue> issues,
    Map<String, dynamic> stats,
  ) async {
    final index = await _tasteIndex.load(vaultPath);
    stats['tasteSignals'] = index.signals.length;

    final sourcePaths = sourceRecords
        .map((record) => p.normalize(record.relativePath))
        .toSet();
    final sourceRecordIds = sourceRecords
        .map((record) => record.sourceRecordId)
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final signal in index.signals) {
      if (!sourcePaths.contains(p.normalize(signal.evidencePath))) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.tasteIndexName,
          code: 'taste_signal_stale_evidence_path',
          message: 'Taste signal evidence path is not present in Markdown.',
          recordId: signal.sourceRecordId,
          path: signal.evidencePath,
        );
      }
      if (!sourceRecordIds.contains(signal.sourceRecordId)) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.tasteIndexName,
          code: 'taste_signal_unknown_source_record',
          message: 'Taste signal sourceRecordId is not present in Markdown.',
          recordId: signal.sourceRecordId,
          path: signal.evidencePath,
        );
      }
    }
  }

  Future<List<_SourceRecord>> _scanSourceRecords(
    String vaultPath,
    List<ArchiveIndexValidationIssue> issues,
  ) async {
    final records = <_SourceRecord>[];
    final root = Directory(vaultPath);
    if (!await root.exists()) {
      _addIssue(
        issues,
        severity: ArchiveIndexValidationSeverity.error,
        indexName: 'vault',
        code: 'vault_path_missing',
        message: 'Vault path does not exist.',
        path: vaultPath,
      );
      return records;
    }

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      if (_shouldSkipPath(entity.path)) continue;
      try {
        final record = await _SourceRecord.fromFile(
          vaultPath: vaultPath,
          file: entity,
        );
        if (record != null) records.add(record);
      } catch (error) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.warning,
          indexName: 'source',
          code: 'source_markdown_unreadable',
          message: 'Markdown file could not be parsed for index validation.',
          path: _relativePath(vaultPath, entity.path),
          details: {'error': error.toString()},
        );
      }
    }
    return records;
  }

  Future<List<TitleAliasIndexEntry>> _loadTitleAliasEntries(
    String vaultPath,
    List<ArchiveIndexValidationIssue> issues,
  ) async {
    final dir = Directory(
      p.join(
        vaultPath,
        TitleAliasIndexService.akashaDirName,
        TitleAliasIndexService.indexDirName,
        TitleAliasIndexService.namesDirName,
      ),
    );
    if (!await dir.exists()) return const [];

    final entries = <TitleAliasIndexEntry>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final decoded = jsonDecode(await entity.readAsString());
        if (decoded is! Map) continue;
        final raw = decoded['names'];
        if (raw is! Map) continue;
        for (final value in raw.values) {
          if (value is! List) continue;
          for (final rawEntry in value) {
            if (rawEntry is! Map) continue;
            entries.add(
              TitleAliasIndexEntry.fromJson(
                Map<String, dynamic>.from(rawEntry),
              ),
            );
          }
        }
      } catch (error) {
        _addIssue(
          issues,
          severity: ArchiveIndexValidationSeverity.error,
          indexName: ArchiveIndexManager.titleAliasIndexName,
          code: 'title_alias_shard_unreadable',
          message: 'Title/alias shard could not be read.',
          path: entity.path,
          details: {'error': error.toString()},
        );
      }
    }
    return entries;
  }

  Future<_LinkIndex> _loadLinkIndex(
    String vaultPath,
    List<ArchiveIndexValidationIssue> issues,
  ) async {
    final file = File(
      p.join(
        vaultPath,
        RecordLinkIndexService.indexDirName,
        RecordLinkIndexService.indexFileName,
      ),
    );
    if (!await file.exists()) return const _LinkIndex();

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const _LinkIndex();

      final outgoingRaw = decoded['outgoing'];
      final outgoing = <String, List<RecordLink>>{};
      if (outgoingRaw is Map) {
        for (final entry in outgoingRaw.entries) {
          final sourcePath = p.normalize(entry.key.toString());
          final linksJson = entry.value;
          if (linksJson is! List) continue;
          outgoing[sourcePath] = linksJson
              .whereType<Map>()
              .map(
                (link) => RecordLink.fromJson(
                  sourcePath,
                  Map<String, dynamic>.from(link),
                ),
              )
              .toList(growable: false);
        }
      }

      final incomingRaw = decoded['incoming'];
      final incoming = <String, List<String>>{};
      if (incomingRaw is Map) {
        for (final entry in incomingRaw.entries) {
          final sources = entry.value;
          incoming[entry.key.toString()] = sources is List
              ? sources.map((source) => p.normalize(source.toString())).toList()
              : const [];
        }
      }

      return _LinkIndex(outgoing: outgoing, incoming: incoming);
    } catch (error) {
      _addIssue(
        issues,
        severity: ArchiveIndexValidationSeverity.error,
        indexName: ArchiveIndexManager.linkIndexName,
        code: 'link_index_unreadable',
        message: 'Link index could not be read.',
        path: file.path,
        details: {'error': error.toString()},
      );
      return const _LinkIndex();
    }
  }

  bool _isKnownTarget(
    String targetId,
    Set<String> sourceIds,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems,
  ) {
    if (sourceIds.contains(targetId)) return true;
    if (userCatalog?.getById(targetId) != null) return true;
    return vaultItems.any((item) => item.workId == targetId);
  }

  static Map<String, dynamic> _finalStats(
    Map<String, dynamic> stats,
    List<ArchiveIndexValidationIssue> issues,
  ) => {
    ...stats,
    'issues': issues.length,
    'errors': issues.where((issue) => issue.isError).length,
    'warnings': issues.where((issue) => !issue.isError).length,
  };

  static Map<K, List<V>> _groupBy<K, V>(
    Iterable<V> values,
    K Function(V value) keyFor,
  ) {
    final grouped = <K, List<V>>{};
    for (final value in values) {
      grouped.putIfAbsent(keyFor(value), () => <V>[]).add(value);
    }
    return grouped;
  }

  static bool _sameStrings(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);

  static bool _shouldSkipPath(String filePath) {
    final parts = p.split(p.normalize(filePath));
    return parts.any(
      (part) =>
          _scanSkipDirNames.contains(part) ||
          (part.startsWith('.') && part != '.akasha'),
    );
  }

  static void _addIssue(
    List<ArchiveIndexValidationIssue> issues, {
    required ArchiveIndexValidationSeverity severity,
    required String indexName,
    required String code,
    required String message,
    String? recordId,
    String? path,
    Map<String, dynamic> details = const {},
  }) {
    issues.add(
      ArchiveIndexValidationIssue(
        severity: severity,
        indexName: indexName,
        code: code,
        message: message,
        recordId: recordId,
        path: path,
        details: details,
      ),
    );
  }

  static String _relativePath(String vaultPath, String absolutePath) =>
      p.relative(absolutePath, from: vaultPath).replaceAll('\\', '/');
}

class _SourceRecord {
  const _SourceRecord({
    required this.id,
    required this.documentRecordId,
    required this.sourceRecordId,
    required this.recordKind,
    required this.entityType,
    required this.title,
    required this.relativePath,
    required this.absolutePath,
    required this.nameValues,
  });

  final String id;
  final String? documentRecordId;
  final String sourceRecordId;
  final RecordKind recordKind;
  final String entityType;
  final String title;
  final String relativePath;
  final String absolutePath;
  final List<_NameValue> nameValues;

  static Future<_SourceRecord?> fromFile({
    required String vaultPath,
    required File file,
  }) async {
    final content = await file.readAsString();
    final split = _splitFrontmatter(content);
    if (split == null) return null;

    final parsed = loadYaml(split.frontmatter);
    if (parsed is! YamlMap) return null;

    final relativePath = p
        .relative(file.path, from: vaultPath)
        .replaceAll('\\', '/');
    final kind = _recordKindFromYaml(parsed);
    final id = _recordIdFromYaml(parsed, kind, relativePath);
    final documentRecordId = _string(parsed['record_id']);
    if (id.isEmpty) return null;

    final title =
        _string(parsed['title']) ?? p.basenameWithoutExtension(file.path);
    return _SourceRecord(
      id: id,
      documentRecordId: documentRecordId,
      sourceRecordId:
          documentRecordId ?? _sourceRecordIdFromYaml(parsed, relativePath),
      recordKind: kind,
      entityType: _entityTypeFromYaml(parsed, kind),
      title: title,
      relativePath: relativePath,
      absolutePath: p.normalize(file.path),
      nameValues: _nameValuesFromYaml(parsed, title),
    );
  }

  static RecordKind _recordKindFromYaml(YamlMap yaml) {
    final raw = _string(yaml['record_kind']);
    if (raw == TimelineEntryParser.legacyRecordKind) {
      return RecordKind.timelineEntry;
    }
    for (final kind in RecordKind.values) {
      if (kind.name == raw) return kind;
    }
    final entityType = _string(yaml['entity_type']);
    if (_string(yaml['work_id']) != null || entityType == 'work') {
      return RecordKind.workJournal;
    }
    if (_string(yaml['entity_id']) != null) {
      return RecordKind.entityJournal;
    }
    return RecordKind.freeformJournal;
  }

  static String _recordIdFromYaml(
    YamlMap yaml,
    RecordKind kind,
    String relativePath,
  ) {
    final id = switch (kind) {
      RecordKind.workJournal => _string(yaml['work_id'] ?? yaml['entity_id']),
      RecordKind.entityJournal => _string(yaml['entity_id']),
      RecordKind.timelineEntry ||
      RecordKind.freeformJournal => _string(yaml['record_id']),
    };
    return id?.trim().isNotEmpty == true ? id!.trim() : 'path:$relativePath';
  }

  static String _sourceRecordIdFromYaml(YamlMap yaml, String relativePath) {
    final recordId = _string(yaml['record_id']);
    if (recordId != null && recordId.isNotEmpty) return recordId;
    final workId = _string(yaml['work_id']);
    if (workId != null && workId.isNotEmpty) return 'rec_$workId';
    final entityId = _string(yaml['entity_id']);
    if (entityId != null && entityId.isNotEmpty) return 'rec_$entityId';
    return 'path:$relativePath';
  }

  static String _entityTypeFromYaml(YamlMap yaml, RecordKind kind) {
    final raw = _string(yaml['entity_type']);
    if (raw != null && raw.isNotEmpty) return raw;
    return switch (kind) {
      RecordKind.workJournal => 'work',
      RecordKind.entityJournal => 'object',
      RecordKind.timelineEntry => 'timeline',
      RecordKind.freeformJournal => 'journal',
    };
  }

  static List<_NameValue> _nameValuesFromYaml(YamlMap yaml, String title) {
    final values = <_NameValue>[];

    void add(String field, Object? raw) {
      final value = _string(raw);
      if (value == null || value.isEmpty) return;
      values.add(_NameValue(field, value));
    }

    add('title', title);
    for (final alias in _stringList(yaml['aliases'])) {
      values.add(_NameValue('alias', alias));
    }
    add('original_title', yaml['original_title'] ?? yaml['originalTitle']);
    add('localized_title', yaml['localized_title'] ?? yaml['localizedTitle']);
    _addLocalizedTitles(values, yaml['titles']);
    _addLocalizedTitles(
      values,
      yaml['localized_titles'] ?? yaml['localizedTitles'],
    );

    final seen = <String>{};
    return [
      for (final value in values)
        if (seen.add('${value.field}|${value.value}')) value,
    ];
  }

  static void _addLocalizedTitles(List<_NameValue> values, Object? raw) {
    if (raw is YamlMap) {
      for (final entry in raw.entries) {
        final tag = entry.key?.toString().trim() ?? '';
        final field = tag.isEmpty ? 'localized_title' : 'localized_title:$tag';
        final value = _string(entry.value);
        if (value != null && value.isNotEmpty) {
          values.add(_NameValue(field, value));
        }
      }
      return;
    }
    if (raw is YamlList || raw is List) {
      for (final value in _stringList(raw)) {
        values.add(_NameValue('localized_title', value));
      }
    }
  }

  static _Split? _splitFrontmatter(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return null;
    var end = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        end = i;
        break;
      }
    }
    if (end < 0) return null;
    return _Split(frontmatter: lines.sublist(1, end).join('\n'));
  }

  static String? _string(Object? raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static List<String> _stringList(Object? raw) {
    if (raw is YamlList || raw is List) {
      return (raw as Iterable)
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}

class _NameValue {
  const _NameValue(this.field, this.value);

  final String field;
  final String value;
}

class _Split {
  const _Split({required this.frontmatter});

  final String frontmatter;
}

class _LinkIndex {
  const _LinkIndex({this.outgoing = const {}, this.incoming = const {}});

  final Map<String, List<RecordLink>> outgoing;
  final Map<String, List<String>> incoming;
}
