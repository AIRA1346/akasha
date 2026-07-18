import 'package:akasha/features/workbench/data/workbench_controller.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/coordinators/home_catalog_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_dialogs_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_navigation_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_shell_wiring.dart';
import 'package:akasha/screens/home/coordinators/home_vault_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_workbench_coordinator.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_collectible_collection_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/screens/home/home_section_preferences.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_registry_port.dart';
import '../fakes/fake_user_catalog_port.dart';
import '../fakes/fake_vault_port.dart';

void main() {
  test('persists a dialog Work without loading the complete Vault', () async {
    final vaultPort = FakeVaultPort();
    final userCatalog = FakeUserCatalogPort();
    final items = <AkashaItem>[];
    var fullLoadCalls = 0;

    final vault = HomeVaultCoordinator(
      vault: vaultPort,
      registry: FakeRegistryPort(),
      userCatalog: userCatalog,
      isMounted: () => true,
      scheduleRebuild: (mutate) => mutate(),
      onVaultItemsSynced: (_) {},
      prefetchRegistry: () async {},
    );
    final workbench = HomeWorkbenchCoordinator(
      workbench: WorkbenchController(),
      vault: vaultPort,
      userCatalog: userCatalog,
      isMounted: () => true,
      rebuild: () {},
      getItems: () => items,
      mutateItems: (mutate) => mutate(items),
      hasLegacyItemsLoaded: () => false,
    );
    final filterCtrl = HomeBrowseFilterController();
    final dashboardCtrl = HomeDashboardController();
    final personalLibraries = HomePersonalLibraryController();
    final wiring = HomeShellWiring.create(
      vault: vaultPort,
      registry: FakeRegistryPort(),
      personalLibCtrl: personalLibraries,
      collectionCtrl: HomeCollectibleCollectionController(),
      userCatalog: userCatalog,
      filterCtrl: filterCtrl,
      dashboardCtrl: dashboardCtrl,
      sectionPrefs: HomeSectionPreferences(),
      workbenchCoord: workbench,
      reloadItems: () async => fullLoadCalls++,
      rebuild: () {},
      showMessage: (_) {},
    );
    final catalog = HomeCatalogCoordinator(
      registry: FakeRegistryPort(),
      isMounted: () => true,
      scheduleRebuild: (mutate) => mutate(),
      filterCtrl: filterCtrl,
      dashboardCtrl: dashboardCtrl,
      isPersonalLibraryMode: () => false,
      showError: (_) {},
    );
    final navigation = HomeNavigationCoordinator(
      isMounted: () => true,
      scheduleRebuild: (mutate) => mutate(),
      sidebarCoordinator: wiring.sidebarCoordinator,
      filterCoordinator: wiring.filterCoordinator,
      workbench: WorkbenchController(),
      prefetchRegistry: () async {},
      rebuild: () {},
    );
    final dialogs = HomeDialogsCoordinator(
      hostContext: () => throw UnimplementedError(),
      isMounted: () => true,
      scheduleRebuild: (mutate) => mutate(),
      showMessage: (_) {},
      wiring: wiring,
      vault: vault,
      catalog: catalog,
      navigation: navigation,
      workbenchCoord: workbench,
      getItems: () => items,
      addItemInMemory: items.add,
      loadItems: () async => fullLoadCalls++,
      loadPersonalLibraries: () async {},
      autoArchiveWorks: ({bool showFeedback = false}) async {},
      rebuild: () {},
      wrapSetState: (mutate) => mutate(),
      canAddToLibrary: () => false,
      userCatalog: userCatalog,
    );
    final item = createItem(
      workId: 'wk_u_abc12345',
      title: 'Dialog import',
      category: MediaCategory.movie,
    );

    await dialogs.persistWorkToVault(item);

    expect(vaultPort.inMemoryCache[item.workId], same(item));
    expect(userCatalog.getById(item.workId)?.title, item.title);
    expect(items, isEmpty);
    expect(fullLoadCalls, 0);
  });
}
