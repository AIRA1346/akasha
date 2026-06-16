import 'package:akasha/config/catalog_locale.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/catalog_display_title.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/registry_test_harness.dart';

void main() {
  setUpAll(() async {
    await initRegistryForFranchiseFixtures();
    await prefetchRegistryFixtureQueries(const ['kimetsu', '귀멸']);
  });

  tearDownAll(clearRegistryTestFetcher);

  test('resolveCatalogDisplayTitle uses registry locale titles', () {
    const workId = 'wk_000000343';
    final item = createItem(
      workId: workId,
      title: '귀멸의 칼날',
      category: MediaCategory.manga,
    );

    CatalogLocaleScope.setCurrent(CatalogLocale.ko);
    expect(
      resolveCatalogDisplayTitle(item),
      '귀멸의 칼날',
    );

    CatalogLocaleScope.setCurrent(CatalogLocale.en);
    expect(
      resolveCatalogDisplayTitle(item),
      contains('Demon Slayer'),
    );
  });

  test('resolveCatalogDisplayTitle keeps vault title when workId unknown', () {
    final item = createItem(
      workId: '',
      title: '내가 지은 제목',
      category: MediaCategory.manga,
    );

    CatalogLocaleScope.setCurrent(CatalogLocale.en);
    expect(resolveCatalogDisplayTitle(item), '내가 지은 제목');
  });

  tearDown(() {
    CatalogLocaleScope.setCurrent(CatalogLocale.ko);
  });
}
