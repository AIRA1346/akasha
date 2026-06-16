import 'package:akasha/screens/home/coordinators/home_catalog_coordinator.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_registry_port.dart';
import '../fakes/fake_registry_sync_port.dart';

HomeCatalogCoordinator _catalog({
  required FakeRegistryPort registry,
  FakeRegistrySyncPort? sync,
  bool personalLibrary = false,
}) {
  return HomeCatalogCoordinator(
    registry: registry,
    registrySyncPort: sync ?? FakeRegistrySyncPort(),
    isMounted: () => true,
    scheduleRebuild: (mutate) => mutate(),
    filterCtrl: HomeBrowseFilterController(),
    dashboardCtrl: HomeDashboardController()..activeDashboardId = 'master_index',
    isPersonalLibraryMode: () => personalLibrary,
    showSuccess: (_) {},
    showError: (_) {},
    reloadItems: () async {},
    autoArchiveWorks: ({bool showFeedback = false}) async {},
  );
}

void main() {
  test('catalogHasMore is true when windowed prefetch has remaining entries', () {
    final registry = FakeRegistryPort()..catalogIndexTotal = 5181;
    final catalog = _catalog(registry: registry);

    catalog.catalogBrowseOffset = 48;
    catalog.catalogTotalEntries = 5181;

    expect(catalog.catalogUsesWindowedPrefetch, isTrue);
    expect(catalog.catalogHasMore, isTrue);
    expect(catalog.catalogLoadedThrough, 48);
  });

  test('catalogUsesWindowedPrefetch is false in personal library mode', () {
    final catalog = _catalog(
      registry: FakeRegistryPort(),
      personalLibrary: true,
    );

    expect(catalog.catalogUsesWindowedPrefetch, isFalse);
  });

  test('refreshLastSyncTime reads registry sync port', () async {
    final sync = FakeRegistrySyncPort()
      ..lastSyncTimeValue = DateTime.utc(2026, 6, 16, 12, 30);
    final catalog = _catalog(
      registry: FakeRegistryPort(),
      sync: sync,
    );

    await catalog.refreshLastSyncTime();

    expect(sync.initCallCount, 1);
    expect(catalog.lastSyncTime, sync.lastSyncTimeValue);
  });

  test('syncRegistry delegates to registry sync port', () async {
    final sync = FakeRegistrySyncPort()..syncResult = true;
    final catalog = _catalog(
      registry: FakeRegistryPort(),
      sync: sync,
    )..init();

    await catalog.syncRegistry();

    expect(sync.syncCallCount, 1);
  });
}
