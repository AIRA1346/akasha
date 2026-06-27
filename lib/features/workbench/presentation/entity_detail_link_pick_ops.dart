import 'package:flutter/material.dart';

import '../../../data/adapters/markdown_vault_adapter.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'workbench_link_pick_ops.dart';

/// EntityDetailWorkspace wiki link pick·삽입.
abstract final class EntityDetailLinkPickOps {
  static WorkbenchPendingLinkRequest pendingRequest({
    required String? pendingEntityId,
    required bool pendingWorkLinkPick,
    required EntityAnchorType? entityLinkType,
  }) =>
      WorkbenchPendingLinkRequest(
        contextId: pendingEntityId,
        pendingWorkLinkPick: pendingWorkLinkPick,
        entityLinkType: entityLinkType,
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
  }) =>
      WorkbenchLinkPickOps.pickWorkLink(
        context: context,
        vaultItems: vaultItems,
        excludeWorkId: '',
      );

  static Future<void> applySelection({
    required EntityLinkSelection picked,
    required TextEditingController bodyCtrl,
    required VoidCallback markDirty,
    required Future<void> Function() reloadLinkNeighbors,
  }) async {
    WorkbenchLinkPickOps.applyToBodyController(
      bodyCtrl: bodyCtrl,
      picked: picked,
    );
    markDirty();
    await reloadLinkNeighbors();
  }

  static Future<void> runPendingPick({
    required BuildContext context,
    required String? pendingEntityId,
    required bool pendingWorkLinkPick,
    required EntityAnchorType? pendingEntityLinkType,
    required String currentEntityId,
    required UserCatalogPort? catalog,
    required AkashaItem item,
    required List<AkashaItem> vaultItems,
    required TextEditingController bodyCtrl,
    required void Function(SanctumPageView view) showBodyView,
    required VoidCallback markDirty,
    required Future<void> Function() reloadLinkNeighbors,
    required Future<void> Function() requestWorkLink,
    required VoidCallback? onPendingHandled,
  }) async {
    final request = pendingRequest(
      pendingEntityId: pendingEntityId,
      pendingWorkLinkPick: pendingWorkLinkPick,
      entityLinkType: pendingEntityLinkType,
    );
    switch (WorkbenchLinkPickOps.classifyPending(
      request: request,
      currentContextId: currentEntityId,
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
        );
        if (picked == null) return;
        await applySelection(
          picked: picked,
          bodyCtrl: bodyCtrl,
          markDirty: markDirty,
          reloadLinkNeighbors: reloadLinkNeighbors,
        );
    }
  }
}
