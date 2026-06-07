import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/registry_models.dart';
import 'registry_shard_loader.dart';
import 'works_registry.dart';

typedef RegistryTextFetcher = Future<String?> Function(String url);

/// Git 기반 글로벌 작품 사전 동기화 서비스 (샤딩 아키텍처)
class RegistrySyncService {
  static const String _prefLastSyncKey = 'akasha_last_sync_time';
  static const String _prefCustomUrlKey = 'akasha_custom_db_url';

  static const String defaultDbBaseUrl =
      'https://raw.githubusercontent.com/AIRA1346/akasha-db/main/';

  static const String defaultLegacyDbUrl =
      '${defaultDbBaseUrl}works_registry.json';

  static final RegistrySyncService _instance = RegistrySyncService._internal();
  factory RegistrySyncService() => _instance;
  RegistrySyncService._internal();

  SharedPreferences? _prefs;
  static RegistryTextFetcher? _textFetcherOverride;

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
    return File(p.join(dir.path, 'local_works_registry.json'));
  }

  Future<String?> readCachedRegistry() async {
    try {
      final file = await _legacyCacheFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error reading legacy registry cache: $e');
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
    final loader = WorksRegistry.loader;
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
      print('Error parsing remote manifest: $e');
      return _syncLegacyFallback(loader);
    }

    if (_isManifestUpToDate(previousManifest, remoteManifest)) {
      await _updateLastSyncTime();
      return true;
    }

    success = await loader.cacheRemoteManifest(manifestContent);

    final indexContent = await _fetchText('${baseUrl}search_index.json');
    if (indexContent != null) {
      success = (await loader.cacheRemoteSearchIndex(indexContent)) || success;
    }

    final eagerShards = remoteManifest.eagerShards();
    for (final shard in eagerShards) {
      if (!await _shardNeedsSync(shard, previousManifest, loader)) continue;
      final shardContent = await _fetchText('${baseUrl}${shard.path}');
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
          print('Error syncing legacy registry: $e');
        }
      }
    }

    if (success) {
      await _updateLastSyncTime();
    }
    return success;
  }

  Future<void> _updateLastSyncTime() async {
    await _prefs?.setString(
      _prefLastSyncKey,
      DateTime.now().toIso8601String(),
    );
  }

  bool _isManifestUpToDate(
    RegistryManifest? local,
    RegistryManifest remote,
  ) {
    if (local == null) return false;
    final localGen = local.generatedAt;
    final remoteGen = remote.generatedAt;
    if (localGen == null || remoteGen == null) return false;
    return localGen == remoteGen;
  }

  Future<bool> _shardNeedsSync(
    RegistryShardMeta remoteShard,
    RegistryManifest? previousManifest,
    RegistryShardLoader loader,
  ) async {
    final previousShard = previousManifest?.shardById(remoteShard.id);
    if (previousShard == null) return true;
    if (previousShard.entryCount != remoteShard.entryCount) return true;
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
        print('Error syncing legacy registry: $e');
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
    final loader = WorksRegistry.loader;
    final shardIds = loader.resolveShardIdsForQuery(query);
    if (shardIds.isEmpty) return false;

    var success = false;
    for (final shardId in shardIds) {
      if (loader.isShardLoaded(shardId)) continue;
      final meta = loader.manifest?.shardById(shardId);
      if (meta == null) continue;
      final content = await _fetchText('${baseUrl}${meta.path}');
      if (content != null) {
        success = await loader.cacheRemoteShard(meta.path, content) || success;
      }
    }
    return success;
  }

  /// 필터 범위에 해당하는 샤드만 온디맨드 다운로드 (shardId dedupe, 미로드만 fetch)
  Future<bool> syncShardsForFilters({
    AppDomain? domain,
    MediaCategory? category,
  }) async {
    final loader = WorksRegistry.loader;
    final shardIds = loader.resolveShardIdsForFilters(
      domain: domain,
      category: category,
    );
    if (shardIds.isEmpty) return false;

    var success = false;
    for (final shardId in shardIds) {
      if (loader.isShardLoaded(shardId)) continue;
      final meta = loader.manifest?.shardById(shardId);
      if (meta == null) continue;
      final content = await _fetchText('${baseUrl}${meta.path}');
      if (content != null) {
        success = await loader.cacheRemoteShard(meta.path, content) || success;
      }
    }
    return success;
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
      print('Error fetching registry resource from $url: $e');
    } finally {
      client.close();
    }
    return null;
  }
}
