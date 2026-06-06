import '../models/enums.dart';
import '../models/work_id_codec.dart';
import 'registry_shard_loader.dart';
import 'registry_sync_service.dart';

/// 공통 작품 사전 모델 (Tier 1 - Metadata)
class RegistryWork {
  final String workId;
  final String title;
  final MediaCategory category;
  final AppDomain domain;
  final String creator;
  final int? releaseYear;
  final String description;
  final List<String> tags;
  final String? posterPath;

  const RegistryWork({
    required this.workId,
    required this.title,
    required this.category,
    required this.domain,
    this.creator = '',
    this.releaseYear,
    this.description = '',
    this.tags = const [],
    this.posterPath,
  });

  factory RegistryWork.fromJson(Map<String, dynamic> json) {
    final workId = json['workId']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';

    final categoryStr = json['category']?.toString() ?? 'manga';
    final category = MediaCategory.values.firstWhere(
      (e) => e.name == categoryStr,
      orElse: () => MediaCategory.manga,
    );

    final domainStr = json['domain']?.toString() ?? 'subculture';
    final domain = AppDomain.values.firstWhere(
      (e) => e.name == domainStr,
      orElse: () => AppDomain.subculture,
    );

    return RegistryWork(
      workId: workId,
      title: title,
      category: category,
      domain: domain,
      creator: json['creator']?.toString() ?? '',
      releaseYear: int.tryParse(json['releaseYear']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      posterPath: json['posterPath']?.toString(),
    );
  }
}

/// 샤딩 기반 글로벌 작품 사전 레지스트리
class WorksRegistry {
  static final Map<String, RegistryWork> _registry = {};
  static final RegistryShardLoader _loader = RegistryShardLoader();
  static bool _initialized = false;

  static RegistryShardLoader get loader => _loader;

  /// 앱 시작 시 번들 샤드 + 캐시 + 레거시 병합
  static Future<void> init() async {
    if (_initialized) return;
    await _loader.loadBundledBootstrap();
    await loadCachedRegistry();
    _initialized = true;
  }

  static void mergeShardEntries(Map<String, dynamic> entries) {
    entries.forEach((key, value) {
      if (value is! Map) return;
      final map = Map<String, dynamic>.from(value);
      final incoming = RegistryWork.fromJson(map);
      final resolvedId = _loader.resolveWorkId(incoming.workId.isNotEmpty
          ? incoming.workId
          : key);
      final work = RegistryWork(
        workId: resolvedId,
        title: incoming.title,
        category: incoming.category,
        domain: incoming.domain,
        creator: incoming.creator,
        releaseYear: incoming.releaseYear,
        description: incoming.description,
        tags: incoming.tags,
        posterPath: incoming.posterPath,
      );
      _registry[resolvedId] = work;
      _registry[key] = work;
    });
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
    final q = query.toLowerCase().replaceAll(' ', '');
    final results = <String, RegistryWork>{};
    for (final work in _uniqueWorks()) {
      final t = work.title.toLowerCase().replaceAll(' ', '');
      final c = work.creator.toLowerCase().replaceAll(' ', '');
      final tagsMatch = work.tags.any((tag) => tag.toLowerCase().contains(q));
      if (t.contains(q) || c.contains(q) || tagsMatch) {
        results[work.workId] = work;
      }
    }
    return results.values.toList();
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

  /// master_index용: 번들/캐시에서 전체 카탈로그 즉시 로드 (카테고리 병렬)
  /// [fetchRemote] true면 로컬 로드 후 원격 샤드도 백그라운드 갱신합니다.
  static Future<void> prefetchMasterCatalog({bool fetchRemote = false}) async {
    await Future.wait(
      MediaCategory.values.map(
        (category) => _loader.ensureShardsForFilters(
          domain: null,
          category: category,
        ),
      ),
    );

    if (!fetchRemote) return;

    for (final category in MediaCategory.values) {
      await RegistrySyncService().syncShardsForFilters(
        domain: null,
        category: category,
      );
      await _loader.ensureShardsForFilters(domain: null, category: category);
    }
  }

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
      for (final category in categories!) {
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

  /// 로드된 샤드 → search_index 순으로 registry 포스터 URL을 반환합니다.
  /// lazy 샤드 미로드 시에도 search_index의 posterPath로 UI fusion이 가능합니다.
  static String? resolvePosterPath(String workId) {
    if (workId.isEmpty) return null;
    final resolved = _loader.resolveWorkId(workId);

    final work = getWorkById(resolved);
    final fromShard = work?.posterPath;
    if (fromShard != null && fromShard.isNotEmpty) return fromShard;

    for (final entry in _loader.searchIndex) {
      if (entry.workId == resolved || entry.workId == workId) {
        final poster = entry.posterPath;
        if (poster != null && poster.isNotEmpty) return poster;
        break;
      }
    }
    return null;
  }

  static bool isLegacyWorkId(String workId) =>
      !WorkIdCodec.isMasterFormat(workId) && workId.isNotEmpty;
}
