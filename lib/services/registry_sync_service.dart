import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/registry_models.dart';
import '../utils/app_log.dart';
import 'registry_cache_contract.dart';
import 'registry_shard_loader.dart';

typedef RegistryTextFetcher = Future<String?> Function(String url);

/// Git 기반 글로벌 작품 사전 동기화 서비스 (샤딩 아키텍처).
///
/// 기능적 sync seam을 제공한다. 현재 production composition에는 배선되지 않으며,
/// 앱 시작은 bundled Registry bootstrap만 사용한다.
///
/// 이 서비스와 관련 adapter는 격리 테스트 또는 향후 명시적으로 활성화될
/// sync composition을 위해 유지되고 있다.
class RegistrySyncService {
  static const String _prefLastSyncKey =
      RegistryCacheContract.lastSyncPreferenceKey;
  static const String _prefCustomUrlKey =
      RegistryCacheContract.customDbUrlPreferenceKey;

  /// Read path: Cloudflare Pages (GitHub akasha-db push → auto deploy).
  static const String defaultDbBaseUrl = 'https://akasha-db.pages.dev/';

  static const String defaultLegacyDbUrl =
      '${defaultDbBaseUrl}works_registry.json';

  static final RegistrySyncService _instance = RegistrySyncService._internal();
  static int _factoryInvocationCount = 0;
  factory RegistrySyncService() {
    _factoryInvocationCount++;
    return _instance;
  }
  RegistrySyncService._internal();

  @visibleForTesting
  static int get factoryInvocationCountForTesting => _factoryInvocationCount;

  @visibleForTesting
  static void resetFactoryInvocationCountForTesting() {
    _factoryInvocationCount = 0;
  }

  SharedPreferences? _prefs;
  static RegistryTextFetcher? _textFetcherOverride;

  /// sync() 성공 후 메모리 Registry를 다시 로드할 콜백.
  ///
  /// 현재 production composition은 registry sync를 배선하지 않으므로
  /// production startup에서는 주입되지 않는다.
  Future<void> Function()? _onSyncSuccess;

  /// sync 성공 후 메모리 Registry를 다시 로드할 콜백을 등록한다.
  ///
  /// 현재 production composition은 registry sync를 배선하지 않으므로
  /// production startup에서는 호출되지 않는다. 격리 테스트나 향후
  /// 명시적으로 활성화된 sync composition을 위한 seam이다.
  void registerOnSyncSuccess(Future<void> Function() callback) {
    _onSyncSuccess = callback;
  }

  RegistryShardLoader? _loader;

  /// 이 optional sync service가 사용할 loader를 바인딩한다.
  ///
  /// 현재 production composition은 registry sync를 배선하지 않으며,
  /// 앱 시작은 bundled bootstrap을 사용한다. 격리 테스트나 향후
  /// 명시적으로 활성화된 sync composition을 위한 seam이다.
  void bindLoader(RegistryShardLoader loader) {
    _loader = loader;
  }

  RegistryShardLoader get _effectiveLoader {
    final l = _loader;
    assert(
      l != null,
      'RegistrySyncService: loader not bound. Call bindLoader() before invoking sync operations.',
    );
    return l!;
  }

  @visibleForTesting
  static void setTextFetcherForTesting(RegistryTextFetcher? fetcher) {
    _textFetcherOverride = fetcher;
  }

  @visibleForTesting
  void resetForTesting() {
    _prefs = null;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String get customDbUrl {
    return _prefs?.getString(_prefCustomUrlKey) ?? defaultDbBaseUrl;
  }

  String get baseUrl {
    final url = customDbUrl.trim();
    if (url.isEmpty) return defaultDbBaseUrl;
    return url.endsWith('/') ? url : '$url/';
  }

  Future<void> setCustomDbUrl(String url) async {
    await init();
    if (url.trim().isEmpty) {
      await _prefs?.remove(_prefCustomUrlKey);
    } else {
      await _prefs?.setString(_prefCustomUrlKey, url.trim());
    }
  }

  DateTime? get lastSyncTime {
    final timeStr = _prefs?.getString(_prefLastSyncKey);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  Future<File> get _legacyCacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, RegistryCacheContract.legacyRegistryFileName));
  }

  /// `local_works_registry.json` — v3 이전 단일 캐시.
  /// TODO(remove): R5 — docs/active/LEGACY_REMOVAL_POLICY.md §3.2
  Future<void> clearLegacyRegistryCache() async {
    try {
      final file = await _legacyCacheFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      appLog('Error clearing legacy registry cache: $e');
    }
  }

  Future<String?> readCachedRegistry() async {
    try {
      final file = await _legacyCacheFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      appLog('Error reading legacy registry cache: $e');
    }
    return null;
  }

  Future<bool> shouldAutoSync() async {
    await init();
    final lastSync = lastSyncTime;
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inHours >= 24;
  }

  /// 샤딩 메타데이터 + 검색 인덱스 + eager 샤드 동기화 (증분)
  Future<bool> sync() async {
    await init();
    final loader = _effectiveLoader;
    final previousManifest = loader.manifest;
    var success = false;

    final manifestContent = await _fetchText('${baseUrl}manifest.json');
    if (manifestContent == null) {
      return _syncLegacyFallback(loader);
    }

    RegistryManifest? remoteManifest;
    try {
      remoteManifest = RegistryManifest.fromJson(
        json.decode(manifestContent) as Map<String, dynamic>,
      );
    } catch (e) {
      appLog('Error parsing remote manifest: $e');
      return _syncLegacyFallback(loader);
    }

    if (_isManifestUpToDate(previousManifest, remoteManifest)) {
      await _updateLastSyncTime();
      return true;
    }

    await loader.clearDiskCache();
    await clearLegacyRegistryCache();
    success = await loader.cacheRemoteManifest(manifestContent);

    final indexManifestContent = await _fetchText(
      '${baseUrl}search_index/manifest.json',
    );
    if (indexManifestContent != null) {
      success =
          (await loader.cacheRemoteSearchIndexManifest(indexManifestContent)) ||
          success;
      try {
        final indexManifest = RegistrySearchIndexManifest.fromJson(
          json.decode(indexManifestContent) as Map<String, dynamic>,
        );
        for (final shard in indexManifest.shards) {
          final shardContent = await _fetchText('$baseUrl${shard.path}');
          if (shardContent != null) {
            success =
                (await loader.cacheRemoteSearchIndexShard(
                  shard.path,
                  shardContent,
                )) ||
                success;
          }
        }
      } catch (e) {
        appLog('Error syncing sharded search index: $e');
      }
    } else {
      final indexContent = await _fetchText('${baseUrl}search_index.json');
      if (indexContent != null) {
        success =
            (await loader.cacheRemoteSearchIndex(indexContent)) || success;
      }
    }

    final eagerShards = remoteManifest.eagerShards();
    for (final shard in eagerShards) {
      if (!await _shardNeedsSync(shard, previousManifest, loader)) continue;
      final shardContent = await _fetchText('$baseUrl${shard.path}');
      if (shardContent != null) {
        final ok = await loader.cacheRemoteShard(shard.path, shardContent);
        success = ok || success;
      }
    }

    // 레거시 단일 JSON 폴백 (akasha-db 마이그레이션 전)
    if (!success) {
      final legacyUrl = baseUrl.endsWith('/')
          ? '${baseUrl}works_registry.json'
          : '$baseUrl/works_registry.json';
      final legacyContent = await _fetchText(legacyUrl);
      if (legacyContent != null) {
        try {
          final decoded = json.decode(legacyContent);
          if (decoded is Map || decoded is List) {
            final file = await _legacyCacheFile;
            await file.writeAsString(legacyContent);
            await loader.mergeLegacyMonolithicJson(legacyContent);
            success = true;
          }
        } catch (e) {
          appLog('Error syncing legacy registry: $e');
        }
      }
    }

    if (success) {
      if (_onSyncSuccess != null) await _onSyncSuccess!();
      await _updateLastSyncTime();
    }
    return success;
  }

  Future<void> _updateLastSyncTime() async {
    await _prefs?.setString(_prefLastSyncKey, DateTime.now().toIso8601String());
  }

  bool _isManifestUpToDate(RegistryManifest? local, RegistryManifest remote) {
    if (local == null) return false;
    final localAt = _parseGeneratedAt(local.generatedAt);
    final remoteAt = _parseGeneratedAt(remote.generatedAt);
    if (localAt == null || remoteAt == null) return false;
    // 번들/캐시가 원격보다 최신이면 다운그레이드하지 않음
    return !localAt.isBefore(remoteAt);
  }

  DateTime? _parseGeneratedAt(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<bool> _shardNeedsSync(
    RegistryShardMeta remoteShard,
    RegistryManifest? previousManifest,
    RegistryShardLoader loader,
  ) async {
    final previousShard = previousManifest?.shardById(remoteShard.id);
    if (previousShard == null) return true;
    if (previousShard.entryCount != remoteShard.entryCount) return true;
    final remoteSha = remoteShard.sha256;
    final localSha = previousShard.sha256;
    if (remoteSha != null &&
        remoteSha.isNotEmpty &&
        localSha != null &&
        remoteSha != localSha) {
      return true;
    }
    if (!loader.isShardLoaded(remoteShard.id)) {
      return !(await loader.isShardCached(remoteShard.path));
    }
    return false;
  }

  Future<bool> _syncLegacyFallback(RegistryShardLoader loader) async {
    var success = false;
    final legacyUrl = baseUrl.endsWith('/')
        ? '${baseUrl}works_registry.json'
        : '$baseUrl/works_registry.json';
    final legacyContent = await _fetchText(legacyUrl);
    if (legacyContent != null) {
      try {
        final decoded = json.decode(legacyContent);
        if (decoded is Map || decoded is List) {
          final file = await _legacyCacheFile;
          await file.writeAsString(legacyContent);
          await loader.mergeLegacyMonolithicJson(legacyContent);
          success = true;
        }
      } catch (e) {
        appLog('Error syncing legacy registry: $e');
      }
    }
    if (success) {
      await _updateLastSyncTime();
    }
    return success;
  }

  /// 검색어에 필요한 샤드만 온디맨드 다운로드 (shardId dedupe, 미로드만 fetch)
  Future<bool> syncShardsForQuery(String query) async {
    if (query.trim().isEmpty) return false;
    final loader = _effectiveLoader;
    await loader.ensureSearchIndexLoaded();
    final shardIds = loader.resolveShardIdsForQuery(query);
    return syncShardsByIds(shardIds);
  }

  /// 지정 shardId 집합만 원격 fetch (browse window · query 공용)
  Future<bool> syncShardsByIds(Set<String> shardIds) async {
    if (shardIds.isEmpty) return false;
    if (!await _shouldAllowRemoteShardFetch(shardIds)) return false;

    final loader = _effectiveLoader;
    var success = false;
    for (final shardId in shardIds) {
      if (loader.isShardLoaded(shardId)) continue;
      final meta = loader.manifest?.shardById(shardId);
      if (meta == null) continue;
      if (await loader.hasBundledShard(meta.path)) continue;
      final content = await _fetchText('$baseUrl${meta.path}');
      if (content != null) {
        success = await loader.cacheRemoteShard(meta.path, content) || success;
      }
    }
    return success;
  }

  /// 필터 범위에 해당하는 샤드만 온디맨드 다운로드 (shardId dedupe, 미로드만 fetch)
  /// 번들·캐시 manifest가 원격보다 최신이면 fetch 생략 (옛 GitHub 데이터로 덮어쓰기 방지)
  /// ADR-010: 번들에 없는 shard는 manifest 동일 시에도 on-demand fetch 허용
  Future<bool> syncShardsForFilters({
    AppDomain? domain,
    MediaCategory? category,
  }) async {
    final loader = _effectiveLoader;
    final shardIds = loader.resolveShardIdsForFilters(
      domain: domain,
      category: category,
    );
    return syncShardsByIds(shardIds);
  }

  /// 원격 manifest가 더 최신이거나, 번들에 없고 캐시도 없는 shard가 있으면 fetch
  Future<bool> _shouldAllowRemoteShardFetch(Set<String> shardIds) async {
    if (await _remoteManifestIsNewerThanLocal()) return true;

    final loader = _effectiveLoader;
    for (final shardId in shardIds) {
      if (loader.isShardLoaded(shardId)) continue;
      final meta = loader.manifest?.shardById(shardId);
      if (meta == null) continue;
      if (await loader.hasBundledShard(meta.path)) continue;
      if (!(await loader.isShardCached(meta.path))) return true;
    }
    return false;
  }

  Future<bool> _remoteManifestIsNewerThanLocal() async {
    final loader = _effectiveLoader;
    final localAt =
        _parseGeneratedAt(loader.manifest?.generatedAt) ??
        loader.bundledManifestGeneratedAt;
    if (localAt == null) return true;

    final remoteContent = await _fetchText('${baseUrl}manifest.json');
    if (remoteContent == null) return false;
    try {
      final remote = RegistryManifest.fromJson(
        json.decode(remoteContent) as Map<String, dynamic>,
      );
      final remoteAt = _parseGeneratedAt(remote.generatedAt);
      if (remoteAt == null) return false;
      return remoteAt.isAfter(localAt);
    } catch (_) {
      return false;
    }
  }

  Future<String?> _fetchText(String url) async {
    final override = _textFetcherOverride;
    if (override != null) return override(url);

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        return await response.transform(utf8.decoder).join();
      }
    } catch (e) {
      appLog('Error fetching registry resource from $url: $e');
    } finally {
      client.close();
    }
    return null;
  }
}
