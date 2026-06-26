import 'package:flutter/material.dart';

import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/record_link.dart';
import '../../../models/akasha_item.dart';
import '../../../models/registry_work.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/record_link_navigator.dart';
import '../../../models/entity_link_selection.dart';
import 'dialogs/entity_link_picker_dialog.dart';
import 'home_shell_controller_base.dart';

/// Preview stack·link pick flows.
mixin HomeShellControllerPreviewMixin on HomeShellControllerBase {
  void clearPendingWorkEntityLinkType() => preview.clearPendingWork();

  void clearPendingEntityLink() => preview.clearPendingEntity();

  void openWorkFromPreviewToConnect(EntityAnchorType type) =>
      preview.openWorkFromPreviewToConnect(type);

  void openWorkFromPreviewToConnectWork() =>
      preview.openWorkFromPreviewToConnectWork();

  void openWorkFromPreviewToConnectSuggested(LinkCandidate candidate) =>
      preview.openWorkFromPreviewToConnectSuggested(candidate);

  void openEntityFromPreviewToConnect(EntityAnchorType type) =>
      preview.openEntityFromPreviewToConnect(type);

  void openEntityFromPreviewToConnectWork() =>
      preview.openEntityFromPreviewToConnectWork();

  void connectSuggestedForWork(LinkCandidate candidate, AkashaItem work) {
    preview.openWorkPreview(workbenchCoord.resolveItemForOpen(work));
    preview.openWorkFromPreviewToConnectSuggested(candidate);
  }

  Future<void> openWorkDetail(AkashaItem item) => preview.openWorkDetail(item);

  void openWorkPreview(AkashaItem item, {bool push = false}) =>
      preview.openWorkPreview(item, push: push);

  void closeAllPreviews() => preview.closeAllPreviews();

  void navigateWorkPreview(AkashaItem item) => preview.navigateWorkPreview(item);

  void navigateEntityPreview(UserCatalogEntity entity) =>
      preview.navigateEntityPreview(entity);

  void popPreview() => preview.popPreview();

  Future<void> openWorkFromPreview() => preview.openWorkFromPreview();

  void previewRegistryWork(RegistryWork work) =>
      preview.previewRegistryWork(work);

  Future<void> archiveRegistryWorkFromPreview() =>
      preview.archiveRegistryWorkFromPreview();

  void openEntityPreview(UserCatalogEntity entity, {bool push = false}) =>
      preview.openEntityPreview(entity, push: push);

  Future<void> openEntityFromPreview() => preview.openEntityFromPreview();

  void previewLinkedWork(AkashaItem work) => preview.previewLinkedWork(work);

  void previewLinkedEntity(UserCatalogEntity entity) =>
      preview.previewLinkedEntity(entity);

  Future<void> handleWikiLinkTap(ParsedRecordLink link) async {
    if (!host.mounted) return;
    workbench.showBrowse();
    await RecordLinkNavigator.navigateLink(
      host.context,
      link: link,
      userCatalog: userCatalog,
      vaultItems: vault.items,
      onOpenWork: (item) {
        openWorkPreview(workbenchCoord.resolveItemForOpen(item));
      },
      onOpenEntity: (entity) async {
        openEntityPreview(entity);
      },
      linkIndex: vault.linkIndex,
    );
  }

  Future<EntityLinkSelection?> handleRequestEntityLink(
    BuildContext context,
    String selectedText,
  ) {
    return showEntityLinkPickerDialog(
      context,
      userCatalog: userCatalog,
      initialQuery: selectedText,
    );
  }
}
