import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/data/adapters/works_registry_adapter.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_registry_prefetch.dart';
import 'package:akasha/services/registry_sync_service.dart';
import 'package:akasha/services/works_registry.dart';

/// Isolated provider guard: any registry network access fails this test.
void _mockAkashaDbShardFetcher() {
  RegistrySyncService.setTextFetcherForTesting(
    (url) => throw StateError('registry network access is forbidden: $url'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.';
  });

  setUpAll(() async {
    await WorksRegistry.init();
  });

  tearDown(() {
    RegistrySyncService.setTextFetcherForTesting(null);
  });

  group('browse window dogfood @5181', () {
    test('catalog index exceeds full-load threshold', () {
      final total = WorksRegistry.catalogIndexEntryCount();
      expect(total, greaterThan(WorksRegistry.browseFullCatalogThreshold));
      expect(total, greaterThanOrEqualTo(5000));
    });

    test('first prefetch loads window not full catalog', () async {
      WorksRegistry.loader.resetLoadedShardsForTesting();
      await WorksRegistry.reloadBundleForTesting();

      final total = WorksRegistry.catalogIndexEntryCount();
      await WorksRegistry.prefetchBrowseWindow(
        limit: WorksRegistry.browsePrefetchWindowSize,
      );
      final loaded = WorksRegistry.allWorks.length;

      expect(total, greaterThan(WorksRegistry.browseFullCatalogThreshold));
      expect(loaded, greaterThan(0));
      expect(loaded, lessThan(total));
    });

    test('loadMore prefetch accumulates locally bundled shard entries', () async {
      WorksRegistry.loader.resetLoadedShardsForTesting();
      await WorksRegistry.reloadBundleForTesting();
      _mockAkashaDbShardFetcher();

      final total = WorksRegistry.catalogIndexEntryCount();
      const window = WorksRegistry.browsePrefetchWindowSize;

      await WorksRegistry.prefetchBrowseWindow(offset: 0, limit: window);
      final afterFirst = WorksRegistry.allWorks.length;

      await WorksRegistry.prefetchBrowseWindow(
        offset: window,
        limit: window,
      );
      final afterSecond = WorksRegistry.allWorks.length;

      expect(afterFirst, greaterThan(0));
      expect(afterSecond, greaterThan(afterFirst));
      expect(afterSecond, lessThanOrEqualTo(total));
    });

    test('prefetchRegistryForFilters emits window progress state', () async {
      WorksRegistry.loader.resetLoadedShardsForTesting();
      await WorksRegistry.reloadBundleForTesting();

      final filters = HomeBrowseFilterController();
      CatalogWindowState? state;

      await prefetchRegistryForFilters(
        registry: WorksRegistryAdapter(),
        activeDashboardId: 'master_index',
        filters: filters,
        onCatalogLoadingChanged: (_) {},
        isMounted: () => true,
        onDataChanged: () {},
        onCatalogWindowState: (s) => state = s,
      );

      expect(state, isNotNull);
      final s = state!;
      expect(s.totalEntries, greaterThan(WorksRegistry.browseFullCatalogThreshold));
      expect(s.browseOffset, WorksRegistry.browsePrefetchWindowSize);
    });

    test('master_index filter prefetch emits scoped catalog window state', () async {
      WorksRegistry.loader.resetLoadedShardsForTesting();
      await WorksRegistry.reloadBundleForTesting();

      final filters = HomeBrowseFilterController()
        ..toggleCategory(MediaCategory.webtoon);
      final webtoonTotal = WorksRegistry.catalogIndexEntryCount(
        category: MediaCategory.webtoon,
      );
      CatalogWindowState? state;

      await prefetchRegistryForFilters(
        registry: WorksRegistryAdapter(),
        activeDashboardId: 'master_index',
        filters: filters,
        onCatalogLoadingChanged: (_) {},
        isMounted: () => true,
        onDataChanged: () {},
        onCatalogWindowState: (s) => state = s,
      );

      expect(state, isNotNull);
      final s = state!;
      expect(s.totalEntries, webtoonTotal);
      expect(s.browseOffset, webtoonTotal);
      expect(webtoonTotal, greaterThan(0));
    });

    test('append prefetch advances catalog window offset', () async {
      WorksRegistry.loader.resetLoadedShardsForTesting();
      await WorksRegistry.reloadBundleForTesting();

      final filters = HomeBrowseFilterController();
      CatalogWindowState? first;
      CatalogWindowState? second;

      await prefetchRegistryForFilters(
        registry: WorksRegistryAdapter(),
        activeDashboardId: 'master_index',
        filters: filters,
        onCatalogLoadingChanged: (_) {},
        isMounted: () => true,
        onDataChanged: () {},
        onCatalogWindowState: (s) => first = s,
      );

      await prefetchRegistryForFilters(
        registry: WorksRegistryAdapter(),
        activeDashboardId: 'master_index',
        filters: filters,
        onCatalogLoadingChanged: (_) {},
        isMounted: () => true,
        onDataChanged: () {},
        append: true,
        browseOffset: first!.browseOffset,
        onCatalogWindowState: (s) => second = s,
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      final f = first!;
      final s = second!;
      expect(s.browseOffset, greaterThan(f.browseOffset));
      expect(s.totalEntries, f.totalEntries);
    });

    test('webtoon category filter loads category-scoped works', () async {
      WorksRegistry.loader.resetLoadedShardsForTesting();
      await WorksRegistry.reloadBundleForTesting();

      final indexTotal = WorksRegistry.catalogIndexEntryCount(
        category: MediaCategory.webtoon,
      );
      expect(indexTotal, greaterThanOrEqualTo(2));

      _mockAkashaDbShardFetcher();

      await WorksRegistry.prefetchForFilters(
        categories: {MediaCategory.webtoon},
      );
      final works = await WorksRegistry.getFilteredWorks(
        category: MediaCategory.webtoon,
      );

      expect(works.length, greaterThanOrEqualTo(2));
      expect(works.every((w) => w.workId.startsWith('wk_')), isTrue);
      expect(works.length, lessThanOrEqualTo(indexTotal));
    });
  });
}
