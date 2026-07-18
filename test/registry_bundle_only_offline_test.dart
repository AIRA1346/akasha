import 'dart:io';

import 'package:akasha/models/enums.dart';
import 'package:akasha/services/franchise_registry.dart';
import 'package:akasha/services/registry_cache_contract.dart';
import 'package:akasha/services/registry_sync_service.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  late Directory documents;
  var networkCalls = 0;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp(
      'akasha_bundle_only_offline_',
    );
    PathProviderPlatform.instance = _FakePathProvider(documents);
    SharedPreferences.setMockInitialValues({
      RegistryCacheContract.lastSyncPreferenceKey: '2026-06-19T00:00:00Z',
      RegistryCacheContract.customDbUrlPreferenceKey: 'https://stale.test/',
    });

    final cache = Directory(
      p.join(documents.path, RegistryCacheContract.cacheDirectoryName),
    )..createSync(recursive: true);
    File(p.join(cache.path, 'manifest.json')).writeAsStringSync('{}');
    File(
      p.join(documents.path, RegistryCacheContract.legacyRegistryFileName),
    ).writeAsStringSync('{}');

    RegistrySyncService.setTextFetcherForTesting((url) async {
      networkCalls++;
      throw StateError('registry network access is forbidden: $url');
    });
    RegistrySyncService.resetFactoryInvocationCountForTesting();

    await WorksRegistry.init();
    await FranchiseRegistry.init();
  });

  tearDownAll(() async {
    RegistrySyncService.setTextFetcherForTesting(null);
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  test(
    'production bootstrap migrates stale remote state without network',
    () async {
      expect(WorksRegistry.loader.manifest?.bundleMode, 'full');
      expect(WorksRegistry.loader.manifest?.entryCount, 10048);
      expect(WorksRegistry.loader.manifest?.shards, hasLength(1713));
      expect(
        Directory(
          p.join(documents.path, RegistryCacheContract.cacheDirectoryName),
        ).existsSync(),
        isFalse,
      );
      expect(
        File(
          p.join(documents.path, RegistryCacheContract.legacyRegistryFileName),
        ).existsSync(),
        isFalse,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool(
          RegistryCacheContract.bundleOnlyMigrationPreferenceKey,
        ),
        isTrue,
      );
      expect(
        preferences.containsKey(RegistryCacheContract.customDbUrlPreferenceKey),
        isFalse,
      );
      expect(networkCalls, 0);
      expect(RegistrySyncService.factoryInvocationCountForTesting, 0);
    },
  );

  test('Korean, English, and alias lookup stay inside the bundle', () async {
    final english = await WorksRegistry.searchAsync('Triangle Strategy');
    final korean = await WorksRegistry.searchAsync('트라이앵글 스트래티지');
    final alias = await WorksRegistry.getWorkByIdAsync('axiom_game');

    expect(english.map((work) => work.workId), contains('wk_000001375'));
    expect(korean.map((work) => work.workId), contains('wk_000001375'));
    expect(alias?.workId, 'wk_000000135');
    expect(networkCalls, 0);
  });

  test('eager and representative on-demand details load offline', () async {
    expect(WorksRegistry.getWorkById('wk_000000258'), isNotNull);
    expect(await WorksRegistry.getWorkByIdAsync('wk_000001375'), isNotNull);
    expect(await WorksRegistry.getWorkByIdAsync('wk_000000680'), isNotNull);
    expect(await WorksRegistry.getWorkByIdAsync('wk_000001079'), isNotNull);
    expect(networkCalls, 0);
  });

  test(
    'category, browse windows, load more, and franchise stay offline',
    () async {
      final movies = await WorksRegistry.getFilteredWorks(
        category: MediaCategory.movie,
      );
      expect(movies, isNotEmpty);

      await WorksRegistry.reloadBundleForTesting();
      await WorksRegistry.prefetchBrowseWindow(offset: 0, limit: 48);
      final firstWindowCount = WorksRegistry.allWorks.length;
      await WorksRegistry.prefetchBrowseWindow(offset: 48, limit: 48);
      expect(firstWindowCount, greaterThan(0));
      expect(WorksRegistry.allWorks.length, greaterThan(firstWindowCount));

      expect(FranchiseRegistry.groupFor('wk_000000292')?.id, 'franchise_86');
      expect(networkCalls, 0);
      expect(RegistrySyncService.factoryInvocationCountForTesting, 0);
      expect(
        Directory(
          p.join(documents.path, RegistryCacheContract.cacheDirectoryName),
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('registry reinitialization remains bundle-only', () async {
    await WorksRegistry.reloadBundleForTesting();
    expect(await WorksRegistry.getWorkByIdAsync('wk_000000001'), isNotNull);
    expect(networkCalls, 0);
    expect(RegistrySyncService.factoryInvocationCountForTesting, 0);
  });
}
