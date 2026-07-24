import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/poster_image.dart';
import '../../../widgets/work_link_neighbors_sections.dart';
import '../../../core/archiving/canvas_record.dart';
import '../../../services/canvas_store.dart';
import 'destination_empty_state.dart';

/// 볼트 작품별 위키 링크 연결을 탐색하는 연결 목록 뷰 (v1.1 리스트형).
class KnowledgeGraphView extends StatefulWidget {
  const KnowledgeGraphView({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.linkIndex,
    required this.onOpenWork,
    required this.onOpenEntity,
    this.onOpenRecord,
    this.onConnectEntity,
    required this.vaultPath,
    required this.onOpenCanvas,
    this.canvasDiscoverer,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem work) onOpenWork;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final VoidCallback? onOpenRecord;
  final VoidCallback? onConnectEntity;
  final String vaultPath;
  final void Function(CanvasRecord canvas) onOpenCanvas;

  /// Optional override for tests / injectable discovery.
  final Future<CanvasDiscoveryResult> Function(String vaultPath)?
  canvasDiscoverer;

  @override
  State<KnowledgeGraphView> createState() => _KnowledgeGraphViewState();
}

class _KnowledgeGraphViewState extends State<KnowledgeGraphView> {
  final Map<String, int> _linkCounts = {};
  final Map<String, WorkLinkNeighbors> _expandedNeighbors = {};
  final Set<String> _loadingWorkIds = {};
  var _loadingCounts = true;
  var _loadGeneration = 0;

  List<CanvasRecord> _canvases = [];
  List<IncompleteCanvasRecord> _incompleteCanvases = [];
  bool _loadingCanvases = false;
  Object? _canvasDiscoveryError;
  int _canvasLoadGeneration = 0;
  int _activeTabIndex = 0; // 0 = Canvas, 1 = Connections List

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadCanvases();
  }

  @override
  void didUpdateWidget(covariant KnowledgeGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vaultItems != widget.vaultItems ||
        oldWidget.linkIndex != widget.linkIndex) {
      setState(() {
        _loadingCounts = true;
        _expandedNeighbors.clear();
        _loadingWorkIds.clear();
      });
      _loadCounts();
    }
    if (oldWidget.vaultPath != widget.vaultPath) {
      _loadCanvases();
    }
  }

  Future<void> _loadCanvases() async {
    final generation = ++_canvasLoadGeneration;
    if (widget.vaultPath.isEmpty) {
      if (!mounted) return;
      setState(() {
        _canvases = const [];
        _incompleteCanvases = const [];
        _canvasDiscoveryError = null;
        _loadingCanvases = false;
      });
      return;
    }
    setState(() {
      _loadingCanvases = true;
      _canvasDiscoveryError = null;
    });
    try {
      final discoverer =
          widget.canvasDiscoverer ?? CanvasStore.instance.discoverCanvases;
      final discovery = await discoverer(widget.vaultPath);
      if (!mounted || generation != _canvasLoadGeneration) return;
      setState(() {
        _canvases = discovery.complete;
        _incompleteCanvases = discovery.incomplete;
        _canvasDiscoveryError = null;
        _loadingCanvases = false;
      });
    } catch (error, stackTrace) {
      assert(() {
        // ignore: avoid_print
        print('KnowledgeGraphView._loadCanvases failed: $error\n$stackTrace');
        return true;
      }());
      if (!mounted || generation != _canvasLoadGeneration) return;
      setState(() {
        _canvases = const [];
        _incompleteCanvases = const [];
        _canvasDiscoveryError = error;
        _loadingCanvases = false;
      });
    }
  }

  Future<void> _loadCounts() async {
    final generation = ++_loadGeneration;
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    final counts = <String, int>{};
    for (final item in widget.vaultItems) {
      if (item.workId.isEmpty) continue;
      final linked = await discovery.entityIdsForWork(item.workId);
      counts[item.workId] = linked.length;
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _linkCounts
        ..clear()
        ..addAll(counts);
      _loadingCounts = false;
    });
  }

  Future<void> _loadNeighbors(AkashaItem work) async {
    if (_expandedNeighbors.containsKey(work.workId) ||
        _loadingWorkIds.contains(work.workId)) {
      return;
    }
    final generation = _loadGeneration;
    setState(() => _loadingWorkIds.add(work.workId));
    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    final neighbors = await fetchWorkLinkNeighbors(
      work: work,
      userCatalog: widget.userCatalog,
      discovery: discovery,
      linkIndex: widget.linkIndex,
      vaultItems: widget.vaultItems,
    );
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _loadingWorkIds.remove(work.workId);
      _expandedNeighbors[work.workId] = neighbors;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;
    final works = List<AkashaItem>.from(widget.vaultItems)
      ..sort((a, b) {
        final ca = _linkCounts[a.workId] ?? 0;
        final cb = _linkCounts[b.workId] ?? 0;
        if (ca != cb) return cb.compareTo(ca);
        return a.title.compareTo(b.title);
      });

    final allLinksEmpty =
        !_loadingCounts &&
        works.isNotEmpty &&
        works.every((w) => (_linkCounts[w.workId] ?? 0) == 0);

    return Container(
      color: palette.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AkashaSpacing.lg,
              AkashaSpacing.md,
              AkashaSpacing.lg,
              AkashaSpacing.sm,
            ),
            child: Wrap(
              spacing: AkashaSpacing.sm,
              runSpacing: AkashaSpacing.sm,
              children: [
                _buildTabButton(
                  0,
                  l10n?.graphTabMyKnowledgeMap ?? '지식 지도',
                  palette,
                ),
                _buildTabButton(
                  1,
                  l10n?.graphTabAutoConnections ?? '연결 목록',
                  palette,
                ),
              ],
            ),
          ),
          if (_activeTabIndex == 0)
            Expanded(child: _buildCanvasTab(palette))
          else ...[
            if (allLinksEmpty) _buildEmptyLinksBanner(),
            if (_loadingCounts)
              const Expanded(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (widget.vaultPath.isEmpty)
              Expanded(child: _buildVaultRequiredState())
            else if (works.isEmpty)
              Expanded(
                child: DestinationEmptyState(
                  stateId: 'graph-connections-empty-vault',
                  icon: Icons.hub_outlined,
                  title: l10n?.knowledgeGraphEmptyVault ?? '아카이브된 작품이 없습니다.',
                  body:
                      l10n?.knowledgeGraphEmptyVaultBody ??
                      '작품을 아카이브하면 기록에서 파생된 연결을 여기서 탐색할 수 있습니다.',
                  action: widget.onConnectEntity == null
                      ? null
                      : OutlinedButton.icon(
                          onPressed: widget.onConnectEntity,
                          icon: const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 16,
                          ),
                          label: Text(
                            l10n?.knowledgeGraphConnectEntity ?? '엔티티 연결하기',
                          ),
                        ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AkashaSpacing.lg,
                    AkashaSpacing.sm,
                    AkashaSpacing.lg,
                    AkashaSpacing.xl,
                  ),
                  itemCount: works.length,
                  itemBuilder: (context, index) {
                    final work = works[index];
                    final count = _linkCounts[work.workId] ?? 0;
                    final expanded = _expandedNeighbors[work.workId];
                    final loading = _loadingWorkIds.contains(work.workId);

                    return Container(
                      margin: EdgeInsets.only(bottom: AkashaSpacing.sm),
                      decoration: palette.surfaceCard(radius: AkashaRadius.lg),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: AkashaSpacing.md,
                            vertical: AkashaSpacing.xs,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            AkashaSpacing.md,
                            0,
                            AkashaSpacing.md,
                            AkashaSpacing.md,
                          ),
                          onExpansionChanged: (open) {
                            if (open) _loadNeighbors(work);
                          },
                          leading: ClipRRect(
                            borderRadius: AkashaRadius.smBorder,
                            child: SizedBox(
                              width: 36,
                              height: 52,
                              child: PosterImage(item: work, fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(
                            work.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AkashaTypography.listItemTitle,
                          ),
                          subtitle: Text(
                            count > 0
                                ? (l10n != null
                                      ? l10n.graphConnectionsCountDesc(count)
                                      : '연결 $count개')
                                : (l10n?.graphNoConnectionsDesc ??
                                      '연결 없음 · 기록에서 링크 추가'),
                            style: AkashaTypography.bodySecondary.copyWith(
                              color: count > 0 ? palette.accent : null,
                            ),
                          ),
                          trailing: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more, size: 20),
                          children: [
                            if (expanded != null)
                              WorkLinkNeighborsSections(
                                neighbors: expanded,
                                onOpenEntity: widget.onOpenEntity,
                                onOpenWork: widget.onOpenWork,
                              )
                            else
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AkashaSpacing.sm,
                                ),
                                child: Text(
                                  l10n?.knowledgeGraphExpandToLoad ??
                                      '펼쳐서 연결을 불러오세요.',
                                  style: AkashaTypography.bodySecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, AkashaPalette palette) {
    final selected = _activeTabIndex == index;
    return Semantics(
      button: true,
      selected: selected,
      child: Tooltip(
        message: label,
        child: InkWell(
          key: ValueKey<String>('graph-tab-$index'),
          onTap: () => setState(() => _activeTabIndex = index),
          borderRadius: AkashaRadius.smBorder,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? palette.accentSoft : Colors.transparent,
              borderRadius: AkashaRadius.smBorder,
              border: Border.all(
                color: selected
                    ? palette.accent.withValues(alpha: 0.4)
                    : palette.borderSubtle(0.18),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? palette.accent : palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasTab(AkashaPalette palette) {
    final l10n = lookupAppL10n(context);
    if (widget.vaultPath.isEmpty) {
      return _buildVaultRequiredState();
    }

    if (_loadingCanvases) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_canvasDiscoveryError != null) {
      final diagnosis = _sanitizeDiscoveryDiagnosis(_canvasDiscoveryError!);
      final baseBody =
          l10n?.graphCanvasDiscoveryFailedBody ??
          '볼트의 지식 지도 폴더를 읽는 중 문제가 발생했습니다. 다시 시도해 주세요.';
      return DestinationEmptyState(
        stateId: 'graph-canvas-discovery-error',
        icon: Icons.error_outline,
        title: l10n?.graphCanvasDiscoveryFailedTitle ?? '지식 지도 목록을 읽지 못했습니다',
        body: '$baseBody\n$diagnosis',
        action: OutlinedButton.icon(
          key: const ValueKey<String>('graph-canvas-discovery-retry'),
          onPressed: _loadCanvases,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(l10n?.graphCanvasDiscoveryRetry ?? '재시도'),
        ),
      );
    }

    // State 1: complete 0, incomplete 0 -> standard empty state
    if (_canvases.isEmpty && _incompleteCanvases.isEmpty) {
      return DestinationEmptyState(
        stateId: 'graph-canvas-empty',
        icon: Icons.map_outlined,
        title: l10n?.graphEmptyCanvases ?? '아직 지식 지도가 없습니다.',
        body:
            l10n?.graphEmptyCanvasBody ??
            '캔버스에 작품과 엔티티를 직접 배치해 나만의 관계를 정리해 보세요.',
        action: OutlinedButton.icon(
          onPressed: _showCreateCanvasDialog,
          icon: const Icon(Icons.add, size: 16),
          label: Text(l10n?.graphBtnCreateFirstCanvas ?? '새 지식 지도 만들기'),
        ),
      );
    }

    // State 2: complete 0, incomplete >= 1 -> Full incomplete discovery alert
    if (_canvases.isEmpty && _incompleteCanvases.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AkashaSpacing.lg,
          vertical: AkashaSpacing.md,
        ),
        children: [
          _buildIncompleteCanvasHeader(palette, l10n),
          const SizedBox(height: AkashaSpacing.md),
          ..._incompleteCanvases.map(
            (record) => _buildIncompleteCanvasCard(record, palette, l10n),
          ),
          const SizedBox(height: AkashaSpacing.lg),
          Center(
            child: OutlinedButton.icon(
              onPressed: _showCreateCanvasDialog,
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n?.graphBtnCreateFirstCanvas ?? '새 지식 지도 만들기'),
            ),
          ),
        ],
      );
    }

    // State 3: complete >= 1, incomplete >= 1 -> Normal list with non-blocking top warning banner
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_incompleteCanvases.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AkashaSpacing.lg,
              vertical: AkashaSpacing.xs,
            ),
            child: _buildIncompleteCanvasBanner(palette, l10n),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AkashaSpacing.lg,
            vertical: AkashaSpacing.xs,
          ),
          child: Text(
            l10n != null
                ? l10n.graphCanvasesListHeader(_canvases.length)
                : '지식 지도 목록 (${_canvases.length})',
            style: AkashaTypography.compactLabel.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AkashaSpacing.lg,
              AkashaSpacing.xs,
              AkashaSpacing.lg,
              AkashaSpacing.xl,
            ),
            itemCount: _canvases.length,
            itemBuilder: (context, index) {
              final canvas = _canvases[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AkashaSpacing.sm),
                decoration: palette.surfaceCard(radius: AkashaRadius.md),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: AkashaRadius.mdBorder,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AkashaSpacing.md,
                      vertical: AkashaSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: palette.accentSoft,
                      child: Icon(Icons.map_outlined, color: palette.accent),
                    ),
                    title: Text(
                      canvas.title,
                      style: AkashaTypography.listItemTitle,
                    ),
                    subtitle: Text(
                      'ID: ${canvas.canvasId}',
                      style: AkashaTypography.bodySecondary,
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => widget.onOpenCanvas(canvas),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncompleteCanvasHeader(
    AkashaPalette palette,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(AkashaSpacing.md),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.1),
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: palette.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.danger, size: 24),
          const SizedBox(width: AkashaSpacing.md),
          Expanded(
            child: Text(
              l10n?.incompleteKnowledgeMapsFound ?? '불완전한 지식 지도를 발견했습니다',
              style: AkashaTypography.compactLabel.copyWith(
                color: palette.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncompleteCanvasBanner(
    AkashaPalette palette,
    AppLocalizations? l10n,
  ) {
    final text =
        l10n?.incompleteKnowledgeMapsCount(_incompleteCanvases.length) ??
        '불완전한 지식 지도 ${_incompleteCanvases.length}개가 감지되었습니다.';
    return Container(
      margin: const EdgeInsets.only(bottom: AkashaSpacing.xs),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.1),
        borderRadius: AkashaRadius.smBorder,
        border: Border.all(color: palette.warning.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AkashaRadius.smBorder,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AkashaSpacing.md,
            vertical: 0,
          ),
          leading: Icon(
            Icons.warning_amber_rounded,
            color: palette.warning,
            size: 20,
          ),
          title: Text(
            text,
            style: AkashaTypography.bodySecondary.copyWith(
              color: palette.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: _incompleteCanvases
              .map(
                (rec) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AkashaSpacing.md,
                    0,
                    AkashaSpacing.md,
                    AkashaSpacing.sm,
                  ),
                  child: _buildIncompleteCanvasCard(rec, palette, l10n),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildIncompleteCanvasCard(
    IncompleteCanvasRecord record,
    AkashaPalette palette,
    AppLocalizations? l10n,
  ) {
    final missingLabel = l10n?.missingFilesLabel ?? '누락 파일';
    final existingLabel = l10n?.existingFilesLabel ?? '존재 파일';
    final diagLabel = l10n?.diagnosticLabel ?? '진단';

    return Container(
      padding: const EdgeInsets.all(AkashaSpacing.md),
      decoration: palette.surfaceCard(radius: AkashaRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.broken_image_outlined,
                color: palette.warning,
                size: 18,
              ),
              const SizedBox(width: AkashaSpacing.xs),
              Text(
                'Canvas ID: ${record.inferredCanvasId}',
                style: AkashaTypography.compactLabel.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.status.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: palette.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AkashaSpacing.xs),
          Text(
            '$existingLabel: ${record.existingFiles.join(", ")}',
            style: AkashaTypography.bodySecondary,
          ),
          if (record.missingFiles.isNotEmpty)
            Text(
              '$missingLabel: ${record.missingFiles.join(", ")}',
              style: AkashaTypography.bodySecondary.copyWith(
                color: palette.danger,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '$diagLabel: ${record.diagnosticMessage}',
            style: AkashaTypography.caption.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateCanvasDialog() async {
    final titleController = TextEditingController();
    final slugController = TextEditingController();
    final palette = context.akashaPalette;
    final l10n = lookupAppL10n(context);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.surfaceElevated,
          title: Text(l10n?.graphDialogCreateCanvasTitle ?? '새 지식 지도 만들기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText:
                      l10n?.graphDialogCreateCanvasLabelTitle ??
                      '지도 제목 (예: 리제로 인물 관계도)',
                ),
              ),
              const SizedBox(height: AkashaSpacing.sm),
              TextField(
                controller: slugController,
                decoration: InputDecoration(
                  labelText:
                      l10n?.graphDialogCreateCanvasLabelSlug ??
                      'URL 슬러그 (예: re-zero)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.actionCancel ?? '취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final slug = slugController.text.trim();
                Navigator.pop(context);

                if (title.isNotEmpty) {
                  final data = await CanvasStore.instance.createCanvas(
                    vaultPath: widget.vaultPath,
                    title: title,
                    slug: slug,
                  );
                  await _loadCanvases();
                  _enterCanvas(data.record);
                }
              },
              child: Text(l10n?.graphDialogCreateCanvasBtnCreate ?? '생성'),
            ),
          ],
        );
      },
    );
  }

  void _enterCanvas(CanvasRecord record) {
    widget.onOpenCanvas(record);
  }

  Widget _buildVaultRequiredState() {
    final l10n = lookupAppL10n(context);
    return DestinationEmptyState(
      stateId: 'graph-vault-required',
      icon: Icons.folder_open_outlined,
      title: l10n?.graphVaultRequiredTitle ?? '볼트를 먼저 연결하세요.',
      body:
          l10n?.graphVaultRequiredBody ?? '지식 지도와 연결 목록은 로컬 볼트에 저장된 기록을 사용합니다.',
    );
  }

  Widget _buildEmptyLinksBanner() {
    final l10n = lookupAppL10n(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AkashaSpacing.lg + AkashaSpacing.sm,
        0,
        AkashaSpacing.lg + AkashaSpacing.sm,
        AkashaSpacing.md,
      ),
      child: Container(
        padding: EdgeInsets.all(AkashaSpacing.lg),
        decoration: context.akashaPalette.surfaceCard(radius: AkashaRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n?.knowledgeGraphEmptyTitle ?? '기록에서 파생된 연결이 없습니다.',
              style: AkashaTypography.compactLabel.copyWith(
                fontWeight: FontWeight.bold,
                color: context.akashaPalette.textSecondary,
              ),
            ),
            SizedBox(height: AkashaSpacing.xs),
            Text(
              l10n?.knowledgeGraphEmptyBody ??
                  '첫 연결을 만들어 보세요. 작품 기록에 링크를 추가하면 여기에 표시됩니다.',
              style: AkashaTypography.bodySecondary,
            ),
            SizedBox(height: AkashaSpacing.md),
            Wrap(
              spacing: AkashaSpacing.sm,
              runSpacing: AkashaSpacing.sm,
              children: [
                if (widget.onOpenRecord != null)
                  FilledButton.icon(
                    onPressed: widget.onOpenRecord,
                    icon: const Icon(Icons.edit_note_outlined, size: 14),
                    label: Text(
                      l10n?.knowledgeGraphOpenRecord ?? '기록 열기',
                      style: AkashaTypography.compactLabel,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.akashaPalette.accent,
                      padding: EdgeInsets.symmetric(
                        horizontal: AkashaSpacing.md,
                        vertical: AkashaSpacing.sm,
                      ),
                    ),
                  ),
                if (widget.onConnectEntity != null)
                  OutlinedButton.icon(
                    onPressed: widget.onConnectEntity,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 14),
                    label: Text(
                      l10n?.knowledgeGraphConnectEntity ?? '엔티티 연결하기',
                      style: AkashaTypography.compactLabel,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Short diagnosis without absolute paths or stack traces.
  static String _sanitizeDiscoveryDiagnosis(Object error) {
    final typeName = error.runtimeType.toString();
    var message = error.toString();
    message = message.replaceAll(RegExp(r'[A-Za-z]:\\[^\s"]+'), '<path>');
    message = message.replaceAll(RegExp(r'/[^\s"]{3,}'), '<path>');
    message = message.replaceAll(RegExp(r'\\[^\s"]+'), '<path>');
    if (message.length > 120) {
      message = '${message.substring(0, 117)}...';
    }
    return '($typeName) $message';
  }
}
