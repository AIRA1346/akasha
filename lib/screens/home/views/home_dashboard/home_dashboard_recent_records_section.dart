import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../widgets/poster_image.dart';
import 'home_dashboard_styles.dart';

/// 기록이 있는 최근 작품 — Sanctum·리뷰 기반.
class HomeDashboardRecentRecordsSection extends StatelessWidget {
  const HomeDashboardRecentRecordsSection({
    super.key,
    required this.vaultItems,
    required this.onItemTap,
  });

  final List<AkashaItem> vaultItems;
  final void Function(AkashaItem item) onItemTap;

  @override
  Widget build(BuildContext context) {
    final withRecords = vaultItems
        .where((w) => w.review.isNotEmpty || w.filePath != null)
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final recent = withRecords.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader('최근 기록'),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Text(
            '작품을 열어 감상을 기록하면 여기에 표시됩니다.',
            style: AkashaTypography.bodySecondary.copyWith(
              color: AkashaColors.textMuted,
            ),
          )
        else
          Column(
            children: recent.map((work) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onItemTap(work),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: AkashaColors.surfaceCard(radius: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 32,
                              height: 44,
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
                                  style: AkashaTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AkashaColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  work.review.isNotEmpty
                                      ? work.review
                                      : '아카이브됨 · 기록 있음',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AkashaTypography.caption.copyWith(
                                    color: AkashaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_note_outlined,
                              size: 16, color: AkashaColors.textCaption),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
