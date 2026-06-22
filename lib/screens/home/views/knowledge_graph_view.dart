import 'package:flutter/material.dart';

import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/poster_image.dart';
import '../../../widgets/work_link_neighbors_sections.dart';

/// 볼트 작품별 위키 링크 연결을 탐색하는 지식 그래프 뷰 (v1.1 리스트형).
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
    final works = List<AkashaItem>.from(widget.vaultItems)
      ..sort((a, b) {
        final ca = _linkCounts[a.workId] ?? 0;
        final cb = _linkCounts[b.workId] ?? 0;
        if (ca != cb) return cb.compareTo(ca);
        return a.title.compareTo(b.title);
      });

    final allLinksEmpty = !_loadingCounts &&
        works.isNotEmpty &&
        works.every((w) => (_linkCounts[w.workId] ?? 0) == 0);

    return Container(
      color: AkashaColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '지식 연결 맵',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '작품 기록의 [[위키 링크]]로 연결된 인물·작품을 탐색합니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                    Text(
                      '볼트에 작품이 없습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (widget.onConnectEntity != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: widget.onConnectEntity,
                        child: const Text(
                          '엔티티 연결하기',
                          style: TextStyle(fontSize: 11),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: works.length,
                itemBuilder: (context, index) {
                  final work = works[index];
                  final count = _linkCounts[work.workId] ?? 0;
                  final expanded = _expandedNeighbors[work.workId];
                  final loading = _loadingWorkIds.contains(work.workId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: AkashaColors.surfaceCard(radius: 10),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          12,
                        ),
                        onExpansionChanged: (open) {
                          if (open) _loadNeighbors(work);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          count > 0
                              ? '연결 $count개'
                              : '연결 없음 · 기록에서 [[링크]] 추가',
                          style: TextStyle(
                            fontSize: 11,
                            color: count > 0
                                ? AkashaColors.accent
                                : Colors.grey[600],
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () => widget.onOpenWork(work),
                          child: const Text(
                            '열기',
                            style: TextStyle(fontSize: 11),
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '펼쳐서 연결을 불러오세요.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AkashaColors.surfaceCard(radius: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '아직 연결된 지식이 없습니다.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '첫 연결을 만들어 보세요. 작품 기록에 [[위키 링크]]를 추가하면 여기에 표시됩니다.',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.onOpenRecord != null)
                  FilledButton.icon(
                    onPressed: widget.onOpenRecord,
                    icon: const Icon(Icons.edit_note_outlined, size: 14),
                    label: const Text(
                      '기록 열기',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AkashaColors.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (widget.onConnectEntity != null)
                  OutlinedButton.icon(
                    onPressed: widget.onConnectEntity,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 14),
                    label: const Text(
                      '엔티티 연결하기',
                      style: TextStyle(fontSize: 11),
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
