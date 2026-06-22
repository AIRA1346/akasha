import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../widgets/poster_image.dart';
import 'home_dashboard_styles.dart';

class HomeDashboardContinueSection extends StatelessWidget {
  const HomeDashboardContinueSection({
    super.key,
    required this.recentExploreItems,
    required this.selectedPreviewItem,
    required this.onItemTap,
    required this.onGoExplore,
  });

  final List<AkashaItem> recentExploreItems;
  final AkashaItem? selectedPreviewItem;
  final void Function(AkashaItem item) onItemTap;
  final VoidCallback onGoExplore;

  @override
  Widget build(BuildContext context) {
    final recentItems = recentExploreItems.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader('계속 탐험하기'),
        const SizedBox(height: 12),
        if (recentItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '아직 탐색 기록이 없습니다. 작품이나 인물을 열면 여기에 표시됩니다.',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...recentItems.map((item) => _ExploreCard(
                    item: item,
                    isSelected: _isSameExploreItem(selectedPreviewItem, item),
                    onTap: () => onItemTap(item),
                  )),
              _AddExploreCard(onTap: onGoExplore),
            ],
          ),
        ),
      ],
    );
  }

  static bool _isSameExploreItem(AkashaItem? selected, AkashaItem item) {
    if (selected == null) return false;
    if (item is EntityItem && selected is EntityItem) {
      return selected.entityId == item.entityId;
    }
    if (item is! EntityItem && selected is! EntityItem) {
      return selected.workId == item.workId;
    }
    return false;
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AkashaItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AkashaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AkashaColors.accent : AkashaColors.borderSubtle(0.08),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PosterImage(item: item, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HomeDashboardStyles.categoryColor(item)
                              .withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category.name,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (item.tags.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.local_offer_outlined,
                                size: 10, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.tags.take(2).join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (item.review.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.edit_document,
                                size: 10, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              '기록 있음',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddExploreCard extends StatelessWidget {
  const _AddExploreCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AkashaColors.borderSubtle(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 20, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Text(
                '탐색 기록 더 보기',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
