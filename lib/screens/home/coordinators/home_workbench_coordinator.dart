import '../../../features/workbench/data/workbench_controller.dart';
import '../../../features/workbench/presentation/work_tab.dart';
import '../../../models/akasha_item.dart';

/// 워크벤치 탭·작품 열기/저장 (E2-3).
class HomeWorkbenchCoordinator {
  HomeWorkbenchCoordinator({
    required this.workbench,
    required this.isMounted,
    required this.rebuild,
    required this.getItems,
    required this.mutateItems,
    required this.reloadItems,
  });

  final WorkbenchController workbench;
  final bool Function() isMounted;
  final void Function() rebuild;
  final List<AkashaItem> Function() getItems;
  final void Function(void Function(List<AkashaItem> items) mutate) mutateItems;
  final Future<void> Function() reloadItems;

  bool _lastWorkbenchShowsWork = false;
  bool _lastWorkbenchHadTabs = false;

  void attach() => workbench.addListener(onWorkbenchChanged);

  void dispose() => workbench.removeListener(onWorkbenchChanged);

  void onWorkbenchChanged() {
    if (!isMounted()) return;
    final showsWork = workbench.hasOpenWork;
    final hasTabs = workbench.hasTabs;
    if (showsWork == _lastWorkbenchShowsWork && hasTabs == _lastWorkbenchHadTabs) {
      return;
    }
    _lastWorkbenchShowsWork = showsWork;
    _lastWorkbenchHadTabs = hasTabs;
    rebuild();
  }

  void captureWorkbenchLayout() {
    _lastWorkbenchShowsWork = workbench.hasOpenWork;
    _lastWorkbenchHadTabs = workbench.hasTabs;
  }

  AkashaItem resolveItemForOpen(AkashaItem item) {
    final items = getItems();
    for (final existing in items) {
      if (item.workId.isNotEmpty && existing.workId == item.workId) {
        return existing;
      }
      if (existing.title == item.title &&
          existing.category == item.category) {
        return existing;
      }
    }
    return item;
  }

  void openBrowseItem(AkashaItem item) {
    workbench.openWork(resolveItemForOpen(item));
    if (isMounted()) rebuild();
  }

  Future<void> onWorkbenchWorkSaved(AkashaItem saved) async {
    await reloadItems();
    if (!isMounted()) return;
    workbench.updateTabItem(WorkTab.idFor(saved), saved, dirty: false);
  }

  Future<void> onWorkbenchWorkDeleted(String tabId, AkashaItem item) async {
    workbench.closeTab(tabId);
    if (isMounted()) {
      mutateItems((items) {
        items.removeWhere((e) =>
            (item.workId.isNotEmpty && e.workId == item.workId) ||
            (e.title == item.title && e.category == item.category));
      });
    }
    await reloadItems();
  }
}
