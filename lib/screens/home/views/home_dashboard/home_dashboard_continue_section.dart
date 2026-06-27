import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/exploration_progress.dart';
import '../../../../widgets/poster_image.dart';
import '../../../home/views/preview_record_view_model.dart';
import 'home_dashboard_styles.dart';

class HomeDashboardContinueSection extends StatelessWidget {
  const HomeDashboardContinueSection({
    super.key,
    required this.recentExploreItems,
    required this.selectedPreviewItem,
    required this.onItemTap,
    this.onItemDoubleTap,
    this.selectedEntityPreviewId,
    this.isColdStart = false,
    this.fallbackVaultItems = const [],
  });

  final List<AkashaItem> recentExploreItems;
  final AkashaItem? selectedPreviewItem;
  final String? selectedEntityPreviewId;
  final void Function(AkashaItem item) onItemTap;
  final void Function(AkashaItem item)? onItemDoubleTap;
  final bool isColdStart;
  final List<AkashaItem> fallbackVaultItems;

  List<AkashaItem> get _displayItems {
    if (recentExploreItems.isNotEmpty) {
      return recentExploreItems.take(4).toList();
    }
    final sorted = List<AkashaItem>.from(fallbackVaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.take(4).toList();
  }

  bool get _usingVaultFallback =>
      recentExploreItems.isEmpty && _displayItems.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final displayItems = _displayItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader('계속 탐험하기'),
        const SizedBox(height: 12),
        if (displayItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isColdStart
                  ? '탐험을 시작하면 최근에 본 작품과 인물이 여기에 표시됩니다.'
                  : '아직 탐색 기록이 없습니다. 작품이나 인물을 열면 여기에 표시됩니다.',
              style: AkashaTypography.bodySecondary.copyWith(
                color: AkashaColors.textMuted,
              ),
            ),
          )
        else if (_usingVaultFallback)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '최근 추가한 작품부터 탐험해 보세요.',
              style: AkashaTypography.bodySecondary.copyWith(
                color: AkashaColors.textMuted,
              ),
            ),
          ),
        if (displayItems.isNotEmpty)
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...displayItems.map((item) => _ExploreCard(
                      item: item,
                      isSelected: _isSelected(item),
                      onTap: () => onItemTap(item),
                      onDoubleTap: onItemDoubleTap == null
                          ? null
                          : () => onItemDoubleTap!(item),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  bool _isSelected(AkashaItem item) {
    if (item is EntityItem && selectedEntityPreviewId != null) {
      return selectedEntityPreviewId == item.entityId;
    }
    return _isSameExploreItem(selectedPreviewItem, item);
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
    this.onDoubleTap,
  });

  final AkashaItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final progress = explorationProgress(item);
    final progressLabel = explorationProgressPercent(item);
    final badgeLabel = switch (item) {
      EntityItem(:final entityType) => entityTypeDisplayLabel(entityType),
      _ => item.category.label,
    };
    final badgeColor = item is EntityItem
        ? HomeDashboardStyles.categoryColorFor(badgeLabel)
        : HomeDashboardStyles.categoryColor(item);

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
          onDoubleTap: onDoubleTap,
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
                          color: badgeColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeLabel,
                          style: AkashaTypography.micro.copyWith(
                            color: AkashaColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AkashaTypography.compactLabel.copyWith(
                          color: AkashaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (item.tags.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.local_offer_outlined,
                                size: 10, color: AkashaColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.tags.take(2).join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AkashaTypography.micro.copyWith(
                                  color: AkashaColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (item.review.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.edit_document,
                                size: 10, color: AkashaColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '기록 있음',
                              style: AkashaTypography.micro.copyWith(
                                color: AkashaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 3,
                                backgroundColor: AkashaColors.borderSubtle(0.12),
                                valueColor: const AlwaysStoppedAnimation(
                                  AkashaColors.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$progressLabel%',
                            style: AkashaTypography.nano.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AkashaColors.textSecondary,
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
