import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
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
  }) =>
      WorkbenchLinkPickOps.pickEntityLink(
        context: context,
        catalog: catalog,
        type: type,
        workContext: workContext,
        vaultItems: vaultItems,
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
}
