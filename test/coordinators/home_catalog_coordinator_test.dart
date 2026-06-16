import 'package:akasha/screens/home/coordinators/home_catalog_coordinator.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogHasMore is true when windowed prefetch has remaining entries', () {
    final filterCtrl = HomeBrowseFilterController();
    final dashboardCtrl = HomeDashboardController();
    dashboardCtrl.activeDashboardId = 'master_index';

    final catalog = HomeCatalogCoordinator(
      isMounted: () => true,
      scheduleRebuild: (_) {},
      filterCtrl: filterCtrl,
      dashboardCtrl: dashboardCtrl,
      isPersonalLibraryMode: () => false,
      showSuccess: (_) {},
      showError: (_) {},
      reloadItems: () async {},
      autoArchiveWorks: ({bool showFeedback = false}) async {},
    );

    catalog.catalogBrowseOffset = 48;
    catalog.catalogTotalEntries = 5181;

    expect(catalog.catalogUsesWindowedPrefetch, isTrue);
    expect(catalog.catalogHasMore, isTrue);
    expect(catalog.catalogLoadedThrough, 48);
  });

  test('catalogUsesWindowedPrefetch is false in personal library mode', () {
    final catalog = HomeCatalogCoordinator(
      isMounted: () => true,
      scheduleRebuild: (_) {},
      filterCtrl: HomeBrowseFilterController(),
      dashboardCtrl: HomeDashboardController()..activeDashboardId = 'master_index',
      isPersonalLibraryMode: () => true,
      showSuccess: (_) {},
      showError: (_) {},
      reloadItems: () async {},
      autoArchiveWorks: ({bool showFeedback = false}) async {},
    );

    expect(catalog.catalogUsesWindowedPrefetch, isFalse);
  });
}
