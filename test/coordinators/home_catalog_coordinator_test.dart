import 'package:akasha/screens/home/coordinators/home_catalog_coordinator.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_registry_port.dart';

HomeCatalogCoordinator _catalog({
  required FakeRegistryPort registry,
  bool personalLibrary = false,
  void Function(String message)? showError,
}) {
  return HomeCatalogCoordinator(
    registry: registry,
    isMounted: () => true,
    scheduleRebuild: (mutate) => mutate(),
    filterCtrl: HomeBrowseFilterController(),
    dashboardCtrl: HomeDashboardController()
      ..activeDashboardId = 'master_index',
    isPersonalLibraryMode: () => personalLibrary,
    showError: showError ?? (_) {},
  );
}

void main() {
  test(
    'catalogHasMore is true when windowed prefetch has remaining entries',
    () {
      final registry = FakeRegistryPort()..catalogIndexTotal = 5181;
      final catalog = _catalog(registry: registry);

      catalog.catalogBrowseOffset = 48;
      catalog.catalogTotalEntries = 5181;

      expect(catalog.catalogUsesWindowedPrefetch, isTrue);
      expect(catalog.catalogHasMore, isTrue);
      expect(catalog.catalogLoadedThrough, 48);
    },
  );

  test('catalogUsesWindowedPrefetch is false in personal library mode', () {
    final catalog = _catalog(
      registry: FakeRegistryPort(),
      personalLibrary: true,
    );

    expect(catalog.catalogUsesWindowedPrefetch, isFalse);
  });

  test(
    'bundle failures are reported instead of becoming empty results',
    () async {
      final errors = <String>[];
      final registry = FakeRegistryPort()
        ..catalogIndexTotal = 5181
        ..prefetchFailure = StateError('missing bundled shard');
      final catalog = _catalog(registry: registry, showError: errors.add);

      await catalog.prefetchRegistryForCurrentFilters();

      expect(catalog.isCatalogLoading, isFalse);
      expect(errors, hasLength(1));
      expect(errors.single, contains('missing bundled shard'));
    },
  );
}
