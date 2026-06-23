import 'package:flutter/material.dart';

import '../../../config/feature_flags.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/registry_discovery_candidate_service.dart';
import '../../../services/works_registry.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/vault_work_presence.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/poster_image.dart';
import '../../../widgets/registry_discovery_candidates_section.dart';
import '../../../widgets/work_link_neighbors_sections.dart';
import '../../../widgets/work_preview_empty_connections.dart';
import '../../../widgets/work_preview_next_connections.dart';
import '../../../widgets/work_preview_registry_surface.dart';
import 'preview_panel_chrome.dart';
import 'preview_memo_bar.dart';

class DashboardPreviewPanel extends StatefulWidget {
  const DashboardPreviewPanel({
    super.key,
    required this.item,
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
    this.onConnectEntityType,
    this.onConnectSuggested,
    this.onPreviewRegistryWork,
    this.onArchiveRegistryWork,
  });

  final AkashaItem item;
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
  final void Function(EntityAnchorType type)? onConnectEntityType;
  final void Function(LinkCandidate candidate)? onConnectSuggested;
  final void Function(RegistryWork work)? onPreviewRegistryWork;
  final Future<void> Function()? onArchiveRegistryWork;

  @override
  State<DashboardPreviewPanel> createState() => _DashboardPreviewPanelState();
}

class _DashboardPreviewPanelState extends State<DashboardPreviewPanel> {
  late Future<WorkLinkNeighbors> _neighborsFuture;
  late Future<List<LinkCandidate>> _suggestedFuture;
  late Future<List<LinkCandidate>> _nextConnectionsFuture;
  late Future<List<RegistryDiscoveryCandidate>> _registryFuture;
  var _archiving = false;

  bool get _isRegistryOnly =>
      VaultWorkPresence.isRegistryOnlyPreview(widget.item, widget.vaultItems);

  @override
  void initState() {
    super.initState();
    _reloadFutures();
  }

  @override
  void didUpdateWidget(covariant DashboardPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.workId != widget.item.workId ||
        oldWidget.vaultItems != widget.vaultItems ||
        oldWidget.linkIndex != widget.linkIndex) {
      _reloadFutures();
    }
  }

  void _reloadFutures() {
    _neighborsFuture = _loadNeighbors();
    _suggestedFuture = _loadSuggested();
    _nextConnectionsFuture = _loadNextConnections();
    _registryFuture = _loadRegistryCandidates();
  }

  Future<WorkLinkNeighbors> _loadNeighbors() {
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    return fetchWorkLinkNeighbors(
      work: widget.item,
      userCatalog: widget.userCatalog,
      discovery: discovery,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
  }

  Future<List<LinkCandidate>> _loadSuggested() {
    return LinkCandidateService.candidatesForWork(
      work: widget.item,
      userCatalog: widget.userCatalog,
      limit: 3,
    );
  }

  Future<List<LinkCandidate>> _loadNextConnections() async {
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    final linkedIds = await discovery.entityIdsForWork(widget.item.workId);
    if (linkedIds.isEmpty) return const [];

    return LinkCandidateService.candidatesForWork(
      work: widget.item,
      userCatalog: widget.userCatalog,
      excludeEntityIds: linkedIds.toSet(),
      limit: 3,
    );
  }

  Future<List<RegistryDiscoveryCandidate>> _loadRegistryCandidates() async {
    if (_isRegistryOnly) {
      final registryWork = WorksRegistry.getWorkById(widget.item.workId);
      if (registryWork == null) return const [];
      return RegistryDiscoveryCandidateService.candidatesForRegistryWork(
        work: registryWork,
        vaultItems: widget.vaultItems,
        limit: 4,
      );
    }
    return RegistryDiscoveryCandidateService.candidatesForVaultWork(
      work: widget.item,
      vaultItems: widget.vaultItems,
      userCatalog: widget.userCatalog,
      linkIndex: widget.linkIndex,
      limit: 4,
    );
  }

  String? _registryBridgeHint(List<RegistryDiscoveryCandidate> candidates) {
    if (candidates.isEmpty) return null;
    final creator = widget.item.creator.trim();
    if (creator.isNotEmpty &&
        candidates.any((c) => c.reason == RegistryDiscoveryReason.creator)) {
      return '$creator 작품';
    }
    final bridge = candidates.first.bridgeLabel;
    return bridge != null && bridge.isNotEmpty ? '$bridge 관련' : null;
  }

  Future<void> _handleArchive() async {
    if (widget.onArchiveRegistryWork == null || _archiving) return;
    setState(() => _archiving = true);
    try {
      await widget.onArchiveRegistryWork!();
    } finally {
      if (mounted) setState(() => _archiving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _isRegistryOnly ? '사전 · ${widget.item.category.name}' : widget.item.category.name;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: PreviewPanelChrome(
              typeLabel: typeLabel,
              title: widget.item.title,
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
                    width: 140,
                    height: 200,
                    child: PosterImage(
                      item: widget.item,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                [
                  if (widget.item.creator.isNotEmpty) widget.item.creator,
                  widget.item.releaseYear?.toString() ?? '연도 미상',
                ].join(' · '),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              if (widget.item.rating > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '평점 ${widget.item.rating} / 10',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              _PreviewMetaTable(item: widget.item),
              if (_isRegistryOnly)
                WorkPreviewRegistrySurface(
                  archiving: _archiving,
                  onArchive: widget.onArchiveRegistryWork == null
                      ? null
                      : _handleArchive,
                ),
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
              FutureBuilder<WorkLinkNeighbors>(
                future: _neighborsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const WorkLinkNeighborsSections(
                      neighbors: WorkLinkNeighbors(),
                      loading: true,
                    );
                  }
                  final neighbors =
                      snapshot.data ?? const WorkLinkNeighbors();
                  if (!neighbors.hasAnyLink &&
                      widget.item.tags.isEmpty) {
                    return FutureBuilder<List<LinkCandidate>>(
                      future: _suggestedFuture,
                      builder: (context, suggestedSnap) {
                        return WorkPreviewEmptyConnections(
                          suggestedLinks: suggestedSnap.data ?? const [],
                          onSelectSuggested: widget.onConnectSuggested,
                          onConnectPerson: widget.onConnectEntityType == null
                              ? null
                              : () => widget.onConnectEntityType!(
                                    EntityAnchorType.person,
                                  ),
                          onConnectEvent: widget.onConnectEntityType == null
                              ? null
                              : () => widget.onConnectEntityType!(
                                    EntityAnchorType.event,
                                  ),
                          onConnectConcept: widget.onConnectEntityType == null
                              ? null
                              : () => widget.onConnectEntityType!(
                                    EntityAnchorType.concept,
                                  ),
                          onConnectPlace: widget.onConnectEntityType == null
                              ? null
                              : () => widget.onConnectEntityType!(
                                    EntityAnchorType.place,
                                  ),
                          onConnectOrganization:
                              widget.onConnectEntityType == null
                                  ? null
                                  : () => widget.onConnectEntityType!(
                                        EntityAnchorType.organization,
                                      ),
                          onOpenRecord: widget.onOpenDetail,
                        );
                      },
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkLinkNeighborsSections(
                        neighbors: neighbors,
                        conceptTags: widget.item.tags,
                        sourceWork: widget.item,
                        onOpenEntity: widget.onOpenEntity,
                        onOpenWork: widget.onOpenWork,
                        onLinkCta: widget.onOpenDetail,
                        onOpenConcept: widget.onOpenEntity,
                      ),
                      if (neighbors.hasAnyLink)
                        FutureBuilder<List<LinkCandidate>>(
                          future: _nextConnectionsFuture,
                          builder: (context, nextSnap) {
                            return WorkPreviewNextConnections(
                              candidates: nextSnap.data ?? const [],
                              onSelectSuggested: widget.onConnectSuggested,
                            );
                          },
                        ),
                    ],
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
                    bridgeHint: _registryBridgeHint(registrySnap.data ?? const []),
                    onPreviewRegistryWork: widget.onPreviewRegistryWork,
                  );
                },
              ),
              if (widget.onGoKnowledgeGraph != null &&
                  FeatureFlags.showKnowledgeGraph) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onGoKnowledgeGraph,
                    icon: const Icon(Icons.hub_outlined, size: 14),
                    label: const Text(
                      '연결 맵에서 보기',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
            ),
          ),
          PreviewMemoBar(onOpenDetail: widget.onOpenDetail),
        ],
      ),
    );
  }
}

class _PreviewMetaTable extends StatelessWidget {
  const _PreviewMetaTable({required this.item});

  final AkashaItem item;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('장르', item.category.label),
      if (item.creator.isNotEmpty) ('원작', item.creator),
      if (item.tags.isNotEmpty) ('태그', item.tags.take(3).join(', ')),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        row.$1,
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: TextStyle(fontSize: 10, color: Colors.grey[300]),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
