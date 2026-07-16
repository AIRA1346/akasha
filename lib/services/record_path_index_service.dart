import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import 'derived_index_atomic_write.dart';
import 'vault_document_identity.dart';

/// A sharded, rebuildable map from a stable Record id to its Markdown path.
///
/// The Vault remains canonical. This index deliberately stores only physical
/// lookup information, so it must not be used as a source of Record meaning.
/// Keeping the reverse path map alongside the id map lets one changed Markdown
/// file update its old and new ids without loading a whole-vault index.
class RecordPathIndexService {
  const RecordPathIndexService({
    this.atomicWrite = const DerivedIndexAtomicWrite(),
  });

  final DerivedIndexAtomicWrite atomicWrite;

  static const int schemaVersion = 1;
  static const String akashaDirName = '.akasha';
  static const String indexDirName = 'record_path_index';
  static const String idDirName = 'id';
  static const String pathDirName = 'path';
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

  /// Reads one id shard only. Multiple paths are preserved rather than
  /// choosing one silently when a Vault has duplicate stable ids.
  Future<RecordPathIndexLookup> lookup(
    String vaultPath,
    String recordId,
  ) async {
    final id = recordId.trim();
    if (!isStableRecordId(id)) return const RecordPathIndexLookup.empty();
    try {
      final entries = await _readEntries(_idShardFile(vaultPath, _idShard(id)));
      final matches = entries
          .where((entry) => entry.recordId == id)
          .toList(growable: false);
      return RecordPathIndexLookup(entries: matches);
    } on DerivedIndexCorruptException {
      return const RecordPathIndexLookup.corrupt();
    }
  }

  Future<void> ensureIndex(String vaultPath) async {
    if (vaultPath.trim().isEmpty || await isAvailable(vaultPath)) return;
    await rebuildFromVault(vaultPath);
  }

  Future<bool> isAvailable(String vaultPath) async {
    final file = _manifestFile(vaultPath);
    final opened = await atomicWrite.openForRead(
      target: file,
      validateContent: _isValidManifestContent,
    );
    return opened.isReady;
  }

  /// Used by integrity validation. Normal record reads must use [lookup].
  Future<List<RecordPathIndexEntry>> loadAllIdEntries(String vaultPath) async {
    final dir = Directory(p.join(_indexRoot(vaultPath), idDirName));
    if (!await dir.exists()) return const [];
    final entries = <RecordPathIndexEntry>[];
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      entries.addAll(await _readEntries(entity));
    }
    return _sortedUnique(entries);
  }

  Future<RecordPathIndexStats> rebuildFromVault(String vaultPath) async {
    if (vaultPath.trim().isEmpty) {
      return const RecordPathIndexStats(records: 0, idShards: 0, pathShards: 0);
    }
    return atomicWrite.runExclusive(
      target: _manifestFile(vaultPath),
      action: () => _rebuildFromVaultUnlocked(vaultPath),
    );
  }

  Future<RecordPathIndexStats> _rebuildFromVaultUnlocked(
    String vaultPath,
  ) async {
    final byIdShard = <String, List<RecordPathIndexEntry>>{};
    final byPathShard = <String, List<RecordPathIndexEntry>>{};
    await for (final file in _scanRecordFiles(vaultPath)) {
      final recordId = await VaultDocumentIdentity.readRecordId(file);
      if (recordId == null || !isStableRecordId(recordId)) continue;
      final entry = RecordPathIndexEntry(
        recordId: recordId,
        relativePath: _relativePath(vaultPath, file.path),
      );
      byIdShard.putIfAbsent(_idShard(entry.recordId), () => []).add(entry);
      byPathShard
          .putIfAbsent(_pathShard(entry.relativePath), () => [])
          .add(entry);
    }

    final root = Directory(_indexRoot(vaultPath));
    if (await root.exists() && _isWithinVault(vaultPath, root.path)) {
      await root.delete(recursive: true);
    }

    for (final entry in byIdShard.entries) {
      await _writeEntries(
        _idShardFile(vaultPath, entry.key),
        shard: entry.key,
        records: entry.value,
      );
    }
    for (final entry in byPathShard.entries) {
      await _writeEntries(
        _pathShardFile(vaultPath, entry.key),
        shard: entry.key,
        records: entry.value,
      );
    }

    final records = byPathShard.values.expand((entries) => entries).length;
    final stats = RecordPathIndexStats(
      records: records,
      idShards: byIdShard.length,
      pathShards: byPathShard.length,
    );
    await _writeManifest(vaultPath, stats: stats);
    return stats;
  }

  Future<String?> upsertMarkdownFile({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) return null;
    if (!_isWithinVault(vaultPath, absolutePath)) return null;

    return atomicWrite.runExclusive(
      target: _manifestFile(vaultPath),
      action: () => _upsertMarkdownFileUnlocked(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      ),
    );
  }

  Future<String?> _upsertMarkdownFileUnlocked({
    required String vaultPath,
    required String absolutePath,
  }) async {
    final relativePath = _relativePath(vaultPath, absolutePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      return _removeByAbsolutePathUnlocked(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      );
    }

    final recordId = await VaultDocumentIdentity.readRecordId(file);
    if (recordId == null || !isStableRecordId(recordId)) {
      await _removeByAbsolutePathUnlocked(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      );
      return null;
    }

    final pathShard = _pathShard(relativePath);
    final pathFile = _pathShardFile(vaultPath, pathShard);
    final pathEntries = await _readEntries(pathFile);
    final previous = pathEntries
        .where((entry) => entry.relativePath == relativePath)
        .toList(growable: false);
    final current = RecordPathIndexEntry(
      recordId: recordId,
      relativePath: relativePath,
    );

    final affectedIdShards = <String>{
      _idShard(current.recordId),
      ...previous.map((entry) => _idShard(entry.recordId)),
    };
    for (final shard in affectedIdShards) {
      final idFile = _idShardFile(vaultPath, shard);
      final entries = await _readEntries(idFile);
      entries.removeWhere((entry) => entry.relativePath == relativePath);
      if (shard == _idShard(current.recordId)) entries.add(current);
      await _writeEntries(idFile, shard: shard, records: entries);
    }

    pathEntries.removeWhere((entry) => entry.relativePath == relativePath);
    pathEntries.add(current);
    await _writeEntries(pathFile, shard: pathShard, records: pathEntries);
    await _writeManifest(vaultPath);
    return current.recordId;
  }

  Future<String?> removeByAbsolutePath({
    required String vaultPath,
    required String absolutePath,
  }) async {
    if (vaultPath.trim().isEmpty || absolutePath.trim().isEmpty) return null;
    if (!_isWithinVault(vaultPath, absolutePath)) return null;

    return atomicWrite.runExclusive(
      target: _manifestFile(vaultPath),
      action: () => _removeByAbsolutePathUnlocked(
        vaultPath: vaultPath,
        absolutePath: absolutePath,
      ),
    );
  }

  Future<String?> _removeByAbsolutePathUnlocked({
    required String vaultPath,
    required String absolutePath,
  }) async {
    final relativePath = _relativePath(vaultPath, absolutePath);
    final pathShard = _pathShard(relativePath);
    final pathFile = _pathShardFile(vaultPath, pathShard);
    final pathEntries = await _readEntries(pathFile);
    final previous = pathEntries
        .where((entry) => entry.relativePath == relativePath)
        .toList(growable: false);
    if (previous.isEmpty) return null;

    pathEntries.removeWhere((entry) => entry.relativePath == relativePath);
    await _writeEntries(pathFile, shard: pathShard, records: pathEntries);
    for (final shard
        in previous.map((entry) => _idShard(entry.recordId)).toSet()) {
      final idFile = _idShardFile(vaultPath, shard);
      final entries = await _readEntries(idFile);
      entries.removeWhere((entry) => entry.relativePath == relativePath);
      await _writeEntries(idFile, shard: shard, records: entries);
    }
    await _writeManifest(vaultPath);
    return previous.first.recordId;
  }

  static bool isStableRecordId(String value) =>
      RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value.trim()) &&
      !value.contains('..') &&
      !value.startsWith('path:');

  String _indexRoot(String vaultPath) =>
      p.join(vaultPath, akashaDirName, indexDirName);

  File _manifestFile(String vaultPath) =>
      File(p.join(_indexRoot(vaultPath), manifestFileName));

  File _idShardFile(String vaultPath, String shard) =>
      File(p.join(_indexRoot(vaultPath), idDirName, '$shard.json'));

  File _pathShardFile(String vaultPath, String shard) =>
      File(p.join(_indexRoot(vaultPath), pathDirName, '$shard.json'));

  Future<void> _writeManifest(
    String vaultPath, {
    RecordPathIndexStats? stats,
  }) async {
    final file = _manifestFile(vaultPath);
    final payload = <String, Object?>{
      'version': schemaVersion,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      if (stats != null) ...stats.toJson(),
    };
    await atomicWrite.writeText(target: file, content: jsonEncode(payload));
  }

  Future<List<RecordPathIndexEntry>> _readEntries(File file) async {
    final opened = await atomicWrite.openForRead(
      target: file,
      validateContent: _isValidShardContent,
    );
    if (opened.isMissing) return <RecordPathIndexEntry>[];
    if (opened.isCorrupt) {
      throw DerivedIndexCorruptException(file.path);
    }

    late final Object decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on Object catch (error) {
      throw DerivedIndexCorruptException(file.path, error);
    }
    if (decoded is! Map || decoded['version'] != schemaVersion) {
      throw DerivedIndexCorruptException(file.path);
    }
    final raw = decoded['records'];
    if (raw is! List) {
      throw DerivedIndexCorruptException(file.path);
    }
    try {
      return _sortedUnique(
        raw
            .whereType<Map>()
            .map(
              (value) => RecordPathIndexEntry.fromJson(
                value.map((key, item) => MapEntry(key.toString(), item)),
              ),
            )
            .where(
              (entry) =>
                  isStableRecordId(entry.recordId) &&
                  _isSafeRelativePath(entry.relativePath),
            ),
      );
    } on Object catch (error) {
      throw DerivedIndexCorruptException(file.path, error);
    }
  }

  Future<void> _writeEntries(
    File file, {
    required String shard,
    required Iterable<RecordPathIndexEntry> records,
  }) async {
    final sorted = _sortedUnique(records);
    await atomicWrite.writeText(
      target: file,
      content: jsonEncode({
        'version': schemaVersion,
        'shard': shard,
        'records': sorted.map((entry) => entry.toJson()).toList(),
      }),
    );
  }

  static bool _isValidManifestContent(String content) {
    try {
      final decoded = jsonDecode(content);
      return decoded is Map && decoded['version'] == schemaVersion;
    } on Object {
      return false;
    }
  }

  static bool _isValidShardContent(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map || decoded['version'] != schemaVersion) return false;
      return decoded['records'] is List;
    } on Object {
      return false;
    }
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

  bool _shouldSkipPath(String filePath) => p
      .split(p.normalize(filePath))
      .any(
        (part) =>
            _scanSkipDirNames.contains(part) ||
            (part.startsWith('.') && part != akashaDirName),
      );

  static String _relativePath(String vaultPath, String absolutePath) =>
      p.relative(absolutePath, from: vaultPath).replaceAll('\\', '/');

  static bool _isWithinVault(String vaultPath, String absolutePath) {
    final root = p.normalize(p.absolute(vaultPath));
    final target = p.normalize(p.absolute(absolutePath));
    final relative = p.relative(target, from: root);
    return relative == '.' ||
        (!p.isAbsolute(relative) &&
            relative != '..' &&
            !relative.startsWith('..${p.separator}'));
  }

  static bool _isSafeRelativePath(String relativePath) {
    if (relativePath.trim().isEmpty || p.isAbsolute(relativePath)) return false;
    final normalized = p.normalize(relativePath);
    return normalized != '..' && !normalized.startsWith('..${p.separator}');
  }

  static String _idShard(String recordId) =>
      crypto.sha256.convert(utf8.encode(recordId)).toString().substring(0, 2);

  static String _pathShard(String relativePath) => crypto.sha256
      .convert(utf8.encode(relativePath))
      .toString()
      .substring(0, 2);

  static List<RecordPathIndexEntry> _sortedUnique(
    Iterable<RecordPathIndexEntry> entries,
  ) {
    final byIdentity = <String, RecordPathIndexEntry>{};
    for (final entry in entries) {
      byIdentity[entry.identityKey] = entry;
    }
    final sorted = byIdentity.values.toList()
      ..sort((a, b) => a.identityKey.compareTo(b.identityKey));
    return sorted;
  }
}

class RecordPathIndexEntry {
  const RecordPathIndexEntry({
    required this.recordId,
    required this.relativePath,
  });

  final String recordId;
  final String relativePath;

  String get identityKey => '$recordId\u0000$relativePath';

  Map<String, String> toJson() => {'recordId': recordId, 'path': relativePath};

  factory RecordPathIndexEntry.fromJson(Map<String, dynamic> json) =>
      RecordPathIndexEntry(
        recordId: json['recordId']?.toString().trim() ?? '',
        relativePath: json['path']?.toString().trim() ?? '',
      );
}

class RecordPathIndexLookup {
  const RecordPathIndexLookup({required this.entries, this.isCorrupt = false});

  const RecordPathIndexLookup.empty() : entries = const [], isCorrupt = false;

  const RecordPathIndexLookup.corrupt() : entries = const [], isCorrupt = true;

  final List<RecordPathIndexEntry> entries;
  final bool isCorrupt;

  bool get isFound => !isCorrupt && entries.length == 1;
  bool get isAmbiguous => !isCorrupt && entries.length > 1;
  String? get relativePath => isFound ? entries.single.relativePath : null;
}

class RecordPathIndexStats {
  const RecordPathIndexStats({
    required this.records,
    required this.idShards,
    required this.pathShards,
  });

  final int records;
  final int idShards;
  final int pathShards;

  Map<String, int> toJson() => {
    'records': records,
    'idShards': idShards,
    'pathShards': pathShards,
  };
}
