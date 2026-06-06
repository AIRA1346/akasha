import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/enums.dart';
import '../models/registry_models.dart';
import '../utils/registry_search_utils.dart';
import 'works_registry.dart';

// ════════════════════════════════════════════════════════════════
//  AKASHA — 샤딩 레지스트리 로더 (온디맨드 + 캐시)
// ════════════════════════════════════════════════════════════════

class RegistryShardLoader {
  static const String bundledManifestAsset = 'assets/registry/manifest.json';
  static const String bundledSearchIndexAsset = 'assets/registry/search_index.json';
  static const String bundledLegacyAliasesAsset = 'assets/registry/legacy_aliases.json';

  RegistryManifest? _manifest;
  List<RegistrySearchIndexEntry> _searchIndex = [];
  final Map<String, String> _legacyAliases = {};
  final Set<String> _loadedShardIds = {};

  RegistryManifest? get manifest => _manifest;
  List<RegistrySearchIndexEntry> get searchIndex => _searchIndex;
  Map<String, String> get legacyAliases => Map.unmodifiable(_legacyAliases);

  bool isShardLoaded(String shardId) => _loadedShardIds.contains(shardId);

  Set<String> resolveShardIdsForQuery(String query) =>
      shardIdsForQuery(_searchIndex, query);

  Future<void> loadBundledBootstrap() async {
    await _loadBundledManifest();
    await _loadBundledSearchIndex();
    await _loadBundledLegacyAliases();
    await loadEagerShards();
  }

  Future<void> _loadBundledManifest() async {
    try {
      final raw = await rootBundle.loadString(bundledManifestAsset);
      _manifest = RegistryManifest.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      print('[RegistryShardLoader] Failed to load bundled manifest: $e');
    }
  }

  Future<void> _loadBundledSearchIndex() async {
    try {
      final raw = await rootBundle.loadString(bundledSearchIndexAsset);
      final decoded = json.decode(raw);
      if (decoded is List) {
        _searchIndex = decoded
            .whereType<Map>()
            .map((e) => RegistrySearchIndexEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .where((e) => e.workId.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('[RegistryShardLoader] Failed to load bundled search index: $e');
    }
  }

  Future<void> _loadBundledLegacyAliases() async {
    try {
      final raw = await rootBundle.loadString(bundledLegacyAliasesAsset);
      final decoded = json.decode(raw);
      if (decoded is Map) {
        decoded.forEach((key, value) {
          _legacyAliases[key.toString()] = value.toString();
        });
      }
    } catch (e) {
      print('[RegistryShardLoader] Failed to load legacy aliases: $e');
    }
  }

  String resolveWorkId(String workId) {
    if (workId.isEmpty) return workId;
    return _legacyAliases[workId] ?? workId;
  }

  Future<void> loadEagerShards() async {
    final shards = _manifest?.eagerShards() ?? const [];
    for (final shard in shards) {
      await ensureShardLoaded(shard.id);
    }
  }

  Future<void> ensureShardLoaded(String shardId) async {
    if (shardId.isEmpty || _loadedShardIds.contains(shardId)) return;
    final meta = _manifest?.shardById(shardId);
    if (meta == null) return;

    Map<String, dynamic>? shardMap;

    // 1) 디스크 캐시
    shardMap = await _readCachedShardMap(meta.path);

    // 2) 번들 asset
    shardMap ??= await _readBundledShardMap(meta.path);

    if (shardMap != null) {
      WorksRegistry.mergeShardEntries(shardMap);
      _loadedShardIds.add(shardId);
    }
  }

  Future<void> ensureShardsForQuery(String query) async {
    if (query.trim().isEmpty) return;
    for (final id in resolveShardIdsForQuery(query)) {
      await ensureShardLoaded(id);
    }
  }

  Future<void> ensureShardsForFilters({
    AppDomain? domain,
    MediaCategory? category,
  }) async {
    final shardIds = <String>{};
    for (final entry in _searchIndex) {
      if (domain != null && entry.domain != domain) continue;
      if (category != null && entry.category != category) continue;
      shardIds.add(entry.shardId);
    }
    for (final id in shardIds) {
      await ensureShardLoaded(id);
    }
  }

  Future<bool> cacheRemoteManifest(String content) async {
    try {
      final parsed = RegistryManifest.fromJson(
        json.decode(content) as Map<String, dynamic>,
      );
      _manifest = parsed;
      final file = await _cacheFile('manifest.json');
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('[RegistryShardLoader] Failed to cache remote manifest: $e');
      return false;
    }
  }

  Future<bool> cacheRemoteSearchIndex(String content) async {
    try {
      final decoded = json.decode(content);
      if (decoded is List) {
        _searchIndex = decoded
            .whereType<Map>()
            .map((e) => RegistrySearchIndexEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .where((e) => e.workId.isNotEmpty)
            .toList();
        final file = await _cacheFile('search_index.json');
        await file.writeAsString(content);
        return true;
      }
    } catch (e) {
      print('[RegistryShardLoader] Failed to cache remote search index: $e');
    }
    return false;
  }

  Future<bool> cacheRemoteShard(String relativePath, String content) async {
    try {
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        final file = await _cacheFile(relativePath);
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
        WorksRegistry.mergeShardEntries(decoded);
        final shardId = _manifest?.shards
            .where((s) => s.path == relativePath)
            .map((s) => s.id)
            .firstOrNull;
        if (shardId != null) _loadedShardIds.add(shardId);
        return true;
      }
    } catch (e) {
      print('[RegistryShardLoader] Failed to cache remote shard $relativePath: $e');
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
      print('[RegistryShardLoader] Failed to load cached manifest: $e');
    }
  }

  Future<void> _loadCachedSearchIndex() async {
    try {
      final file = await _cacheFile('search_index.json');
      if (await file.exists()) {
        final decoded = json.decode(await file.readAsString());
        if (decoded is List) {
          _searchIndex = decoded
              .whereType<Map>()
              .map((e) => RegistrySearchIndexEntry.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .where((e) => e.workId.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      print('[RegistryShardLoader] Failed to load cached search index: $e');
    }
  }

  /// 레거시 단일 JSON(works_registry.json) 병합 — 하위 호환
  Future<void> mergeLegacyMonolithicJson(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        WorksRegistry.mergeShardEntries(decoded);
      }
    } catch (e) {
      print('[RegistryShardLoader] Failed to merge legacy monolithic JSON: $e');
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

  Future<File> _cacheFile(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'registry_cache', relativePath));
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
