import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/enums.dart';
import '../models/registry_models.dart';
import '../utils/app_log.dart';
import '../utils/registry_search_utils.dart';
import 'registry_cache_contract.dart';
import 'registry_source.dart';

part 'registry_shard_loader_cache.dart';
part 'registry_shard_loader_search_index.dart';
part 'registry_shard_loader_shards.dart';
part 'registry_shard_loader_sync.dart';

typedef ShardEntriesMerger = void Function(Map<String, dynamic> entries);

// ════════════════════════════════════════════════════════════════
//  AKASHA — 샤딩 레지스트리 로더 (온디맨드 + 캐시)
// ════════════════════════════════════════════════════════════════

abstract class _RegistryShardLoaderBase {
  late final RegistrySource _source;
  late final bool _allowLegacyManifest;
  RegistryManifest? _manifest;
  RegistrySearchIndexManifest? _searchIndexManifest;
  List<RegistrySearchIndexEntry> _searchIndex = [];
  final Map<String, RegistrySearchIndexEntry> _searchIndexByWorkId = {};
  final Map<MediaCategory, List<RegistrySearchIndexEntry>>
  _searchIndexByCategory = {};
  bool _useShardedSearchIndex = false;
  final Map<String, String> _legacyAliases = {};
  final Set<String> _loadedShardIds = {};
  ShardEntriesMerger? _shardEntriesMerger;

  void resetLoadedShards() => _loadedShardIds.clear();

  RegistrySourceException sourceError(
    RegistrySourceFailureType type,
    String relativePath, {
    String? shardId,
    Object? cause,
  }) => RegistrySourceException(
    type: type,
    relativePath: relativePath,
    sourceId: _source.sourceId,
    shardId: shardId,
    releaseId: _manifest?.releaseId,
    cause: cause,
  );

  void verifySha256({
    required String content,
    required String? expected,
    required String relativePath,
    String? shardId,
  }) {
    if (expected == null || expected.isEmpty) return;
    final actual = sha256.convert(utf8.encode(content)).toString();
    if (actual == expected) return;
    throw sourceError(
      RegistrySourceFailureType.manifestMismatch,
      relativePath,
      shardId: shardId,
      cause: 'SHA-256 expected=$expected actual=$actual',
    );
  }
}

class RegistryShardLoader extends _RegistryShardLoaderBase
    with
        _RegistryShardLoaderCache,
        _RegistryShardLoaderSearchIndex,
        _RegistryShardLoaderShards,
        _RegistryShardLoaderSync {
  static const int supportedSchemaVersion = 4;
  static const int supportedShardBits = 8;
  static const String bundledManifestAsset = 'manifest.json';
  static const String bundledSearchIndexAsset = 'search_index.json';
  static const String bundledSearchIndexManifestAsset =
      'search_index/manifest.json';
  static const String bundledLegacyAliasesAsset = 'legacy_aliases.json';
  static const String bundledFranchiseGroupsAsset = 'franchise_groups.json';
  // TODO(remove): R1 — docs/active/LEGACY_REMOVAL_POLICY.md §3.1

  RegistryShardLoader({
    ShardEntriesMerger? shardEntriesMerger,
    RegistrySource? source,
    bool allowLegacyManifest = false,
  }) {
    _shardEntriesMerger = shardEntriesMerger;
    _source = source ?? BundledRegistrySource();
    _allowLegacyManifest = allowLegacyManifest;
  }

  RegistryManifest? get manifest => _manifest;
  RegistrySearchIndexManifest? get searchIndexManifest => _searchIndexManifest;
  List<RegistrySearchIndexEntry> get searchIndex => _searchIndex;
  bool get usesShardedSearchIndex => _useShardedSearchIndex;
  Map<String, String> get legacyAliases => Map.unmodifiable(_legacyAliases);
  RegistrySource get source => _source;

  @visibleForTesting
  set manifestForTesting(RegistryManifest? value) => _manifest = value;

  @visibleForTesting
  void resetLoadedShardsForTesting() {
    _loadedShardIds.clear();
    _searchIndexByCategory.clear();
    _searchIndex = [];
    _searchIndexByWorkId.clear();
    _searchIndexManifest = null;
    _useShardedSearchIndex = false;
  }

  void resetBundleStateForTesting() {
    resetLoadedShardsForTesting();
    _legacyAliases.clear();
    _manifest = null;
  }

  bool isShardLoaded(String shardId) => _loadedShardIds.contains(shardId);

  DateTime? get bundledManifestGeneratedAt =>
      RegistryShardLoader.parseGeneratedAt(_manifest?.generatedAt);

  int? entryCountForShard(String shardId) =>
      _manifest?.shardById(shardId)?.entryCount;

  int qualityScoreFor(String workId) {
    if (workId.isEmpty) return 0;
    return _searchIndexByWorkId[workId]?.qualityScore ?? 0;
  }

  static DateTime? parseGeneratedAt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
