import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/entity_link_selection.dart';
import '../../../screens/home/dialogs/entity_link_picker_dialog.dart';
import '../../../screens/home/dialogs/work_link_picker_dialog.dart';
import '../../../services/link_candidate_service.dart';
import '../../../utils/markdown_edit_actions.dart';

/// Preview → workbench pending link handoff payload.
class WorkbenchPendingLinkRequest {
  const WorkbenchPendingLinkRequest({
    this.contextId,
    this.pendingWorkLinkPick = false,
    this.entityLinkType,
    this.preselected,
  });

  /// Tab workId / entityId filter from [HomePreviewLinkCoordinator].
  final String? contextId;
  final bool pendingWorkLinkPick;
  final EntityAnchorType? entityLinkType;
  final LinkCandidate? preselected;
}

enum WorkbenchPendingLinkResolution {
  wrongContext,
  skipped,
  pickWork,
  pickEntity,
}

/// Entity·Work link picker 공통 로직.
abstract final class WorkbenchLinkPickOps {
  static bool matchesContext({
    required String? pendingContextId,
    required String currentContextId,
  }) =>
      pendingContextId == null || pendingContextId == currentContextId;

  static WorkbenchPendingLinkResolution classifyPending({
    required WorkbenchPendingLinkRequest request,
    required String currentContextId,
    required UserCatalogPort? catalog,
  }) {
    if (!matchesContext(
      pendingContextId: request.contextId,
      currentContextId: currentContextId,
    )) {
      return WorkbenchPendingLinkResolution.wrongContext;
    }
    if (request.pendingWorkLinkPick) {
      return WorkbenchPendingLinkResolution.pickWork;
    }
    if (request.entityLinkType == null || catalog == null) {
      return WorkbenchPendingLinkResolution.skipped;
    }
    return WorkbenchPendingLinkResolution.pickEntity;
  }

  static Future<EntityLinkSelection?> pickEntityLink({
    required BuildContext context,
    required UserCatalogPort catalog,
    required EntityAnchorType type,
    required AkashaItem workContext,
    required List<AkashaItem> vaultItems,
    String? vaultPath,
    LinkCandidate? preselected,
  }) async {
    if (preselected != null) {
      return LinkCandidateService.resolveSelection(
        candidate: preselected,
        userCatalog: catalog,
      );
    }
    return showEntityLinkPickerDialog(
      context,
      userCatalog: catalog,
      anchorTypeFilter: type,
      workContext: workContext,
      vaultItems: vaultItems,
      vaultPath: vaultPath,
    );
  }

  static Future<EntityLinkSelection?> pickWorkLink({
    required BuildContext context,
    required List<AkashaItem> vaultItems,
    required String excludeWorkId,
  }) =>
      showWorkLinkPickerDialog(
        context,
        vaultItems: vaultItems,
        excludeWorkId: excludeWorkId,
      );

  static void applyToBodyController({
    required TextEditingController bodyCtrl,
    required EntityLinkSelection picked,
  }) {
    final patch = MarkdownEditActions.insertWikiLink(
      text: bodyCtrl.text,
      selection: bodyCtrl.selection,
      entityId: picked.entityId,
      title: picked.title,
    );
    bodyCtrl.text = patch.text;
    bodyCtrl.selection = patch.selection;
  }
}
