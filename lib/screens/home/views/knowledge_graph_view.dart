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
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/poster_image.dart';
import '../../../widgets/work_link_neighbors_sections.dart';

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
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final void Function(AkashaItem work) onOpenWork;
  final void Function(UserCatalogEntity entity) onOpenEntity;
  final VoidCallback? onOpenRecord;
  final VoidCallback? onConnectEntity;

  @override
  State<KnowledgeGraphView> createState() => _KnowledgeGraphViewState();
}

class _KnowledgeGraphViewState extends State<KnowledgeGraphView> {
  final Map<String, int> _linkCounts = {};
  final Map<String, WorkLinkNeighbors> _expandedNeighbors = {};
  final Set<String> _loadingWorkIds = {};
  var _loadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void didUpdateWidget(covariant KnowledgeGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vaultItems != widget.vaultItems ||
        oldWidget.linkIndex != widget.linkIndex) {
      setState(() {
        _loadingCounts = true;
        _expandedNeighbors.clear();
      });
      _loadCounts();
    }
  }

  Future<void> _loadCounts() async {
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
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _loadingWorkIds.remove(work.workId);
      _expandedNeighbors[work.workId] = neighbors;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                Text('연결 목록', style: AkashaTypography.graphTitle),
                SizedBox(height: AkashaSpacing.xs + 2),
                Text(
                  '작품별로 묶인 연결을 목록으로 봅니다. (노드 그래프가 아닙니다)',
                  style: AkashaTypography.body,
                ),
              ],
            ),
          ),
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
                    Text('볼트에 작품이 없습니다.', style: AkashaTypography.body),
                    if (widget.onConnectEntity != null) ...[
                      SizedBox(height: AkashaSpacing.md),
                      OutlinedButton(
                        onPressed: widget.onConnectEntity,
                        child: Text(
                          '엔티티 연결하기',
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
                            color: count > 0
                                ? palette.accent
                                : AkashaColors.textCaption,
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () => widget.onOpenWork(work),
                          child: Text(
                            '열기',
                            style: AkashaTypography.compactLabel,
                          ),
                        ),
                        children: [
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          else if (expanded != null)
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
      ),
    );
  }

  Widget _buildEmptyLinksBanner() {
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
              '아직 연결된 지식이 없습니다.',
              style: AkashaTypography.compactLabel.copyWith(
                fontWeight: FontWeight.bold,
                color: AkashaColors.textSecondary,
              ),
            ),
            SizedBox(height: AkashaSpacing.xs),
            Text(
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
                    label: Text('기록 열기', style: AkashaTypography.compactLabel),
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
                      '엔티티 연결하기',
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
