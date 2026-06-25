import 'package:flutter/material.dart';

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
}
