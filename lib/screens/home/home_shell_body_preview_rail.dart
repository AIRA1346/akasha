import 'package:flutter/material.dart';

import '../../core/archiving/entity_anchor.dart';
import '../../core/ports/record_link_port.dart';
import '../../core/ports/user_catalog_port.dart';
import '../../models/akasha_item.dart';
import '../../models/registry_work.dart';
import '../../models/user_catalog_entity.dart';
import '../../services/link_candidate_service.dart';
import 'views/dashboard_preview_panel.dart';
import 'views/entity_dashboard_preview_panel.dart';

/// Work·entity preview 패널 (Workbench detail 열림 시 숨김).
List<Widget> buildHomeShellBodyPreviewPanels({
  required bool workbenchHasOpenDetail,
  required AkashaItem? workPreviewItem,
  required UserCatalogEntity? entityPreviewItem,
  required UserCatalogPort userCatalog,
  required RecordLinkPort linkIndex,
  required int linkIndexRevision,
  required List<AkashaItem> vaultItems,
  required bool canPopPreview,
  required VoidCallback onPopPreview,
  required VoidCallback onCloseAllPreviews,
  required VoidCallback onOpenWorkFromPreview,
  required Future<void> Function() onOpenEntityFromPreview,
  required void Function(UserCatalogEntity entity) onPreviewLinkedEntity,
  required void Function(AkashaItem item) onPreviewLinkedWork,
  required Future<void> Function() onGoKnowledgeGraph,
  required void Function(EntityAnchorType type) onConnectEntityFromPreview,
  required VoidCallback onConnectWorkFromPreview,
  required void Function(EntityAnchorType type) onConnectEntityFromEntityPreview,
  required VoidCallback onConnectWorkFromEntityPreview,
  required void Function(LinkCandidate candidate) onConnectSuggestedFromPreview,
  required void Function(RegistryWork work) onPreviewRegistryWork,
  required Future<void> Function() onArchiveRegistryWorkFromPreview,
}) {
  if (workbenchHasOpenDetail) {
    return const [];
  }

  final panels = <Widget>[];
  if (workPreviewItem != null) {
    panels.add(
      DashboardPreviewPanel(
        item: workPreviewItem,
        userCatalog: userCatalog,
        linkIndex: linkIndex,
        linkIndexRevision: linkIndexRevision,
        vaultItems: vaultItems,
        canGoBack: canPopPreview,
        onBack: onPopPreview,
        onClose: onCloseAllPreviews,
        onOpenDetail: onOpenWorkFromPreview,
        onOpenEntity: onPreviewLinkedEntity,
        onOpenWork: onPreviewLinkedWork,
        onGoKnowledgeGraph: () => onGoKnowledgeGraph(),
        onConnectEntityType: onConnectEntityFromPreview,
        onConnectWorkFromPreview: onConnectWorkFromPreview,
        onConnectSuggested: onConnectSuggestedFromPreview,
        onPreviewRegistryWork: onPreviewRegistryWork,
        onArchiveRegistryWork: onArchiveRegistryWorkFromPreview,
      ),
    );
  }
  if (entityPreviewItem != null) {
    panels.add(
      EntityDashboardPreviewPanel(
        entity: entityPreviewItem,
        userCatalog: userCatalog,
        linkIndex: linkIndex,
        linkIndexRevision: linkIndexRevision,
        vaultItems: vaultItems,
        canGoBack: canPopPreview,
        onBack: onPopPreview,
        onClose: onCloseAllPreviews,
        onOpenDetail: onOpenEntityFromPreview,
        onOpenEntity: onPreviewLinkedEntity,
        onOpenWork: onPreviewLinkedWork,
        onGoKnowledgeGraph: () => onGoKnowledgeGraph(),
        onPreviewRegistryWork: onPreviewRegistryWork,
        onConnectEntityType: onConnectEntityFromEntityPreview,
        onConnectWork: onConnectWorkFromEntityPreview,
      ),
    );
  }
  return panels;
}
