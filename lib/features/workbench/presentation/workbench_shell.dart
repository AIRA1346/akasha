import 'package:flutter/material.dart';

import '../../../core/archiving/entity_journal_entry.dart';
import '../../../core/archiving/record_link.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/user_catalog_entity.dart';
import '../data/workbench_controller.dart';
import '../../../widgets/collectible_tab_rail.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'dialogs/workbench_close_tab_dialog.dart';
import 'entity_detail_workspace.dart';
import 'collectible_tab.dart';
import 'work_detail_workspace.dart';

/// 워크벤치 메인 영역 — 탭 레일 + (Collectible detail | browse 콘텐츠)
class WorkbenchShell extends StatefulWidget {
  const WorkbenchShell({
    super.key,
    required this.controller,
    required this.browseContent,
    required this.onWorkSaved,
    required this.onWorkDeleted,
    required this.onEntitySaved,
    required this.onEntityDeleted,
    this.userCatalog,
    this.linkIndex,
    this.onAddToLibrary,
    this.onWikiLinkTap,
    this.onRequestEntityLink,
  });

  final WorkbenchController controller;
  final Widget browseContent;
  final void Function(AkashaItem saved) onWorkSaved;
  final void Function(String tabId, AkashaItem item) onWorkDeleted;
  final void Function(UserCatalogEntity entity, EntityJournalEntry? journal)
      onEntitySaved;
  final void Function(String tabId) onEntityDeleted;
  final UserCatalogPort? userCatalog;
  final RecordLinkPort? linkIndex;
  final Future<void> Function(AkashaItem item)? onAddToLibrary;
  final void Function(ParsedRecordLink link)? onWikiLinkTap;
  final Future<EntityLinkSelection?> Function(
    BuildContext context,
    String selectedText,
  )? onRequestEntityLink;

  @override
  State<WorkbenchShell> createState() => _WorkbenchShellState();
}

class _WorkbenchShellState extends State<WorkbenchShell> {
  Future<void> _handleCloseTab(String id) async {
    CollectibleTab? tab;
    for (final candidate in widget.controller.tabs) {
      if (candidate.id == id) {
        tab = candidate;
        break;
      }
    }
    if (tab == null) return;
    if (!tab.isDirty) {
      widget.controller.closeTab(id);
      return;
    }

    final wasActive = widget.controller.activeTabId == id;
    if (!wasActive) {
      widget.controller.selectTab(id);
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      for (final candidate in widget.controller.tabs) {
        if (candidate.id == id) {
          tab = candidate;
          break;
        }
      }
      if (tab == null) return;
    }

    final canSave = widget.controller.saveActiveTab != null;
    final choice = await showWorkbenchCloseTabDialog(
      context,
      title: tab.title,
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
              child: CollectibleTabRail(
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
              if (!widget.controller.hasOpenDetail) {
                return widget.browseContent;
              }
              final layout = widget.controller.layout;
              final active = widget.controller.activeTab;
              if (active == null) return widget.browseContent;

              return switch (active) {
                WorkCollectibleTab(:final item, :final isDirty) =>
                  WorkDetailWorkspace(
                    key: ValueKey(active.id),
                    tabId: active.id,
                    item: item,
                    isDirty: isDirty,
                    infoPanelWidth: layout.infoPanelWidth,
                    infoPanelLocked: layout.infoPanelLocked,
                    onInfoWidthChanged: widget.controller.setInfoPanelWidth,
                    onToggleInfoLock: widget.controller.toggleInfoPanelLocked,
                    onBindSave: (save) =>
                        widget.controller.saveActiveTab = save,
                    onPreserveDraft: (tabId, draft) {
                      widget.controller.updateTabItem(tabId, draft, dirty: true);
                    },
                    onSaved: (saved) {
                      widget.controller.updateTabItem(
                        active.id,
                        saved,
                        dirty: false,
                      );
                      widget.onWorkSaved(saved);
                    },
                    onDeleted: () {
                      widget.onWorkDeleted(active.id, item);
                    },
                    onDirtyChanged: (dirty) {
                      widget.controller.markDirty(active.id, dirty: dirty);
                    },
                    onAddToLibrary: widget.onAddToLibrary,
                    onWikiLinkTap: widget.onWikiLinkTap,
                    onRequestEntityLink: widget.onRequestEntityLink,
                  ),
                EntityCollectibleTab(:final entity, :final journal, :final isDirty) =>
                  EntityDetailWorkspace(
                    key: ValueKey(active.id),
                    tabId: active.id,
                    entity: entity,
                    journal: journal,
                    isDirty: isDirty,
                    infoPanelWidth: layout.infoPanelWidth,
                    infoPanelLocked: layout.infoPanelLocked,
                    userCatalog: widget.userCatalog,
                    linkIndex: widget.linkIndex,
                    onInfoWidthChanged: widget.controller.setInfoPanelWidth,
                    onToggleInfoLock: widget.controller.toggleInfoPanelLocked,
                    onBindSave: (save) =>
                        widget.controller.saveActiveTab = save,
                    onPreserveDraft: (tabId, draftEntity, draftJournal, tags, body) {
                      widget.controller.preserveEntityDraft(
                        tabId,
                        draftEntity.copyWith(tags: tags),
                        draftJournal,
                      );
                    },
                    onSaved: (savedEntity, savedJournal) {
                      widget.controller.updateEntityTab(
                        active.id,
                        savedEntity,
                        savedJournal,
                        dirty: false,
                      );
                      widget.onEntitySaved(savedEntity, savedJournal);
                    },
                    onDeleted: () {
                      widget.onEntityDeleted(active.id);
                    },
                    onDirtyChanged: (dirty) {
                      widget.controller.markDirty(active.id, dirty: dirty);
                    },
                    onWikiLinkTap: widget.onWikiLinkTap,
                    onRequestEntityLink: widget.onRequestEntityLink,
                  ),
              };
            },
          ),
        ),
      ],
    );
  }
}
