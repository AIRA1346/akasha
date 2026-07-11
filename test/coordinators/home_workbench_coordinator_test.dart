import 'package:akasha/features/workbench/data/workbench_controller.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/coordinators/home_workbench_coordinator.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_user_catalog_port.dart';
import '../fakes/fake_vault_port.dart';

void main() {
  HomeWorkbenchCoordinator coordinator({
    required List<AkashaItem> items,
    required bool legacyItemsLoaded,
  }) {
    return HomeWorkbenchCoordinator(
      workbench: WorkbenchController(),
      vault: FakeVaultPort(),
      userCatalog: FakeUserCatalogPort(),
      isMounted: () => true,
      rebuild: () {},
      getItems: () => items,
      mutateItems: (mutate) => mutate(items),
      hasLegacyItemsLoaded: () => legacyItemsLoaded,
    );
  }

  test(
    'saved Work replaces its legacy list entry without a full reload',
    () async {
      final previous = createItem(
        workId: 'wk_u_alpha',
        title: 'Alpha',
        category: MediaCategory.movie,
      );
      final saved = createItem(
        workId: 'wk_u_alpha',
        title: 'Alpha revised',
        category: MediaCategory.movie,
      );
      final items = <AkashaItem>[previous];

      await coordinator(
        items: items,
        legacyItemsLoaded: true,
      ).onWorkbenchWorkSaved(saved);

      expect(items, [same(saved)]);
    },
  );

  test(
    'bounded Work save does not create a partial legacy item list',
    () async {
      final saved = createItem(
        workId: 'wk_u_alpha',
        title: 'Alpha',
        category: MediaCategory.movie,
      );
      final items = <AkashaItem>[];

      await coordinator(
        items: items,
        legacyItemsLoaded: false,
      ).onWorkbenchWorkSaved(saved);

      expect(items, isEmpty);
    },
  );

  test('deleted Work is removed from an already loaded legacy list', () async {
    final item = createItem(
      workId: 'wk_u_alpha',
      title: 'Alpha',
      category: MediaCategory.movie,
    );
    final items = <AkashaItem>[item];

    await coordinator(
      items: items,
      legacyItemsLoaded: true,
    ).onWorkbenchWorkDeleted('work:wk_u_alpha', item);

    expect(items, isEmpty);
  });
}
