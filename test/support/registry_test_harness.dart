import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/franchise_registry.dart';
import 'package:akasha/services/registry_sync_service.dart';
import 'package:akasha/services/works_registry.dart';

/// path_provider mock — disk cache 경로 필요 테스트 공용
void installRegistryTestBindings() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => '.');
}

/// Isolated provider guard: production-style fixture reads must stay local.
void mockAkashaDbShardFetcher() {
  RegistrySyncService.setTextFetcherForTesting(
    (url) => throw StateError('registry network access is forbidden: $url'),
  );
}

void clearRegistryTestFetcher() {
  RegistrySyncService.setTextFetcherForTesting(null);
}

Future<void> prefetchRegistryFixtureQueries(Iterable<String> queries) async {
  for (final q in queries) {
    await WorksRegistry.searchAsync(q);
  }
}

/// 게임 카테고리 전체 shard (phase6 fusion 등)
Future<void> initRegistryForGameCategoryFixtures() async {
  installRegistryTestBindings();
  await WorksRegistry.init();
  WorksRegistry.loader.resetLoadedShardsForTesting();
  await WorksRegistry.reloadBundleForTesting();
  mockAkashaDbShardFetcher();
  await WorksRegistry.prefetchForFilters(categories: {MediaCategory.game});
}

/// G1+ @5181: franchise·browse pipeline fixture shard 로드
Future<void> initRegistryForFranchiseFixtures() async {
  installRegistryTestBindings();
  await WorksRegistry.init();
  await FranchiseRegistry.init();
  WorksRegistry.loader.resetLoadedShardsForTesting();
  await WorksRegistry.reloadBundleForTesting();
  mockAkashaDbShardFetcher();

  await prefetchRegistryFixtureQueries(const ['rezero', '제로', '86', '에이티식스']);
}
