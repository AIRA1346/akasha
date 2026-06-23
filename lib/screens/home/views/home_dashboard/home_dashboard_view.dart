import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../models/registry_work.dart';
import '../../../../services/link_candidate_service.dart';
import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../theme/akasha_colors.dart';
import 'home_dashboard_hero.dart';
import 'home_dashboard_continue_section.dart';
import 'home_dashboard_recent_discovery_section.dart';
import 'home_dashboard_recent_records_section.dart';
import 'home_dashboard_registry_bridge_section.dart';
import 'home_dashboard_theme_clusters_section.dart';
import 'home_dashboard_todays_links_section.dart';
import 'home_dashboard_top_bar.dart';

/// 탐험 중심 홈 — 4섹션 IA (P5).
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
    required this.onVaultSettings,
    this.previewItem,
    this.entityPreviewItem,
    this.onConnectSuggested,
    this.onPreviewRegistryWork,
  });

  final List<AkashaItem> vaultItems;
  final List<AkashaItem> recentExploreItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem) onPreviewWork;
  final void Function(UserCatalogEntity) onPreviewEntity;
  final VoidCallback onSearch;
  final VoidCallback onVaultSettings;
  final AkashaItem? previewItem;
  final UserCatalogEntity? entityPreviewItem;
  final void Function(LinkCandidate candidate, AkashaItem work)?
      onConnectSuggested;
  final void Function(RegistryWork work)? onPreviewRegistryWork;

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
            HomeDashboardHero(onStartExplore: onSearch),
            const SizedBox(height: 24),
            HomeDashboardTopBar(
              onSearch: onSearch,
              onVaultSettings: onVaultSettings,
            ),
            const SizedBox(height: 28),
            HomeDashboardContinueSection(
              recentExploreItems: recentExploreItems,
              fallbackVaultItems: vaultItems,
              selectedPreviewItem: previewItem,
              selectedEntityPreviewId: entityPreviewItem?.entityId,
              onItemTap: _handleItemTap,
              isColdStart: isColdStart,
            ),
            const SizedBox(height: 32),
            HomeDashboardTodaysLinksSection(
              vaultItems: vaultItems,
              userCatalog: userCatalog,
              linkIndex: linkIndex,
              onOpenWork: onPreviewWork,
              onOpenEntity: onPreviewEntity,
              onConnectSuggested: onConnectSuggested,
            ),
            const SizedBox(height: 32),
            HomeDashboardThemeClustersSection(
              vaultItems: vaultItems,
              userCatalog: userCatalog,
              linkIndex: linkIndex,
              onOpenConcept: onPreviewEntity,
            ),
            const SizedBox(height: 32),
            if (onPreviewRegistryWork != null)
              HomeDashboardRegistryBridgeSection(
                vaultItems: vaultItems,
                userCatalog: userCatalog,
                linkIndex: linkIndex,
                onPreviewRegistryWork: onPreviewRegistryWork!,
              ),
            if (onPreviewRegistryWork != null) const SizedBox(height: 32),
            HomeDashboardRecentDiscoverySection(
              vaultItems: vaultItems,
              selectedPreviewItem: previewItem,
              onItemTap: _handleItemTap,
            ),
            const SizedBox(height: 32),
            HomeDashboardRecentRecordsSection(
              vaultItems: vaultItems,
              onItemTap: onPreviewWork,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
