import 'package:flutter/material.dart';

import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../theme/akasha_colors.dart';
import '../dashboard_preview_panel.dart';
import 'home_dashboard_continue_section.dart';
import 'home_dashboard_discovery_section.dart';
import 'home_dashboard_quick_actions_section.dart';
import 'home_dashboard_top_bar.dart';
import 'home_dashboard_universe_section.dart';
import 'home_dashboard_welcome_header.dart';

/// 시안 사진과 동일한 프리미엄 홈 대시보드 마스터 뷰.
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({
    super.key,
    required this.vaultItems,
    required this.recentExploreItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onOpenWork,
    required this.onOpenEntity,
    required this.onSearch,
    required this.onTimeline,
    required this.onGoExplore,
    required this.onGoKnowledgeGraph,
    required this.onExploreEntities,
    required this.onVaultSettings,
  });

  final List<AkashaItem> vaultItems;
  final List<AkashaItem> recentExploreItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem) onOpenWork;
  final void Function(UserCatalogEntity) onOpenEntity;
  final VoidCallback onSearch;
  final VoidCallback onTimeline;
  final VoidCallback onGoExplore;
  final VoidCallback onGoKnowledgeGraph;
  final VoidCallback onExploreEntities;
  final VoidCallback onVaultSettings;

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  AkashaItem? _selectedPreviewItem;

  void _handleItemTap(AkashaItem item) {
    if (item is EntityItem) {
      final entity = widget.userCatalog.all.firstWhere(
        (e) => e.entityId == item.entityId,
        orElse: () => UserCatalogEntity.userLocal(
          entityId: item.entityId,
          type: item.entityType,
          title: item.title,
          subtype: item.category,
          addedAt: item.addedAt,
        ),
      );
      widget.onOpenEntity(entity);
      return;
    }
    setState(() => _selectedPreviewItem = item);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AkashaColors.background),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeDashboardTopBar(
                    onSearch: widget.onSearch,
                    onVaultSettings: widget.onVaultSettings,
                  ),
                  const SizedBox(height: 40),
                  const HomeDashboardWelcomeHeader(),
                  const SizedBox(height: 28),
                  HomeDashboardContinueSection(
                    recentExploreItems: widget.recentExploreItems,
                    selectedPreviewItem: _selectedPreviewItem,
                    onItemTap: _handleItemTap,
                    onGoExplore: widget.onGoExplore,
                  ),
                  const SizedBox(height: 40),
                  HomeDashboardDiscoverySection(
                    vaultItems: widget.vaultItems,
                    userCatalog: widget.userCatalog,
                    onItemTap: _handleItemTap,
                    onOpenEntity: widget.onOpenEntity,
                    onGoExplore: widget.onGoExplore,
                  ),
                  const SizedBox(height: 40),
                  HomeDashboardUniverseSection(
                    vaultItems: widget.vaultItems,
                    userCatalog: widget.userCatalog,
                    selectedPreviewItem: _selectedPreviewItem,
                    onItemTap: _handleItemTap,
                    onSearch: widget.onSearch,
                  ),
                  const SizedBox(height: 40),
                  HomeDashboardQuickActionsSection(
                    onSearch: widget.onSearch,
                    onExploreEntities: widget.onExploreEntities,
                    onGoExplore: widget.onGoExplore,
                    onGoKnowledgeGraph: widget.onGoKnowledgeGraph,
                    onTimeline: widget.onTimeline,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          if (_selectedPreviewItem != null)
            DashboardPreviewPanel(
              item: _selectedPreviewItem!,
              userCatalog: widget.userCatalog,
              linkIndex: widget.linkIndex,
              vaultItems: widget.vaultItems,
              onClose: () => setState(() => _selectedPreviewItem = null),
              onOpenDetail: () {
                final item = _selectedPreviewItem!;
                setState(() => _selectedPreviewItem = null);
                widget.onOpenWork(item);
              },
              onOpenEntity: widget.onOpenEntity,
              onOpenWork: (work) {
                setState(() => _selectedPreviewItem = work);
              },
            ),
        ],
      ),
    );
  }
}
