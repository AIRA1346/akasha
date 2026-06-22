import 'package:flutter/material.dart';

import '../../../core/ports/record_link_port.dart';
import '../../../core/ports/user_catalog_port.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/coordinators/home_shell_wiring.dart';
import '../../../services/entity_related_works_discovery.dart';
import '../../../theme/akasha_colors.dart';
import '../../../utils/work_link_neighbors.dart';
import '../../../widgets/poster_image.dart';
import '../../../widgets/work_link_neighbors_sections.dart';

class DashboardPreviewPanel extends StatefulWidget {
  const DashboardPreviewPanel({
    super.key,
    required this.item,
    required this.userCatalog,
    required this.linkIndex,
    required this.vaultItems,
    required this.onClose,
    required this.onOpenDetail,
    this.onOpenEntity,
    this.onOpenWork,
  });

  final AkashaItem item;
  final UserCatalogPort userCatalog;
  final RecordLinkPort linkIndex;
  final List<AkashaItem> vaultItems;
  final VoidCallback onClose;
  final VoidCallback onOpenDetail;
  final void Function(UserCatalogEntity entity)? onOpenEntity;
  final void Function(AkashaItem work)? onOpenWork;

  @override
  State<DashboardPreviewPanel> createState() => _DashboardPreviewPanelState();
}

class _DashboardPreviewPanelState extends State<DashboardPreviewPanel> {
  late Future<WorkLinkNeighbors> _neighborsFuture;

  @override
  void initState() {
    super.initState();
    _neighborsFuture = _loadNeighbors();
  }

  @override
  void didUpdateWidget(covariant DashboardPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.workId != widget.item.workId) {
      _neighborsFuture = _loadNeighbors();
    }
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

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
            child: Row(
              children: [
                Text(
                  widget.item.category.name,
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
                        width: 180,
                        height: 260,
                        child: PosterImage(
                          item: widget.item,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.item.creator.isNotEmpty
                        ? widget.item.creator
                        : '작자 미상',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.item.releaseYear ?? '연도 미상'} · ${widget.item.category.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
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
                            '상세 정보 >',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildInfoRow('장르', widget.item.category.name),
                  _buildInfoRow(
                    '원작',
                    widget.item.creator.isNotEmpty
                        ? widget.item.creator
                        : '정보 없음',
                  ),
                  _buildInfoRow(
                    '평점',
                    widget.item.rating > 0
                        ? '${widget.item.rating} / 10.0'
                        : '평가 없음',
                  ),
                  const SizedBox(height: 24),
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
                      return WorkLinkNeighborsSections(
                        neighbors: neighbors,
                        onOpenEntity: widget.onOpenEntity,
                        onOpenWork: widget.onOpenWork,
                      );
                    },
                  ),
                  if (widget.item.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '관련 개념',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.item.tags
                          .map((tag) => _buildTagChip(tag))
                          .toList(),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: Colors.grey[300]),
      ),
    );
  }
}