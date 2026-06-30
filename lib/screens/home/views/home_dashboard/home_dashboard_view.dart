import 'package:flutter/material.dart';

import '../../../../config/feature_flags.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/browse_entity_scope.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../models/registry_work.dart';
import '../../../../services/link_candidate_service.dart';
import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../theme/akasha_colors.dart';
import 'home_dashboard_hero.dart';
import 'home_dashboard_continue_section.dart';
import 'home_dashboard_discovery_section.dart';
import 'home_dashboard_quick_actions_section.dart';
import 'home_dashboard_registry_bridge_section.dart';
import 'home_dashboard_universe_section.dart';

/// 탐험 중심 홈 — Continue·Discover·Universe 블록 (Discover/Universe는 [FeatureFlags]).
class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({
    super.key,
    required this.vaultItems,
    required this.recentExploreItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onPreviewWork,
    required this.onPreviewEntity,
    required this.onSearch,
    required this.onGoExplore,
    required this.onGoExploreEntities,
    required this.onGoKnowledgeGraph,
    required this.onTimeline,
    this.previewItem,
    this.entityPreviewItem,
    this.onConnectSuggested,
    this.onPreviewRegistryWork,
    this.onOpenRecordFromHome,
    this.onOpenItemDetail,
    this.onOpenEntityDetail,
  });

  final List<AkashaItem> vaultItems;
  final List<AkashaItem> recentExploreItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem) onPreviewWork;
  final void Function(UserCatalogEntity) onPreviewEntity;
  final VoidCallback onSearch;
  final VoidCallback onGoExplore;
  final void Function(BrowseEntityScope scope) onGoExploreEntities;
  final VoidCallback onGoKnowledgeGraph;
  final VoidCallback onTimeline;
  final AkashaItem? previewItem;
  final UserCatalogEntity? entityPreviewItem;
  final void Function(LinkCandidate candidate, AkashaItem work)?
      onConnectSuggested;
  final void Function(RegistryWork work)? onPreviewRegistryWork;
  final void Function(AkashaItem work)? onOpenRecordFromHome;
  final void Function(AkashaItem item)? onOpenItemDetail;
  final void Function(UserCatalogEntity entity)? onOpenEntityDetail;

  void _handleItemTap(AkashaItem item) {
    if (item is EntityItem) {
      final entity = userCatalog.all.firstWhere(
        (e) => e.entityId == item.entityId,
        orElse: () => UserCatalogEntity.userLocal(
          entityId: item.entityId,
          type: item.entityType,
          title: item.title,
          subtype: item.category,
          addedAt: item.addedAt,
        ),
      );
      onPreviewEntity(entity);
      return;
    }
    onPreviewWork(item);
  }

  void _handleItemDoubleTap(AkashaItem item) {
    if (item is EntityItem) {
      final entity = userCatalog.all.firstWhere(
        (e) => e.entityId == item.entityId,
        orElse: () => UserCatalogEntity.userLocal(
          entityId: item.entityId,
          type: item.entityType,
          title: item.title,
          subtype: item.category,
          addedAt: item.addedAt,
        ),
      );
      if (onOpenEntityDetail != null) {
        onOpenEntityDetail!(entity);
      } else {
        onPreviewEntity(entity);
      }
      return;
    }
    if (onOpenItemDetail != null) {
      onOpenItemDetail!(item);
    } else {
      onOpenRecordFromHome?.call(item);
    }
  }

  void _handleEntityDoubleTap(UserCatalogEntity entity) {
    if (onOpenEntityDetail != null) {
      onOpenEntityDetail!(entity);
    } else {
      onPreviewEntity(entity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isColdStart = recentExploreItems.isEmpty;

    return Container(
      decoration: const BoxDecoration(color: AkashaColors.background),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeDashboardHero(),
            const SizedBox(height: 28),
            HomeDashboardContinueSection(
              recentExploreItems: recentExploreItems,
              fallbackVaultItems: vaultItems,
              selectedPreviewItem: previewItem,
              selectedEntityPreviewId: entityPreviewItem?.entityId,
              onItemTap: _handleItemTap,
              onItemDoubleTap: _handleItemDoubleTap,
              isColdStart: isColdStart,
            ),
            if (FeatureFlags.showDiscoveryHome) ...[
              const SizedBox(height: 32),
              HomeDashboardDiscoverySection(
                vaultItems: vaultItems,
                userCatalog: userCatalog,
                linkIndex: linkIndex,
                onItemTap: _handleItemTap,
                onItemDoubleTap: _handleItemDoubleTap,
                onOpenEntity: onPreviewEntity,
                onOpenEntityDetail: _handleEntityDoubleTap,
                onGoExplore: onGoExplore,
                onSearch: onSearch,
                onConnectSuggested: onConnectSuggested,
                onOpenRecord: onOpenRecordFromHome,
              ),
            ],
            if (FeatureFlags.showHomeUniverseSection) ...[
              const SizedBox(height: 32),
              HomeDashboardUniverseSection(
                vaultItems: vaultItems,
                userCatalog: userCatalog,
                selectedPreviewItem: previewItem,
                onItemTap: _handleItemTap,
                onItemDoubleTap: _handleItemDoubleTap,
                onSearch: onSearch,
              ),
            ],
            if (onPreviewRegistryWork != null) ...[
              const SizedBox(height: 32),
              HomeDashboardRegistryBridgeSection(
                vaultItems: vaultItems,
                userCatalog: userCatalog,
                linkIndex: linkIndex,
                onPreviewRegistryWork: onPreviewRegistryWork!,
              ),
            ],
            const SizedBox(height: 32),
            HomeDashboardQuickActionsSection(
              onSearch: onSearch,
              onExploreEntities: () =>
                  onGoExploreEntities(BrowseEntityScope.person),
              onGoExplore: onGoExplore,
              onGoKnowledgeGraph: onGoKnowledgeGraph,
              onTimeline: onTimeline,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
