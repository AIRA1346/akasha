import 'package:flutter/material.dart';

import '../../../config/feature_flags.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/registry_work.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../screens/home/dialogs/add_catalog_entity_dialog.dart';
import '../../../theme/akasha_colors.dart';
import '../../../services/registry_discovery_candidate_service.dart';
import '../../../utils/entity_link_neighbors.dart';
import '../../../widgets/entity_link_neighbors_sections.dart';
import '../../../widgets/poster_image.dart';
import '../../../widgets/registry_discovery_candidates_section.dart';
import 'preview_panel_chrome.dart';

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
    this.onPreviewRegistryWork,
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
  final void Function(RegistryWork work)? onPreviewRegistryWork;

  @override
  State<EntityDashboardPreviewPanel> createState() =>
      _EntityDashboardPreviewPanelState();
}

class _EntityDashboardPreviewPanelState
    extends State<EntityDashboardPreviewPanel> {
  late Future<EntityLinkNeighbors> _neighborsFuture;
  late Future<List<RegistryDiscoveryCandidate>> _registryFuture;

  @override
  void initState() {
    super.initState();
    _neighborsFuture = _loadNeighbors();
    _registryFuture = _loadRegistryCandidates();
  }

  @override
  void didUpdateWidget(covariant EntityDashboardPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.entityId != widget.entity.entityId) {
      _neighborsFuture = _loadNeighbors();
      _registryFuture = _loadRegistryCandidates();
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

  Future<List<RegistryDiscoveryCandidate>> _loadRegistryCandidates() {
    return RegistryDiscoveryCandidateService.candidatesForEntity(
      entity: widget.entity,
      vaultItems: widget.vaultItems,
      linkIndex: widget.linkIndex,
      userCatalog: widget.userCatalog,
      limit: 4,
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
      child: PreviewPanelChrome(
        typeLabel: badge,
        title: widget.entity.title,
        canGoBack: widget.canGoBack,
        onBack: widget.onBack,
        onClose: widget.onClose,
        onOpenDetail: widget.onOpenDetail,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: PosterImage(item: avatarItem, fit: BoxFit.cover),
                  ),
                ),
              ),
              if (widget.entity.aliases.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.entity.aliases.join(' · '),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                '연결',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
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
              FutureBuilder<List<RegistryDiscoveryCandidate>>(
                future: _registryFuture,
                builder: (context, registrySnap) {
                  return RegistryDiscoveryCandidatesSection(
                    candidates: registrySnap.data ?? const [],
                    loading: registrySnap.connectionState ==
                        ConnectionState.waiting,
                    bridgeHint: widget.entity.title.isNotEmpty
                        ? '${widget.entity.title} 관련 사전 작품'
                        : null,
                    onPreviewRegistryWork: widget.onPreviewRegistryWork,
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
                    icon: const Icon(Icons.list_alt_outlined, size: 14),
                    label: const Text(
                      '연결 목록에서 보기',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
