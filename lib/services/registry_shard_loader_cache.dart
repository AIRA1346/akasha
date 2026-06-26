part of 'registry_shard_loader.dart';

mixin _RegistryShardLoaderCache on _RegistryShardLoaderBase {
  Future<DateTime?> cachedManifestGeneratedAt() async {
    try {
      final file = await _cacheFile('manifest.json');
      if (!await file.exists()) return null;
      final decoded = json.decode(await file.readAsString());
      if (decoded is! Map) return null;
      return RegistryShardLoader.parseGeneratedAt(
        decoded['generatedAt']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 번들(앱 업데이트)이 디스크 캐시보다 최신이면 옛 샤드 캐시를 무효화합니다.
  Future<bool> isDiskCacheStaleComparedToBundle() async {
    final bundledRaw = _manifest?.generatedAt;
    final cachedRaw = await _readCachedManifestGeneratedAtRaw();
    if (bundledRaw == null ||
        cachedRaw == null ||
        bundledRaw.isEmpty ||
        cachedRaw.isEmpty) {
      return false;
    }
    if (bundledRaw == cachedRaw) return false;
    final bundledAt = RegistryShardLoader.parseGeneratedAt(bundledRaw);
    final cachedAt = RegistryShardLoader.parseGeneratedAt(cachedRaw);
    if (bundledAt == null || cachedAt == null) return false;
    return bundledAt.isAfter(cachedAt);
  }

  Future<String?> _readCachedManifestGeneratedAtRaw() async {
    try {
      final file = await _cacheFile('manifest.json');
      if (!await file.exists()) return null;
      final decoded = json.decode(await file.readAsString());
      if (decoded is! Map) return null;
      return decoded['generatedAt']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDiskCache() async {
    try {
      final dir = await _cacheDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      appLog('[RegistryShardLoader] Failed to clear disk cache: $e');
    }
    resetLoadedShards();
  }

  Future<bool> isShardCached(String relativePath) async {
    if (relativePath.isEmpty) return false;
    final file = await _cacheFile(relativePath);
    return file.exists();
  }

  Future<String?> _readCachedText(String relativePath) async {
    try {
      final file = await _cacheFile(relativePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _readCachedShardMap(String relativePath) async {
    try {
      final file = await _cacheFile(relativePath);
      if (await file.exists()) {
        final decoded = json.decode(await file.readAsString());
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<Directory> _cacheDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory(p.join(dir.path, 'registry_cache'));
  }

  Future<File> _cacheFile(String relativePath) async {
    final dir = await _cacheDirectory();
    return File(p.join(dir.path, relativePath));
  }
}
