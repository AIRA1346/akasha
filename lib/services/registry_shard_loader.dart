import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/enums.dart';
import '../models/registry_models.dart';
import '../utils/registry_search_utils.dart';

typedef ShardEntriesMerger = void Function(Map<String, dynamic> entries);

// ════════════════════════════════════════════════════════════════
//  AKASHA — 샤딩 레지스트리 로더 (온디맨드 + 캐시)
// ════════════════════════════════════════════════════════════════

class RegistryShardLoader {
  static const String bundledManifestAsset = 'assets/registry/manifest.json';
  static const String bundledSearchIndexAsset = 'assets/registry/search_index.json';
  static const String bundledSearchIndexManifestAsset =
      'assets/registry/search_index/manifest.json';
  static const String bundledLegacyAliasesAsset = 'assets/registry/legacy_aliases.json';

  RegistryManifest? _manifest;
  RegistrySearchIndexManifest? _searchIndexManifest;
  List<RegistrySearchIndexEntry> _searchIndex = [];
  final Map<MediaCategory, List<RegistrySearchIndexEntry>> _searchIndexByCategory =
      {};
  bool _useShardedSearchIndex = false;
  final Map<String, String> _legacyAliases = {};
  final Set<String> _loadedShardIds = {};
  final ShardEntriesMerger? _shardEntriesMerger;

  RegistryShardLoader({ShardEntriesMerger? shardEntriesMerger})
      : _shardEntriesMerger = shardEntriesMerger;

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
    _searchIndexManifest = null;
    _useShardedSearchIndex = false;
  }

  bool isShardLoaded(String shardId) => _loadedShardIds.contains(shardId);

  void resetLoadedShards() => _loadedShardIds.clear();

  DateTime? get bundledManifestGeneratedAt =>
      _parseGeneratedAt(_manifest?.generatedAt);

  Future<DateTime?> cachedManifestGeneratedAt() async {
    try {
      final file = await _cacheFile('manifest.json');
      if (!await file.exists()) return null;
      final decoded = json.decode(await file.readAsString());
      if (decoded is! Map) return null;
      return _parseGeneratedAt(decoded['generatedAt']?.toString());
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
    final bundledAt = _parseGeneratedAt(bundledRaw);
    final cachedAt = _parseGeneratedAt(cachedRaw);
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
      print('[RegistryShardLoader] Failed to clear disk cache: $e');
    }
    resetLoadedShards();
  }

  Future<bool> isShardCached(String relativePath) async {
    if (relativePath.isEmpty) return false;
    final file = await _cacheFile(relativePath);
    return file.exists();
  }

  int? entryCountForShard(String shardId) =>
      _manifest?.shardById(shardId)?.entryCount;

  int qualityScoreFor(String workId) {
    if (workId.isEmpty) return 0;
    for (final entry in _searchIndex) {
      if (entry.workId == workId) return entry.qualityScore;
    }
    return 0;
  }

  Set<String> resolveShardIdsForQuery(String query) =>
      shardIdsForQuery(_searchIndex, query);

  Set<String> resolveShardIdsForFilters({
    AppDomain? domain,
    MediaCategory? category,
  }) =>
      shardIdsForFilters(
        _searchIndex,
        domain: domain,
        category: category,
      );

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
    if (await _tryLoadBundledSearchIndexManifest()) return;

    try {
      final raw = await rootBundle.loadString(bundledSearchIndexAsset);
      _parseMonolithicSearchIndex(raw);
    } catch (e) {
      print('[RegistryShardLoader] Failed to load bundled search index: $e');
    }
  }

  Future<bool> _tryLoadBundledSearchIndexManifest() async {
    try {
      final raw = await rootBundle.loadString(bundledSearchIndexManifestAsset);
      _searchIndexManifest = RegistrySearchIndexManifest.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
      _useShardedSearchIndex = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _parseMonolithicSearchIndex(String raw) {
    final decoded = json.decode(raw);
    if (decoded is List) {
      _searchIndex = _parseSearchIndexList(decoded);
      _useShardedSearchIndex = false;
    }
  }

  List<RegistrySearchIndexEntry> _parseSearchIndexList(Object? decoded) {
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => RegistrySearchIndexEntry.fromJson(
              Map<String, dynamic>.from(e),
            ))
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
        (shard) => _ensureCategorySearchIndexLoaded(shard.category, bundled: true),
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
      try {
        raw = await rootBundle.loadString('assets/registry/${shard.path}');
      } catch (_) {}
    }
    raw ??= await _readCachedText(shard.path);

    if (raw == null) {
      _searchIndexByCategory[category] = const [];
      return;
    }

    _searchIndexByCategory[category] = _parseSearchIndexList(json.decode(raw));
  }

  void _rebuildMergedSearchIndex() {
    if (_searchIndexByCategory.isEmpty) return;
    _searchIndex = _searchIndexByCategory.values.expand((e) => e).toList();
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

  Set<String> resolveShardIdsForBrowseWindow({
    AppDomain? domain,
    MediaCategory? category,
    int offset = 0,
    int limit = 48,
  }) {
    if (limit <= 0) return const {};

    final entries = _entriesForFilters(domain: domain, category: category).toList()
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
        return _searchIndexManifest!.shardForCategory(category)?.entryCount ?? 0;
      }
      if (_searchIndex.isNotEmpty || _searchIndexByCategory.isNotEmpty) {
        return _entriesForFilters(domain: domain, category: category).length;
      }
      if (domain == null) return _searchIndexManifest!.entryCount;
    }
    return _entriesForFilters(domain: domain, category: category).length;
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
      print('[RegistryShardLoader] Failed to cache remote manifest: $e');
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
      print('[RegistryShardLoader] Failed to cache remote search index: $e');
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
      final file = await _cacheFile('search_index/manifest.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('[RegistryShardLoader] Failed to cache remote search index manifest: $e');
    }
    return false;
  }

  Future<bool> cacheRemoteSearchIndexShard(String relativePath, String content) async {
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
      print(
        '[RegistryShardLoader] Failed to cache remote search index shard $relativePath: $e',
      );
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
        _shardEntriesMerger?.call(decoded);
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
    if (await _tryLoadCachedSearchIndexManifest()) return;

    try {
      final file = await _cacheFile('search_index.json');
      if (await file.exists()) {
        _parseMonolithicSearchIndex(await file.readAsString());
      }
    } catch (e) {
      print('[RegistryShardLoader] Failed to load cached search index: $e');
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
          (shard) => _ensureCategorySearchIndexLoaded(shard.category, bundled: false),
        ),
      );
      _rebuildMergedSearchIndex();
      return true;
    } catch (e) {
      print('[RegistryShardLoader] Failed to load cached search index manifest: $e');
      return false;
    }
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

  /// 레거시 단일 JSON(works_registry.json) 병합 — 하위 호환
  Future<void> mergeLegacyMonolithicJson(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        _shardEntriesMerger?.call(decoded);
      }
    } catch (e) {
      print('[RegistryShardLoader] Failed to merge legacy monolithic JSON: $e');
    }
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

  static DateTime? _parseGeneratedAt(String? raw) {
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
