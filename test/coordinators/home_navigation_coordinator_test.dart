import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/features/workbench/data/workbench_controller.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/coordinators/home_filter_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_navigation_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_sidebar_coordinator.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_collectible_collection_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/screens/home/home_section_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeNavigationCoordinator', () {
    late HomeDashboardController dashboardCtrl;
    late HomePersonalLibraryController personalLibCtrl;
    late HomeBrowseFilterController filterCtrl;
    late HomeFilterCoordinator filterCoordinator;
    late HomeSidebarCoordinator sidebarCoordinator;
    late WorkbenchController workbench;
    late HomeNavigationCoordinator navigation;
  var rebuildCount = 0;

    setUp(() {
      rebuildCount = 0;
      dashboardCtrl = HomeDashboardController();
      dashboardCtrl.dashboards = HomeDashboardController.defaultDashboards();
      dashboardCtrl.activeDashboardId = 'master_index';

      personalLibCtrl = HomePersonalLibraryController();
      filterCtrl = HomeBrowseFilterController();
      filterCoordinator = HomeFilterCoordinator(
        filterCtrl: filterCtrl,
        dashboardCtrl: dashboardCtrl,
        personalLibCtrl: personalLibCtrl,
      );
      sidebarCoordinator = HomeSidebarCoordinator(
        personalLibCtrl: personalLibCtrl,
        collectionCtrl: HomeCollectibleCollectionController(),
        dashboardCtrl: dashboardCtrl,
        sectionPrefs: HomeSectionPreferences(),
        filterCoordinator: filterCoordinator,
      );
      workbench = WorkbenchController();
      navigation = HomeNavigationCoordinator(
        isMounted: () => true,
        scheduleRebuild: (mutate) => mutate(),
        sidebarCoordinator: sidebarCoordinator,
        filterCoordinator: filterCoordinator,
        workbench: workbench,
        prefetchRegistry: () async {},
        rebuild: () => rebuildCount++,
      );
    });

    test('goHome clears explore mode and filters for premium dashboard', () async {
      navigation.isExploreBrowseMode = true;
      filterCtrl.domain = AppDomain.subculture;
      filterCtrl.categories.add(MediaCategory.animation);

      await navigation.goHome();

      expect(navigation.isExploreBrowseMode, isFalse);
      expect(navigation.isHomeDashboardMode, isTrue);
      expect(filterCtrl.hasAnyFilters, isFalse);
      expect(dashboardCtrl.activeDashboardId, 'master_index');
    });

    test('goExplore enables browse grid on master dashboard', () async {
      await navigation.goExplore();

      expect(navigation.isExploreBrowseMode, isTrue);
      expect(navigation.isExploreModeActive, isTrue);
      expect(navigation.isHomeDashboardMode, isFalse);
    });

    test('selectDashboard clears explore mode', () async {
      navigation.isExploreBrowseMode = true;

      await navigation.selectDashboard('master_index');

      expect(navigation.isExploreBrowseMode, isFalse);
    });
  });
}
