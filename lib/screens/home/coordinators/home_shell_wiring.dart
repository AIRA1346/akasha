import '../../../core/ports/registry_port.dart';
import '../../../services/browse_pipeline.dart';
import '../../../services/my_library_pipeline.dart';
import '../../../services/personal_library_membership_service.dart';
import '../home_browse_filter_controller.dart';
import '../home_dashboard_controller.dart';
import '../home_dashboard_ui.dart';
import '../home_library_ui.dart';
import '../home_personal_library_controller.dart';
import '../home_personal_library_ui.dart';
import '../home_registry_hide_actions.dart';
import '../home_section_preferences.dart';
import 'home_filter_coordinator.dart';
import 'home_library_menu_builder.dart';
import 'home_membership_coordinator.dart';
import 'home_sidebar_coordinator.dart';
import 'home_workbench_coordinator.dart';

/// Home UI glue·파이프라인 조립 (E2-4).
class HomeShellWiring {
  HomeShellWiring._({
    required this.libraryMembership,
    required this.browsePipeline,
    required this.myLibraryPipeline,
    required this.membershipCoordinator,
    required this.filterCoordinator,
    required this.sidebarCoordinator,
    required this.libraryMenuBuilder,
    required this.libraryUi,
    required this.personalLibraryUi,
    required this.dashboardUi,
    required this.hideActions,
  });

  final PersonalLibraryMembershipService libraryMembership;
  final BrowsePipeline browsePipeline;
  final MyLibraryPipeline myLibraryPipeline;
  final HomeMembershipCoordinator membershipCoordinator;
  final HomeFilterCoordinator filterCoordinator;
  final HomeSidebarCoordinator sidebarCoordinator;
  final HomeLibraryMenuBuilder libraryMenuBuilder;
  final HomeLibraryUi libraryUi;
  final HomePersonalLibraryUi personalLibraryUi;
  final HomeDashboardUi dashboardUi;
  final HomeRegistryHideActions hideActions;

  factory HomeShellWiring.create({
    required RegistryPort registry,
    required HomePersonalLibraryController personalLibCtrl,
    required HomeBrowseFilterController filterCtrl,
    required HomeDashboardController dashboardCtrl,
    required HomeSectionPreferences sectionPrefs,
    required HomeWorkbenchCoordinator workbenchCoord,
    required Future<void> Function() reloadItems,
    required void Function() rebuild,
    required void Function(String message) showMessage,
  }) {
    final hideActions = HomeRegistryHideActions(
      onStateChanged: rebuild,
      showMessage: showMessage,
    );
    final libraryMembership =
        PersonalLibraryMembershipService(personalLibCtrl, registry);
    final membershipCoordinator = HomeMembershipCoordinator(
      personalLibraryController: personalLibCtrl,
      membership: libraryMembership,
      resolveItemForOpen: workbenchCoord.resolveItemForOpen,
      reloadItems: reloadItems,
    );
    final filterCoordinator = HomeFilterCoordinator(
      filterCtrl: filterCtrl,
      dashboardCtrl: dashboardCtrl,
      personalLibCtrl: personalLibCtrl,
    );
    final sidebarCoordinator = HomeSidebarCoordinator(
      personalLibCtrl: personalLibCtrl,
      dashboardCtrl: dashboardCtrl,
      sectionPrefs: sectionPrefs,
      filterCoordinator: filterCoordinator,
    );
    final libraryMenuBuilder = HomeLibraryMenuBuilder(
      hideActions: hideActions,
      membership: libraryMembership,
    );
    final libraryUi = HomeLibraryUi(
      membershipCoordinator: membershipCoordinator,
      libraryMenuBuilder: libraryMenuBuilder,
      filterCoordinator: filterCoordinator,
      personalLibCtrl: personalLibCtrl,
      hideActions: hideActions,
    );
    final personalLibraryUi = HomePersonalLibraryUi(
      personalLibCtrl: personalLibCtrl,
      filterCoordinator: filterCoordinator,
      sectionPrefs: sectionPrefs,
    );
    final dashboardUi = HomeDashboardUi(
      dashboardCtrl: dashboardCtrl,
      filterCoordinator: filterCoordinator,
    );

    return HomeShellWiring._(
      libraryMembership: libraryMembership,
      browsePipeline: BrowsePipeline(registry),
      myLibraryPipeline: MyLibraryPipeline(registry),
      membershipCoordinator: membershipCoordinator,
      filterCoordinator: filterCoordinator,
      sidebarCoordinator: sidebarCoordinator,
      libraryMenuBuilder: libraryMenuBuilder,
      libraryUi: libraryUi,
      personalLibraryUi: personalLibraryUi,
      dashboardUi: dashboardUi,
      hideActions: hideActions,
    );
  }
}
