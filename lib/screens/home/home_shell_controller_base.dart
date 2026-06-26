import '../../core/ports/registry_port.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../features/workbench/data/workbench_controller.dart';
import 'coordinators/home_browse_coordinator.dart';
import 'coordinators/home_catalog_coordinator.dart';
import 'coordinators/home_dialogs_coordinator.dart';
import 'coordinators/home_navigation_coordinator.dart';
import 'coordinators/home_preview_coordinator.dart';
import 'coordinators/home_recent_exploration_coordinator.dart';
import 'coordinators/home_shell_coordinator_bundle.dart';
import 'coordinators/home_shell_wiring.dart';
import 'coordinators/home_vault_coordinator.dart';
import 'coordinators/home_workbench_coordinator.dart';
import 'home_browse_filter_controller.dart';
import 'home_collectible_collection_controller.dart';
import 'home_dashboard_controller.dart';
import 'home_personal_library_controller.dart';
import 'home_registry_ui.dart';
import 'home_section_preferences.dart';
import 'home_shell_host.dart';

/// [HomeShellController] mixin·coordinator 공유 surface.
abstract class HomeShellControllerBase {
  HomeShellHost get host;

  HomeBrowseFilterController get filterCtrl;
  HomeDashboardController get dashboardCtrl;
  HomePersonalLibraryController get personalLibCtrl;
  HomeCollectibleCollectionController get collectionCtrl;
  WorkbenchController get workbench;
  HomeRegistryUi get registryUi;
  RegistryPort get registry;
  UserCatalogPort get userCatalog;

  HomeShellCoordinatorBundle get coordinators;

  HomeVaultCoordinator get vault;
  HomeCatalogCoordinator get catalog;
  HomeWorkbenchCoordinator get workbenchCoord;
  HomeShellWiring get wiring;
  HomeNavigationCoordinator get navigation;
  HomeBrowseCoordinator get browse;
  HomeDialogsCoordinator get dialogs;
  HomeRecentExplorationCoordinator get recentExplore;
  HomePreviewCoordinator get preview;

  HomeSectionPreferences get sectionPrefs;
  set sectionPrefs(HomeSectionPreferences value);

  void wrapSetState(void Function() mutate);
  void rebuild();
  void showSnack(String msg);
}
