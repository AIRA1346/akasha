part of 'registry_shard_loader.dart';

mixin _RegistryShardLoaderSearchIndex
    on _RegistryShardLoaderBase, _RegistryShardLoaderCache {
  Set<String> resolveShardIdsForQuery(String query) =>
      shardIdsForQuery(_searchIndex, query);

  Set<String> resolveShardIdsForFilters({
    AppDomain? domain,
    MediaCategory? category,
  }) => shardIdsForFilters(_searchIndex, domain: domain, category: category);

  Future<void> _loadBundledSearchIndex() async {
    if (await _tryLoadBundledSearchIndexManifest()) return;

    if (!_allowLegacyManifest) {
      throw sourceError(
        RegistrySourceFailureType.missing,
        RegistryShardLoader.bundledSearchIndexManifestAsset,
      );
    }
    final raw = await _source.readRequired(
      RegistryShardLoader.bundledSearchIndexAsset,
    );
    _parseMonolithicSearchIndex(raw);
  }

  Future<bool> _tryLoadBundledSearchIndexManifest() async {
    final path = RegistryShardLoader.bundledSearchIndexManifestAsset;
    if (!await _source.exists(path)) return false;
    try {
      final raw = await _source.readRequired(path);
      _searchIndexManifest = RegistrySearchIndexManifest.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
      _useShardedSearchIndex = true;
      return true;
    } catch (error) {
      if (error is RegistrySourceException) rethrow;
      throw sourceError(
        RegistrySourceFailureType.malformedJson,
        path,
        cause: error,
      );
    }
  }

  void _parseMonolithicSearchIndex(String raw) {
    final decoded = json.decode(raw);
    if (decoded is List) {
      _searchIndex = _parseSearchIndexList(decoded);
      _rebuildSearchIndexWorkIdMap();
      _useShardedSearchIndex = false;
    }
  }

  List<RegistrySearchIndexEntry> _parseSearchIndexList(Object? decoded) {
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map(
          (e) =>
              RegistrySearchIndexEntry.fromJson(Map<String, dynamic>.from(e)),
        )
        .where((e) => e.workId.isNotEmpty)
        .toList();
  }

  /// sharded search_index — manifest만 로드된 상태에서 category shard를 적재합니다.
  Future<void> ensureSearchIndexLoaded({MediaCategory? category}) async {
    if (!_useShardedSearchIndex || _searchIndexManifest == null) return;

    if (category != null) {
      await _ensureCategorySearchIndexLoaded(category, bundled: true);
      _rebuildMergedSearchIndex();
      return;
    }

    final expected = _searchIndexManifest!.entryCount;
    if (_searchIndex.length >= expected && expected > 0) return;

    await Future.wait(
      _searchIndexManifest!.shards.map(
        (shard) =>
            _ensureCategorySearchIndexLoaded(shard.category, bundled: true),
      ),
    );
    _rebuildMergedSearchIndex();
  }

  Future<void> _ensureCategorySearchIndexLoaded(
    MediaCategory category, {
    required bool bundled,
  }) async {
    if (_searchIndexByCategory.containsKey(category)) return;

    final shard = _searchIndexManifest?.shardForCategory(category);
    if (shard == null || shard.path.isEmpty) {
      _searchIndexByCategory[category] = const [];
      return;
    }

    String? raw;
    if (bundled) {
      raw = await _source.readRequired(shard.path);
    } else {
      raw = await _readCachedText(shard.path);
    }

    if (raw == null) {
      _searchIndexByCategory[category] = const [];
      return;
    }

    try {
      final decoded = json.decode(raw);
      if (decoded is! List) {
        throw const FormatException('search index shard must be a JSON list');
      }
      if (bundled) {
        // Search-index manifests hash the builder's compact JSON encoding,
        // independent of whitespace and line endings in the packaged asset.
        verifySha256(
          content: jsonEncode(decoded),
          expected: shard.sha256,
          relativePath: shard.path,
        );
      }
      _searchIndexByCategory[category] = _parseSearchIndexList(decoded);
    } on RegistrySourceException {
      rethrow;
    } catch (error) {
      throw sourceError(
        RegistrySourceFailureType.malformedJson,
        shard.path,
        cause: error,
      );
    }
  }

  void _rebuildMergedSearchIndex() {
    if (_searchIndexByCategory.isEmpty) return;
    _searchIndex = _searchIndexByCategory.values.expand((e) => e).toList();
    _rebuildSearchIndexWorkIdMap();
  }

  void _rebuildSearchIndexWorkIdMap() {
    _searchIndexByWorkId
      ..clear()
      ..addEntries(_searchIndex.map((entry) => MapEntry(entry.workId, entry)));
  }

  Iterable<RegistrySearchIndexEntry> _entriesForFilters({
    AppDomain? domain,
    MediaCategory? category,
  }) {
    Iterable<RegistrySearchIndexEntry> entries;
    if (_useShardedSearchIndex &&
        category != null &&
        _searchIndexByCategory.containsKey(category)) {
      entries = _searchIndexByCategory[category] ?? const [];
    } else {
      entries = _searchIndex;
    }

    return entries.where((entry) {
      if (domain != null && entry.domain != domain) return false;
      if (category != null && entry.category != category) return false;
      return true;
    });
  }

  Future<void> _loadCachedSearchIndex() async {
    if (await _tryLoadCachedSearchIndexManifest()) return;

    try {
      final file = await _cacheFile('search_index.json');
      if (await file.exists()) {
        _parseMonolithicSearchIndex(await file.readAsString());
      }
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to load cached search index: $e');
    }
  }

  Future<bool> _tryLoadCachedSearchIndexManifest() async {
    try {
      final file = await _cacheFile('search_index/manifest.json');
      if (!await file.exists()) return false;
      _searchIndexManifest = RegistrySearchIndexManifest.fromJson(
        json.decode(await file.readAsString()) as Map<String, dynamic>,
      );
      _useShardedSearchIndex = true;

      await Future.wait(
        _searchIndexManifest!.shards.map(
          (shard) =>
              _ensureCategorySearchIndexLoaded(shard.category, bundled: false),
        ),
      );
      _rebuildMergedSearchIndex();
      return true;
    } catch (e) {
      appLog(
        '[RegistryShardLoader] Failed to load cached search index manifest: $e',
      );
      return false;
    }
  }

  Future<bool> cacheRemoteSearchIndex(String content) async {
    try {
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        return await cacheRemoteSearchIndexManifest(content);
      }
      if (decoded is List) {
        _parseMonolithicSearchIndex(content);
        final file = await _cacheFile('search_index.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
        return true;
      }
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to cache remote search index: $e');
    }
    return false;
  }

  Future<bool> cacheRemoteSearchIndexManifest(String content) async {
    try {
      _searchIndexManifest = RegistrySearchIndexManifest.fromJson(
        json.decode(content) as Map<String, dynamic>,
      );
      _useShardedSearchIndex = true;
      _searchIndexByCategory.clear();
      _searchIndex = [];
      _searchIndexByWorkId.clear();
      final file = await _cacheFile('search_index/manifest.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      appLog(
        '[RegistryShardLoader] Failed to cache remote search index manifest: $e',
      );
    }
    return false;
  }

  Future<bool> cacheRemoteSearchIndexShard(
    String relativePath,
    String content,
  ) async {
    try {
      final decoded = json.decode(content);
      if (decoded is! List) return false;

      final file = await _cacheFile(relativePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(content);

      if (_useShardedSearchIndex && _searchIndexManifest != null) {
        final categoryName = p.basenameWithoutExtension(relativePath);
        final category = MediaCategory.values.firstWhere(
          (e) => e.name == categoryName,
          orElse: () => MediaCategory.manga,
        );
        _searchIndexByCategory[category] = _parseSearchIndexList(decoded);
        _rebuildMergedSearchIndex();
      }
      return true;
    } catch (e) {
      appLog(
        '[RegistryShardLoader] Failed to cache remote search index shard $relativePath: $e',
      );
    }
    return false;
  }

  Set<String> resolveShardIdsForBrowseWindow({
    AppDomain? domain,
    MediaCategory? category,
    int offset = 0,
    int limit = 48,
  }) {
    if (limit <= 0) return const {};

    final entries =
        _entriesForFilters(domain: domain, category: category).toList()
          ..sort((a, b) {
            final score = b.qualityScore.compareTo(a.qualityScore);
            if (score != 0) return score;
            return a.title.compareTo(b.title);
          });

    final shardIds = <String>{};
    for (final entry in entries.skip(offset).take(limit)) {
      shardIds.add(entry.shardId);
    }
    return shardIds;
  }

  /// search_index 항목 수 (domain 필터는 index 로드 후 정확)
  int countIndexEntries({AppDomain? domain, MediaCategory? category}) {
    if (_useShardedSearchIndex && _searchIndexManifest != null) {
      if (category != null) {
        final loaded = _searchIndexByCategory[category];
        if (loaded != null) {
          return _entriesForFilters(domain: domain, category: category).length;
        }
        return _searchIndexManifest!.shardForCategory(category)?.entryCount ??
            0;
      }
      if (_searchIndex.isNotEmpty || _searchIndexByCategory.isNotEmpty) {
        return _entriesForFilters(domain: domain, category: category).length;
      }
      if (domain == null) return _searchIndexManifest!.entryCount;
    }
    return _entriesForFilters(domain: domain, category: category).length;
  }
}
