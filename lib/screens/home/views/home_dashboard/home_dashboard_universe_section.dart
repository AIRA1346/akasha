import 'package:flutter/material.dart';

import '../../../../core/archiving/entity_anchor.dart';
import '../../../../core/ports/user_catalog_port.dart';
import '../../../../models/akasha_item.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../widgets/poster_image.dart';
import '../../../../widgets/universe_orbit_painter.dart';
import 'home_dashboard_styles.dart';

class HomeDashboardUniverseSection extends StatelessWidget {
  const HomeDashboardUniverseSection({
    super.key,
    required this.vaultItems,
    required this.userCatalog,
    required this.selectedPreviewItem,
    required this.onItemTap,
    required this.onSearch,
  });

  final List<AkashaItem> vaultItems;
  final UserCatalogPort userCatalog;
  final AkashaItem? selectedPreviewItem;
  final void Function(AkashaItem item) onItemTap;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final allEntities = userCatalog.all;
    final personCount =
        allEntities.where((e) => e.anchorType == EntityAnchorType.person).length;
    final placeCount =
        allEntities.where((e) => e.anchorType == EntityAnchorType.place).length;
    final eventCount =
        allEntities.where((e) => e.anchorType == EntityAnchorType.event).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AkashaColors.surfaceCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('지식 우주 현황', style: HomeDashboardStyles.panelTitle),
                const SizedBox(height: 12),
                UniverseOrbitWidget(
                  workCount: vaultItems.length,
                  personCount: personCount,
                  placeCount: placeCount,
                  eventCount: eventCount,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AkashaColors.surfaceCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '최근 추가된 작품',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeDashboardStyles.panelTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onSearch,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '모두 보기',
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._recentlyAddedRows(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _recentlyAddedRows() {
    final sortedItems = List<AkashaItem>.from(vaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final recentItems = sortedItems.take(5).toList();

    if (recentItems.isEmpty) {
      return [
        Text(
          '최근 추가한 작품이 없습니다.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ];
    }

    return List.generate(recentItems.length, (index) {
      final work = recentItems[index];
      final isSelected = selectedPreviewItem?.workId == work.workId;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: isSelected
              ? AkashaColors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onItemTap(work),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: PosterImage(item: work, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${work.releaseYear ?? ''} · ${work.category.name}',
                          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (index == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AkashaColors.newBadgeBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AkashaColors.newBadgeBorder,
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: AkashaColors.newBadgeText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
