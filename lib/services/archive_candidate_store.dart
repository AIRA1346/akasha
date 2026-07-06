import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/archiving/archive_candidate.dart';
import '../core/archiving/archive_candidate_validator.dart';
import '../core/archiving/entity_anchor.dart';

class ArchiveCandidateIndexStats {
  const ArchiveCandidateIndexStats({
    required this.totalCandidates,
    required this.openCandidates,
    required this.indexedNames,
  });

  final int totalCandidates;
  final int openCandidates;
  final int indexedNames;

  Map<String, dynamic> toJson() => {
    'totalCandidates': totalCandidates,
    'openCandidates': openCandidates,
    'indexedNames': indexedNames,
  };
}

/// Durable candidate layer for agent/import extraction.
///
/// New writes use `.akasha/candidates/{entityType}/{shard}.json` plus a
/// sharded name index so high-volume extraction does not rewrite one large
/// `catalog/candidates.json` file. The old catalog file remains read-compatible.
class ArchiveCandidateStore {
  ArchiveCandidateStore();

  static const int schemaVersion = 1;
  static const String catalogDirName = 'catalog';
  static const String fileName = 'candidates.json';

  static const String akashaDirName = '.akasha';
  static const String candidateDirName = 'candidates';
  static const String nameIndexDirName = 'name_index';
  static const String manifestFileName = 'manifest.json';

  Future<List<ArchiveCandidate>> load(String vaultPath) async {
    if (vaultPath.trim().isEmpty) return const [];

    final byId = <String, ArchiveCandidate>{};
    for (final candidate in await _loadLegacy(vaultPath)) {
      byId[candidate.candidateId] = candidate;
    }
    for (final candidate in await _loadSharded(vaultPath)) {
      byId[candidate.candidateId] = candidate;
    }

    final candidates =
        byId.values
            .where(
              (candidate) => ArchiveCandidateValidator.validateCandidate(
                candidate,
              ).isValid,
            )
            .toList(growable: false)
          ..sort(_compare);
    return candidates;
  }

  Future<List<ArchiveCandidate>> openCandidates(String vaultPath) async {
    final candidates = await load(vaultPath);
    return candidates
        .where(
          (candidate) => candidate.status == ArchiveCandidateStatus.candidate,
        )
        .toList(growable: false);
  }

  Future<ArchiveCandidateIndexStats> rebuildDerivedIndexes(
    String vaultPath,
  ) async {
    if (vaultPath.trim().isEmpty) {
      return const ArchiveCandidateIndexStats(
        totalCandidates: 0,
        openCandidates: 0,
        indexedNames: 0,
      );
    }

    await _maybeMigrateLegacy(vaultPath);
    final candidates = await load(vaultPath);
    final open = candidates
        .where((candidate) => candidate.isOpen)
        .toList(growable: false);

    final nameIndexRoot = Directory(
      p.join(vaultPath, akashaDirName, candidateDirName, nameIndexDirName),
    );
    if (await nameIndexRoot.exists()) {
      await nameIndexRoot.delete(recursive: true);
    }

    final indexedNames = <String>{};
    for (final candidate in open) {
      final names = ArchiveCandidateValidator.normalizedCandidateNames(
        candidate,
      );
      indexedNames.addAll(names);
      await _updateNameIndexForChange(
        vaultPath: vaultPath,
        previous: null,
        next: candidate,
      );
    }

    await _writeManifest(vaultPath);
    return ArchiveCandidateIndexStats(
      totalCandidates: candidates.length,
      openCandidates: open.length,
      indexedNames: indexedNames.length,
    );
  }

  Future<ArchiveCandidate?> lookup(String vaultPath, String candidateId) async {
    final id = candidateId.trim();
    if (id.isEmpty || vaultPath.trim().isEmpty) return null;

    for (final type in _candidateTypesForId(id)) {
      final candidate = await _lookupSharded(vaultPath, type, id);
      if (candidate != null) return candidate;
    }

    for (final candidate in await _loadLegacy(vaultPath)) {
      if (candidate.candidateId == id) return candidate;
    }
    return null;
  }

  Future<void> upsert({
    required String vaultPath,
    required ArchiveCandidate candidate,
  }) async {
    final validation = ArchiveCandidateValidator.validateCandidate(candidate);
    if (!validation.isValid) {
      throw ArgumentError(
        'Invalid archive candidate: '
        '${validation.errors.map((e) => e.code).join(', ')}',
      );
    }

    await _maybeMigrateLegacy(vaultPath);
    final existing = await lookup(vaultPath, candidate.candidateId);
    if (existing != null && existing.entityType != candidate.entityType) {
      throw ArgumentError('candidate entityType must not change.');
    }
    final duplicate = await _findDuplicateCandidate(vaultPath, candidate);
    if (duplicate != null) {
      throw ArgumentError(
        'Duplicate archive candidate: ${duplicate.candidateId}',
      );
    }

    await _writeCandidate(vaultPath, candidate);
    await _updateNameIndexForChange(
      vaultPath: vaultPath,
      previous: existing,
      next: candidate,
    );
    await _writeManifest(vaultPath);
  }

  Future<void> markPromoted({
    required String vaultPath,
    required String candidateId,
    required String entityId,
    DateTime? updatedAt,
  }) async {
    await _updateCandidate(
      vaultPath: vaultPath,
      candidateId: candidateId,
      update: (candidate) =>
          candidate.markPromoted(entityId: entityId, updatedAt: updatedAt),
    );
  }

  Future<void> dismiss({
    required String vaultPath,
    required String candidateId,
    DateTime? updatedAt,
  }) async {
    await _updateCandidate(
      vaultPath: vaultPath,
      candidateId: candidateId,
      update: (candidate) => candidate.markDismissed(updatedAt: updatedAt),
    );
  }

  Future<void> markMerged({
    required String vaultPath,
    required String candidateId,
    required String duplicateOfEntityId,
    DateTime? updatedAt,
  }) async {
    await _updateCandidate(
      vaultPath: vaultPath,
      candidateId: candidateId,
      update: (candidate) => candidate.markMerged(
        duplicateOfEntityId: duplicateOfEntityId,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> _updateCandidate({
    required String vaultPath,
    required String candidateId,
    required ArchiveCandidate Function(ArchiveCandidate candidate) update,
  }) async {
    await _maybeMigrateLegacy(vaultPath);
    final existing = await lookup(vaultPath, candidateId);
    if (existing == null) return;

    final updated = _validateUpdated(update(existing));
    if (updated.candidateId != existing.candidateId) {
      throw ArgumentError('candidateId must not change during update.');
    }

    await _writeCandidate(vaultPath, updated);
    await _updateNameIndexForChange(
      vaultPath: vaultPath,
      previous: existing,
      next: updated,
    );
    await _writeManifest(vaultPath);
  }

  Future<ArchiveCandidate?> _findDuplicateCandidate(
    String vaultPath,
    ArchiveCandidate incoming,
  ) async {
    if (!incoming.isOpen) return null;
    final incomingNames = ArchiveCandidateValidator.normalizedCandidateNames(
      incoming,
    );
    if (incomingNames.isEmpty) return null;

    final candidateIds = <String>{};
    for (final name in incomingNames) {
      candidateIds.addAll(
        await _candidateIdsForName(vaultPath, incoming.entityType, name),
      );
    }

    for (final candidateId in candidateIds) {
      if (candidateId == incoming.candidateId) continue;
      final existing = await lookup(vaultPath, candidateId);
      if (existing == null ||
          !existing.isOpen ||
          existing.entityType != incoming.entityType) {
        continue;
      }
      final existingNames = ArchiveCandidateValidator.normalizedCandidateNames(
        existing,
      );
      if (existingNames.any(incomingNames.contains)) return existing;
    }

    return _findDuplicateCandidateByScan(vaultPath, incoming, incomingNames);
  }

  Future<ArchiveCandidate?> _findDuplicateCandidateByScan(
    String vaultPath,
    ArchiveCandidate incoming,
    Set<String> incomingNames,
  ) async {
    for (final existing in await load(vaultPath)) {
      if (existing.candidateId == incoming.candidateId ||
          existing.entityType != incoming.entityType ||
          !existing.isOpen) {
        continue;
      }
      final existingNames = ArchiveCandidateValidator.normalizedCandidateNames(
        existing,
      );
      if (existingNames.any(incomingNames.contains)) return existing;
    }
    return null;
  }

  Future<List<String>> _candidateIdsForName(
    String vaultPath,
    EntityAnchorType type,
    String normalizedName,
  ) async {
    final index = await _readNameIndex(
      _nameIndexFile(vaultPath, type, _shardFor(normalizedName)),
    );
    final ids = index[normalizedName];
    if (ids == null || ids.isEmpty) return const [];
    return ids.toList(growable: false)..sort();
  }

  Future<void> _updateNameIndexForChange({
    required String vaultPath,
    required ArchiveCandidate? previous,
    required ArchiveCandidate next,
  }) async {
    if (previous != null && previous.isOpen) {
      for (final name in ArchiveCandidateValidator.normalizedCandidateNames(
        previous,
      )) {
        await _removeFromNameIndex(
          vaultPath,
          previous.entityType,
          name,
          previous.candidateId,
        );
      }
    }

    if (next.isOpen) {
      for (final name in ArchiveCandidateValidator.normalizedCandidateNames(
        next,
      )) {
        await _addToNameIndex(
          vaultPath,
          next.entityType,
          name,
          next.candidateId,
        );
      }
    }
  }

  Future<void> _addToNameIndex(
    String vaultPath,
    EntityAnchorType type,
    String normalizedName,
    String candidateId,
  ) async {
    if (normalizedName.isEmpty) return;
    final file = _nameIndexFile(vaultPath, type, _shardFor(normalizedName));
    final index = await _readNameIndex(file);
    index.putIfAbsent(normalizedName, () => <String>{}).add(candidateId);
    await _writeNameIndex(file, type, _shardFor(normalizedName), index);
  }

  Future<void> _removeFromNameIndex(
    String vaultPath,
    EntityAnchorType type,
    String normalizedName,
    String candidateId,
  ) async {
    if (normalizedName.isEmpty) return;
    final shard = _shardFor(normalizedName);
    final file = _nameIndexFile(vaultPath, type, shard);
    final index = await _readNameIndex(file);
    final ids = index[normalizedName];
    if (ids == null) return;

    ids.remove(candidateId);
    if (ids.isEmpty) index.remove(normalizedName);
    await _writeNameIndex(file, type, shard, index);
  }

  Future<void> _writeCandidate(
    String vaultPath,
    ArchiveCandidate candidate,
  ) async {
    if (vaultPath.trim().isEmpty) return;
    final shard = _shardFor(candidate.candidateId);
    final file = _candidateShardFile(vaultPath, candidate.entityType, shard);
    final candidates = await _readCandidateShard(file);
    final next = <ArchiveCandidate>[
      for (final existing in candidates)
        if (existing.candidateId != candidate.candidateId) existing,
      candidate,
    ]..sort(_compare);
    await _writeCandidateShard(file, candidate.entityType, shard, next);
  }

  Future<ArchiveCandidate?> _lookupSharded(
    String vaultPath,
    EntityAnchorType type,
    String candidateId,
  ) async {
    final file = _candidateShardFile(vaultPath, type, _shardFor(candidateId));
    for (final candidate in await _readCandidateShard(file)) {
      if (candidate.candidateId == candidateId) return candidate;
    }
    return null;
  }

  Future<List<ArchiveCandidate>> _loadSharded(String vaultPath) async {
    final candidates = <ArchiveCandidate>[];
    for (final type in EntityAnchorType.values) {
      final dir = Directory(_candidateTypeDir(vaultPath, type));
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        candidates.addAll(await _readCandidateShard(entity));
      }
    }
    return candidates;
  }

  Future<List<ArchiveCandidate>> _readCandidateShard(File file) async {
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const [];
      final raw = decoded['candidates'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (entry) =>
                ArchiveCandidate.fromJson(Map<String, dynamic>.from(entry)),
          )
          .where(
            (candidate) =>
                ArchiveCandidateValidator.validateCandidate(candidate).isValid,
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCandidateShard(
    File file,
    EntityAnchorType type,
    String shard,
    List<ArchiveCandidate> candidates,
  ) async {
    await file.parent.create(recursive: true);
    final payload = <String, dynamic>{
      'version': schemaVersion,
      'storage': 'archiveCandidateShard',
      'entityType': type.name,
      'shard': shard,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
    };
    await _writeJsonAtomic(file, payload);
  }

  Future<Map<String, Set<String>>> _readNameIndex(File file) async {
    if (!await file.exists()) return <String, Set<String>>{};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return <String, Set<String>>{};
      final raw = decoded['names'];
      if (raw is! Map) return <String, Set<String>>{};
      return raw.map((key, value) {
        final ids = value is List
            ? value
                  .map((entry) => entry.toString().trim())
                  .where((entry) => entry.isNotEmpty)
                  .toSet()
            : <String>{};
        return MapEntry(key.toString(), ids);
      });
    } catch (_) {
      return <String, Set<String>>{};
    }
  }

  Future<void> _writeNameIndex(
    File file,
    EntityAnchorType type,
    String shard,
    Map<String, Set<String>> index,
  ) async {
    await file.parent.create(recursive: true);
    final sortedNames = index.keys.toList()..sort();
    final payload = <String, dynamic>{
      'version': schemaVersion,
      'storage': 'archiveCandidateNameIndex',
      'entityType': type.name,
      'shard': shard,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'names': {
        for (final name in sortedNames) name: (index[name]!.toList()..sort()),
      },
    };
    await _writeJsonAtomic(file, payload);
  }

  Future<void> _maybeMigrateLegacy(String vaultPath) async {
    if (vaultPath.trim().isEmpty) return;
    if (await _manifestFile(vaultPath).exists()) return;

    final legacy = await _loadLegacy(vaultPath);
    if (legacy.isEmpty) return;
    for (final candidate in legacy) {
      await _writeCandidate(vaultPath, candidate);
      await _updateNameIndexForChange(
        vaultPath: vaultPath,
        previous: null,
        next: candidate,
      );
    }
    await _writeManifest(vaultPath, migratedLegacy: true);
  }

  Future<void> _writeManifest(
    String vaultPath, {
    bool migratedLegacy = false,
  }) async {
    if (vaultPath.trim().isEmpty) return;
    final file = _manifestFile(vaultPath);
    await file.parent.create(recursive: true);
    final payload = <String, dynamic>{
      'version': schemaVersion,
      'storage': 'archiveCandidateShards',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'legacyCatalogReadCompatible': true,
      if (migratedLegacy)
        'migratedLegacyAt': DateTime.now().toUtc().toIso8601String(),
    };
    await _writeJsonAtomic(file, payload);
  }

  Future<List<ArchiveCandidate>> _loadLegacy(String vaultPath) async {
    if (vaultPath.trim().isEmpty) return const [];
    final file = _legacyFile(vaultPath);
    if (!await file.exists()) return const [];

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const [];
      final raw = decoded['candidates'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (entry) =>
                ArchiveCandidate.fromJson(Map<String, dynamic>.from(entry)),
          )
          .where(
            (candidate) =>
                ArchiveCandidateValidator.validateCandidate(candidate).isValid,
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
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

  File _legacyFile(String vaultPath) =>
      File(p.join(vaultPath, catalogDirName, fileName));

  File _manifestFile(String vaultPath) => File(
    p.join(vaultPath, akashaDirName, candidateDirName, manifestFileName),
  );

  String _candidateTypeDir(String vaultPath, EntityAnchorType type) =>
      p.join(vaultPath, akashaDirName, candidateDirName, type.name);

  File _candidateShardFile(
    String vaultPath,
    EntityAnchorType type,
    String shard,
  ) => File(p.join(_candidateTypeDir(vaultPath, type), '$shard.json'));

  File _nameIndexFile(String vaultPath, EntityAnchorType type, String shard) =>
      File(
        p.join(
          vaultPath,
          akashaDirName,
          candidateDirName,
          nameIndexDirName,
          type.name,
          '$shard.json',
        ),
      );

  static ArchiveCandidate _validateUpdated(ArchiveCandidate candidate) {
    final validation = ArchiveCandidateValidator.validateCandidate(candidate);
    if (!validation.isValid) {
      throw ArgumentError(
        'Invalid archive candidate update: '
        '${validation.errors.map((e) => e.code).join(', ')}',
      );
    }
    return candidate;
  }

  static Iterable<EntityAnchorType> _candidateTypesForId(String candidateId) {
    final preferred = EntityAnchorType.values
        .where((type) => candidateId.startsWith('cand_${type.name}_'))
        .toList(growable: false);
    return [
      ...preferred,
      for (final type in EntityAnchorType.values)
        if (!preferred.contains(type)) type,
    ];
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

  static int _compare(ArchiveCandidate a, ArchiveCandidate b) {
    final status = a.status.name.compareTo(b.status.name);
    if (status != 0) return status;
    final type = _entityTypeOrder(
      a.entityType,
    ).compareTo(_entityTypeOrder(b.entityType));
    if (type != 0) return type;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static int _entityTypeOrder(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.work => 0,
      EntityAnchorType.person => 1,
      EntityAnchorType.organization => 2,
      EntityAnchorType.place => 3,
      EntityAnchorType.event => 4,
      EntityAnchorType.concept => 5,
      EntityAnchorType.object => 6,
      // ignore: deprecated_member_use_from_same_package
      EntityAnchorType.custom => 7,
      EntityAnchorType.phenomenon => 8,
    };
  }
}
