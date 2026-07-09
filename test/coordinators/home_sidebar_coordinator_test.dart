import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/coordinators/home_filter_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_sidebar_coordinator.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_collectible_collection_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/screens/home/home_section_preferences.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  group('HomeSidebarCoordinator', () {
    late HomeDashboardController dashboardCtrl;
    late HomePersonalLibraryController personalLibCtrl;
    late HomeSectionPreferences sectionPrefs;
    late HomeFilterCoordinator filterCoordinator;
    late HomeSidebarCoordinator sidebarCoordinator;

    setUp(() {
      dashboardCtrl = HomeDashboardController();
      personalLibCtrl = HomePersonalLibraryController();
      sectionPrefs = HomeSectionPreferences();
      filterCoordinator = HomeFilterCoordinator(
        filterCtrl: HomeBrowseFilterController(),
        dashboardCtrl: dashboardCtrl,
        personalLibCtrl: personalLibCtrl,
      );
      sidebarCoordinator = HomeSidebarCoordinator(
        personalLibCtrl: personalLibCtrl,
        collectionCtrl: HomeCollectibleCollectionController(),
        dashboardCtrl: dashboardCtrl,
        sectionPrefs: sectionPrefs,
        filterCoordinator: filterCoordinator,
      );
    });

    test('curated 서재 선택 시 manualOrder 정렬로 전환', () {
      personalLibCtrl.sidebarMode = SidebarSelectionMode.dashboard;
      sectionPrefs.librarySort = SortCriteria.titleAsc;
      personalLibCtrl.libraries = [
        PersonalLibraryConfig(
          id: 'curated1',
          name: 'Curated',
          mode: PersonalLibraryMode.curated,
        ),
      ];

      sidebarCoordinator.selectPersonalLibrary('curated1');

      expect(sectionPrefs.librarySort, SortCriteria.manualOrder);
      expect(sidebarCoordinator.isCuratedLibraryActive, isTrue);
    });
  });
}
