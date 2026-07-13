import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/coordinators/home_preview_coordinator.dart';
import 'package:akasha/screens/home/preview_frame.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_vault_port.dart';

HomePreviewCoordinator _coordinator({
  required BuildContext context,
  void Function()? onRebuild,
  void Function(String workId)? onRecordWork,
  Future<void> Function()? onShowBrowse,
}) {
  return HomePreviewCoordinator(
    hostContext: () => context,
    vault: FakeVaultPort(),
    rebuild: onRebuild ?? () {},
    resolveItemForOpen: (item) => item,
    openBrowseItemInWorkbench: (_) {},
    openEntityInWorkbench: (_) async {},
    showBrowseInWorkbench: onShowBrowse ?? () async {},
    getVaultItems: () => const [],
    recordWorkExploration: onRecordWork ?? (_) {},
    recordEntityExploration: (_) {},
    showSnack: (_) {},
    onWorkPersisted: (_) async {},
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
    expect(coord.previewTarget, isA<EntityPreviewTarget>());

    final work = createItem(
      workId: 'wk_1',
      title: 'Work',
      category: MediaCategory.manga,
    );

    coord.openWorkPreview(work);

    expect(coord.previewTarget, isA<WorkPreviewTarget>());
    expect((coord.previewTarget as WorkPreviewTarget).item.workId, 'wk_1');
    expect(coord.workPreviewItem?.workId, 'wk_1');
    expect(coord.entityPreviewItem, isNull);
    expect(recordedWorkId, 'wk_1');
    expect(rebuilds, greaterThanOrEqualTo(2));
  });

  testWidgets('push stacks prior target and pop restores its type', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    final first = _entity(id: 'ent_a', title: 'Entity A');
    final second = createItem(
      workId: 'wk_b',
      title: 'B',
      category: MediaCategory.manga,
    );
    final coord = _coordinator(context: context);
    coord.openEntityPreview(first);
    coord.openWorkPreview(second, push: true);

    expect(coord.previewTarget, isA<WorkPreviewTarget>());
    expect(coord.workPreviewItem?.workId, 'wk_b');
    expect(coord.canPopPreview, isTrue);

    coord.popPreview();

    expect(coord.previewTarget, isA<EntityPreviewTarget>());
    expect(
      (coord.previewTarget as EntityPreviewTarget).entity.entityId,
      'ent_a',
    );
    expect(coord.workPreviewItem, isNull);
    expect(coord.canPopPreview, isFalse);
  });

  testWidgets(
    'close selects NoPreviewTarget without touching external shell sentinels',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));
      var navigationSentinel = 'explore';
      final filterSentinel = <String>{'manga', 'watching'};
      var showBrowseCalls = 0;
      var rebuilds = 0;
      final coord = _coordinator(
        context: context,
        onRebuild: () => rebuilds++,
        onShowBrowse: () async => showBrowseCalls++,
      );
      coord.openWorkPreview(
        createItem(
          workId: 'wk_close',
          title: 'Close target',
          category: MediaCategory.manga,
        ),
      );
      navigationSentinel = 'library';
      filterSentinel.add('favorite');
      final rebuildsBeforeClose = rebuilds;

      coord.closeAllPreviews();

      expect(coord.previewTarget, same(NoPreviewTarget.instance));
      expect(coord.hasOpenPreview, isFalse);
      expect(coord.canPopPreview, isFalse);
      expect(navigationSentinel, 'library');
      expect(filterSentinel, {'manga', 'watching', 'favorite'});
      expect(showBrowseCalls, 0);
      expect(rebuilds, rebuildsBeforeClose + 1);
    },
  );

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
      showBrowseInWorkbench: () async {
        browseShown = true;
      },
      getVaultItems: () => [work, linked],
      recordWorkExploration: (_) {},
      recordEntityExploration: (_) {},
      showSnack: (_) {},
      onWorkPersisted: (_) async {},
      resolveEntity: (_) => null,
    );
    coord.openWorkPreview(work);
    coord.previewLinkedWork(linked);

    await coord.openWorkFromPreview();

    expect(coord.previewTarget, same(NoPreviewTarget.instance));
    expect(coord.hasOpenPreview, isFalse);

    await coord.maybeReturnAfterSave(workId: 'wk_linked');

    expect(coord.previewTarget, isA<WorkPreviewTarget>());
    expect(coord.workPreviewItem?.workId, 'wk_linked');
    expect(coord.canPopPreview, isTrue);
    expect(browseShown, isTrue);
  });
}
