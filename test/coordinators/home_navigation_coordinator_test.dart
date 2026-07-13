import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akasha/features/workbench/data/workbench_controller.dart';
import 'package:akasha/features/workbench/presentation/collectible_tab.dart';
import 'package:akasha/models/browse_entity_scope.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/coordinators/home_filter_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_navigation_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_sidebar_coordinator.dart';
import 'package:akasha/screens/home/app_destination.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_collectible_collection_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/screens/home/home_section_preferences.dart';
import 'package:akasha/utils/helpers.dart';

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
    late WorkbenchNavigationGuardPrompt guardPrompt;
    var rebuildCount = 0;
    var legacyLoadCount = 0;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      rebuildCount = 0;
      legacyLoadCount = 0;
      guardPrompt = ({required title, required canSave}) async =>
          WorkbenchNavigationDecision.cancel;
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
        ensureLegacyItemsLoaded: () async => legacyLoadCount++,
        requestWorkbenchNavigationDecision:
            ({required title, required canSave}) =>
                guardPrompt(title: title, canSave: canSave),
      );
    });

    test(
      'goHome clears explore mode and filters for premium dashboard',
      () async {
        await navigation.goExplore();
        filterCtrl.categories.add(MediaCategory.animation);

        await navigation.goHome();

        expect(navigation.isExploreBrowseMode, isFalse);
        expect(navigation.isHomeDashboardMode, isTrue);
        expect(filterCtrl.hasAnyFilters, isFalse);
        expect(dashboardCtrl.activeDashboardId, 'master_index');
      },
    );

    test('goExplore enables browse grid on master dashboard', () async {
      await navigation.goExplore();

      expect(navigation.isExploreBrowseMode, isTrue);
      expect(navigation.isExploreModeActive, isTrue);
      expect(navigation.isHomeDashboardMode, isFalse);
    });

    test('enterWorkArchiveBrowse selects the bounded Work scope', () async {
      await navigation.enterWorkArchiveBrowse();

      expect(navigation.isExploreBrowseMode, isTrue);
      expect(filterCoordinator.filterCtrl.entityScope, BrowseEntityScope.work);
      expect(legacyLoadCount, 0);
    });

    test(
      'Explore / Graph stay bounded; Home surfaces request legacy items',
      () async {
        await navigation.goExplore();
        await navigation.goKnowledgeGraph();
        expect(legacyLoadCount, 0);
        expect(navigation.currentDestination, AppDestination.graph);

        await navigation.goHome();
        expect(legacyLoadCount, 1);
        expect(navigation.isHomeDashboardMode, isTrue);

        await navigation.selectDashboard('master_index');
        expect(legacyLoadCount, 2);

        expect(navigation.isKnowledgeGraphMode, isFalse);
      },
    );

    test('selectDashboard clears explore mode', () async {
      await navigation.goExplore();

      await navigation.selectDashboard('master_index');

      expect(navigation.isExploreBrowseMode, isFalse);
      expect(navigation.currentDestination, AppDestination.home);
    });

    test('Graph and Timeline use the existing destination surfaces', () async {
      await navigation.selectDestination(AppDestination.graph);
      expect(navigation.currentDestination, AppDestination.graph);
      expect(navigation.isKnowledgeGraphMode, isTrue);

      await navigation.selectDestination(AppDestination.timeline);
      expect(navigation.currentDestination, AppDestination.timeline);
      expect(navigation.isTimelineMode, isTrue);
      expect(navigation.isKnowledgeGraphMode, isFalse);
    });

    test('dirty Workbench cancel keeps the detail and destination', () async {
      final item = createItem(
        workId: 'wk_guard_cancel',
        title: 'Unsaved Work',
        category: MediaCategory.manga,
      );
      workbench.openWork(item);
      workbench.markDirty(workbench.activeTab!.id);
      guardPrompt = ({required title, required canSave}) async {
        expect(title, 'Unsaved Work');
        expect(canSave, isFalse);
        return WorkbenchNavigationDecision.cancel;
      };

      await navigation.selectDestination(AppDestination.graph);

      expect(navigation.currentDestination, AppDestination.home);
      expect(workbench.hasOpenDetail, isTrue);
      expect(workbench.tabs.single.isDirty, isTrue);
    });

    test('dirty Workbench discard allows destination navigation', () async {
      final item = createItem(
        workId: 'wk_guard_discard',
        title: 'Discard Work',
        category: MediaCategory.manga,
      );
      workbench.openWork(item);
      workbench.markDirty(workbench.activeTab!.id);
      guardPrompt = ({required title, required canSave}) async =>
          WorkbenchNavigationDecision.discard;

      await navigation.selectDestination(AppDestination.graph);

      expect(navigation.currentDestination, AppDestination.graph);
      expect(workbench.tabs, isEmpty);
    });

    test('dirty Workbench save completes before navigation', () async {
      final item = createItem(
        workId: 'wk_guard_save',
        title: 'Save Work',
        category: MediaCategory.manga,
      );
      workbench.openWork(item);
      final tabId = workbench.activeTab!.id;
      workbench.markDirty(tabId);
      var saveCount = 0;
      workbench.saveActiveTab = () async {
        saveCount++;
        workbench.markDirty(tabId, dirty: false);
      };
      guardPrompt = ({required title, required canSave}) async {
        expect(canSave, isTrue);
        return WorkbenchNavigationDecision.save;
      };

      await navigation.selectDestination(AppDestination.timeline);

      expect(saveCount, 1);
      expect(navigation.currentDestination, AppDestination.timeline);
      expect(workbench.tabs, isEmpty);
    });

    test('every dirty tab must be confirmed before navigation', () async {
      final first = createItem(
        workId: 'wk_guard_first',
        title: 'First Dirty Work',
        category: MediaCategory.manga,
      );
      final second = createItem(
        workId: 'wk_guard_second',
        title: 'Second Dirty Work',
        category: MediaCategory.animation,
      );
      workbench.openWork(first);
      workbench.markDirty(workbench.activeTab!.id);
      workbench.tabs.add(
        WorkCollectibleTab(
          id: WorkCollectibleTab.idFor(second),
          item: second,
          isDirty: true,
        ),
      );
      final promptedTitles = <String>[];
      guardPrompt = ({required title, required canSave}) async {
        promptedTitles.add(title);
        return promptedTitles.length == 1
            ? WorkbenchNavigationDecision.discard
            : WorkbenchNavigationDecision.cancel;
      };

      await navigation.selectDestination(AppDestination.graph);

      expect(promptedTitles, ['First Dirty Work', 'Second Dirty Work']);
      expect(navigation.currentDestination, AppDestination.home);
      expect(workbench.tabs, hasLength(2));
      expect(workbench.tabs.every((tab) => tab.isDirty), isTrue);
    });

    test(
      'latest destination wins when an older request finishes late',
      () async {
        final prepareStarted = Completer<void>();
        final releasePrepare = Completer<void>();
        navigation = HomeNavigationCoordinator(
          isMounted: () => true,
          scheduleRebuild: (mutate) => mutate(),
          sidebarCoordinator: sidebarCoordinator,
          filterCoordinator: filterCoordinator,
          workbench: workbench,
          prefetchRegistry: () async {},
          rebuild: () => rebuildCount++,
          ensureLegacyItemsLoaded: () async {
            if (!prepareStarted.isCompleted) prepareStarted.complete();
            await releasePrepare.future;
          },
          requestWorkbenchNavigationDecision:
              ({required title, required canSave}) =>
                  guardPrompt(title: title, canSave: canSave),
        );

        final staleHomeRequest = navigation.goHome();
        await prepareStarted.future;
        await navigation.goKnowledgeGraph();
        expect(navigation.currentDestination, AppDestination.graph);

        releasePrepare.complete();
        await staleHomeRequest;

        expect(navigation.currentDestination, AppDestination.graph);
      },
    );

    test('legacy sidebar selection restores its AppDestination', () async {
      SharedPreferences.setMockInitialValues({
        'akasha_active_sidebar_mode': SidebarSelectionMode.timeline.name,
      });

      await navigation.loadPersonalLibraries();
      await navigation.finalizeInitialDestination(vaultLinked: true);

      expect(navigation.currentDestination, AppDestination.timeline);
      expect(legacyLoadCount, 0);
    });

    test('new profile defaults to Home after sidebar state load', () async {
      await navigation.loadPersonalLibraries();
      await navigation.finalizeInitialDestination(vaultLinked: true);

      expect(navigation.currentDestination, AppDestination.home);
      expect(legacyLoadCount, 1);
    });

    test('Collections remains enterable when no collection exists', () async {
      expect(sidebarCoordinator.collectionCtrl.collections, isEmpty);

      await navigation.goCollection();

      expect(navigation.currentDestination, AppDestination.collections);
      expect(
        personalLibCtrl.sidebarMode,
        SidebarSelectionMode.collectibleCollection,
      );
    });
  });
}
