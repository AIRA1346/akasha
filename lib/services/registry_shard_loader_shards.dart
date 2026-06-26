part of 'registry_shard_loader.dart';

mixin _RegistryShardLoaderShards
    on
        _RegistryShardLoaderBase,
        _RegistryShardLoaderCache,
        _RegistryShardLoaderSearchIndex {
  Future<void> loadEagerShards() async {
    final shards = _manifest?.eagerShards() ?? const [];
    for (final shard in shards) {
      await ensureShardLoaded(shard.id);
    }
  }

  /// 번들·캐시에 있는 manifest 전체 shard 적재 (소규모 카탈로그 browse용)
  Future<void> ensureAllManifestShardsLoaded() async {
    final shards = _manifest?.shards ?? const [];
    if (shards.isEmpty) return;
    await Future.wait(shards.map((s) => ensureShardLoaded(s.id)));
  }

  Future<void> ensureShardLoaded(String shardId) async {
    if (shardId.isEmpty || _loadedShardIds.contains(shardId)) return;
    final meta = _manifest?.shardById(shardId);
    if (meta == null) return;

    Map<String, dynamic>? shardMap;

    // 1) 번들 asset (로컬 수정본 우선)
    shardMap = await _readBundledShardMap(meta.path);

    // 2) 디스크 캐시
    shardMap ??= await _readCachedShardMap(meta.path);

    if (shardMap != null) {
      _shardEntriesMerger?.call(shardMap);
      _loadedShardIds.add(shardId);
    }
  }

  Future<void> ensureShardsForQuery(String query) async {
    if (query.trim().isEmpty) return;
    await ensureSearchIndexLoaded();
    for (final id in resolveShardIdsForQuery(query)) {
      await ensureShardLoaded(id);
    }
  }

  Future<void> ensureShardsForFilters({
    AppDomain? domain,
    MediaCategory? category,
  }) async {
    if (_useShardedSearchIndex && category != null) {
      await ensureSearchIndexLoaded(category: category);
    } else if (_useShardedSearchIndex) {
      await ensureSearchIndexLoaded();
    }

    final shardIds = <String>{};
    for (final entry in _entriesForFilters(domain: domain, category: category)) {
      shardIds.add(entry.shardId);
    }
    for (final id in shardIds) {
      await ensureShardLoaded(id);
    }
  }

  /// Phase 2.2 — search_index 품질순 윈도우만 shard 로드 (전체 카탈로그 bulk prefetch 대체)
  Future<void> ensureShardsForBrowseWindow({
    AppDomain? domain,
    MediaCategory? category,
    int offset = 0,
    int limit = 48,
  }) async {
    if (limit <= 0) return;

    if (_useShardedSearchIndex && category != null) {
      await ensureSearchIndexLoaded(category: category);
    } else {
      await ensureSearchIndexLoaded();
    }

    final shardIds = resolveShardIdsForBrowseWindow(
      domain: domain,
      category: category,
      offset: offset,
      limit: limit,
    );
    await Future.wait(shardIds.map(ensureShardLoaded));
  }

  Future<bool> hasBundledShard(String relativePath) async {
    try {
      await rootBundle.loadString('assets/registry/$relativePath');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _readBundledShardMap(String relativePath) async {
    try {
      final raw = await rootBundle.loadString('assets/registry/$relativePath');
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
