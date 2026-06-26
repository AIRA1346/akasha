part of 'registry_shard_loader.dart';

mixin _RegistryShardLoaderSync
    on
        _RegistryShardLoaderBase,
        _RegistryShardLoaderCache,
        _RegistryShardLoaderSearchIndex,
        _RegistryShardLoaderShards {
  Future<void> loadBundledBootstrap() async {
    await _loadBundledManifest();
    await _loadBundledSearchIndex();
    await _loadBundledLegacyAliases();
    await loadEagerShards();
  }

  Future<void> _loadBundledManifest() async {
    try {
      final raw = await rootBundle.loadString(RegistryShardLoader.bundledManifestAsset);
      _manifest = RegistryManifest.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to load bundled manifest: $e');
    }
  }

  Future<void> _loadBundledLegacyAliases() async {
    try {
      final raw = await rootBundle.loadString(
        RegistryShardLoader.bundledLegacyAliasesAsset,
      );
      final decoded = json.decode(raw);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          _legacyAliases[key.toString()] = value.toString();
        });
      }
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to load legacy aliases: $e');
    }
  }

  String resolveWorkId(String workId) {
    if (workId.isEmpty) return workId;
    return _legacyAliases[workId] ?? workId;
  }

  Future<bool> cacheRemoteManifest(String content) async {
    try {
      final parsed = RegistryManifest.fromJson(
        json.decode(content) as Map<String, dynamic>,
      );
      _manifest = parsed;
      final file = await _cacheFile('manifest.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to cache remote manifest: $e');
      return false;
    }
  }

  Future<bool> cacheRemoteShard(String relativePath, String content) async {
    try {
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        final file = await _cacheFile(relativePath);
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
        _shardEntriesMerger?.call(decoded);
        final shardId = _manifest?.shards
            .where((s) => s.path == relativePath)
            .map((s) => s.id)
            .firstOrNull;
        if (shardId != null) _loadedShardIds.add(shardId);
        return true;
      }
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to cache remote shard $relativePath: $e');
    }
    return false;
  }

  Future<void> loadCachedBootstrap() async {
    await _loadCachedManifest();
    await _loadCachedSearchIndex();
    await loadEagerShards();
  }

  Future<void> _loadCachedManifest() async {
    try {
      final file = await _cacheFile('manifest.json');
      if (await file.exists()) {
        _manifest = RegistryManifest.fromJson(
          json.decode(await file.readAsString()) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to load cached manifest: $e');
    }
  }

  /// 레거시 단일 JSON(works_registry.json) 병합 — 하위 호환
  /// TODO(remove): R2 — docs/draft/LEGACY_REMOVAL_POLICY.md §3.2
  Future<void> mergeLegacyMonolithicJson(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        _shardEntriesMerger?.call(decoded);
      }
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to merge legacy monolithic JSON: $e');
    }
  }
}
