import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/archiving/journal_entry.dart';
import '../core/archiving/record_kind.dart';
import '../core/archiving/timeline_entry.dart';
import '../models/akasha_item.dart';
import 'timeline_entry_parser.dart';

part 'record_summary_index_parse_part.dart';
part 'record_summary_index_summary_part.dart';

/// `{vault}/.akasha/record_index.json` — lightweight record map for app and tools.
///
/// The Markdown files remain the source of truth. This index is rebuildable and
/// intentionally stores only frontmatter-level summary fields.
class RecordSummaryIndexService {
  RecordSummaryIndexService();

  static const int schemaVersion = 1;
  static const String indexDirName = '.akasha';
  static const String indexFileName = 'record_index.json';

  static const Set<String> _scanSkipDirNames = {
    'posters',
    'catalog',
    'node_modules',
    '.git',
    '.obsidian',
    '.trash',
    '.cursor',
    indexDirName,
  };

  File _indexFile(String vaultPath) =>
      File(p.join(vaultPath, indexDirName, indexFileName));

  Future<void> ensureIndex(String vaultPath) async {
    final file = _indexFile(vaultPath);
    if (await file.exists()) return;
    await rebuildFromVault(vaultPath);
  }

  Future<List<VaultRecordSummary>> load(String vaultPath) async {
    final file = _indexFile(vaultPath);
    if (!await file.exists()) return const [];

    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if ((json['version'] as num?)?.toInt() != schemaVersion) return const [];
      final records = json['records'];
      if (records is! List) return const [];
      return records
          .whereType<Map>()
          .map(
            (raw) =>
                VaultRecordSummary.fromJson(Map<String, dynamic>.from(raw)),
          )
          .where((summary) => summary.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<VaultRecordSummary?> lookupById(
    String vaultPath,
    String recordId,
  ) async {
    if (recordId.trim().isEmpty) return null;
    for (final summary in await load(vaultPath)) {
      if (summary.id == recordId) return summary;
    }
    return null;
  }

  Future<List<VaultRecordSummary>> queryByTag(
    String vaultPath,
    String tag,
  ) async {
    final normalized = _normalizeTag(tag);
    if (normalized.isEmpty) return const [];
    final records = await load(vaultPath);
    return records
        .where((record) => record.normalizedTags.contains(normalized))
        .toList(growable: false);
  }

  Future<void> rebuildFromVault(String vaultPath) async {
    final records = <VaultRecordSummary>[];
    await for (final file in _scanRecordFiles(vaultPath)) {
      final summary = await VaultRecordSummary.fromMarkdownFile(
        vaultPath: vaultPath,
        file: file,
      );
      if (summary != null) records.add(summary);
    }
    await _write(vaultPath, _dedupe(records));
  }

  Future<void> upsertWork({
    required String vaultPath,
    required AkashaItem item,
    required String absolutePath,
  }) async {
    final summary = await VaultRecordSummary.fromWorkItem(
      vaultPath: vaultPath,
      item: item,
      absolutePath: absolutePath,
    );
    await _upsert(vaultPath, summary);
  }

  Future<void> upsertEntity({
    required String vaultPath,
    required EntityJournalEntry entry,
  }) async {
    final summary = await VaultRecordSummary.fromEntityEntry(
      vaultPath: vaultPath,
      entry: entry,
    );
    await _upsert(vaultPath, summary);
  }

  Future<void> upsertJournal({
    required String vaultPath,
    required JournalEntry entry,
  }) async {
    final summary = await VaultRecordSummary.fromJournalEntry(
      vaultPath: vaultPath,
      entry: entry,
    );
    await _upsert(vaultPath, summary);
  }

  Future<void> upsertTimeline({
    required String vaultPath,
    required TimelineEntry entry,
  }) async {
    final summary = await VaultRecordSummary.fromTimelineEntry(
      vaultPath: vaultPath,
      entry: entry,
    );
    await _upsert(vaultPath, summary);
  }

  Future<void> removeByAbsolutePath({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.isEmpty || absolutePath.isEmpty) return;
    final relative = _relativePath(vaultPath, absolutePath);
    final records = await load(vaultPath);
    final next = records
        .where((record) => record.relativePath != relative)
        .toList(growable: false);
    if (next.length == records.length) return;
    await _write(vaultPath, next);
  }

  Future<void> removeById({
    required String vaultPath,
    required String recordId,
  }) async {
    if (vaultPath.isEmpty || recordId.trim().isEmpty) return;
    final records = await load(vaultPath);
    final next = records
        .where((record) => record.id != recordId)
        .toList(growable: false);
    if (next.length == records.length) return;
    await _write(vaultPath, next);
  }

  Future<void> _upsert(String vaultPath, VaultRecordSummary summary) async {
    if (vaultPath.isEmpty || summary.id.isEmpty) return;
    final records = await load(vaultPath);
    final next = <VaultRecordSummary>[
      for (final record in records)
        if (record.id != summary.id &&
            record.relativePath != summary.relativePath)
          record,
      summary,
    ];
    await _write(vaultPath, _dedupe(next));
  }

  Future<void> _write(
    String vaultPath,
    List<VaultRecordSummary> records,
  ) async {
    final dir = Directory(p.join(vaultPath, indexDirName));
    await dir.create(recursive: true);

    final sorted = List<VaultRecordSummary>.from(records)
      ..sort((a, b) {
        final kind = a.recordKind.name.compareTo(b.recordKind.name);
        if (kind != 0) return kind;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    final payload = <String, dynamic>{
      'version': schemaVersion,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'records': sorted.map((record) => record.toJson()).toList(),
      'tagIndex': _buildTagIndex(sorted),
    };

    final file = _indexFile(vaultPath);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  Stream<File> _scanRecordFiles(String vaultPath) async* {
    final root = Directory(vaultPath);
    if (!await root.exists()) return;

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      if (_shouldSkipPath(entity.path)) continue;
      yield entity;
    }
  }

  bool _shouldSkipPath(String filePath) {
    final parts = p.split(p.normalize(filePath));
    return parts.any(
      (part) =>
          _scanSkipDirNames.contains(part) ||
          (part.startsWith('.') && part != indexDirName),
    );
  }

  List<VaultRecordSummary> _dedupe(List<VaultRecordSummary> records) {
    final byId = <String, VaultRecordSummary>{};
    for (final record in records) {
      byId[record.id] = record;
    }
    return byId.values.toList(growable: false);
  }

  Map<String, List<String>> _buildTagIndex(List<VaultRecordSummary> records) {
    final index = <String, Set<String>>{};
    for (final record in records) {
      for (final tag in record.normalizedTags) {
        index.putIfAbsent(tag, () => <String>{}).add(record.id);
      }
    }
    return index.map((tag, ids) {
      final sorted = ids.toList()..sort();
      return MapEntry(tag, sorted);
    });
  }

  static String _relativePath(String vaultPath, String absolutePath) =>
      p.relative(absolutePath, from: vaultPath).replaceAll('\\', '/');

  static String _normalizeTag(String tag) => tag.trim().toLowerCase();
}
