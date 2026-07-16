import 'dart:io';

import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/coordinators/home_vault_coordinator.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_registry_port.dart';
import '../fakes/fake_user_catalog_port.dart';
import '../fakes/fake_vault_port.dart';

void main() {
  test('loadItems reads vault port and syncs workbench items', () async {
    final vaultDir = await Directory.systemTemp.createTemp(
      'akasha_home_vault_coordinator_',
    );
    addTearDown(() async {
      if (await vaultDir.exists()) await vaultDir.delete(recursive: true);
    });
    final vault = FakeVaultPort();
    await vault.setVaultPath(vaultDir.path);
    await vault.saveItem(
      createItem(
        workId: 'wk_test',
        title: 'Test Work',
        category: MediaCategory.manga,
      ),
    );

    var synced = <AkashaItem>[];
    final coordinator = HomeVaultCoordinator(
      vault: vault,
      registry: FakeRegistryPort(),
      userCatalog: FakeUserCatalogPort(),
      isMounted: () => true,
      scheduleRebuild: (mutate) => mutate(),
      onVaultItemsSynced: (items) => synced = items,
      prefetchRegistry: () async {},
    );

    await coordinator.loadItems();

    expect(coordinator.items, hasLength(1));
    expect(coordinator.items.first.workId, 'wk_test');
    expect(synced, hasLength(1));
    await coordinator.ensureItemsLoaded();
    expect(coordinator.items, hasLength(1));

    await coordinator.setVaultPath(
      '${vaultDir.path}${Platform.pathSeparator}other-vault',
    );
    expect(coordinator.hasLoadedItems, isFalse);
    expect(coordinator.items, isEmpty);
  });

  test('bindVaultWatch debounces vault update stream', () async {
    final vault = FakeVaultPort();
    await vault.setVaultPath('/fake/vault');

    var changeCount = 0;
    final coordinator = HomeVaultCoordinator(
      vault: vault,
      registry: FakeRegistryPort(),
      userCatalog: FakeUserCatalogPort(),
      isMounted: () => true,
      scheduleRebuild: (_) {},
      onVaultItemsSynced: (_) {},
      prefetchRegistry: () async {},
    );
    coordinator.bindVaultWatch(
      onVaultChanged: (_) async {
        changeCount++;
      },
    );

    await vault.saveItem(
      createItem(
        workId: 'wk_debounce',
        title: 'Debounce',
        category: MediaCategory.book,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));

    expect(changeCount, 1);
    coordinator.dispose();
  });
}
