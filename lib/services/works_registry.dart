import '../config/catalog_poster_policy.dart';
import '../models/enums.dart';
import '../models/registry_work.dart';
import '../models/work_id_codec.dart';
import '../utils/registry_catalog_filter.dart';
import '../utils/registry_search_utils.dart';
import 'registry_shard_loader.dart';
import 'registry_sync_service.dart';

export '../models/registry_work.dart';

/// 샤딩 기반 글로벌 작품 사전 레지스트리
class WorksRegistry {
  static final Map<String, RegistryWork> _registry = {};
  static final RegistryShardLoader _loader = RegistryShardLoader(
    shardEntriesMerger: mergeShardEntries,
  );
  static bool _initialized = false;

  static RegistryShardLoader get loader => _loader;

  /// search_index 빌드 산출 품질 점수 (0–100, 파생값)
  static int qualityScoreFor(String workId) => _loader.qualityScoreFor(workId);

  /// 앱 시작 시 번들 샤드 + (유효한) 캐시 + 레거시 병합
  static Future<void> init() async {
    if (_initialized) return;
    // E1-A3b: loader·reload 콜백을 sync service에 주입해 순환 import 제거
    final syncService = RegistrySyncService();
    syncService.bindLoader(_loader);
    syncService.registerOnSyncSuccess(reloadAfterRemoteSync);
    await _loader.loadBundledBootstrap();
    if (await _loader.isDiskCacheStaleComparedToBundle()) {
      await _loader.clearDiskCache();
      await syncService.clearLegacyRegistryCache();
    } else {
      await loadCachedRegistry();
    }
    _initialized = true;
  }

  /// 원격 manifest 갱신 후 메모리·캐시 기준으로 레지스트리를 다시 구성합니다.
  static Future<void> reloadAfterRemoteSync() async {
    _registry.clear();
    _loader.resetLoadedShards();
    await _loader.loadCachedBootstrap();
    final legacyJson = await RegistrySyncService().readCachedRegistry();
    if (legacyJson != null && legacyJson.isNotEmpty) {
      await _loader.mergeLegacyMonolithicJson(legacyJson);
    }
  }

  /// 디스크·레거시 캐시 삭제 후 앱 번들 사전으로 메모리를 재구성합니다.
  static Future<void> clearDiskCacheAndReloadBundle() async {
    _registry.clear();
    _loader.resetLoadedShards();
    await _loader.clearDiskCache();
    await RegistrySyncService().clearLegacyRegistryCache();
    await _loader.loadBundledBootstrap();
  }

  static void mergeShardEntries(Map<String, dynamic> entries) {
    entries.forEach((key, value) {
      if (value is! Map) return;
      final map = Map<String, dynamic>.from(value);
      final incoming = RegistryWork.fromJson(map);
      final resolvedId = _loader.resolveWorkId(incoming.workId.isNotEmpty
          ? incoming.workId
          : key);
      final existing =
          _registry[resolvedId] ?? _registry[key];
      final posterPath = _resolveMergedPosterPath(
        workId: resolvedId,
        incoming: incoming,
        existing: existing,
      );
      final work = RegistryWork(
        workId: resolvedId,
        title: incoming.title,
        titles: incoming.titles,
        aliases: incoming.aliases,
        externalIds: incoming.externalIds,
        category: incoming.category,
        domain: incoming.domain,
        creator: incoming.creator,
        releaseYear: incoming.releaseYear,
        description: incoming.description,
        tags: incoming.tags,
        posterPath: posterPath,
        extensions: incoming.extensions,
      );
      _registry[resolvedId] = work;
      _registry[key] = work;
    });
  }

  static bool _isPosterVerified(RegistryWork work) =>
      work.extensions['posterVerified'] == true;

  static String? _posterFromSearchIndex(String workId) {
    for (final entry in _loader.searchIndex) {
      if (entry.workId == workId) {
        final poster = entry.posterPath;
        if (poster != null && poster.isNotEmpty) return poster;
        break;
      }
    }
    return null;
  }

  static String? _resolveMergedPosterPath({
    required String workId,
    required RegistryWork incoming,
    required RegistryWork? existing,
  }) {
    if (existing != null &&
        _isPosterVerified(existing) &&
        !_isPosterVerified(incoming)) {
      return existing.posterPath;
    }
    if (_isPosterVerified(incoming)) return incoming.posterPath;

    final fromIndex = _posterFromSearchIndex(workId);
    if (fromIndex != null && fromIndex.isNotEmpty) {
      return fromIndex;
    }
    return incoming.posterPath ?? existing?.posterPath;
  }

  static RegistryWork? getWorkById(String workId) {
    if (workId.isEmpty) return null;
    final resolved = _loader.resolveWorkId(workId);
    return _registry[resolved] ?? _registry[workId];
  }

  static List<RegistryWork> _uniqueWorks() {
    final map = <String, RegistryWork>{};
    for (final work in _registry.values) {
      if (work.workId.isNotEmpty) map[work.workId] = work;
    }
    return map.values.toList();
  }

  static List<RegistryWork> search(String query) {
    if (query.isEmpty) return _uniqueWorks();
    final q = normalizeRegistryQuery(query);
    final results = <String, RegistryWork>{};
    for (final work in _uniqueWorks()) {
      if (isMaintainerCatalogProbe(work)) continue;
      if (_workMatchesQuery(work, q)) {
        results[work.workId] = work;
      }
    }
    final list = results.values.toList();
    list.sort((a, b) {
      final scoreCmp =
          qualityScoreFor(b.workId).compareTo(qualityScoreFor(a.workId));
      if (scoreCmp != 0) return scoreCmp;
      return a.title.compareTo(b.title);
    });
    return list;
  }

  static bool _workMatchesQuery(RegistryWork work, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return false;
    for (final token in work.searchTokens) {
      if (registryTokenMatchesQuery(token, normalizedQuery)) return true;
    }
    return false;
  }

  /// 온디맨드 검색: 원격 shard fetch → 캐시/번들 로드 → 메모리 검색
  /// [금지] sync(), loadEagerShards(), ensureShardsForFilters() 호출 없음
  static Future<List<RegistryWork>> searchAsync(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    await RegistrySyncService().syncShardsForQuery(trimmed);
    await _loader.ensureShardsForQuery(trimmed);
    return search(trimmed);
  }

  static List<RegistryWork> get allWorks => _uniqueWorks();

  static Future<List<RegistryWork>> getFilteredWorks({
    AppDomain? domain,
    MediaCategory? category,
  }) async {
    await _loader.ensureShardsForFilters(domain: domain, category: category);
    return _uniqueWorks().where((work) {
      if (isMaintainerCatalogProbe(work)) return false;
      if (domain != null && work.domain != domain) return false;
      if (category != null && work.category != category) return false;
      return true;
    }).toList();
  }

  /// 동기 버전 — 이미 로드된 샤드만 (하위 호환)
  static List<RegistryWork> getFilteredWorksSync({
    AppDomain? domain,
    MediaCategory? category,
  }) {
    return _uniqueWorks().where((work) {
      if (isMaintainerCatalogProbe(work)) return false;
      if (domain != null && work.domain != domain) return false;
      if (category != null && work.category != category) return false;
      return true;
    }).toList();
  }

  static Future<void> loadCachedRegistry() async {
    try {
      await _loader.loadCachedBootstrap();

      // 레거시 단일 JSON 캐시 하위 호환
      final legacyJson = await RegistrySyncService().readCachedRegistry();
      if (legacyJson != null && legacyJson.isNotEmpty) {
        await _loader.mergeLegacyMonolithicJson(legacyJson);
      }
    } catch (e) {
      print('Error loading cached sharded registry: $e');
    }
  }

  /// browse 첫 화면에 로드할 search_index 윈도우 (Phase 2.2)
  static const int browsePrefetchWindowSize = 48;

  /// 이하이면 master_index 첫 prefetch 시 번들 전체 shard 적재 (lazy window 생략)
  static const int browseFullCatalogThreshold = 2500;

  /// master_index·무필터 browse — search_index 품질순 윈도우만 prefetch
  /// [fetchRemote] true면 윈도우 shard만 원격 갱신 (전 카테고리 bulk fetch 없음)
  static Future<void> prefetchBrowseWindow({
    AppDomain? domain,
    MediaCategory? category,
    int offset = 0,
    int limit = browsePrefetchWindowSize,
    bool fetchRemote = false,
  }) async {
    final total = catalogIndexEntryCount(domain: domain, category: category);
    final useFullBundledCatalog = domain == null &&
        category == null &&
        offset == 0 &&
        total > 0 &&
        total <= browseFullCatalogThreshold;

    if (useFullBundledCatalog) {
      await _loader.ensureSearchIndexLoaded();
      await _loader.ensureAllManifestShardsLoaded();
      if (fetchRemote) {
        final shardIds = _loader.manifest?.shards.map((s) => s.id).toSet() ??
            const {};
        await RegistrySyncService().syncShardsByIds(shardIds);
        await _loader.ensureAllManifestShardsLoaded();
      }
      return;
    }

    await _loader.ensureShardsForBrowseWindow(
      domain: domain,
      category: category,
      offset: offset,
      limit: limit,
    );

    if (!fetchRemote) return;

    final shardIds = _loader.resolveShardIdsForBrowseWindow(
      domain: domain,
      category: category,
      offset: offset,
      limit: limit,
    );
    await RegistrySyncService().syncShardsByIds(shardIds);
    await _loader.ensureShardsForBrowseWindow(
      domain: domain,
      category: category,
      offset: offset,
      limit: limit,
    );
  }

  /// @deprecated Phase 2.2 — [prefetchBrowseWindow] 사용. 하위 호환 alias.
  static Future<void> prefetchMasterCatalog({bool fetchRemote = false}) =>
      prefetchBrowseWindow(fetchRemote: fetchRemote);

  static int catalogIndexEntryCount({
    AppDomain? domain,
    MediaCategory? category,
  }) =>
      _loader.countIndexEntries(domain: domain, category: category);

  /// 필터 범위 샤드 온디맨드 프리페치 (원격 fetch → 캐시/번들 로드)
  /// domain·categories 모두 비어 있으면 no-op (전체 샤드 bulk fetch 방지)
  static Future<void> prefetchForFilters({
    AppDomain? domain,
    Set<MediaCategory>? categories,
  }) async {
    final hasDomain = domain != null;
    final hasCategories = categories != null && categories.isNotEmpty;
    if (!hasDomain && !hasCategories) return;

    if (hasCategories) {
      for (final category in categories) {
        await _prefetchSingleFilter(domain: domain, category: category);
      }
      return;
    }

    await _prefetchSingleFilter(domain: domain, category: null);
  }

  static Future<void> _prefetchSingleFilter({
    AppDomain? domain,
    MediaCategory? category,
  }) async {
    await _loader.ensureShardsForFilters(domain: domain, category: category);
    await RegistrySyncService().syncShardsForFilters(
      domain: domain,
      category: category,
    );
    await _loader.ensureShardsForFilters(domain: domain, category: category);
  }

  static String resolveWorkId(String workId) => _loader.resolveWorkId(workId);

  /// `sub_*` 볼트 ID와 `wk_*` 사전 ID가 같은 작품인지 판별
  static bool setContainsWorkId(Set<String> ids, String workId) {
    if (workId.isEmpty) return false;
    final canonical = resolveWorkId(workId);
    for (final id in ids) {
      if (id.isEmpty) continue;
      final idCanonical = resolveWorkId(id);
      if (id == workId ||
          id == canonical ||
          idCanonical == workId ||
          idCanonical == canonical) {
        return true;
      }
    }
    return false;
  }

  /// Tier 1 registry 포스터 URL (v1: 비활성 — 유저 볼트만).
  static String? resolvePosterPath(String workId) {
    if (!CatalogPosterPolicy.tier1RegistryPostersEnabled) return null;
    if (workId.isEmpty) return null;
    final resolved = _loader.resolveWorkId(workId);
    final work = getWorkById(resolved);
    final fromIndex =
        _posterFromSearchIndex(resolved) ?? _posterFromSearchIndex(workId);

    if (work != null && _isPosterVerified(work)) {
      final fromShard = work.posterPath;
      if (fromShard != null && fromShard.isNotEmpty) return fromShard;
    }
    if (fromIndex != null && fromIndex.isNotEmpty) return fromIndex;

    final fallback = work?.posterPath;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  static bool isLegacyWorkId(String workId) =>
      !WorkIdCodec.isMasterFormat(workId) && workId.isNotEmpty;
}
