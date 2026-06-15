import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../data/workbench_controller.dart';
import '../../../widgets/work_tab_rail.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'work_detail_workspace.dart';

/// 워크벤치 메인 영역 — 탭 레일 + (작업 뷰 | 브라우즈 콘텐츠)
class WorkbenchShell extends StatelessWidget {
  final WorkbenchController controller;
  final Widget browseContent;
  final void Function(AkashaItem saved) onWorkSaved;
  final void Function(String tabId, AkashaItem item) onWorkDeleted;
  final Future<void> Function(AkashaItem item)? onAddToLibrary;

  const WorkbenchShell({
    super.key,
    required this.controller,
    required this.browseContent,
    required this.onWorkSaved,
    required this.onWorkDeleted,
    this.onAddToLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layout = controller.layout;
        final tabRailWidth =
            layout.tabRailCollapsed ? 52.0 : layout.tabRailWidth;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.hasTabs)
              WorkbenchResizablePanel(
                width: tabRailWidth,
                minWidth: layout.tabRailCollapsed ? 52 : 120,
                maxWidth: 320,
                locked: layout.tabRailLocked,
                onWidthChanged: layout.tabRailCollapsed
                    ? null
                    : controller.setTabRailWidth,
                onToggleLock: controller.toggleTabRailLocked,
                child: WorkTabRail(
                  tabs: controller.tabs,
                  activeTabId: controller.activeTabId,
                  collapsed: layout.tabRailCollapsed,
                  onToggleCollapsed: controller.toggleTabRailCollapsed,
                  onSelect: controller.selectTab,
                  onClose: controller.closeTab,
                ),
              ),
            Expanded(
              child: controller.hasOpenWork
                  ? WorkDetailWorkspace(
                      key: ValueKey(controller.activeTab!.id),
                      tabId: controller.activeTab!.id,
                      item: controller.activeTab!.item,
                      isDirty: controller.activeTab!.isDirty,
                      infoPanelWidth: layout.infoPanelWidth,
                      infoPanelLocked: layout.infoPanelLocked,
                      onInfoWidthChanged: controller.setInfoPanelWidth,
                      onToggleInfoLock: controller.toggleInfoPanelLocked,
                      onSaved: (saved) {
                        final id = controller.activeTab!.id;
                        controller.updateTabItem(id, saved, dirty: false);
                        onWorkSaved(saved);
                      },
                      onDeleted: () {
                        final tab = controller.activeTab!;
                        onWorkDeleted(tab.id, tab.item);
                      },
                      onDirtyChanged: (dirty) {
                        final id = controller.activeTab!.id;
                        controller.markDirty(id, dirty: dirty);
                      },
                      onAddToLibrary: onAddToLibrary,
                    )
                  : browseContent,
            ),
          ],
        );
      },
    );
  }
}
