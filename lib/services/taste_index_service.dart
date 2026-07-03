import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../core/archiving/taste_signal.dart';
import 'markdown_body_merger.dart';
import 'record_link_parser.dart';

/// Rebuildable preference signal index for tools and future agents.
///
/// Markdown files remain the source of truth. This derived index is safe to
/// delete and rebuild from user-owned vault evidence.
class TasteIndexService {
  TasteIndexService();

  static const int schemaVersion = 1;
  static const String akashaDirName = '.akasha';
  static const String indexesDirName = 'indexes';
  static const String indexFileName = 'taste_index.json';

  static const Set<String> _scanSkipDirNames = {
    'posters',
    'catalog',
    'node_modules',
    '.git',
    '.obsidian',
    '.trash',
    '.cursor',
    akashaDirName,
  };

  Future<TasteIndex> load(String vaultPath) async {
    final file = _indexFile(vaultPath);
    if (!await file.exists()) return TasteIndex.empty;

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return TasteIndex.empty;
      final json = Map<String, dynamic>.from(decoded);
      if ((json['version'] as num?)?.toInt() != schemaVersion) {
        return TasteIndex.empty;
      }
      return TasteIndex.fromJson(json);
    } catch (_) {
      return TasteIndex.empty;
    }
  }

  Future<List<TasteSignal>> queryByTarget(
    String vaultPath,
    String targetId,
  ) async {
    if (targetId.trim().isEmpty) return const [];
    final index = await load(vaultPath);
    return index.signalsForTarget(targetId);
  }

  Future<List<TasteSignal>> queryBySourceRecord(
    String vaultPath,
    String sourceRecordId,
  ) async {
    if (sourceRecordId.trim().isEmpty) return const [];
    final index = await load(vaultPath);
    return index.signalsForSource(sourceRecordId);
  }

  Future<TasteIndex> rebuildFromVault(String vaultPath) async {
    final signals = <TasteSignal>[];
    await for (final file in _scanRecordFiles(vaultPath)) {
      signals.addAll(await _extractSignals(vaultPath, file));
    }

    final index = TasteIndex(
      generatedAt: DateTime.now().toUtc(),
      signals: _dedupeAndSort(signals),
    );
    await _write(vaultPath, index);
    return index;
  }

  Future<List<TasteSignal>> _extractSignals(String vaultPath, File file) async {
    try {
      final content = await file.readAsString();
      final split = _splitFrontmatter(content);
      if (split == null) return const [];

      final parsed = loadYaml(split.frontmatter);
      if (parsed is! YamlMap) return const [];

      final relativePath = _relativePath(vaultPath, file.path);
      final stat = await _tryStat(file.path);
      final meta = _TasteRecordMeta.fromYaml(
        parsed,
        relativePath: relativePath,
        updatedAt: stat?.modified.toUtc(),
      );
      if (meta.sourceRecordId.isEmpty) return const [];

      final signals = <TasteSignal>[];
      void add({
        required TasteSignalType type,
        required String targetId,
        required String targetKind,
        required String evidenceField,
        required double weight,
        Object? value,
        String? snippet,
      }) {
        if (targetId.trim().isEmpty || evidenceField.trim().isEmpty) return;
        final signal = TasteSignal(
          signalId: _buildSignalId(
            sourceRecordId: meta.sourceRecordId,
            type: type,
            targetId: targetId,
            evidencePath: relativePath,
            evidenceField: evidenceField,
            value: value,
          ),
          signalType: type,
          sourceRecordId: meta.sourceRecordId,
          sourceRecordKind: meta.sourceRecordKind,
          targetId: targetId,
          targetKind: targetKind,
          value: value,
          weight: _clampWeight(weight),
          evidencePath: relativePath,
          evidenceField: evidenceField,
          snippet: snippet,
          updatedAt: meta.updatedAt,
        );
        signals.add(signal);
      }

      if (meta.rating != null && meta.rating! > 0) {
        add(
          type: TasteSignalType.rating,
          targetId: meta.subjectId,
          targetKind: meta.subjectKind,
          evidenceField: 'frontmatter.rating',
          value: meta.rating,
          weight: meta.rating! / 5.0,
        );
      }

      final status = meta.myStatus?.trim();
      if (status != null && status.isNotEmpty) {
        add(
          type: TasteSignalType.status,
          targetId: 'status:${_normalizeKey(status)}',
          targetKind: 'status',
          evidenceField: 'frontmatter.my_status',
          value: status,
          weight: _statusWeight(status),
        );
      }

      if (meta.isHallOfFame) {
        add(
          type: TasteSignalType.favorite,
          targetId: meta.subjectId,
          targetKind: meta.subjectKind,
          evidenceField: 'frontmatter.is_hall_of_fame',
          value: true,
          weight: 1,
        );
      }

      final seenTags = <String>{};
      for (var i = 0; i < meta.tags.length; i++) {
        final tag = meta.tags[i].trim();
        final normalized = _normalizeKey(tag);
        if (tag.isEmpty || normalized.isEmpty || !seenTags.add(normalized)) {
          continue;
        }
        add(
          type: TasteSignalType.tag,
          targetId: 'tag:$normalized',
          targetKind: 'tag',
          evidenceField: 'frontmatter.tags[$i]',
          value: tag,
          weight: 0.7,
        );
      }

      final slots = MarkdownBodyMerger.parseSlots(split.body);
      final memo = slots.memo.trim();
      if (memo.isNotEmpty) {
        final snippet = _snippet(memo, maxLength: 240);
        add(
          type: TasteSignalType.memo,
          targetId: meta.subjectId,
          targetKind: meta.subjectKind,
          evidenceField: 'body.memo',
          value: snippet,
          snippet: snippet,
          weight: 0.65,
        );
      }

      for (var i = 0; i < slots.quotes.length; i++) {
        final quote = slots.quotes[i].trim();
        if (quote.isEmpty) continue;
        final snippet = _snippet(quote, maxLength: 200);
        add(
          type: TasteSignalType.quote,
          targetId: meta.subjectId,
          targetKind: meta.subjectKind,
          evidenceField: 'body.quotes[$i]',
          value: snippet,
          snippet: snippet,
          weight: 0.75,
        );
      }

      final links = RecordLinkParser.parseFromMarkdown(split.body);
      for (var i = 0; i < links.length; i++) {
        final link = links[i];
        final titleTarget = link.targetTitle ?? link.raw;
        final targetId =
            link.targetEntityId ?? 'title:${_normalizeKey(titleTarget)}';
        add(
          type: TasteSignalType.link,
          targetId: targetId,
          targetKind: link.targetEntityId == null ? 'title' : 'record',
          evidenceField: 'body.links[$i]',
          value: link.displayText,
          weight: 0.5,
        );
      }

      return signals;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _write(String vaultPath, TasteIndex index) async {
    if (vaultPath.trim().isEmpty) return;
    final file = _indexFile(vaultPath);
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(index.toJson(version: schemaVersion)),
      flush: true,
    );
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  Stream<File> _scanRecordFiles(String vaultPath) async* {
    if (vaultPath.trim().isEmpty) return;
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
          (part.startsWith('.') && part != akashaDirName),
    );
  }

  File _indexFile(String vaultPath) =>
      File(p.join(vaultPath, akashaDirName, indexesDirName, indexFileName));

  static List<TasteSignal> _dedupeAndSort(List<TasteSignal> signals) {
    final byId = <String, TasteSignal>{};
    for (final signal in signals) {
      byId[signal.signalId] = signal;
    }
    final sorted = byId.values.toList(growable: false)
      ..sort((a, b) {
        final source = a.sourceRecordId.compareTo(b.sourceRecordId);
        if (source != 0) return source;
        final type = a.signalType.name.compareTo(b.signalType.name);
        if (type != 0) return type;
        final target = a.targetId.compareTo(b.targetId);
        if (target != 0) return target;
        return a.evidenceField.compareTo(b.evidenceField);
      });
    return sorted;
  }

  static String _buildSignalId({
    required String sourceRecordId,
    required TasteSignalType type,
    required String targetId,
    required String evidencePath,
    required String evidenceField,
    Object? value,
  }) {
    return 'ts_${_hashToken([sourceRecordId, type.name, targetId, evidencePath, evidenceField, value?.toString() ?? ''].join('|'))}';
  }

  static String _hashToken(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _normalizeKey(String value) {
    final buffer = StringBuffer();
    var wroteDash = false;
    for (final rune in value.trim().toLowerCase().runes) {
      if (_isAsciiLetterOrDigit(rune) || rune > 0x7f) {
        buffer.writeCharCode(rune);
        wroteDash = false;
      } else if (!wroteDash && buffer.isNotEmpty) {
        buffer.write('-');
        wroteDash = true;
      }
    }
    final normalized = buffer.toString();
    return normalized.endsWith('-')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  static bool _isAsciiLetterOrDigit(int rune) =>
      (rune >= 0x30 && rune <= 0x39) || (rune >= 0x61 && rune <= 0x7a);

  static double _statusWeight(String status) {
    final normalized = _normalizeKey(status);
    if (const {
      'finished',
      'cleared',
      'watching',
      'playing',
    }.contains(normalized)) {
      return 0.75;
    }
    if (const {'dropped', 'abandoned'}.contains(normalized)) return 0.25;
    return 0.45;
  }

  static double _clampWeight(double value) {
    if (value.isNaN) return 0;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  static String _snippet(String text, {required int maxLength}) {
    final compact = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (compact.length <= maxLength) return compact;
    return compact.substring(0, maxLength).trimRight();
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
    return _Split(
      frontmatter: lines.sublist(1, end).join('\n'),
      body: lines.sublist(end + 1).join('\n'),
    );
  }

  static String _relativePath(String vaultPath, String absolutePath) =>
      p.relative(absolutePath, from: vaultPath).replaceAll('\\', '/');
}

class _TasteRecordMeta {
  const _TasteRecordMeta({
    required this.sourceRecordId,
    required this.sourceRecordKind,
    required this.subjectId,
    required this.subjectKind,
    required this.tags,
    required this.isHallOfFame,
    this.rating,
    this.myStatus,
    this.updatedAt,
  });

  final String sourceRecordId;
  final String sourceRecordKind;
  final String subjectId;
  final String subjectKind;
  final double? rating;
  final String? myStatus;
  final List<String> tags;
  final bool isHallOfFame;
  final DateTime? updatedAt;

  factory _TasteRecordMeta.fromYaml(
    YamlMap yaml, {
    required String relativePath,
    DateTime? updatedAt,
  }) {
    final workId = _string(yaml['work_id']);
    final entityId = _string(yaml['entity_id']);
    final rawRecordKind = _string(yaml['record_kind']);
    final entityType = _string(yaml['entity_type']);
    final sourceRecordId =
        _string(yaml['record_id']) ??
        (workId != null
            ? 'rec_$workId'
            : entityId != null
            ? 'rec_$entityId'
            : 'path:$relativePath');
    final subjectId = workId ?? entityId ?? sourceRecordId;
    final subjectKind = workId != null ? 'work' : (entityType ?? 'record');

    return _TasteRecordMeta(
      sourceRecordId: sourceRecordId,
      sourceRecordKind:
          rawRecordKind ??
          (workId != null
              ? 'workJournal'
              : entityId != null
              ? 'entityJournal'
              : 'journal'),
      subjectId: subjectId,
      subjectKind: subjectKind,
      rating: _double(yaml['rating']),
      myStatus: _string(yaml['my_status'] ?? yaml['status']),
      tags: _tags(yaml['tags']),
      isHallOfFame: _bool(yaml['is_hall_of_fame']),
      updatedAt: updatedAt,
    );
  }
}

class _Split {
  const _Split({required this.frontmatter, required this.body});

  final String frontmatter;
  final String body;
}

Future<FileStat?> _tryStat(String path) async {
  try {
    return await File(path).stat();
  } catch (_) {
    return null;
  }
}

String? _string(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

double? _double(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

bool _bool(Object? raw) {
  if (raw is bool) return raw;
  final value = raw?.toString().toLowerCase();
  return value == 'true' || value == 'yes' || value == '1';
}

List<String> _tags(Object? raw) {
  if (raw is YamlList) {
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  if (raw is List) {
    return raw
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
