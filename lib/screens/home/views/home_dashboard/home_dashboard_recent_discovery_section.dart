import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../widgets/poster_image.dart';
import 'home_dashboard_styles.dart';

/// 최근 볼트에 추가된 작품 — 탐색 진입용 (통계 없음).
class HomeDashboardRecentDiscoverySection extends StatelessWidget {
  const HomeDashboardRecentDiscoverySection({
    super.key,
    required this.vaultItems,
    required this.onItemTap,
    this.selectedPreviewItem,
  });

  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item) onItemTap;
  final AkashaItem? selectedPreviewItem;

  @override
  Widget build(BuildContext context) {
    final sorted = List<AkashaItem>.from(vaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final recent = sorted.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader('최근 발견'),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Text(
            '검색으로 작품을 찾아 볼트에 추가해 보세요.',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final work = recent[index];
                final selected = selectedPreviewItem?.workId == work.workId;
                return _DiscoveryCard(
                  item: work,
                  isSelected: selected,
                  onTap: () => onItemTap(work),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AkashaItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: AkashaColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AkashaColors.accent
                    : Colors.white.withValues(alpha: 0.06),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 48,
                    height: 64,
                    child: PosterImage(item: item, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category.name,
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
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
