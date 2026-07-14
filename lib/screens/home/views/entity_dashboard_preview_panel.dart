import 'package:flutter/material.dart';

import '../../../config/feature_flags.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/registry_work.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../services/registry_discovery_candidate_service.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';
import '../../../utils/entity_link_neighbors.dart';
import '../../../widgets/entity_link_neighbors_sections.dart';
import '../../../widgets/entity_preview_empty_connections.dart';
import '../../../widgets/registry_discovery_candidates_section.dart';
import '../shell_layout_spec.dart';
import 'preview_panel_chrome.dart';
import 'preview_panel_layout.dart';
import 'preview_record_view_model.dart';
import 'preview_work_panel_content.dart';

class EntityDashboardPreviewPanel extends StatefulWidget {
  const EntityDashboardPreviewPanel({
    super.key,
    required this.entity,
    this.width = 288,
    this.previewPresentation = ShellPreviewPresentation.inline,
    required this.userCatalog,
    required this.linkIndex,
    this.linkIndexRevision = 0,
    required this.vaultItems,
    this.canGoBack = false,
    this.onBack,
    required this.onClose,
    required this.onOpenDetail,
    this.onOpenEntity,
    this.onOpenWork,
    this.onGoKnowledgeGraph,
    this.onPreviewRegistryWork,
    this.onConnectEntityType,
    this.onConnectWork,
  });

  final UserCatalogEntity entity;
  final double width;
  final ShellPreviewPresentation previewPresentation;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final int linkIndexRevision;
  final List<AkashaItem> vaultItems;
  final bool canGoBack;
  final VoidCallback? onBack;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final void Function(AkashaItem work)? onOpenWork;
  final VoidCallback? onGoKnowledgeGraph;
  final void Function(RegistryWork work)? onPreviewRegistryWork;
  final void Function(EntityAnchorType type)? onConnectEntityType;
  final VoidCallback? onConnectWork;

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
    if (oldWidget.entity.entityId != widget.entity.entityId ||
        oldWidget.linkIndexRevision != widget.linkIndexRevision ||
        oldWidget.vaultItems.length != widget.vaultItems.length) {
      setState(() {
        _neighborsFuture = _loadNeighbors();
        _registryFuture = _loadRegistryCandidates();
      });
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

  Widget _buildConnectionsSection() {
    return FutureBuilder<EntityLinkNeighbors>(
      future: _neighborsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const EntityLinkNeighborsSections(
            neighbors: EntityLinkNeighbors(),
            entityTags: [],
            loading: true,
          );
        }
        final neighbors = snapshot.data ?? const EntityLinkNeighbors();
        if (!neighbors.hasAnyLink) {
          return EntityPreviewEmptyConnections(
            onConnectWork: widget.onConnectWork,
            onConnectPerson: widget.onConnectEntityType == null
                ? null
                : () => widget.onConnectEntityType!(EntityAnchorType.person),
            onConnectEvent: widget.onConnectEntityType == null
                ? null
                : () => widget.onConnectEntityType!(EntityAnchorType.event),
            onConnectConcept: widget.onConnectEntityType == null
                ? null
                : () => widget.onConnectEntityType!(EntityAnchorType.concept),
            onConnectPlace: widget.onConnectEntityType == null
                ? null
                : () => widget.onConnectEntityType!(EntityAnchorType.place),
            onConnectOrganization: widget.onConnectEntityType == null
                ? null
                : () => widget.onConnectEntityType!(
                    EntityAnchorType.organization,
                  ),
          );
        }
        return EntityLinkNeighborsSections(
          neighbors: neighbors,
          entityTags: widget.entity.tags,
          showEmptySections: false,
          onOpenEntity: widget.onOpenEntity,
          onOpenWork: widget.onOpenWork,
          onAddEntity: widget.onConnectEntityType,
          onAddWork: widget.onConnectWork,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final record = PreviewRecordViewModel.fromEntity(widget.entity, l10n);
    return PreviewPanelSurface(
      width: widget.width,
      presentation: widget.previewPresentation,
      child: Column(
        children: [
          Expanded(
            child: PreviewPanelChrome(
              typeLabel: record.typeLabel,
              compactHeader: true,
              canGoBack: widget.canGoBack,
              onBack: widget.onBack,
              onClose: widget.onClose,
              body: PreviewPanelScrollBody(
                presentation: widget.previewPresentation,
                children: [
                  PreviewRecordHero(
                    model: record,
                    compact: true,
                    compactMaxHeight: PreviewPanelLayoutSpec.heroMaxHeight(
                      widget.previewPresentation,
                    ),
                  ),
                  const SizedBox(height: PreviewPanelLayoutSpec.compactGap),
                  PreviewRecordTitleBlock(model: record),
                  const SizedBox(height: 10),
                  PreviewRecordActionBar(onPressed: widget.onOpenDetail),
                  const SizedBox(height: PreviewPanelLayoutSpec.sectionGap),
                  PreviewRecordCoreInfoSection(rows: record.coreInfoRows),
                  const SizedBox(height: PreviewPanelLayoutSpec.sectionGap),
                  _buildConnectionsSection(),
                  FutureBuilder<List<RegistryDiscoveryCandidate>>(
                    future: _registryFuture,
                    builder: (context, registrySnap) {
                      final bridgeHint = widget.entity.title.isNotEmpty
                          ? (l10n?.relatedRegistryWorks(widget.entity.title) ??
                                '${widget.entity.title} 관련 사전 작품')
                          : null;
                      return RegistryDiscoveryCandidatesSection(
                        candidates: registrySnap.data ?? const [],
                        loading:
                            registrySnap.connectionState ==
                            ConnectionState.waiting,
                        bridgeHint: bridgeHint,
                        onPreviewRegistryWork: widget.onPreviewRegistryWork,
                      );
                    },
                  ),
                  if (widget.onGoKnowledgeGraph != null &&
                      FeatureFlags.showKnowledgeGraph) ...[
                    const SizedBox(height: PreviewPanelLayoutSpec.compactGap),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onGoKnowledgeGraph,
                        icon: const Icon(Icons.hub_outlined, size: 14),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n?.previewViewInGraph ?? '그래프에서 보기',
                              style: AkashaTypography.compactLabel,
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 16),
                          ],
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
