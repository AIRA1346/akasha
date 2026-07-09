import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/services/default_vault_path_resolver.dart';
import 'package:akasha/screens/home/coordinators/home_dialogs_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_vault_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_catalog_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_navigation_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_sidebar_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_filter_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_workbench_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_shell_wiring.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:akasha/screens/home/home_dashboard_controller.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/screens/home/home_collectible_collection_controller.dart';
import 'package:akasha/screens/home/home_section_preferences.dart';
import 'package:akasha/features/workbench/data/workbench_controller.dart';

import 'fakes/fake_vault_port.dart';
import 'fakes/fake_registry_port.dart';
import 'fakes/fake_user_catalog_port.dart';
import 'fakes/fake_registry_sync_port.dart';

class FakeVaultPathResolver extends DefaultVaultPathResolver {
  final String preferredPathResult;
  final String fallbackPathResult;
  final bool failPreferred;

  FakeVaultPathResolver({
    required this.preferredPathResult,
    required this.fallbackPathResult,
    this.failPreferred = false,
  });

  @override
  Future<String> resolvePreferredPath() async {
    if (failPreferred) {
      throw Exception('Preferred path error');
    }
    return preferredPathResult;
  }

  @override
  Future<String> resolveFallbackPath() async {
    return fallbackPathResult;
  }
}

class TestVaultPort extends FakeVaultPort {
  String? _path;

  @override
  String? get vaultPath => _path;

  @override
  Future<void> setVaultPath(String path) async {
    _path = path;
    // Standard folder bootstrapping logic matching AkashaFileService
    Directory('$path/works').createSync(recursive: true);
    Directory('$path/entities').createSync(recursive: true);
    Directory('$path/journal').createSync(recursive: true);
    Directory('$path/timeline').createSync(recursive: true);
    Directory('$path/posters').createSync(recursive: true);
    Directory('$path/system').createSync(recursive: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late String preferredPath;
  late String fallbackPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('akasha_quick_start_test_');
    preferredPath = '${tempRoot.path}/pref_documents';
    fallbackPath = '${tempRoot.path}/fall_support';
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  testWidgets('createDefaultVault creates subfolders and sets path for preferred path success', (tester) async {
    final fakeVault = TestVaultPort();
    late Future<void> createFuture;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final vaultCoord = HomeVaultCoordinator(
              vault: fakeVault,
              registry: FakeRegistryPort(),
              userCatalog: FakeUserCatalogPort(),
              isMounted: () => true,
              scheduleRebuild: (_) {},
              onVaultItemsSynced: (_) {},
              prefetchRegistry: () async {},
            );

            final catalog = HomeCatalogCoordinator(
              registry: FakeRegistryPort(),
              registrySyncPort: FakeRegistrySyncPort(),
              isMounted: () => true,
              scheduleRebuild: (_) {},
              filterCtrl: HomeBrowseFilterController(),
              dashboardCtrl: HomeDashboardController(),
              isPersonalLibraryMode: () => false,
              showSuccess: (_) {},
              showError: (_) {},
              reloadItems: () async {},
              autoArchiveWorks: ({bool showFeedback = false}) async {},
            );

            final filterCoord = HomeFilterCoordinator(
              filterCtrl: HomeBrowseFilterController(),
              dashboardCtrl: HomeDashboardController(),
              personalLibCtrl: HomePersonalLibraryController(),
            );

            final sidebarCoord = HomeSidebarCoordinator(
              personalLibCtrl: HomePersonalLibraryController(),
              collectionCtrl: HomeCollectibleCollectionController(),
              dashboardCtrl: HomeDashboardController(),
              sectionPrefs: HomeSectionPreferences(),
              filterCoordinator: filterCoord,
            );

            final navigation = HomeNavigationCoordinator(
              isMounted: () => true,
              scheduleRebuild: (_) {},
              sidebarCoordinator: sidebarCoord,
              filterCoordinator: filterCoord,
              workbench: WorkbenchController(),
              prefetchRegistry: () async {},
              rebuild: () {},
            );

            final workbenchCoord = HomeWorkbenchCoordinator(
              workbench: WorkbenchController(),
              vault: fakeVault,
              userCatalog: FakeUserCatalogPort(),
              isMounted: () => true,
              rebuild: () {},
              getItems: () => [],
              mutateItems: (_) {},
              reloadItems: () async {},
            );

            final wiring = HomeShellWiring.create(
              vault: fakeVault,
              registry: FakeRegistryPort(),
              personalLibCtrl: HomePersonalLibraryController(),
              collectionCtrl: HomeCollectibleCollectionController(),
              userCatalog: FakeUserCatalogPort(),
              filterCtrl: HomeBrowseFilterController(),
              dashboardCtrl: HomeDashboardController(),
              sectionPrefs: HomeSectionPreferences(),
              workbenchCoord: workbenchCoord,
              reloadItems: () async {},
              rebuild: () {},
              showMessage: (msg) => debugPrint('SHOWMESSAGE: $msg'),
            );

            final coord = HomeDialogsCoordinator(
              hostContext: () => context,
              isMounted: () => true,
              scheduleRebuild: (_) {},
              showMessage: (msg) => debugPrint('SHOWMESSAGE: $msg'),
              wiring: wiring,
              vault: vaultCoord,
              catalog: catalog,
              navigation: navigation,
              workbenchCoord: workbenchCoord,
              getItems: () => [],
              addItemInMemory: (_) {},
              loadItems: () async {},
              loadPersonalLibraries: () async {},
              autoArchiveWorks: ({bool showFeedback = false}) async {},
              rebuild: () {},
              wrapSetState: (_) {},
              canAddToLibrary: () => true,
              userCatalog: FakeUserCatalogPort(),
            );

            return ElevatedButton(
              onPressed: () {
                final resolver = FakeVaultPathResolver(
                  preferredPathResult: preferredPath,
                  fallbackPathResult: fallbackPath,
                  failPreferred: false,
                );
                createFuture = coord.createDefaultVault(resolver: resolver);
              },
              child: const Text('TRIGGER'),
            );
          },
        ),
      ),
    ));

    // Act
    await tester.tap(find.text('TRIGGER'));
    await tester.runAsync(() async {
      await createFuture;
    });
    await tester.pumpAndSettle();

    // Assert
    final expectedVaultPath = '$preferredPath/AKASHA Vault';
    expect(fakeVault.vaultPath!.replaceAll('\\', '/'), equals(expectedVaultPath.replaceAll('\\', '/')));

    // Verify subfolders exist on the filesystem
    final actualVaultPath = fakeVault.vaultPath!;
    expect(Directory(p.join(actualVaultPath, 'works')).existsSync(), isTrue);
    expect(Directory(p.join(actualVaultPath, 'entities')).existsSync(), isTrue);
    expect(Directory(p.join(actualVaultPath, 'journal')).existsSync(), isTrue);
    expect(Directory(p.join(actualVaultPath, 'timeline')).existsSync(), isTrue);
    expect(Directory(p.join(actualVaultPath, 'posters')).existsSync(), isTrue);
    expect(Directory(p.join(actualVaultPath, 'system')).existsSync(), isTrue);

    // Verify confirmation dialog shows philosophy message
    expect(find.textContaining('이 폴더가 AKASHA의 본체입니다'), findsOneWidget);
    expect(find.textContaining(actualVaultPath), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
  });

  testWidgets('createDefaultVault falls back when preferred path fails', (tester) async {
    final fakeVault = TestVaultPort();
    late Future<void> createFuture;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final vaultCoord = HomeVaultCoordinator(
              vault: fakeVault,
              registry: FakeRegistryPort(),
              userCatalog: FakeUserCatalogPort(),
              isMounted: () => true,
              scheduleRebuild: (_) {},
              onVaultItemsSynced: (_) {},
              prefetchRegistry: () async {},
            );

            final catalog = HomeCatalogCoordinator(
              registry: FakeRegistryPort(),
              registrySyncPort: FakeRegistrySyncPort(),
              isMounted: () => true,
              scheduleRebuild: (_) {},
              filterCtrl: HomeBrowseFilterController(),
              dashboardCtrl: HomeDashboardController(),
              isPersonalLibraryMode: () => false,
              showSuccess: (_) {},
              showError: (_) {},
              reloadItems: () async {},
              autoArchiveWorks: ({bool showFeedback = false}) async {},
            );

            final filterCoord = HomeFilterCoordinator(
              filterCtrl: HomeBrowseFilterController(),
              dashboardCtrl: HomeDashboardController(),
              personalLibCtrl: HomePersonalLibraryController(),
            );

            final sidebarCoord = HomeSidebarCoordinator(
              personalLibCtrl: HomePersonalLibraryController(),
              collectionCtrl: HomeCollectibleCollectionController(),
              dashboardCtrl: HomeDashboardController(),
              sectionPrefs: HomeSectionPreferences(),
              filterCoordinator: filterCoord,
            );

            final navigation = HomeNavigationCoordinator(
              isMounted: () => true,
              scheduleRebuild: (_) {},
              sidebarCoordinator: sidebarCoord,
              filterCoordinator: filterCoord,
              workbench: WorkbenchController(),
              prefetchRegistry: () async {},
              rebuild: () {},
            );

            final workbenchCoord = HomeWorkbenchCoordinator(
              workbench: WorkbenchController(),
              vault: fakeVault,
              userCatalog: FakeUserCatalogPort(),
              isMounted: () => true,
              rebuild: () {},
              getItems: () => [],
              mutateItems: (_) {},
              reloadItems: () async {},
            );

            final wiring = HomeShellWiring.create(
              vault: fakeVault,
              registry: FakeRegistryPort(),
              personalLibCtrl: HomePersonalLibraryController(),
              collectionCtrl: HomeCollectibleCollectionController(),
              userCatalog: FakeUserCatalogPort(),
              filterCtrl: HomeBrowseFilterController(),
              dashboardCtrl: HomeDashboardController(),
              sectionPrefs: HomeSectionPreferences(),
              workbenchCoord: workbenchCoord,
              reloadItems: () async {},
              rebuild: () {},
              showMessage: (msg) => debugPrint('SHOWMESSAGE: $msg'),
            );

            final coord = HomeDialogsCoordinator(
              hostContext: () => context,
              isMounted: () => true,
              scheduleRebuild: (_) {},
              showMessage: (msg) => debugPrint('SHOWMESSAGE: $msg'),
              wiring: wiring,
              vault: vaultCoord,
              catalog: catalog,
              navigation: navigation,
              workbenchCoord: workbenchCoord,
              getItems: () => [],
              addItemInMemory: (_) {},
              loadItems: () async {},
              loadPersonalLibraries: () async {},
              autoArchiveWorks: ({bool showFeedback = false}) async {},
              rebuild: () {},
              wrapSetState: (_) {},
              canAddToLibrary: () => true,
              userCatalog: FakeUserCatalogPort(),
            );

            return ElevatedButton(
              onPressed: () {
                final resolver = FakeVaultPathResolver(
                  preferredPathResult: preferredPath,
                  fallbackPathResult: fallbackPath,
                  failPreferred: true, // Force preferred path fail
                );
                createFuture = coord.createDefaultVault(resolver: resolver);
              },
              child: const Text('TRIGGER'),
            );
          },
        ),
      ),
    ));

    // Act
    await tester.tap(find.text('TRIGGER'));
    await tester.runAsync(() async {
      await createFuture;
    });
    await tester.pumpAndSettle();

    // Assert fallback path used
    final expectedVaultPath = '$fallbackPath/AKASHA Vault';
    expect(fakeVault.vaultPath!.replaceAll('\\', '/'), equals(expectedVaultPath.replaceAll('\\', '/')));

    final actualVaultPath = fakeVault.vaultPath!;
    expect(Directory(p.join(actualVaultPath, 'works')).existsSync(), isTrue);
    expect(Directory(p.join(actualVaultPath, 'system')).existsSync(), isTrue);

    expect(find.textContaining('이 폴더가 AKASHA의 본체입니다'), findsOneWidget);
    expect(find.textContaining(actualVaultPath), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
  });
}
