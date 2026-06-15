import 'dart:io';

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

/// ADR-010 eager-only: non-eager shard는 akasha-db 로컬 파일에서 fetch
void mockAkashaDbShardFetcher() {
  RegistrySyncService.setTextFetcherForTesting((url) async {
    final uri = Uri.parse(url);
    var path = uri.path;
    if (path.startsWith('/')) path = path.substring(1);
    if (path.startsWith('shards/')) {
      final file = File('akasha-db/$path');
      if (file.existsSync()) return file.readAsStringSync();
    }
    return null;
  });
}

void clearRegistryTestFetcher() {
  RegistrySyncService.setTextFetcherForTesting(null);
}

Future<void> prefetchRegistryFixtureQueries(Iterable<String> queries) async {
  for (final q in queries) {
    await RegistrySyncService().syncShardsForQuery(q);
    await WorksRegistry.loader.ensureShardsForQuery(q);
  }
}

/// 게임 카테고리 전체 shard (phase6 fusion 등)
Future<void> initRegistryForGameCategoryFixtures() async {
  installRegistryTestBindings();
  await WorksRegistry.init();
  WorksRegistry.loader.resetLoadedShardsForTesting();
  await WorksRegistry.clearDiskCacheAndReloadBundle();
  mockAkashaDbShardFetcher();
  await WorksRegistry.prefetchForFilters(categories: {MediaCategory.game});
}

/// G1+ @5181: franchise·browse pipeline fixture shard 로드
Future<void> initRegistryForFranchiseFixtures() async {
  installRegistryTestBindings();
  await WorksRegistry.init();
  await FranchiseRegistry.init();
  WorksRegistry.loader.resetLoadedShardsForTesting();
  await WorksRegistry.clearDiskCacheAndReloadBundle();
  mockAkashaDbShardFetcher();

  await prefetchRegistryFixtureQueries(
    const ['rezero', '제로', '86', '에이티식스'],
  );
}
