import 'package:flutter/material.dart';

import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../theme/akasha_colors.dart';
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
  bool _loadingCanvases = false;
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
    if (widget.vaultPath.isEmpty) return;
    setState(() => _loadingCanvases = true);
    try {
      final list = await CanvasStore.instance.listCanvases(widget.vaultPath);
      if (!mounted) return;
      setState(() {
        _canvases = list;
        _loadingCanvases = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCanvases = false);
      }
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
            padding: AkashaSpacing.graphPageHeader,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.knowledgeGraphTitle ?? '연결 목록',
                  style: AkashaTypography.graphTitle,
                ),
                SizedBox(height: AkashaSpacing.xs + 2),
                Text(
                  l10n?.knowledgeGraphSubtitle ??
                      '작품별로 묶인 연결을 목록으로 봅니다. (노드 그래프가 아닙니다)',
                  style: AkashaTypography.body,
                ),
                const SizedBox(height: AkashaSpacing.md),
                Row(
                  children: [
                    _buildTabButton(0, '나의 지식 지도 (Canvas)', palette),
                    const SizedBox(width: AkashaSpacing.sm),
                    _buildTabButton(1, '작품별 자동 연결', palette),
                  ],
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
            else if (works.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n?.knowledgeGraphEmptyVault ?? '볼트에 작품이 없습니다.',
                        style: AkashaTypography.body,
                      ),
                      if (widget.onConnectEntity != null) ...[
                        SizedBox(height: AkashaSpacing.md),
                        OutlinedButton(
                          onPressed: widget.onConnectEntity,
                          child: Text(
                            l10n?.knowledgeGraphConnectEntity ?? '엔티티 연결하기',
                            style: AkashaTypography.compactLabel,
                          ),
                        ),
                      ],
                    ],
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
                            count > 0 ? '연결 $count개' : '연결 없음 · 기록에서 링크 추가',
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
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
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
            color: selected ? palette.accent : palette.borderSubtle(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasTab(AkashaPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AkashaSpacing.lg,
            vertical: AkashaSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '지식 지도 목록 (${_canvases.length})',
                style: AkashaTypography.compactLabel.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateCanvasDialog,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('새 지식 지도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AkashaSpacing.md,
                    vertical: AkashaSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AkashaRadius.sm),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_loadingCanvases)
          const Expanded(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_canvases.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '생성된 지식 지도가 없습니다.\n새 지식 지도를 만들고 나만의 생각 관계망을 정의해 보세요!',
                    textAlign: TextAlign.center,
                    style: AkashaTypography.body,
                  ),
                  const SizedBox(height: AkashaSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _showCreateCanvasDialog,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('첫 지식 지도 만들기'),
                  ),
                ],
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
              itemCount: _canvases.length,
              itemBuilder: (context, index) {
                final canvas = _canvases[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AkashaSpacing.sm),
                  decoration: palette.surfaceCard(radius: AkashaRadius.lg),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AkashaSpacing.md,
                      vertical: AkashaSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: palette.accentSoft,
                      child: Icon(Icons.map_outlined, color: palette.accent, size: 20),
                    ),
                    title: Text(
                      canvas.title,
                      style: AkashaTypography.listItemTitle,
                    ),
                    subtitle: Text(
                      '수정일: ${canvas.updatedAt.toLocal().toString().split('.')[0]}',
                      style: AkashaTypography.bodySecondary,
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _enterCanvas(canvas),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showCreateCanvasDialog() async {
    final titleController = TextEditingController();
    final slugController = TextEditingController();
    final palette = context.akashaPalette;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.surfaceElevated,
          title: const Text('새 지식 지도 만들기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '지도 제목 (예: 리제로 인물 관계도)',
                ),
              ),
              const SizedBox(height: AkashaSpacing.sm),
              TextField(
                controller: slugController,
                decoration: const InputDecoration(
                  labelText: 'URL 슬러그 (예: re-zero)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
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
              child: const Text('생성'),
            ),
          ],
        );
      },
    );
  }

  void _enterCanvas(CanvasRecord record) {
    widget.onOpenCanvas(record);
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
              l10n?.knowledgeGraphEmptyTitle ?? '아직 연결된 지식이 없습니다.',
              style: AkashaTypography.compactLabel.copyWith(
                fontWeight: FontWeight.bold,
                color: AkashaColors.textSecondary,
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
}
