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
    await _validateBundleContract();
    await _loadBundledLegacyAliases();
    await loadEagerShards();
  }

  Future<void> _loadBundledManifest() async {
    const path = RegistryShardLoader.bundledManifestAsset;
    try {
      final raw = await _source.readRequired(path);
      _manifest = RegistryManifest.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    } catch (error) {
      if (error is RegistrySourceException) rethrow;
      throw sourceError(
        RegistrySourceFailureType.malformedJson,
        path,
        cause: error,
      );
    }
  }

  Future<void> _loadBundledLegacyAliases() async {
    const path = RegistryShardLoader.bundledLegacyAliasesAsset;
    try {
      final raw = await _source.readRequired(path);
      final decoded = json.decode(raw);
      if (decoded is! Map) {
        throw const FormatException('legacy aliases must be a JSON object');
      }
      decoded.forEach((key, value) {
        _legacyAliases[key.toString()] = value.toString();
      });
    } catch (error) {
      if (error is RegistrySourceException) rethrow;
      throw sourceError(
        RegistrySourceFailureType.malformedJson,
        path,
        cause: error,
      );
    }
  }

  Future<void> _validateBundleContract() async {
    final manifest = _manifest;
    final searchManifest = _searchIndexManifest;
    if (manifest == null) {
      throw sourceError(
        RegistrySourceFailureType.manifestMismatch,
        RegistryShardLoader.bundledManifestAsset,
        cause: 'root manifest was not initialized',
      );
    }

    final missingProvenance =
        manifest.releaseId == null ||
        manifest.releaseId!.isEmpty ||
        manifest.sourceRevision == null ||
        manifest.sourceRevision!.isEmpty ||
        manifest.schemaVersion == null ||
        manifest.bundleMode == null;
    if (_allowLegacyManifest && missingProvenance) return;

    if (missingProvenance || searchManifest == null) {
      throw sourceError(
        RegistrySourceFailureType.invalidProvenance,
        RegistryShardLoader.bundledManifestAsset,
        cause: 'production bundle requires root and search provenance',
      );
    }
    if (manifest.bundleMode != 'full' || searchManifest.bundleMode != 'full') {
      throw sourceError(
        RegistrySourceFailureType.invalidProvenance,
        RegistryShardLoader.bundledManifestAsset,
        cause:
            'bundleMode must be full (root=${manifest.bundleMode}, search=${searchManifest.bundleMode})',
      );
    }
    if (manifest.version != 4 || searchManifest.version != 1) {
      throw sourceError(
        RegistrySourceFailureType.incompatibleSchema,
        RegistryShardLoader.bundledManifestAsset,
        cause:
            'supported manifest versions root=4 search=1; '
            'actual root=${manifest.version} search=${searchManifest.version}',
      );
    }
    if (manifest.shardBits != RegistryShardLoader.supportedShardBits) {
      throw sourceError(
        RegistrySourceFailureType.incompatibleSchema,
        RegistryShardLoader.bundledManifestAsset,
        cause:
            'supported shardBits=${RegistryShardLoader.supportedShardBits}; '
            'actual=${manifest.shardBits}',
      );
    }
    if (manifest.releaseId != searchManifest.releaseId ||
        manifest.sourceRevision != searchManifest.sourceRevision) {
      throw sourceError(
        RegistrySourceFailureType.invalidProvenance,
        RegistryShardLoader.bundledSearchIndexManifestAsset,
        cause: 'root/search releaseId or sourceRevision mismatch',
      );
    }
    if (manifest.schemaVersion != RegistryShardLoader.supportedSchemaVersion ||
        searchManifest.schemaVersion !=
            RegistryShardLoader.supportedSchemaVersion) {
      throw sourceError(
        RegistrySourceFailureType.incompatibleSchema,
        RegistryShardLoader.bundledManifestAsset,
        cause:
            'supported=${RegistryShardLoader.supportedSchemaVersion} root=${manifest.schemaVersion} search=${searchManifest.schemaVersion}',
      );
    }
    final rootEntryCount = manifest.entryCount;
    final rootShardEntryCount = manifest.shards.fold<int>(
      0,
      (total, shard) => total + shard.entryCount,
    );
    final searchShardEntryCount = searchManifest.shards.fold<int>(
      0,
      (total, shard) => total + shard.entryCount,
    );
    if (rootEntryCount == null ||
        rootEntryCount <= 0 ||
        rootEntryCount != searchManifest.entryCount ||
        rootShardEntryCount != rootEntryCount ||
        searchShardEntryCount != searchManifest.entryCount) {
      throw sourceError(
        RegistrySourceFailureType.manifestMismatch,
        RegistryShardLoader.bundledSearchIndexManifestAsset,
        cause:
            'entryCount root=$rootEntryCount rootShards=$rootShardEntryCount '
            'search=${searchManifest.entryCount} searchShards=$searchShardEntryCount',
      );
    }

    const requiredFiles = <String>[
      RegistryShardLoader.bundledSearchIndexAsset,
      RegistryShardLoader.bundledSearchIndexManifestAsset,
      RegistryShardLoader.bundledLegacyAliasesAsset,
      RegistryShardLoader.bundledFranchiseGroupsAsset,
    ];
    for (final path in requiredFiles) {
      await _requireSafeExistingPath(path);
    }

    final shardIds = <String>{};
    final shardPaths = <String>{};
    for (final shard in manifest.shards) {
      if (!shardIds.add(shard.id) || !shardPaths.add(shard.path)) {
        throw sourceError(
          RegistrySourceFailureType.manifestMismatch,
          shard.path,
          shardId: shard.id,
          cause: 'duplicate shard id or path',
        );
      }
      if (shard.sha256 == null || shard.sha256!.isEmpty) {
        throw sourceError(
          RegistrySourceFailureType.manifestMismatch,
          shard.path,
          shardId: shard.id,
          cause: 'full bundle shard is missing SHA-256',
        );
      }
      await _requireSafeExistingPath(shard.path, shardId: shard.id);
    }
    final searchCategories = <MediaCategory>{};
    final searchPaths = <String>{};
    for (final shard in searchManifest.shards) {
      if (!searchCategories.add(shard.category) ||
          !searchPaths.add(shard.path)) {
        throw sourceError(
          RegistrySourceFailureType.manifestMismatch,
          shard.path,
          cause: 'duplicate search category or path',
        );
      }
      if (shard.sha256 == null || shard.sha256!.isEmpty) {
        throw sourceError(
          RegistrySourceFailureType.manifestMismatch,
          shard.path,
          cause: 'full bundle search shard is missing SHA-256',
        );
      }
      await _requireSafeExistingPath(shard.path);
    }
  }

  Future<void> _requireSafeExistingPath(
    String relativePath, {
    String? shardId,
  }) async {
    final segments = relativePath.replaceAll('\\', '/').split('/');
    final safe =
        relativePath.isNotEmpty &&
        !relativePath.startsWith('/') &&
        !relativePath.contains(':') &&
        segments.every(
          (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
        );
    if (!safe) {
      throw sourceError(
        RegistrySourceFailureType.manifestMismatch,
        relativePath,
        shardId: shardId,
        cause: 'unsafe relative path',
      );
    }
    if (!await _source.exists(relativePath)) {
      throw sourceError(
        RegistrySourceFailureType.missing,
        relativePath,
        shardId: shardId,
      );
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
      appLog(
        '[RegistryShardLoader] Failed to cache remote shard $relativePath: $e',
      );
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
      appLog(
        '[RegistryShardLoader] Failed to merge legacy monolithic JSON: $e',
      );
    }
  }
}
