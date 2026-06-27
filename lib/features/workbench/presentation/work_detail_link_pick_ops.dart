import 'package:flutter/material.dart';

import '../../../data/adapters/markdown_vault_adapter.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../models/sanctum_cast_entry.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/markdown_body_merger.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'widgets/work_sanctum_section_editor.dart';
import 'workbench_link_pick_ops.dart';

/// WorkDetailWorkspace wiki link pick·삽입.
abstract final class WorkDetailLinkPickOps {
  static WorkbenchPendingLinkRequest pendingRequest({
    required String? pendingWorkId,
    required bool pendingWorkLinkPick,
    required EntityAnchorType? entityLinkType,
    required LinkCandidate? preselected,
  }) =>
      WorkbenchPendingLinkRequest(
        contextId: pendingWorkId,
        pendingWorkLinkPick: pendingWorkLinkPick,
        entityLinkType: entityLinkType,
        preselected: preselected,
      );

  static Future<EntityLinkSelection?> requestEntityLinkForType({
    required BuildContext context,
    required UserCatalogPort catalog,
    required EntityAnchorType type,
    required AkashaItem workContext,
    required List<AkashaItem> vaultItems,
    String? vaultPath,
  }) =>
      WorkbenchLinkPickOps.pickEntityLink(
        context: context,
        catalog: catalog,
        type: type,
        workContext: workContext,
        vaultItems: vaultItems,
        vaultPath: vaultPath ?? MarkdownVaultAdapter().vaultPath,
      );

  static Future<EntityLinkSelection?> requestWorkLink({
    required BuildContext context,
    required List<AkashaItem> vaultItems,
    required String excludeWorkId,
  }) =>
      WorkbenchLinkPickOps.pickWorkLink(
        context: context,
        vaultItems: vaultItems,
        excludeWorkId: excludeWorkId,
      );

  static Future<void> applySelection({
    required EntityLinkSelection picked,
    required SanctumPageView pageView,
    required WorkSanctumSectionEditorState? sectionEditor,
    required TextEditingController bodyCtrl,
    required VoidCallback syncBodyToItem,
    required VoidCallback markDirty,
    required Future<void> Function() reloadLinkNeighbors,
  }) async {
    final isPerson = picked.entityType == UserCatalogEntity.entityTypePerson;

    if (sectionEditor != null && pageView == SanctumPageView.body) {
      if (isPerson) {
        sectionEditor.insertCastEntry(picked);
      } else {
        sectionEditor.insertWikiLink(picked);
      }
    } else if (isPerson) {
      _applyCastToBody(bodyCtrl: bodyCtrl, picked: picked);
    } else {
      WorkbenchLinkPickOps.applyToBodyController(
        bodyCtrl: bodyCtrl,
        picked: picked,
      );
    }
    syncBodyToItem();
    markDirty();
    await reloadLinkNeighbors();
  }

  static void _applyCastToBody({
    required TextEditingController bodyCtrl,
    required EntityLinkSelection picked,
  }) {
    final slots = MarkdownBodyMerger.parseSlots(bodyCtrl.text);
    final cast = List<SanctumCastEntry>.from(slots.cast);
    if (cast.any((entry) => entry.entityId == picked.entityId)) return;

    cast.add(SanctumCastEntry(
      entityId: picked.entityId,
      title: picked.title,
    ));

    bodyCtrl.text = MarkdownBodyMerger.mergeBody(
      bodyRaw: bodyCtrl.text,
      cast: cast,
      synopsis: slots.synopsis,
      quotes: slots.quotes,
      memo: slots.memo,
    );
  }

  static Future<void> runInteractiveEntityPick({
    required BuildContext context,
    required bool Function() isMounted,
    required UserCatalogPort? catalog,
    required EntityAnchorType type,
    required AkashaItem workContext,
    required List<AkashaItem> vaultItems,
    required void Function(SanctumPageView view) showBodyView,
    required Future<void> Function(EntityLinkSelection picked) applySelection,
  }) async {
    if (catalog == null || !isMounted()) return;
    showBodyView(SanctumPageView.body);
    final picked = await requestEntityLinkForType(
      context: context,
      catalog: catalog,
      type: type,
      workContext: workContext,
      vaultItems: vaultItems,
    );
    if (!isMounted() || picked == null) return;
    await applySelection(picked);
  }

  static Future<void> runInteractiveWorkPick({
    required BuildContext context,
    required bool Function() isMounted,
    required List<AkashaItem> vaultItems,
    required String excludeWorkId,
    required void Function(SanctumPageView view) showBodyView,
    required Future<void> Function(EntityLinkSelection picked) applySelection,
  }) async {
    if (!isMounted()) return;
    showBodyView(SanctumPageView.body);
    final picked = await requestWorkLink(
      context: context,
      vaultItems: vaultItems,
      excludeWorkId: excludeWorkId,
    );
    if (!isMounted() || picked == null) return;
    await applySelection(picked);
  }

  static Future<void> runPendingPick({
    required BuildContext context,
    required String? pendingWorkId,
    required bool pendingWorkLinkPick,
    required EntityAnchorType? pendingEntityLinkType,
    required LinkCandidate? preselected,
    required String currentWorkId,
    required UserCatalogPort? catalog,
    required AkashaItem item,
    required List<AkashaItem> vaultItems,
    required void Function(SanctumPageView view) showBodyView,
    required Future<void> Function() requestWorkLink,
    required Future<void> Function(EntityLinkSelection picked) applySelection,
    required VoidCallback? onPendingHandled,
  }) async {
    final request = pendingRequest(
      pendingWorkId: pendingWorkId,
      pendingWorkLinkPick: pendingWorkLinkPick,
      entityLinkType: pendingEntityLinkType,
      preselected: preselected,
    );
    switch (WorkbenchLinkPickOps.classifyPending(
      request: request,
      currentContextId: currentWorkId,
      catalog: catalog,
    )) {
      case WorkbenchPendingLinkResolution.wrongContext:
      case WorkbenchPendingLinkResolution.skipped:
        return;
      case WorkbenchPendingLinkResolution.pickWork:
        onPendingHandled?.call();
        await requestWorkLink();
      case WorkbenchPendingLinkResolution.pickEntity:
        onPendingHandled?.call();
        if (catalog == null) return;
        showBodyView(SanctumPageView.body);
        final picked = await WorkbenchLinkPickOps.pickEntityLink(
          context: context,
          catalog: catalog,
          type: request.entityLinkType!,
          workContext: item,
          vaultItems: vaultItems,
          vaultPath: MarkdownVaultAdapter().vaultPath,
          preselected: request.preselected,
        );
        if (picked == null) return;
        await applySelection(picked);
    }
  }
}
