import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/coordinators/home_preview_coordinator.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_vault_port.dart';

HomePreviewCoordinator _coordinator({
  required BuildContext context,
  void Function()? onRebuild,
  void Function(String workId)? onRecordWork,
  void Function()? onShowBrowse,
}) {
  return HomePreviewCoordinator(
    hostContext: () => context,
    vault: FakeVaultPort(),
    rebuild: onRebuild ?? () {},
    resolveItemForOpen: (item) => item,
    openBrowseItemInWorkbench: (_) {},
    openEntityInWorkbench: (_) async {},
    showBrowseInWorkbench: onShowBrowse ?? () {},
    getVaultItems: () => const [],
    recordWorkExploration: onRecordWork ?? (_) {},
    recordEntityExploration: (_) {},
    showSnack: (_) {},
    loadItems: () async {},
    resolveEntity: (_) => null,
  );
}

UserCatalogEntity _entity({required String id, required String title}) {
  return UserCatalogEntity(
    entityId: id,
    entityType: UserCatalogEntity.entityTypePerson,
    title: title,
    subtype: MediaCategory.manga,
    addedAt: DateTime.utc(2024, 1, 1),
  );
}

void main() {
  testWidgets('openWorkPreview replaces entity preview', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    var rebuilds = 0;
    String? recordedWorkId;
    final coord = _coordinator(
      context: context,
      onRebuild: () => rebuilds++,
      onRecordWork: (id) => recordedWorkId = id,
    );
    coord.openEntityPreview(_entity(id: 'ent_1', title: 'Entity'));
    final work = createItem(
      workId: 'wk_1',
      title: 'Work',
      category: MediaCategory.manga,
    );

    coord.openWorkPreview(work);

    expect(coord.workPreviewItem?.workId, 'wk_1');
    expect(coord.entityPreviewItem, isNull);
    expect(recordedWorkId, 'wk_1');
    expect(rebuilds, greaterThanOrEqualTo(2));
  });

  testWidgets('push stacks prior preview and pop restores it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    final first = createItem(
      workId: 'wk_a',
      title: 'A',
      category: MediaCategory.manga,
    );
    final second = createItem(
      workId: 'wk_b',
      title: 'B',
      category: MediaCategory.manga,
    );
    final coord = _coordinator(context: context);
    coord.openWorkPreview(first);
    coord.openWorkPreview(second, push: true);

    expect(coord.workPreviewItem?.workId, 'wk_b');
    expect(coord.canPopPreview, isTrue);

    coord.popPreview();

    expect(coord.workPreviewItem?.workId, 'wk_a');
    expect(coord.canPopPreview, isFalse);
  });

  testWidgets('openWorkFromPreview captures return snapshot for save restore', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    final work = createItem(
      workId: 'wk_save',
      title: 'Saved',
      category: MediaCategory.manga,
    );
    final linked = createItem(
      workId: 'wk_linked',
      title: 'Linked',
      category: MediaCategory.manga,
    );
    var browseShown = false;
    final coord = HomePreviewCoordinator(
      hostContext: () => context,
      vault: FakeVaultPort(),
      rebuild: () {},
      resolveItemForOpen: (item) => item,
      openBrowseItemInWorkbench: (_) {},
      openEntityInWorkbench: (_) async {},
      showBrowseInWorkbench: () => browseShown = true,
      getVaultItems: () => [work, linked],
      recordWorkExploration: (_) {},
      recordEntityExploration: (_) {},
      showSnack: (_) {},
      loadItems: () async {},
      resolveEntity: (_) => null,
    );
    coord.openWorkPreview(work);
    coord.previewLinkedWork(linked);

    await coord.openWorkFromPreview();

    expect(coord.hasOpenPreview, isFalse);

    coord.maybeReturnAfterSave(workId: 'wk_linked');

    expect(coord.workPreviewItem?.workId, 'wk_linked');
    expect(coord.canPopPreview, isTrue);
    expect(browseShown, isTrue);
  });
}
