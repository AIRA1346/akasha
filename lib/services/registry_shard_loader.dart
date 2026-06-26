import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/enums.dart';
import '../models/registry_models.dart';
import '../utils/app_log.dart';
import '../utils/registry_search_utils.dart';

part 'registry_shard_loader_cache.dart';
part 'registry_shard_loader_search_index.dart';
part 'registry_shard_loader_shards.dart';
part 'registry_shard_loader_sync.dart';

typedef ShardEntriesMerger = void Function(Map<String, dynamic> entries);

// ════════════════════════════════════════════════════════════════
//  AKASHA — 샤딩 레지스트리 로더 (온디맨드 + 캐시)
// ════════════════════════════════════════════════════════════════

abstract class _RegistryShardLoaderBase {
  RegistryManifest? _manifest;
  RegistrySearchIndexManifest? _searchIndexManifest;
  List<RegistrySearchIndexEntry> _searchIndex = [];
  final Map<String, RegistrySearchIndexEntry> _searchIndexByWorkId = {};
  final Map<MediaCategory, List<RegistrySearchIndexEntry>> _searchIndexByCategory =
      {};
  bool _useShardedSearchIndex = false;
  final Map<String, String> _legacyAliases = {};
  final Set<String> _loadedShardIds = {};
  ShardEntriesMerger? _shardEntriesMerger;

  void resetLoadedShards() => _loadedShardIds.clear();
}

class RegistryShardLoader extends _RegistryShardLoaderBase
    with
        _RegistryShardLoaderCache,
        _RegistryShardLoaderSearchIndex,
        _RegistryShardLoaderShards,
        _RegistryShardLoaderSync {
  static const String bundledManifestAsset = 'assets/registry/manifest.json';
  static const String bundledSearchIndexAsset = 'assets/registry/search_index.json';
  static const String bundledSearchIndexManifestAsset =
      'assets/registry/search_index/manifest.json';
  static const String bundledLegacyAliasesAsset = 'assets/registry/legacy_aliases.json';
  // TODO(remove): R1 — docs/draft/LEGACY_REMOVAL_POLICY.md §3.1

  RegistryShardLoader({ShardEntriesMerger? shardEntriesMerger}) {
    _shardEntriesMerger = shardEntriesMerger;
  }

  RegistryManifest? get manifest => _manifest;
  RegistrySearchIndexManifest? get searchIndexManifest => _searchIndexManifest;
  List<RegistrySearchIndexEntry> get searchIndex => _searchIndex;
  bool get usesShardedSearchIndex => _useShardedSearchIndex;
  Map<String, String> get legacyAliases => Map.unmodifiable(_legacyAliases);

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
