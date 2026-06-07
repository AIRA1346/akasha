import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/services/registry_sync_service.dart';
import 'package:akasha/services/works_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RegistrySyncService.setTextFetcherForTesting(null);
    RegistrySyncService().resetForTesting();
    await WorksRegistry.init();
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

    test('sync returns true when remote manifest matches local', () async {
      final localManifest = WorksRegistry.loader.manifest;
      expect(localManifest, isNotNull);

      final fetchedUrls = <String>[];
      RegistrySyncService.setTextFetcherForTesting((url) async {
        fetchedUrls.add(url);
        if (url.endsWith('manifest.json')) {
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
  });
}
