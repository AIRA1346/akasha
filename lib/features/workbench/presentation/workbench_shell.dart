import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../data/workbench_controller.dart';
import '../../../widgets/work_tab_rail.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'dialogs/workbench_close_tab_dialog.dart';
import 'work_detail_workspace.dart';

/// 워크벤치 메인 영역 — 탭 레일 + (작업 뷰 | 브라우즈 콘텐츠)
class WorkbenchShell extends StatefulWidget {
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
  State<WorkbenchShell> createState() => _WorkbenchShellState();
}

class _WorkbenchShellState extends State<WorkbenchShell> {
  Future<void> _handleCloseTab(String id) async {
    final tab = widget.controller.tabs.where((t) => t.id == id).firstOrNull;
    if (tab == null) return;
    if (!tab.isDirty) {
      widget.controller.closeTab(id);
      return;
    }

    final isActive = widget.controller.activeTabId == id;
    final canSave = isActive && widget.controller.saveActiveTab != null;
    final choice = await showWorkbenchCloseTabDialog(
      context,
      title: tab.item.title,
      canSave: canSave,
    );
    if (!mounted || choice == null || choice == WorkbenchCloseTabChoice.cancel) {
      return;
    }

    if (choice == WorkbenchCloseTabChoice.saveAndClose) {
      try {
        await widget.controller.saveActiveTab!.call();
      } catch (_) {
        return;
      }
      if (!mounted) return;
      if (widget.controller.tabs.any((t) => t.id == id && t.isDirty)) {
        return;
      }
    }

    widget.controller.closeTab(id);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (!widget.controller.hasTabs) {
              return const SizedBox.shrink();
            }
            final layout = widget.controller.layout;
            final tabRailWidth =
                layout.tabRailCollapsed ? 52.0 : layout.tabRailWidth;

            return WorkbenchResizablePanel(
              width: tabRailWidth,
              minWidth: layout.tabRailCollapsed ? 52 : 120,
              maxWidth: 320,
              locked: layout.tabRailLocked,
              onWidthChanged: layout.tabRailCollapsed
                  ? null
                  : widget.controller.setTabRailWidth,
              onToggleLock: widget.controller.toggleTabRailLocked,
              child: WorkTabRail(
                tabs: widget.controller.tabs,
                activeTabId: widget.controller.activeTabId,
                collapsed: layout.tabRailCollapsed,
                onToggleCollapsed: widget.controller.toggleTabRailCollapsed,
                onSelect: widget.controller.selectTab,
                onClose: _handleCloseTab,
              ),
            );
          },
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              if (!widget.controller.hasOpenWork) {
                return widget.browseContent;
              }
              final layout = widget.controller.layout;
              return WorkDetailWorkspace(
                key: ValueKey(widget.controller.activeTab!.id),
                tabId: widget.controller.activeTab!.id,
                item: widget.controller.activeTab!.item,
                isDirty: widget.controller.activeTab!.isDirty,
                infoPanelWidth: layout.infoPanelWidth,
                infoPanelLocked: layout.infoPanelLocked,
                onInfoWidthChanged: widget.controller.setInfoPanelWidth,
                onToggleInfoLock: widget.controller.toggleInfoPanelLocked,
                onBindSave: (save) =>
                    widget.controller.saveActiveTab = save,
                onSaved: (saved) {
                  final id = widget.controller.activeTab!.id;
                  widget.controller.updateTabItem(id, saved, dirty: false);
                  widget.onWorkSaved(saved);
                },
                onDeleted: () {
                  final tab = widget.controller.activeTab!;
                  widget.onWorkDeleted(tab.id, tab.item);
                },
                onDirtyChanged: (dirty) {
                  final id = widget.controller.activeTab!.id;
                  widget.controller.markDirty(id, dirty: dirty);
                },
                onAddToLibrary: widget.onAddToLibrary,
              );
            },
          ),
        ),
      ],
    );
  }
}
