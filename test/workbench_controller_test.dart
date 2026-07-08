import 'package:akasha/core/archiving/canvas_record.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/features/workbench/data/workbench_controller.dart';
import 'package:akasha/features/workbench/presentation/collectible_tab.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/canvas_store.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('syncFromVaultItems updates open tab when disk content changes', () {
    final ctrl = WorkbenchController();
    final original = createItem(
      workId: 'wk_sync',
      title: 'Before',
      category: MediaCategory.manga,
    );
    original.filePath = r'C:\vault\manga\before.md';
    original.rating = 3;
    ctrl.openWork(original);
    final tabId = WorkCollectibleTab.idFor(original);

    final updated = createItem(
      workId: 'wk_sync',
      title: 'Before',
      category: MediaCategory.manga,
    );
    updated.filePath = original.filePath;
    updated.rating = 5;

    ctrl.syncFromVaultItems([updated]);

    expect(ctrl.activeWorkTab!.item.rating, 5);
    expect(ctrl.activeTab!.id, tabId);
  });

  test('syncFromVaultItems skips dirty tabs', () {
    final ctrl = WorkbenchController();
    final original = createItem(
      workId: 'wk_dirty',
      title: 'Dirty',
      category: MediaCategory.manga,
    );
    original.filePath = r'C:\vault\manga\dirty.md';
    ctrl.openWork(original);
    ctrl.markDirty(WorkCollectibleTab.idFor(original), dirty: true);

    final updated = createItem(
      workId: 'wk_dirty',
      title: 'Dirty',
      category: MediaCategory.manga,
    );
    updated.filePath = original.filePath;
    updated.rating = 9;

    ctrl.syncFromVaultItems([updated]);

    expect(ctrl.activeWorkTab!.item.rating, 0);
  });

  test('openEntity adds entity tab and shows detail view', () {
    final ctrl = WorkbenchController();
    final entity = UserCatalogEntity.userLocal(
      entityId: 'pe_u_test',
      type: EntityAnchorType.person,
      title: 'Test Person',
    );

    ctrl.openEntity(entity);

    expect(ctrl.hasOpenDetail, isTrue);
    expect(ctrl.activeEntityTab!.entity.title, 'Test Person');
    expect(ctrl.tabs.length, 1);
  });

  test('showBrowse persists registered canvas session when editor is disposed', () async {
    final ctrl = WorkbenchController();
    await ctrl.openCanvas('cv_u_test01', 'Test Map');

    final layout = CanvasLayout(
      layoutSchemaVersion: 1,
      canvasId: 'cv_u_test01',
      updatedAt: DateTime.now().toUtc(),
      source: 'user',
      layoutMode: 'freeform',
      viewport: CanvasViewport(x: 42.0, y: -17.0, zoom: 1.25),
      nodes: [],
      edges: [],
    );
    CanvasStore.instance.registerLayoutSession(
      r'C:\vault\canvases\cv_u_test01',
      'cv_u_test01',
      layout,
    );

    await ctrl.showBrowse();

    expect(ctrl.tabs, isEmpty);
  });

  test('showBrowse awaits active canvas viewport flush before clearing tabs', () async {
    final ctrl = WorkbenchController();
    var flushCalls = 0;

    await ctrl.openCanvas('cv_u_test01', 'Test Map');
    ctrl.flushActiveCanvasViewport = () async {
      flushCalls++;
    };

    await ctrl.showBrowse();

    expect(flushCalls, 1);
    expect(ctrl.hasOpenDetail, isFalse);
    expect(ctrl.tabs, isEmpty);
    expect(ctrl.flushActiveCanvasViewport, isNull);
  });

  test('closeTab awaits canvas viewport flush when closing active canvas tab', () async {
    final ctrl = WorkbenchController();
    var flushCalls = 0;

    await ctrl.openCanvas('cv_u_test01', 'Test Map');
    ctrl.flushActiveCanvasViewport = () async {
      flushCalls++;
    };

    await ctrl.closeTab(CanvasCollectibleTab.idFor('cv_u_test01'));

    expect(flushCalls, 1);
    expect(ctrl.tabs, isEmpty);
  });

  test('openDetailBesideCanvas keeps canvas tab and opens work detail', () async {
    final ctrl = WorkbenchController();
    final work = createItem(
      workId: 'wk_canvas_open',
      title: 'Canvas Work',
      category: MediaCategory.manga,
    );

    await ctrl.openCanvas('cv_u_test01', 'Test Map');
    await ctrl.openDetailBesideCanvas(
      WorkCollectibleTab(id: WorkCollectibleTab.idFor(work), item: work),
    );

    expect(ctrl.tabs.length, 2);
    expect(ctrl.tabs.any((t) => t is CanvasCollectibleTab), isTrue);
    expect(ctrl.activeWorkTab!.item.title, 'Canvas Work');
    expect(ctrl.activeTab is WorkCollectibleTab, isTrue);
  });

  test('openDetailBesideCanvas selects existing detail tab by id', () async {
    final ctrl = WorkbenchController();
    final work = createItem(
      workId: 'wk_canvas_open',
      title: 'Canvas Work',
      category: MediaCategory.manga,
    );
    final tabId = WorkCollectibleTab.idFor(work);

    await ctrl.openCanvas('cv_u_test01', 'Test Map');
    await ctrl.openDetailBesideCanvas(
      WorkCollectibleTab(id: tabId, item: work),
    );
    await ctrl.selectTab(CanvasCollectibleTab.idFor('cv_u_test01'));
    await ctrl.openDetailBesideCanvas(
      WorkCollectibleTab(id: tabId, item: work),
    );

    expect(ctrl.tabs.length, 2);
    expect(ctrl.activeTabId, tabId);
  });

  test('openDetailBesideCanvas replaces prior detail tab but keeps canvas', () async {
    final ctrl = WorkbenchController();
    final workA = createItem(
      workId: 'wk_a',
      title: 'Work A',
      category: MediaCategory.manga,
    );
    final workB = createItem(
      workId: 'wk_b',
      title: 'Work B',
      category: MediaCategory.animation,
    );

    await ctrl.openCanvas('cv_u_test01', 'Test Map');
    await ctrl.openDetailBesideCanvas(
      WorkCollectibleTab(id: WorkCollectibleTab.idFor(workA), item: workA),
    );
    await ctrl.selectTab(CanvasCollectibleTab.idFor('cv_u_test01'));
    await ctrl.openDetailBesideCanvas(
      WorkCollectibleTab(id: WorkCollectibleTab.idFor(workB), item: workB),
    );

    expect(ctrl.tabs.length, 2);
    expect(ctrl.tabs.whereType<WorkCollectibleTab>().length, 1);
    expect(ctrl.activeWorkTab!.item.title, 'Work B');
  });

  test('openDetailBesideCanvas falls back to openWork when canvas is not active', () async {
    final ctrl = WorkbenchController();
    final work = createItem(
      workId: 'wk_fallback',
      title: 'Fallback Work',
      category: MediaCategory.manga,
    );

    await ctrl.openDetailBesideCanvas(
      WorkCollectibleTab(id: WorkCollectibleTab.idFor(work), item: work),
    );

    expect(ctrl.tabs.length, 1);
    expect(ctrl.activeWorkTab!.item.title, 'Fallback Work');
    expect(ctrl.tabs.any((t) => t is CanvasCollectibleTab), isFalse);
  });
}
