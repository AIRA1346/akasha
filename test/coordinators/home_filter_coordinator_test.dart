import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/models/enums.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/coordinators/home_filter_coordinator.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';

void main() {
  group('HomeFilterCoordinator', () {
    late HomeBrowseFilterController filterCtrl;
    late HomeDashboardController dashboardCtrl;
    late HomePersonalLibraryController personalLibCtrl;
    late HomeFilterCoordinator coordinator;

    setUp(() {
      filterCtrl = HomeBrowseFilterController();
      dashboardCtrl = HomeDashboardController();
      personalLibCtrl = HomePersonalLibraryController();
      coordinator = HomeFilterCoordinator(
        filterCtrl: filterCtrl,
        dashboardCtrl: dashboardCtrl,
        personalLibCtrl: personalLibCtrl,
      );
    });

    test('대시보드 모드에서 도메인 변경 시 prefetch 필요', () {
      personalLibCtrl.sidebarMode = SidebarSelectionMode.dashboard;
      filterCtrl.onDomainChanged(AppDomain.subculture);

      final needsPrefetch =
          coordinator.onDomainChanged(AppDomain.generalCulture);

      expect(needsPrefetch, isTrue);
      expect(filterCtrl.domain, AppDomain.generalCulture);
    });

    test('나만의 서재 모드에서 카테고리 토글 시 prefetch 불필요', () {
      personalLibCtrl.sidebarMode = SidebarSelectionMode.personalLibrary;
      personalLibCtrl.libraries = [
        PersonalLibraryConfig(
          id: 'lib1',
          name: 'Test',
          categories: {MediaCategory.animation},
        ),
      ];
      personalLibCtrl.activeLibraryId = 'lib1';

      final needsPrefetch =
          coordinator.toggleCategory(MediaCategory.game);

      expect(needsPrefetch, isFalse);
      expect(filterCtrl.categories, contains(MediaCategory.game));
    });
  });
}
