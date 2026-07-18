import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/registry_models.dart';
import 'package:akasha/services/registry_sync_service.dart';
import 'package:akasha/services/works_registry.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root.path;
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('akasha_sync_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempRoot);
    SharedPreferences.setMockInitialValues({});
    RegistrySyncService.setTextFetcherForTesting(null);
    RegistrySyncService().resetForTesting();
    await WorksRegistry.init();
    await WorksRegistry.reloadBundleForTesting();
    RegistrySyncService().bindLoader(WorksRegistry.loader);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  tearDown(() {
    RegistrySyncService.setTextFetcherForTesting(null);
    RegistrySyncService().resetForTesting();
  });

  group('RegistrySyncService', () {
    test('shouldAutoSync returns true when never synced', () async {
      final service = RegistrySyncService();
      await service.init();
      expect(await service.shouldAutoSync(), isTrue);
    });

    test('shouldAutoSync returns false within 24 hours', () async {
      SharedPreferences.setMockInitialValues({
        'akasha_last_sync_time':
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      });
      final service = RegistrySyncService();
      service.resetForTesting();
      await service.init();
      expect(await service.shouldAutoSync(), isFalse);
    });

    test('sync clears stale cache when remote manifest is newer', () async {
      final localManifest = WorksRegistry.loader.manifest;
      expect(localManifest, isNotNull);

      final fetchedUrls = <String>[];
      RegistrySyncService.setTextFetcherForTesting((url) async {
        fetchedUrls.add(url);
        if (url.endsWith('search_index/manifest.json')) {
          return null;
        }
        if (url.endsWith('manifest.json') && !url.contains('search_index/')) {
          return jsonEncode({
            'version': localManifest!.version,
            'generatedAt': '2099-01-01T00:00:00.000Z',
            'shards': localManifest.shards
                .where((s) => s.eager)
                .map(
                  (s) => {
                    'id': s.id,
                    'category': s.category.name,
                    'path': s.path,
                    'eager': s.eager,
                    'entryCount': s.entryCount,
                  },
                )
                .toList(),
          });
        }
        if (url.endsWith('search_index.json')) {
          return jsonEncode([]);
        }
        if (url.contains('/shards/')) {
          return jsonEncode({});
        }
        return null;
      });

      final service = RegistrySyncService();
      await service.init();
      final result = await service.sync();

      expect(result, isTrue);
      expect(
        fetchedUrls.where((u) => u.endsWith('search_index.json')),
        isNotEmpty,
      );
    });

    test('sync returns true when remote manifest matches local', () async {
      final localManifest = WorksRegistry.loader.manifest;
      expect(localManifest, isNotNull);

      final fetchedUrls = <String>[];
      RegistrySyncService.setTextFetcherForTesting((url) async {
        fetchedUrls.add(url);
        if (url.endsWith('search_index/manifest.json')) {
          return null;
        }
        if (url.endsWith('manifest.json') && !url.contains('search_index/')) {
          return jsonEncode({
            'version': localManifest!.version,
            'generatedAt': localManifest.generatedAt,
            'shards': localManifest.shards
                .map(
                  (s) => {
                    'id': s.id,
                    'category': s.category.name,
                    'path': s.path,
                    'eager': s.eager,
                    'entryCount': s.entryCount,
                  },
                )
                .toList(),
          });
        }
        return null;
      });

      final service = RegistrySyncService();
      await service.init();
      final result = await service.sync();

      expect(result, isTrue);
      expect(fetchedUrls.where((u) => u.endsWith('manifest.json')), isNotEmpty);
      expect(
        fetchedUrls.where((u) => u.endsWith('search_index.json')),
        isEmpty,
      );
    });

    test('sync requests legacy registry when manifest unavailable', () async {
      final fetchedUrls = <String>[];
      RegistrySyncService.setTextFetcherForTesting((url) async {
        fetchedUrls.add(url);
        if (url.endsWith('works_registry.json')) {
          return jsonEncode([
            {
              'workId': 'legacy_test_1999',
              'title': 'Legacy Test',
              'category': 'manga',
              'domain': 'subculture',
            },
          ]);
        }
        return null;
      });

      final service = RegistrySyncService();
      await service.init();
      await service.sync();

      expect(
        fetchedUrls.any((u) => u.contains('works_registry.json')),
        isTrue,
      );
    });

    test('syncShardsForQuery returns false for empty query', () async {
      final service = RegistrySyncService();
      expect(await service.syncShardsForQuery(''), isFalse);
      expect(await service.syncShardsForQuery('   '), isFalse);
    });

    test('syncShardsByIds skips a bundled shard when manifest matches local',
        () async {
      WorksRegistry.loader.resetLoadedShardsForTesting();
      await WorksRegistry.reloadBundleForTesting();

      final loader = WorksRegistry.loader;
      final manifest = loader.manifest;
      expect(manifest, isNotNull);

      RegistryShardMeta? target;
      for (final s in manifest!.shards) {
        if (s.eager) continue;
        if (!await loader.hasBundledShard(s.path)) continue;
        target = s;
        break;
      }
      expect(target, isNotNull);
      final bundled = target!;

      final fetchedUrls = <String>[];
      RegistrySyncService.setTextFetcherForTesting((url) async {
        fetchedUrls.add(url);
        if (url.endsWith('manifest.json') && !url.contains('search_index/')) {
          return jsonEncode({
            'version': manifest.version,
            'generatedAt': manifest.generatedAt,
            'shards': manifest.shards
                .map(
                  (s) => {
                    'id': s.id,
                    'category': s.category.name,
                    'path': s.path,
                    'eager': s.eager,
                    'entryCount': s.entryCount,
                  },
                )
                .toList(),
          });
        }
        if (url.endsWith(bundled.path)) {
          return jsonEncode({'wk_test_sync': {'workId': 'wk_test_sync'}});
        }
        return null;
      });

      final service = RegistrySyncService();
      final ok = await service.syncShardsByIds({bundled.id});

      expect(ok, isFalse);
      expect(fetchedUrls.where((u) => u.endsWith(bundled.path)), isEmpty);
    });
  });
}
