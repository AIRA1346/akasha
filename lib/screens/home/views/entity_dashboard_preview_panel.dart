import 'package:flutter/material.dart';

import '../../../config/feature_flags.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/entity_link_neighbors.dart';
import '../../../widgets/entity_link_neighbors_sections.dart';
import '../../../widgets/poster_image.dart';

class EntityDashboardPreviewPanel extends StatefulWidget {
  const EntityDashboardPreviewPanel({
    super.key,
    required this.entity,
    required this.userCatalog,
    required this.linkIndex,
    required this.vaultItems,
    this.canGoBack = false,
    this.onBack,
    required this.onClose,
    required this.onOpenDetail,
    this.onOpenEntity,
    this.onOpenWork,
    this.onGoKnowledgeGraph,
  });

  final UserCatalogEntity entity;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final List<AkashaItem> vaultItems;
  final bool canGoBack;
  final VoidCallback? onBack;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final void Function(AkashaItem work)? onOpenWork;
  final VoidCallback? onGoKnowledgeGraph;

  @override
  State<EntityDashboardPreviewPanel> createState() =>
      _EntityDashboardPreviewPanelState();
}

class _EntityDashboardPreviewPanelState
    extends State<EntityDashboardPreviewPanel> {
  late Future<EntityLinkNeighbors> _neighborsFuture;

  @override
  void initState() {
    super.initState();
    _neighborsFuture = _loadNeighbors();
  }

  @override
  void didUpdateWidget(covariant EntityDashboardPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.entityId != widget.entity.entityId) {
      _neighborsFuture = _loadNeighbors();
    }
  }

  Future<EntityLinkNeighbors> _loadNeighbors() {
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    return fetchEntityLinkNeighbors(
      entity: widget.entity,
      userCatalog: widget.userCatalog,
      discovery: discovery,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = entityTypeBadgeLabel(widget.entity.anchorType);
    final avatarItem = EntityItem(
      entityType: widget.entity.anchorType,
      entityId: widget.entity.entityId,
      title: widget.entity.title,
      category: widget.entity.subtype,
      domain: widget.entity.domain,
      creator: widget.entity.creator,
      releaseYear: widget.entity.releaseYear,
      posterPath: widget.entity.posterPath,
      tags: widget.entity.tags,
      addedAt: widget.entity.addedAt,
    );

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.canGoBack && widget.onBack != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text(
                        '이전',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: Colors.grey[400],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: Colors.grey[500],
                      onPressed: widget.onClose,
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: PosterImage(item: avatarItem, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.entity.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (widget.entity.aliases.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.entity.aliases.join(' · '),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    widget.entity.entityId,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.onOpenDetail,
                      style: FilledButton.styleFrom(
                        backgroundColor: AkashaColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '기록하기 >',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<EntityLinkNeighbors>(
                    future: _neighborsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const EntityLinkNeighborsSections(
                          neighbors: EntityLinkNeighbors(),
                          entityTags: [],
                          loading: true,
                        );
                      }
                      final neighbors =
                          snapshot.data ?? const EntityLinkNeighbors();
                      return EntityLinkNeighborsSections(
                        neighbors: neighbors,
                        entityTags: widget.entity.tags,
                        onOpenEntity: widget.onOpenEntity,
                        onOpenWork: widget.onOpenWork,
                        onRecordCta: widget.onOpenDetail,
                      );
                    },
                  ),
                  if (widget.onGoKnowledgeGraph != null &&
                      FeatureFlags.showKnowledgeGraph) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onGoKnowledgeGraph,
                        icon: const Icon(Icons.hub_outlined, size: 14),
                        label: const Text(
                          '연결 맵에서 보기',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
