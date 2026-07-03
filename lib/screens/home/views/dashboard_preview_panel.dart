import 'package:flutter/material.dart';

import '../../../config/feature_flags.dart';
import '../../../core/archiving/entity_anchor.dart';
import '../../../core/archiving/record_link.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../services/link_candidate_service.dart';
import '../../../services/registry_discovery_candidate_service.dart';
import '../../../services/works_registry.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';
import '../../../utils/vault_work_presence.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/registry_discovery_candidates_section.dart';
import '../../../widgets/work_link_neighbors_sections.dart';
import '../../../widgets/work_preview_empty_connections.dart';
import '../../../widgets/work_preview_next_connections.dart';
import '../../../widgets/work_preview_registry_surface.dart';
import 'preview_journal_reflection_card.dart';
import 'preview_memo_bar.dart';
import 'preview_panel_chrome.dart';
import 'preview_record_view_model.dart';
import 'preview_work_panel_content.dart';

class DashboardPreviewPanel extends StatefulWidget {
  const DashboardPreviewPanel({
    super.key,
    required this.item,
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
    this.onConnectEntityType,
    this.onConnectWorkFromPreview,
    this.onConnectSuggested,
    this.onPreviewRegistryWork,
    this.onArchiveRegistryWork,
  });

  final AkashaItem item;
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
  final void Function(EntityAnchorType type)? onConnectEntityType;
  final VoidCallback? onConnectWorkFromPreview;
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
        oldWidget.item.filePath != widget.item.filePath ||
        oldWidget.linkIndexRevision != widget.linkIndexRevision ||
        oldWidget.vaultItems.length != widget.vaultItems.length ||
        !_sameVaultWorkIds(oldWidget.vaultItems, widget.vaultItems)) {
      _reloadFutures();
    }
  }

  bool _sameVaultWorkIds(List<AkashaItem> a, List<AkashaItem> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].workId != b[i].workId) return false;
    }
    return true;
  }

  void _reloadFutures() {
    setState(() {
      _neighborsFuture = _loadNeighbors();
      _suggestedFuture = _loadSuggested();
      _nextConnectionsFuture = _loadNextConnections();
      _registryFuture = _loadRegistryCandidates();
    });
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
      characterLimit: workLinkNeighborsCharacterPanelLimit,
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

  String? _registryBridgeHint(
    List<RegistryDiscoveryCandidate> candidates,
    AppLocalizations? l10n,
  ) {
    if (candidates.isEmpty) return null;
    final creator = widget.item.creator.trim();
    if (creator.isNotEmpty &&
        candidates.any((c) => c.reason == RegistryDiscoveryReason.creator)) {
      return l10n?.creatorWorks(creator) ?? '$creator 작품';
    }
    final bridge = candidates.first.bridgeLabel;
    return bridge != null && bridge.isNotEmpty
        ? (l10n?.bridgeRelated(bridge) ?? '$bridge 관련')
        : null;
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

  void _handleWikiLinkTap(ParsedRecordLink link) {
    final id = link.unresolvedKey;
    final entity = widget.userCatalog.getById(id);
    if (entity != null) {
      if (widget.onOpenEntity != null) {
        widget.onOpenEntity!(entity);
      }
    } else {
      final matched = widget.vaultItems.where((x) => x.workId == id);
      if (matched.isNotEmpty && widget.onOpenWork != null) {
        widget.onOpenWork!(matched.first);
      }
    }
  }

  Widget _buildConnectionsSection() {
    return FutureBuilder<WorkLinkNeighbors>(
      future: _neighborsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WorkLinkNeighborsSections(
            neighbors: WorkLinkNeighbors(),
            loading: true,
          );
        }
        final neighbors = snapshot.data ?? const WorkLinkNeighbors();
        if (!neighbors.hasAnyLink) {
          return FutureBuilder<List<LinkCandidate>>(
            future: _suggestedFuture,
            builder: (context, suggestedSnap) {
              return WorkPreviewEmptyConnections(
                suggestedLinks: suggestedSnap.data ?? const [],
                onSelectSuggested: widget.onConnectSuggested,
                onConnectPerson: widget.onConnectEntityType == null
                    ? null
                    : () =>
                          widget.onConnectEntityType!(EntityAnchorType.person),
                onConnectEvent: widget.onConnectEntityType == null
                    ? null
                    : () => widget.onConnectEntityType!(EntityAnchorType.event),
                onConnectConcept: widget.onConnectEntityType == null
                    ? null
                    : () =>
                          widget.onConnectEntityType!(EntityAnchorType.concept),
                onConnectPlace: widget.onConnectEntityType == null
                    ? null
                    : () => widget.onConnectEntityType!(EntityAnchorType.place),
                onConnectOrganization: widget.onConnectEntityType == null
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
              showEmptySections: false,
              onOpenEntity: widget.onOpenEntity,
              onOpenWork: widget.onOpenWork,
              onOpenConcept: widget.onOpenEntity,
              onAddEntity: widget.onConnectEntityType,
              onAddWork: widget.onConnectWorkFromPreview,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final typeLabel = _isRegistryOnly
        ? (l10n?.catalogPrefix(widget.item.category.name) ??
              '사전 · ${widget.item.category.name}')
        : widget.item.category.name;
    final record = PreviewRecordViewModel.fromWork(widget.item, l10n);
    final palette = context.akashaPalette;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: palette.previewRail,
        border: Border(left: BorderSide(color: palette.borderSubtle(0.52))),
      ),
      child: Column(
        children: [
          Expanded(
            child: PreviewPanelChrome(
              typeLabel: typeLabel,
              compactHeader: true,
              canGoBack: widget.canGoBack,
              onBack: widget.onBack,
              onClose: widget.onClose,
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PreviewRecordHero(model: record),
                    const SizedBox(height: 14),
                    PreviewRecordTitleBlock(model: record),
                    const SizedBox(height: 12),
                    PreviewRecordActionBar(
                      onOpenDetail: widget.onOpenDetail,
                      canGoBack: widget.canGoBack,
                      onBack: widget.onBack,
                    ),
                    const SizedBox(height: 18),
                    PreviewRecordCoreInfoSection(rows: record.coreInfoRows),
                    if (!_isRegistryOnly) ...[
                      const SizedBox(height: 18),
                      PreviewJournalReflectionCard(
                        item: widget.item,
                        isVaultArchived: true,
                        onOpenDetail: widget.onOpenDetail,
                        userCatalog: widget.userCatalog,
                        onWikiLinkTap: _handleWikiLinkTap,
                      ),
                    ],
                    if (_isRegistryOnly) ...[
                      const SizedBox(height: 14),
                      WorkPreviewRegistrySurface(
                        archiving: _archiving,
                        onArchive: widget.onArchiveRegistryWork == null
                            ? null
                            : _handleArchive,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildConnectionsSection(),
                    FutureBuilder<List<RegistryDiscoveryCandidate>>(
                      future: _registryFuture,
                      builder: (context, registrySnap) {
                        return RegistryDiscoveryCandidatesSection(
                          candidates: registrySnap.data ?? const [],
                          loading:
                              registrySnap.connectionState ==
                              ConnectionState.waiting,
                          bridgeHint: _registryBridgeHint(
                            registrySnap.data ?? const [],
                            l10n,
                          ),
                          onPreviewRegistryWork: widget.onPreviewRegistryWork,
                        );
                      },
                    ),
                    if (widget.onGoKnowledgeGraph != null &&
                        FeatureFlags.showKnowledgeGraph) ...[
                      const SizedBox(height: 14),
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
          ),
          if (FeatureFlags.showPreviewMemoBar)
            PreviewMemoBar(onOpenDetail: widget.onOpenDetail),
        ],
      ),
    );
  }
}
