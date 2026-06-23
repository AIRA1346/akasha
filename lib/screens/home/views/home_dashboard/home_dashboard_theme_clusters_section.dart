import 'package:flutter/material.dart';

import '../../../../core/ports/record_link_port.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../models/user_catalog_entity.dart';
import '../../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../../services/relationship_discovery_service.dart';
import '../../../../widgets/work_preview_theme_clusters_section.dart';
import 'home_dashboard_styles.dart';

/// Home — Concept Theme Cluster (R13).
class HomeDashboardThemeClustersSection extends StatefulWidget {
  const HomeDashboardThemeClustersSection({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onOpenConcept,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(UserCatalogEntity concept) onOpenConcept;

  @override
  State<HomeDashboardThemeClustersSection> createState() =>
      _HomeDashboardThemeClustersSectionState();
}

class _HomeDashboardThemeClustersSectionState
    extends State<HomeDashboardThemeClustersSection> {
  late Future<List<ConceptThemeCluster>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardThemeClustersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vaultItems != widget.vaultItems ||
        oldWidget.linkIndex != widget.linkIndex) {
      _future = _load();
    }
  }

  Future<List<ConceptThemeCluster>> _load() {
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    return RelationshipDiscoveryService.conceptThemeClusters(
      vaultItems: widget.vaultItems,
      userCatalog: widget.userCatalog,
      discovery: discovery,
      limit: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConceptThemeCluster>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final clusters = snapshot.data ?? const [];
        if (clusters.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeDashboardStyles.sectionHeader('반복되는 주제'),
            const SizedBox(height: 12),
            WorkPreviewThemeClustersSection(
              clusters: clusters,
              compact: true,
              onOpenConcept: (cluster) =>
                  widget.onOpenConcept(cluster.concept),
            ),
          ],
        );
      },
    );
  }
}
