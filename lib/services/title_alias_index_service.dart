import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../core/archiving/entity_anchor.dart';
import '../core/archiving/record_kind.dart';
import '../core/utils/unicode_helper.dart';
import 'timeline_entry_parser.dart';

class TitleAliasIndexStats {
  const TitleAliasIndexStats({
    required this.targets,
    required this.names,
    required this.shards,
  });

  final int targets;
  final int names;
  final int shards;

  Map<String, dynamic> toJson() => {
    'targets': targets,
    'names': names,
    'shards': shards,
  };
}

class TitleAliasIndexEntry {
  const TitleAliasIndexEntry({
    required this.targetId,
    required this.recordKind,
    required this.entityType,
    required this.title,
    required this.relativePath,
    this.values = const [],
    this.fields = const [],
  });

  final String targetId;
  final RecordKind recordKind;
  final String entityType;
  final String title;
  final String relativePath;
  final List<String> values;
  final List<String> fields;

  String get identityKey => '$targetId|${recordKind.name}|$relativePath';

  TitleAliasIndexEntry merge(TitleAliasIndexEntry other) {
    if (identityKey != other.identityKey) return this;
    return TitleAliasIndexEntry(
      targetId: targetId,
      recordKind: recordKind,
      entityType: entityType.isNotEmpty ? entityType : other.entityType,
      title: title.isNotEmpty ? title : other.title,
      relativePath: relativePath,
      values: _sortedUnique([...values, ...other.values]),
      fields: _sortedUnique([...fields, ...other.fields]),
    );
  }

  factory TitleAliasIndexEntry.fromJson(Map<String, dynamic> json) {
    final kindName = json['recordKind']?.toString() ?? '';
    final kind = RecordKind.values.firstWhere(
      (candidate) => candidate.name == kindName,
      orElse: () => RecordKind.workJournal,
    );
    return TitleAliasIndexEntry(
      targetId: json['targetId']?.toString() ?? '',
      recordKind: kind,
      entityType: json['entityType']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      relativePath: json['path']?.toString() ?? '',
      values:
          (json['values'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const [],
      fields:
          (json['fields'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'recordKind': recordKind.name,
    'entityType': entityType,
    'title': title,
    'path': relativePath,
    if (values.isNotEmpty) 'values': values,
    if (fields.isNotEmpty) 'fields': fields,
  };

  static List<String> _sortedUnique(Iterable<String> values) {
    final next =
        values
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return next;
  }
}

class TitleAliasIndexService {
  TitleAliasIndexService();

  static const int schemaVersion = 1;
  static const String akashaDirName = '.akasha';
  static const String indexDirName = 'title_alias_index';
  static const String namesDirName = 'names';
  static const String manifestFileName = 'manifest.json';

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

  Future<void> ensureIndex(String vaultPath) async {
    if (vaultPath.trim().isEmpty) return;
    final manifest = _manifestFile(vaultPath);
    if (await manifest.exists()) return;
    await rebuildFromVault(vaultPath);
  }

  Future<TitleAliasIndexStats> rebuildFromVault(String vaultPath) async {
    if (vaultPath.trim().isEmpty) {
      return const TitleAliasIndexStats(targets: 0, names: 0, shards: 0);
    }

    final root = Directory(_indexRootPath(vaultPath));
    if (await root.exists() && _isSafeIndexRoot(vaultPath, root.path)) {
      await root.delete(recursive: true);
    }

    final byShard = <String, Map<String, List<TitleAliasIndexEntry>>>{};
    final targetIds = <String>{};
    final normalizedNames = <String>{};

    await for (final file in _scanRecordFiles(vaultPath)) {
      final entries = await _entriesByNameFromMarkdownFile(
        vaultPath: vaultPath,
        file: file,
      );
      for (final entry in entries.entries) {
        normalizedNames.add(entry.key);
        for (final target in entry.value) {
          targetIds.add(target.identityKey);
        }
        final shard = _shardFor(entry.key);
        final shardIndex = byShard.putIfAbsent(
          shard,
          () => <String, List<TitleAliasIndexEntry>>{},
        );
        for (final target in entry.value) {
          _mergeIntoName(shardIndex, entry.key, target);
        }
      }
    }

    for (final entry in byShard.entries) {
      await _writeNameShard(
        _nameShardFile(vaultPath, entry.key),
        entry.key,
        entry.value,
      );
    }

    final stats = TitleAliasIndexStats(
      targets: targetIds.length,
      names: normalizedNames.length,
      shards: byShard.length,
    );
    await _writeManifest(vaultPath, stats: stats);
    return stats;
  }

  Future<List<TitleAliasIndexEntry>> lookup(
    String vaultPath,
    String name, {
    String? entityType,
    RecordKind? recordKind,
  }) async {
    final normalized = normalizeName(name);
    if (vaultPath.trim().isEmpty || normalized.isEmpty) return const [];

    final shard = await _readNameShard(
      _nameShardFile(vaultPath, _shardFor(normalized)),
    );
    final entries = List<TitleAliasIndexEntry>.from(
      shard[normalized] ?? const [],
    );
    final filtered = entries
        .where((entry) {
          if (entityType != null &&
              entityType.isNotEmpty &&
              entry.entityType != entityType) {
            return false;
          }
          if (recordKind != null && entry.recordKind != recordKind) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    filtered.sort(_compareEntries);
    return filtered;
  }

  Future<List<TitleAliasIndexEntry>> upsertMarkdownFile({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) {
      return const [];
    }
    if (!_isWithinVault(vaultPath, absolutePath)) return const [];

    final file = File(absolutePath);
    if (!await file.exists() || _shouldSkipPath(file.path)) {
      await removeByAbsolutePath(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      );
      return const [];
    }

    final entriesByName = await _entriesByNameFromMarkdownFile(
      vaultPath: vaultPath,
      file: file,
    );

    await removeByAbsolutePath(vaultPath: vaultPath, absolutePath: file.path);
    if (entriesByName.isEmpty) {
      await _writeManifest(vaultPath);
      return const [];
    }

    for (final entry in entriesByName.entries) {
      final shard = _shardFor(entry.key);
      final file = _nameShardFile(vaultPath, shard);
      final index = await _readNameShard(file);
      for (final target in entry.value) {
        _mergeIntoName(index, entry.key, target);
      }
      await _writeNameShard(file, shard, index);
    }

    await _writeManifest(vaultPath);
    final entries = entriesByName.values.expand((entry) => entry).toList();
    entries.sort(_compareEntries);
    return entries;
  }

  Future<int> removeByAbsolutePath({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) return 0;
    if (!_isWithinVault(vaultPath, absolutePath)) return 0;

    final relative = _relativePath(vaultPath, absolutePath);
    final removed = await _removeEntriesWhere(
      vaultPath,
      (entry) => p.normalize(entry.relativePath) == p.normalize(relative),
    );
    if (removed > 0) await _writeManifest(vaultPath);
    return removed;
  }

  Future<int> _removeEntriesWhere(
    String vaultPath,
    bool Function(TitleAliasIndexEntry entry) predicate,
  ) async {
    final dir = Directory(_namesDirPath(vaultPath));
    if (!await dir.exists()) return 0;

    var removed = 0;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final shard = p.basenameWithoutExtension(entity.path);
      final index = await _readNameShard(entity);
      var changed = false;
      final emptyNames = <String>[];

      for (final entry in index.entries) {
        final before = entry.value.length;
        entry.value.removeWhere(predicate);
        removed += before - entry.value.length;
        if (entry.value.length != before) changed = true;
        if (entry.value.isEmpty) emptyNames.add(entry.key);
      }
      for (final name in emptyNames) {
        index.remove(name);
      }

      if (changed) {
        await _writeNameShard(entity, shard, index);
      }
    }
    return removed;
  }

  Future<Map<String, List<TitleAliasIndexEntry>>>
  _entriesByNameFromMarkdownFile({
    required String vaultPath,
    required File file,
  }) async {
    try {
      final content = await file.readAsString();
      final split = _splitFrontmatter(content);
      if (split == null) return const {};

      final parsed = loadYaml(split.frontmatter);
      if (parsed is! YamlMap) return const {};

      final recordKind = _recordKindFromYaml(parsed);
      final relativePath = _relativePath(vaultPath, file.path);
      final targetId = _recordIdFromYaml(parsed, recordKind, relativePath);
      if (targetId.trim().isEmpty) return const {};

      final title =
          _string(parsed['title']) ?? p.basenameWithoutExtension(file.path);
      final entityType = _entityTypeFromYaml(parsed, recordKind);
      final values = _nameValuesFromYaml(parsed, title);
      if (values.isEmpty) return const {};

      final byName = <String, List<TitleAliasIndexEntry>>{};
      for (final value in values) {
        final normalized = normalizeName(value.value);
        if (normalized.isEmpty) continue;
        _mergeIntoName(
          byName,
          normalized,
          TitleAliasIndexEntry(
            targetId: targetId,
            recordKind: recordKind,
            entityType: entityType,
            title: title,
            relativePath: relativePath,
            values: [value.value],
            fields: [value.field],
          ),
        );
      }
      return byName;
    } catch (_) {
      return const {};
    }
  }

  List<_NameValue> _nameValuesFromYaml(YamlMap yaml, String title) {
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

  void _addLocalizedTitles(List<_NameValue> values, Object? raw) {
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

  Future<Map<String, List<TitleAliasIndexEntry>>> _readNameShard(
    File file,
  ) async {
    if (!await file.exists()) return <String, List<TitleAliasIndexEntry>>{};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return <String, List<TitleAliasIndexEntry>>{};
      if ((decoded['version'] as num?)?.toInt() != schemaVersion) {
        return <String, List<TitleAliasIndexEntry>>{};
      }
      final raw = decoded['names'];
      if (raw is! Map) return <String, List<TitleAliasIndexEntry>>{};
      return raw.map((key, value) {
        final entries = value is List
            ? value
                  .whereType<Map>()
                  .map(
                    (entry) => TitleAliasIndexEntry.fromJson(
                      Map<String, dynamic>.from(entry),
                    ),
                  )
                  .where((entry) => entry.targetId.isNotEmpty)
                  .toList()
            : <TitleAliasIndexEntry>[];
        entries.sort(_compareEntries);
        return MapEntry(key.toString(), entries);
      });
    } catch (_) {
      return <String, List<TitleAliasIndexEntry>>{};
    }
  }

  Future<void> _writeNameShard(
    File file,
    String shard,
    Map<String, List<TitleAliasIndexEntry>> index,
  ) async {
    final empty =
        index.isEmpty || index.values.every((entries) => entries.isEmpty);
    if (empty) {
      if (await file.exists()) await file.delete();
      return;
    }

    await file.parent.create(recursive: true);
    final sortedNames = index.keys.toList()..sort();
    final payload = <String, dynamic>{
      'version': schemaVersion,
      'storage': 'titleAliasNameShard',
      'shard': shard,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'names': {
        for (final name in sortedNames)
          if ((index[name] ?? const []).isNotEmpty)
            name: (List<TitleAliasIndexEntry>.from(
              index[name]!,
            )..sort(_compareEntries)).map((entry) => entry.toJson()).toList(),
      },
    };
    await _writeJsonAtomic(file, payload);
  }

  Future<void> _writeManifest(
    String vaultPath, {
    TitleAliasIndexStats? stats,
  }) async {
    final file = _manifestFile(vaultPath);
    await file.parent.create(recursive: true);
    final payload = <String, dynamic>{
      'version': schemaVersion,
      'storage': 'titleAliasIndex',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'namesDir': namesDirName,
      if (stats != null) 'stats': stats.toJson(),
    };
    await _writeJsonAtomic(file, payload);
  }

  Future<void> _writeJsonAtomic(File file, Map<String, dynamic> payload) async {
    await file.parent.create(recursive: true);
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
          (part.startsWith('.') && part != akashaDirName),
    );
  }

  File _manifestFile(String vaultPath) =>
      File(p.join(_indexRootPath(vaultPath), manifestFileName));

  File _nameShardFile(String vaultPath, String shard) =>
      File(p.join(_namesDirPath(vaultPath), '$shard.json'));

  String _indexRootPath(String vaultPath) =>
      p.join(vaultPath, akashaDirName, indexDirName);

  String _namesDirPath(String vaultPath) =>
      p.join(_indexRootPath(vaultPath), namesDirName);

  static void _mergeIntoName(
    Map<String, List<TitleAliasIndexEntry>> index,
    String normalizedName,
    TitleAliasIndexEntry incoming,
  ) {
    final entries = index.putIfAbsent(normalizedName, () => []);
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].identityKey == incoming.identityKey) {
        entries[i] = entries[i].merge(incoming);
        return;
      }
    }
    entries.add(incoming);
  }

  static int _compareEntries(TitleAliasIndexEntry a, TitleAliasIndexEntry b) {
    final kind = a.recordKind.name.compareTo(b.recordKind.name);
    if (kind != 0) return kind;
    final title = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (title != 0) return title;
    return a.targetId.compareTo(b.targetId);
  }

  static RecordKind _recordKindFromYaml(YamlMap yaml) {
    final raw = _safeYamlString(yaml, 'record_kind');
    if (raw == TimelineEntryParser.legacyRecordKind) {
      return RecordKind.timelineEntry;
    }
    for (final kind in RecordKind.values) {
      if (kind.name == raw) return kind;
    }
    final entityType = _safeYamlString(yaml, 'entity_type');
    if (_safeYamlString(yaml, 'work_id') != null || entityType == 'work') {
      return RecordKind.workJournal;
    }
    if (_safeYamlString(yaml, 'entity_id') != null) {
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
      RecordKind.workJournal =>
        _safeYamlString(yaml, 'work_id') ?? _safeYamlString(yaml, 'entity_id'),
      RecordKind.entityJournal => _safeYamlString(yaml, 'entity_id'),
      RecordKind.timelineEntry ||
      RecordKind.freeformJournal =>
        _safeYamlString(yaml, 'record_id'),
    };
    return id?.trim().isNotEmpty == true ? id!.trim() : 'path:$relativePath';
  }

  static String _entityTypeFromYaml(YamlMap yaml, RecordKind kind) {
    final raw = _safeYamlString(yaml, 'entity_type');
    if (raw != null && raw.isNotEmpty) return raw;
    return switch (kind) {
      RecordKind.workJournal => 'work',
      RecordKind.entityJournal => EntityAnchorType.object.name,
      RecordKind.timelineEntry => 'timeline',
      RecordKind.freeformJournal => 'journal',
    };
  }

  static String? _safeYamlString(YamlMap yaml, String key) {
    YamlNode? node;
    for (final k in yaml.nodes.keys) {
      if (k.toString().trim() == key) {
        node = yaml.nodes[k];
        break;
      }
    }
    if (node == null) return null;

    if (node is YamlScalar) {
      final val = node.value;
      if (val is bool || val is num) {
        final rawText = node.span.text.trim();
        final cleaned = rawText.split('#').first.trim();
        if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
            (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
          return UnicodeHelper.toNfc(cleaned.substring(1, cleaned.length - 1));
        }
        return UnicodeHelper.toNfc(cleaned);
      }
    }

    final val = node.value?.toString().trim();
    return val == null || val.isEmpty ? null : UnicodeHelper.toNfc(val);
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
    return value == null || value.isEmpty ? null : UnicodeHelper.toNfc(value);
  }

  static List<String> _stringList(Object? raw) {
    if (raw is YamlList || raw is List) {
      return (raw as Iterable)
          .map((entry) => UnicodeHelper.toNfc(entry.toString().trim()))
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((entry) => UnicodeHelper.toNfc(entry.trim()))
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static String normalizeName(String raw) {
    var value = UnicodeHelper.toNfc(raw.trim().toLowerCase());
    value = value.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    value = value.replaceAll(RegExp(r'\[[^\]]*\]'), ' ');
    value = value.replaceAll(RegExp(r'[{}<>]'), ' ');
    value = value.replaceAll(RegExp(r'[\s_\-:\/\\|.,;!?~`+*=#@%^&]+'), '');
    value = value.replaceAll('"', '').replaceAll("'", '');
    return value.trim();
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

  static bool _isSafeIndexRoot(String vaultPath, String path) {
    if (!_isWithinVault(vaultPath, path)) return false;
    final normalized = p.normalize(path);
    return p.basename(normalized) == indexDirName &&
        p.basename(p.dirname(normalized)) == akashaDirName;
  }

  static String _shardFor(String value) => _hashToken(value).substring(0, 2);

  static String _hashToken(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
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
