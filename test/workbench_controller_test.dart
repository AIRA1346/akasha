import 'package:akasha/features/workbench/data/workbench_controller.dart';
import 'package:akasha/features/workbench/presentation/work_tab.dart';
import 'package:akasha/models/enums.dart';
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
    final tabId = WorkTab.idFor(original);

    final updated = createItem(
      workId: 'wk_sync',
      title: 'Before',
      category: MediaCategory.manga,
    );
    updated.filePath = original.filePath;
    updated.rating = 5;

    ctrl.syncFromVaultItems([updated]);

    expect(ctrl.activeTab!.item.rating, 5);
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
    ctrl.markDirty(WorkTab.idFor(original), dirty: true);

    final updated = createItem(
      workId: 'wk_dirty',
      title: 'Dirty',
      category: MediaCategory.manga,
    );
    updated.filePath = original.filePath;
    updated.rating = 9;

    ctrl.syncFromVaultItems([updated]);

    expect(ctrl.activeTab!.item.rating, 0);
  });
}
