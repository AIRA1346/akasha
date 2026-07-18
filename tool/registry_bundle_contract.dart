library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'registry_hash_utils.dart';

/// Exact, reviewed values for the current registry release.
///
/// These are intentionally separate from [CatalogScaleCeilings]. A catalog
/// update advances this snapshot after review; it does not change the point at
/// which the architecture must be reconsidered.
abstract final class CatalogReleaseBaseline {
  static const entryCount = 10048;
  static const manifestShardCount = 1713;
  static const eagerShardCount = 53;
  static const registrySchemaVersion = 4;
  static const canonicalGeneralCultureCount = 0;
  static const missingShardCount = 0;
  static const orphanShardCount = 0;
  static const manifestShaMismatchCount = 0;
}

/// Hard validation ceilings for the JSON-shard/full-bundle architecture.
abstract final class CatalogScaleCeilings {
  static const entryCount = 50000;
  static const shardCount = 1792; // Seven categories * 256 v4 hash buckets.
  static const bundleBytes = 64 * 1024 * 1024;
  static const searchIndexBytes = 32 * 1024 * 1024;
}

enum RegistryBundleMode {
  all('full'),
  eagerOnly('eager-only');

  const RegistryBundleMode(this.metadataValue);
  final String metadataValue;
}

class RegistryBundleSpec {
  const RegistryBundleSpec({
    required this.source,
    required this.output,
    required this.mode,
    required this.sourceRevision,
    String? releaseId,
  }) : releaseId = releaseId ?? 'registry-$sourceRevision';

  final Directory source;
  final Directory output;
  final RegistryBundleMode mode;
  final String sourceRevision;
  final String releaseId;
}

class RegistryCategoryStats {
  const RegistryCategoryStats({required this.works, required this.shards});

  final int works;
  final int shards;
}

class RegistryBundleAudit {
  const RegistryBundleAudit({
    required this.errors,
    required this.entryCount,
    required this.manifestShardCount,
    required this.sourceShardFileCount,
    required this.eagerShardCount,
    required this.registrySchemaVersion,
    required this.registryLogicalBytes,
    required this.searchIndexBytes,
    required this.categoryIndexBytes,
    required this.manifestBytes,
    required this.bundleAssetBytes,
    required this.bundleAssetFileCount,
    required this.bundledShardCount,
    required this.missingBundleShardCount,
    required this.orphanBundleShardCount,
    required this.manifestShaMismatchCount,
    required this.searchShaMismatchCount,
    required this.searchMissingIdCount,
    required this.searchOrphanIdCount,
    required this.canonicalGeneralCultureCount,
    required this.categoryStats,
    required this.releaseId,
    required this.sourceRevision,
    required this.bundleMode,
  });

  final List<String> errors;
  final int entryCount;
  final int manifestShardCount;
  final int sourceShardFileCount;
  final int eagerShardCount;
  final int registrySchemaVersion;
  final int registryLogicalBytes;
  final int searchIndexBytes;
  final int categoryIndexBytes;
  final int manifestBytes;
  final int bundleAssetBytes;
  final int bundleAssetFileCount;
  final int bundledShardCount;
  final int missingBundleShardCount;
  final int orphanBundleShardCount;
  final int manifestShaMismatchCount;
  final int searchShaMismatchCount;
  final int searchMissingIdCount;
  final int searchOrphanIdCount;
  final int canonicalGeneralCultureCount;
  final Map<String, RegistryCategoryStats> categoryStats;
  final String? releaseId;
  final String? sourceRevision;
  final String? bundleMode;

  bool get isValid => errors.isEmpty;

  void throwIfInvalid() {
    if (!isValid) throw RegistryBundleValidationException(errors);
  }
}

class RegistryBundleValidationException implements Exception {
  const RegistryBundleValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() =>
      'Registry bundle validation failed:\n${errors.map((e) => '  - $e').join('\n')}';
}

class RegistryBundleBuilder {
  const RegistryBundleBuilder();

  RegistryBundleAudit build(RegistryBundleSpec spec) {
    _validateSpec(spec);
    final source = _readSource(spec.source);
    if (source.hasFatalErrors) {
      throw RegistryBundleValidationException(source.errors);
    }

    final staging = Directory(
      '${spec.output.path}.staging-$pid-${DateTime.now().microsecondsSinceEpoch}',
    );
    final backup = Directory(
      '${spec.output.path}.backup-$pid-${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      staging.createSync(recursive: true);
      _writeStagingBundle(source, staging, spec);
      final stagedSpec = RegistryBundleSpec(
        source: spec.source,
        output: staging,
        mode: spec.mode,
        sourceRevision: spec.sourceRevision,
        releaseId: spec.releaseId,
      );
      final audit = auditRegistryBundle(stagedSpec);
      audit.throwIfInvalid();
      _replaceOutput(staging: staging, output: spec.output, backup: backup);
      return auditRegistryBundle(spec)..throwIfInvalid();
    } finally {
      if (staging.existsSync()) staging.deleteSync(recursive: true);
      if (backup.existsSync() && spec.output.existsSync()) {
        backup.deleteSync(recursive: true);
      }
    }
  }

  RegistryBundleAudit verify(RegistryBundleSpec spec) {
    _validateSpec(spec);
    return auditRegistryBundle(spec)..throwIfInvalid();
  }

  void _validateSpec(RegistryBundleSpec spec) {
    if (!spec.source.existsSync()) {
      throw ArgumentError('source does not exist: ${spec.source.path}');
    }
    if (spec.sourceRevision.trim().isEmpty) {
      throw ArgumentError('sourceRevision must not be empty');
    }
    if (spec.releaseId.trim().isEmpty) {
      throw ArgumentError('releaseId must not be empty');
    }
    if (p.equals(
      p.normalize(p.absolute(spec.source.path)),
      p.normalize(p.absolute(spec.output.path)),
    )) {
      throw ArgumentError('source and output must be different directories');
    }
  }
}

RegistryBundleAudit auditRegistryBundle(RegistryBundleSpec spec) {
  final source = _readSource(spec.source);
  final errors = <String>[...source.errors];
  final output = spec.output;

  final bundledPaths = _jsonFilesUnder(
    Directory(p.join(output.path, 'shards')),
  ).map((file) => _relative(output, file)).toSet();
  final expectedShardPaths = <String>{
    for (final shard in source.shards)
      if (spec.mode == RegistryBundleMode.all || shard.eager) shard.path,
  };
  final missing = expectedShardPaths.difference(bundledPaths);
  final orphan = bundledPaths.difference(expectedShardPaths);
  for (final path in missing) {
    errors.add('bundle shard missing: $path');
  }
  for (final path in orphan) {
    errors.add('bundle shard orphan: $path');
  }

  var manifestShaMismatchCount = source.manifestShaMismatchCount;
  for (final shard in source.shards) {
    if (!expectedShardPaths.contains(shard.path)) continue;
    final outputFile = File(p.join(output.path, _native(shard.path)));
    if (!outputFile.existsSync()) continue;
    final actual = sha256HexUtf8(
      _canonicalJsonText(outputFile.readAsStringSync()),
    );
    if (actual != shard.sha256) {
      manifestShaMismatchCount++;
      errors.add('bundle shard SHA-256 mismatch: ${shard.path}');
    }
    final sourceFile = File(p.join(spec.source.path, _native(shard.path)));
    if (sourceFile.existsSync() &&
        !_sameCanonicalJson(sourceFile, outputFile)) {
      errors.add('bundle shard differs from source: ${shard.path}');
    }
  }

  final rootManifestFile = File(p.join(output.path, 'manifest.json'));
  final searchManifestFile = File(
    p.join(output.path, 'search_index', 'manifest.json'),
  );
  Map<String, dynamic>? rootManifest;
  Map<String, dynamic>? searchManifest;
  if (!rootManifestFile.existsSync()) {
    errors.add('bundle required file missing: manifest.json');
  } else {
    rootManifest = _readObject(rootManifestFile, errors);
  }
  if (!searchManifestFile.existsSync()) {
    errors.add('bundle required file missing: search_index/manifest.json');
  } else {
    searchManifest = _readObject(searchManifestFile, errors);
  }

  final releaseId = rootManifest?['releaseId']?.toString();
  final sourceRevision = rootManifest?['sourceRevision']?.toString();
  final bundleMode = rootManifest?['bundleMode']?.toString();
  _expectMetadata(
    errors,
    label: 'root manifest',
    manifest: rootManifest,
    spec: spec,
    sourceSchemaVersion: source.schemaVersion,
  );
  _expectMetadata(
    errors,
    label: 'search manifest',
    manifest: searchManifest,
    spec: spec,
    sourceSchemaVersion: source.schemaVersion,
  );
  if (rootManifest != null && searchManifest != null) {
    for (final key in [
      'releaseId',
      'sourceRevision',
      'schemaVersion',
      'bundleMode',
    ]) {
      if (rootManifest[key] != searchManifest[key]) {
        errors.add('root/search manifest provenance differs for $key');
      }
    }
    if (!_jsonEqual(_withoutProvenance(rootManifest), source.rootManifest)) {
      errors.add('bundle root manifest content differs from source');
    }
    if (!_jsonEqual(
      _withoutProvenance(searchManifest),
      source.searchManifest,
    )) {
      errors.add('bundle search manifest content differs from source');
    }
  }

  final requiredCopies = <String>[
    'search_index.json',
    'legacy_aliases.json',
    'franchise_groups.json',
  ];
  for (final relative in requiredCopies) {
    final sourceFile = File(p.join(spec.source.path, _native(relative)));
    final outputFile = File(p.join(output.path, _native(relative)));
    if (!outputFile.existsSync()) {
      errors.add('bundle required file missing: $relative');
    } else if (sourceFile.existsSync() &&
        !_sameCanonicalJson(sourceFile, outputFile)) {
      errors.add('bundle file differs from source: $relative');
    }
  }

  var searchShaMismatchCount = source.searchShaMismatchCount;
  for (final searchShard in source.searchShards) {
    final outputFile = File(p.join(output.path, _native(searchShard.path)));
    if (!outputFile.existsSync()) {
      errors.add('bundle search shard missing: ${searchShard.path}');
      continue;
    }
    final decoded = _readList(outputFile, errors);
    if (decoded == null) continue;
    final actual = sha256HexUtf8(jsonEncode(decoded));
    if (actual != searchShard.sha256) {
      searchShaMismatchCount++;
      errors.add('bundle search shard SHA-256 mismatch: ${searchShard.path}');
    }
    final sourceFile = File(
      p.join(spec.source.path, _native(searchShard.path)),
    );
    if (sourceFile.existsSync() &&
        !_sameCanonicalJson(sourceFile, outputFile)) {
      errors.add(
        'bundle search shard differs from source: ${searchShard.path}',
      );
    }
  }

  final allowedFiles = <String>{
    'manifest.json',
    ...requiredCopies,
    'search_index/manifest.json',
    for (final shard in source.searchShards) shard.path,
    ...expectedShardPaths,
  };
  final actualFiles = output.existsSync()
      ? output
            .listSync(recursive: true)
            .whereType<File>()
            .map((file) => _relative(output, file))
            .toSet()
      : <String>{};
  for (final path in actualFiles.difference(allowedFiles)) {
    errors.add('bundle file is not allowlisted: $path');
  }

  final bundleAssetBytes = actualFiles.fold<int>(0, (sum, relative) {
    final file = File(p.join(output.path, _native(relative)));
    return sum + (file.existsSync() ? file.lengthSync() : 0);
  });

  return RegistryBundleAudit(
    errors: List.unmodifiable(errors),
    entryCount: source.entryCount,
    manifestShardCount: source.shards.length,
    sourceShardFileCount: source.sourceShardFileCount,
    eagerShardCount: source.shards.where((s) => s.eager).length,
    registrySchemaVersion: source.schemaVersion,
    registryLogicalBytes: source.registryLogicalBytes,
    searchIndexBytes: source.searchIndexBytes,
    categoryIndexBytes: source.categoryIndexBytes,
    manifestBytes: source.manifestBytes,
    bundleAssetBytes: bundleAssetBytes,
    bundleAssetFileCount: actualFiles.length,
    bundledShardCount: bundledPaths.length,
    missingBundleShardCount: missing.length,
    orphanBundleShardCount: orphan.length,
    manifestShaMismatchCount: manifestShaMismatchCount,
    searchShaMismatchCount: searchShaMismatchCount,
    searchMissingIdCount: source.searchMissingIdCount,
    searchOrphanIdCount: source.searchOrphanIdCount,
    canonicalGeneralCultureCount: source.generalCultureCount,
    categoryStats: Map.unmodifiable(source.categoryStats),
    releaseId: releaseId,
    sourceRevision: sourceRevision,
    bundleMode: bundleMode,
  );
}

String registryDirectoryDigest(Directory directory) {
  final files = directory.existsSync()
      ? directory.listSync(recursive: true).whereType<File>().toList()
      : <File>[];
  files.sort(
    (a, b) => _relative(directory, a).compareTo(_relative(directory, b)),
  );
  final bytes = BytesBuilder(copy: false);
  for (final file in files) {
    bytes.add(utf8.encode(_relative(directory, file)));
    bytes.addByte(0);
    final content = file.path.toLowerCase().endsWith('.json')
        ? utf8.encode(_canonicalJsonText(file.readAsStringSync()))
        : file.readAsBytesSync();
    bytes.add(content);
    bytes.addByte(0);
  }
  return sha256.convert(bytes.takeBytes()).toString();
}

void _writeStagingBundle(
  _SourceRegistry source,
  Directory staging,
  RegistryBundleSpec spec,
) {
  final rootManifest = Map<String, dynamic>.from(source.rootManifest)
    ..['releaseId'] = spec.releaseId
    ..['sourceRevision'] = spec.sourceRevision
    ..['schemaVersion'] = source.schemaVersion
    ..['bundleMode'] = spec.mode.metadataValue;
  final searchManifest = Map<String, dynamic>.from(source.searchManifest)
    ..['releaseId'] = spec.releaseId
    ..['sourceRevision'] = spec.sourceRevision
    ..['schemaVersion'] = source.schemaVersion
    ..['bundleMode'] = spec.mode.metadataValue;

  _writeJson(File(p.join(staging.path, 'manifest.json')), rootManifest);
  _writeJson(
    File(p.join(staging.path, 'search_index', 'manifest.json')),
    searchManifest,
  );

  for (final relative in [
    'search_index.json',
    'legacy_aliases.json',
    'franchise_groups.json',
    for (final shard in source.searchShards) shard.path,
    for (final shard in source.shards)
      if (spec.mode == RegistryBundleMode.all || shard.eager) shard.path,
  ]) {
    _copyRequired(source.root, staging, relative);
  }
}

void _replaceOutput({
  required Directory staging,
  required Directory output,
  required Directory backup,
}) {
  output.parent.createSync(recursive: true);
  var movedOldOutput = false;
  try {
    if (output.existsSync()) {
      output.renameSync(backup.path);
      movedOldOutput = true;
    }
    staging.renameSync(output.path);
    if (movedOldOutput && backup.existsSync()) {
      try {
        backup.deleteSync(recursive: true);
      } on FileSystemException {
        // The verified output is already committed. A stale, uniquely named
        // backup is safer than reporting a failed build after changing output.
      }
    }
  } catch (_) {
    if (!output.existsSync() && movedOldOutput && backup.existsSync()) {
      backup.renameSync(output.path);
    }
    rethrow;
  }
}

void _copyRequired(Directory source, Directory output, String relative) {
  final from = File(p.join(source.path, _native(relative)));
  if (!from.existsSync()) {
    throw RegistryBundleValidationException([
      'source required file missing: $relative',
    ]);
  }
  final to = File(p.join(output.path, _native(relative)));
  to.parent.createSync(recursive: true);
  to.writeAsStringSync(_canonicalJsonText(from.readAsStringSync()));
}

void _expectMetadata(
  List<String> errors, {
  required String label,
  required Map<String, dynamic>? manifest,
  required RegistryBundleSpec spec,
  required int sourceSchemaVersion,
}) {
  if (manifest == null) return;
  final expected = <String, Object>{
    'releaseId': spec.releaseId,
    'sourceRevision': spec.sourceRevision,
    'schemaVersion': sourceSchemaVersion,
    'bundleMode': spec.mode.metadataValue,
  };
  for (final entry in expected.entries) {
    if (manifest[entry.key] != entry.value) {
      errors.add(
        '$label ${entry.key} is ${manifest[entry.key]} (expected ${entry.value})',
      );
    }
  }
}

_SourceRegistry _readSource(Directory source) {
  final errors = <String>[];
  final fatalErrors = <String>[];
  final rootManifestFile = File(p.join(source.path, 'manifest.json'));
  final searchManifestFile = File(
    p.join(source.path, 'search_index', 'manifest.json'),
  );
  final rootManifest = _readObject(rootManifestFile, fatalErrors) ?? {};
  final searchManifest = _readObject(searchManifestFile, fatalErrors) ?? {};
  final schemaVersion = _int(rootManifest['version']);
  final declaredEntryCount = _int(rootManifest['entryCount']);
  final shardMaps = (rootManifest['shards'] as List?) ?? const [];
  final shards = <_Shard>[];
  final workIds = <String>{};
  final workShardIds = <String, String>{};
  final categoryWorks = <String, int>{};
  final categoryShards = <String, int>{};
  final seenShardIds = <String>{};
  final seenShardPaths = <String>{};
  var generalCultureCount = 0;
  var manifestShaMismatchCount = 0;
  var registryLogicalBytes = 0;

  for (final value in shardMaps) {
    if (value is! Map) {
      errors.add('source manifest contains a non-object shard declaration');
      continue;
    }
    final map = Map<String, dynamic>.from(value);
    final shard = _Shard(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      path: _slash(map['path']?.toString() ?? ''),
      eager: map['eager'] == true,
      entryCount: _int(map['entryCount']),
      sha256: map['sha256']?.toString() ?? '',
    );
    shards.add(shard);
    if (!seenShardIds.add(shard.id)) {
      errors.add('duplicate source shard id: ${shard.id}');
    }
    if (!seenShardPaths.add(shard.path)) {
      errors.add('duplicate source shard path: ${shard.path}');
    }
    final idPrefix = '${shard.category}_';
    final hex = shard.id.startsWith(idPrefix)
        ? shard.id.substring(idPrefix.length)
        : '';
    if (!isV4ShardFileName(hex) ||
        shard.path != v4ShardPath(shard.category, hex)) {
      errors.add('source v4 shard id/path mismatch: ${shard.id} ${shard.path}');
    }
    categoryShards.update(
      shard.category,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    final file = File(p.join(source.path, _native(shard.path)));
    if (!file.existsSync()) {
      errors.add('source manifest shard missing: ${shard.path}');
      continue;
    }
    registryLogicalBytes += file.lengthSync();
    final raw = _canonicalJsonText(file.readAsStringSync());
    if (sha256HexUtf8(raw) != shard.sha256) {
      manifestShaMismatchCount++;
      errors.add('source manifest SHA-256 mismatch: ${shard.path}');
    }
    final decoded = _decode(raw, file.path, errors);
    if (decoded is! Map) {
      errors.add('source shard root is not an object: ${shard.path}');
      continue;
    }
    if (decoded.length != shard.entryCount) {
      errors.add(
        'source shard entryCount mismatch: ${shard.path} '
        '${decoded.length} != ${shard.entryCount}',
      );
    }
    for (final entry in decoded.entries) {
      final workId = entry.key.toString();
      if (!workIds.add(workId)) errors.add('duplicate source workId: $workId');
      workShardIds[workId] = shard.id;
      if (shardHexForWorkId(workId) != hex) {
        errors.add(
          'source work is in the wrong hash shard: $workId ${shard.id}',
        );
      }
      if (entry.value is Map) {
        final work = entry.value as Map;
        final category = work['category']?.toString() ?? shard.category;
        if (category != shard.category) {
          errors.add(
            'source work category differs from shard: $workId '
            '$category != ${shard.category}',
          );
        }
        categoryWorks.update(category, (value) => value + 1, ifAbsent: () => 1);
        if (work['domain']?.toString() == 'generalCulture') {
          generalCultureCount++;
        }
      }
    }
  }

  final actualShardFiles = _jsonFilesUnder(
    Directory(p.join(source.path, 'shards')),
  );
  final declaredPaths = shards.map((s) => s.path).toSet();
  final actualPaths = actualShardFiles.map((f) => _relative(source, f)).toSet();
  for (final missing in declaredPaths.difference(actualPaths)) {
    errors.add('source shard missing from filesystem: $missing');
  }
  for (final orphan in actualPaths.difference(declaredPaths)) {
    errors.add('source shard not declared by manifest: $orphan');
  }
  if (declaredEntryCount != workIds.length) {
    errors.add(
      'source entryCount $declaredEntryCount != shard records ${workIds.length}',
    );
  }

  final searchShardMaps = (searchManifest['shards'] as List?) ?? const [];
  final searchShards = <_SearchShard>[];
  final searchIds = <String>{};
  final seenSearchCategories = <String>{};
  final seenSearchPaths = <String>{};
  var searchShaMismatchCount = 0;
  var categoryIndexBytes = 0;
  for (final value in searchShardMaps) {
    if (value is! Map) {
      errors.add('source search manifest contains a non-object shard');
      continue;
    }
    final map = Map<String, dynamic>.from(value);
    final shard = _SearchShard(
      category: map['category']?.toString() ?? '',
      path: _slash(map['path']?.toString() ?? ''),
      entryCount: _int(map['entryCount']),
      sha256: map['sha256']?.toString() ?? '',
    );
    searchShards.add(shard);
    if (!seenSearchCategories.add(shard.category)) {
      errors.add('duplicate source search category: ${shard.category}');
    }
    if (!seenSearchPaths.add(shard.path)) {
      errors.add('duplicate source search path: ${shard.path}');
    }
    final file = File(p.join(source.path, _native(shard.path)));
    if (!file.existsSync()) {
      errors.add('source search shard missing: ${shard.path}');
      continue;
    }
    categoryIndexBytes += file.lengthSync();
    registryLogicalBytes += file.lengthSync();
    final decoded = _readList(file, errors);
    if (decoded == null) continue;
    if (decoded.length != shard.entryCount) {
      errors.add(
        'source search entryCount mismatch: ${shard.path} '
        '${decoded.length} != ${shard.entryCount}',
      );
    }
    if (sha256HexUtf8(jsonEncode(decoded)) != shard.sha256) {
      searchShaMismatchCount++;
      errors.add('source search SHA-256 mismatch: ${shard.path}');
    }
    for (final value in decoded) {
      if (value is! Map) continue;
      final workId = value['workId']?.toString() ?? '';
      if (workId.isEmpty) {
        errors.add('source search entry missing workId: ${shard.path}');
      } else if (!searchIds.add(workId)) {
        errors.add('duplicate source search workId: $workId');
      }
      if (value['category']?.toString() != shard.category) {
        errors.add('source search category mismatch: $workId ${shard.path}');
      }
      final expectedShardId = workShardIds[workId];
      if (expectedShardId != null &&
          value['shardId']?.toString() != expectedShardId) {
        errors.add('source search shardId mismatch: $workId');
      }
    }
  }
  final searchMissing = workIds.difference(searchIds);
  final searchOrphans = searchIds.difference(workIds);
  if (searchMissing.isNotEmpty) {
    errors.add(
      'source search index misses ${searchMissing.length} shard workId(s)',
    );
  }
  if (searchOrphans.isNotEmpty) {
    errors.add(
      'source search index has ${searchOrphans.length} orphan workId(s)',
    );
  }
  if (_int(searchManifest['entryCount']) != searchIds.length) {
    errors.add(
      'source search entryCount ${searchManifest['entryCount']} '
      '!= indexed records ${searchIds.length}',
    );
  }
  if (rootManifest['generatedAt'] != searchManifest['generatedAt']) {
    errors.add('source root/search generatedAt values differ');
  }

  final masterSearch = File(p.join(source.path, 'search_index.json'));
  final aliases = File(p.join(source.path, 'legacy_aliases.json'));
  final franchises = File(p.join(source.path, 'franchise_groups.json'));
  for (final file in [masterSearch, aliases, franchises]) {
    if (!file.existsSync()) {
      fatalErrors.add('source required file missing: ${file.path}');
    }
  }
  final searchIndexBytes = masterSearch.existsSync()
      ? masterSearch.lengthSync()
      : 0;
  if (masterSearch.existsSync()) {
    final masterEntries = _readList(masterSearch, errors);
    if (masterEntries != null) {
      final masterIds = <String>{
        for (final value in masterEntries)
          if (value is Map && value['workId'] != null)
            value['workId'].toString(),
      };
      final missing = workIds.difference(masterIds).length;
      final orphan = masterIds.difference(workIds).length;
      final duplicates = masterEntries.length - masterIds.length;
      if (missing != 0 || orphan != 0 || duplicates != 0) {
        errors.add(
          'source master search IDs differ from shards: '
          'missing=$missing orphan=$orphan duplicates=$duplicates',
        );
      }
    }
  }
  final manifestBytes = rootManifestFile.existsSync()
      ? rootManifestFile.lengthSync()
      : 0;
  registryLogicalBytes += searchIndexBytes;
  registryLogicalBytes += manifestBytes;
  if (searchManifestFile.existsSync()) {
    registryLogicalBytes += searchManifestFile.lengthSync();
  }
  if (aliases.existsSync()) registryLogicalBytes += aliases.lengthSync();
  if (franchises.existsSync()) registryLogicalBytes += franchises.lengthSync();

  final categoryStats = <String, RegistryCategoryStats>{};
  final categories = {...categoryWorks.keys, ...categoryShards.keys}.toList()
    ..sort();
  for (final category in categories) {
    categoryStats[category] = RegistryCategoryStats(
      works: categoryWorks[category] ?? 0,
      shards: categoryShards[category] ?? 0,
    );
  }

  return _SourceRegistry(
    root: source,
    rootManifest: rootManifest,
    searchManifest: searchManifest,
    shards: shards,
    searchShards: searchShards,
    entryCount: declaredEntryCount,
    schemaVersion: schemaVersion,
    sourceShardFileCount: actualShardFiles.length,
    registryLogicalBytes: registryLogicalBytes,
    searchIndexBytes: searchIndexBytes,
    categoryIndexBytes: categoryIndexBytes,
    manifestBytes: manifestBytes,
    generalCultureCount: generalCultureCount,
    manifestShaMismatchCount: manifestShaMismatchCount,
    searchShaMismatchCount: searchShaMismatchCount,
    searchMissingIdCount: searchMissing.length,
    searchOrphanIdCount: searchOrphans.length,
    categoryStats: categoryStats,
    errors: [...fatalErrors, ...errors],
    hasFatalErrors: fatalErrors.isNotEmpty,
  );
}

class _SourceRegistry {
  const _SourceRegistry({
    required this.root,
    required this.rootManifest,
    required this.searchManifest,
    required this.shards,
    required this.searchShards,
    required this.entryCount,
    required this.schemaVersion,
    required this.sourceShardFileCount,
    required this.registryLogicalBytes,
    required this.searchIndexBytes,
    required this.categoryIndexBytes,
    required this.manifestBytes,
    required this.generalCultureCount,
    required this.manifestShaMismatchCount,
    required this.searchShaMismatchCount,
    required this.searchMissingIdCount,
    required this.searchOrphanIdCount,
    required this.categoryStats,
    required this.errors,
    required this.hasFatalErrors,
  });

  final Directory root;
  final Map<String, dynamic> rootManifest;
  final Map<String, dynamic> searchManifest;
  final List<_Shard> shards;
  final List<_SearchShard> searchShards;
  final int entryCount;
  final int schemaVersion;
  final int sourceShardFileCount;
  final int registryLogicalBytes;
  final int searchIndexBytes;
  final int categoryIndexBytes;
  final int manifestBytes;
  final int generalCultureCount;
  final int manifestShaMismatchCount;
  final int searchShaMismatchCount;
  final int searchMissingIdCount;
  final int searchOrphanIdCount;
  final Map<String, RegistryCategoryStats> categoryStats;
  final List<String> errors;
  final bool hasFatalErrors;
}

class _Shard {
  const _Shard({
    required this.id,
    required this.category,
    required this.path,
    required this.eager,
    required this.entryCount,
    required this.sha256,
  });

  final String id;
  final String category;
  final String path;
  final bool eager;
  final int entryCount;
  final String sha256;
}

class _SearchShard {
  const _SearchShard({
    required this.category,
    required this.path,
    required this.entryCount,
    required this.sha256,
  });

  final String category;
  final String path;
  final int entryCount;
  final String sha256;
}

Map<String, dynamic>? _readObject(File file, List<String> errors) {
  if (!file.existsSync()) {
    errors.add('required JSON file missing: ${file.path}');
    return null;
  }
  final decoded = _decode(file.readAsStringSync(), file.path, errors);
  if (decoded is! Map) {
    errors.add('JSON root is not an object: ${file.path}');
    return null;
  }
  return Map<String, dynamic>.from(decoded);
}

List<dynamic>? _readList(File file, List<String> errors) {
  if (!file.existsSync()) {
    errors.add('required JSON file missing: ${file.path}');
    return null;
  }
  final decoded = _decode(file.readAsStringSync(), file.path, errors);
  if (decoded is! List) {
    errors.add('JSON root is not a list: ${file.path}');
    return null;
  }
  return decoded;
}

Object? _decode(String raw, String path, List<String> errors) {
  try {
    return jsonDecode(raw);
  } on FormatException catch (error) {
    errors.add('invalid JSON $path: ${error.message}');
    return null;
  }
}

List<File> _jsonFilesUnder(Directory directory) {
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.json'))
      .toList();
}

void _writeJson(File file, Object value) {
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}

bool _sameCanonicalJson(File source, File output) =>
    _canonicalJsonText(source.readAsStringSync()) ==
    _canonicalJsonText(output.readAsStringSync());

String _canonicalJsonText(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

bool _jsonEqual(Object? first, Object? second) =>
    jsonEncode(first) == jsonEncode(second);

Map<String, dynamic> _withoutProvenance(Map<String, dynamic> manifest) =>
    Map<String, dynamic>.from(manifest)
      ..remove('releaseId')
      ..remove('sourceRevision')
      ..remove('schemaVersion')
      ..remove('bundleMode');

int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

String _relative(Directory root, File file) =>
    _slash(p.relative(file.path, from: root.path));

String _slash(String value) => value.replaceAll('\\', '/');

String _native(String value) => value.replaceAll('/', Platform.pathSeparator);
