import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../services/recent_exploration_resolver.dart';
import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../utils/exploration_progress.dart';
import '../../../../widgets/poster_image.dart';
import '../../../home/views/preview_record_view_model.dart';
import 'home_dashboard_styles.dart';
import '../../../../utils/app_l10n.dart';

class HomeDashboardContinueSection extends StatefulWidget {
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

  @override
  State<HomeDashboardContinueSection> createState() =>
      _HomeDashboardContinueSectionState();
}

class _HomeDashboardContinueSectionState
    extends State<HomeDashboardContinueSection> {
  static const _railHeight = 180.0;
  static const _scrollButtonInset = 8.0;
  static const _scrollPageCardCount = 2.5;

  late final ScrollController _scrollController;
  var _canScrollBack = false;
  var _canScrollForward = false;

  List<AkashaItem> _resolveDisplayItems() {
    if (widget.recentExploreItems.isNotEmpty) {
      return widget.recentExploreItems
          .take(homeContinueExploreDisplayLimit)
          .toList();
    }
    final sorted = List<AkashaItem>.from(widget.fallbackVaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.take(homeContinueExploreDisplayLimit).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void didUpdateWidget(covariant HomeDashboardContinueSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recentExploreItems != widget.recentExploreItems ||
        oldWidget.fallbackVaultItems != widget.fallbackVaultItems) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        _updateScrollButtons();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) {
      if (_canScrollBack || _canScrollForward) {
        setState(() {
          _canScrollBack = false;
          _canScrollForward = false;
        });
      }
      return;
    }

    final position = _scrollController.position;
    final canBack = position.pixels > position.minScrollExtent + 0.5;
    final canForward = position.pixels < position.maxScrollExtent - 0.5;
    if (canBack == _canScrollBack && canForward == _canScrollForward) return;

    setState(() {
      _canScrollBack = canBack;
      _canScrollForward = canForward;
    });
  }

  void _scrollByPages(double direction) {
    if (!_scrollController.hasClients) return;

    final stride = _ExploreCard.cardStride;
    final delta = stride * _scrollPageCardCount * direction;
    final target = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  bool _isSelected(AkashaItem item) {
    if (item is EntityItem && widget.selectedEntityPreviewId != null) {
      return widget.selectedEntityPreviewId == item.entityId;
    }
    return _isSameExploreItem(widget.selectedPreviewItem, item);
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

  @override
  Widget build(BuildContext context) {
    final displayItems = _resolveDisplayItems();
    final usingVaultFallback =
        widget.recentExploreItems.isEmpty && displayItems.isNotEmpty;
    final l10n = lookupAppL10n(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader(
          l10n?.labelDashboardContinueExplore ?? '계속 탐험하기',
        ),
        const SizedBox(height: 12),
        if (displayItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.isColdStart
                  ? (l10n?.helpDashboardContinueExploreColdStart ??
                        '탐험을 시작하면 최근에 본 작품과 인물이 여기에 표시됩니다.')
                  : (l10n?.helpDashboardContinueExploreEmpty ??
                        '아직 탐색 기록이 없습니다. 작품이나 인물을 열면 여기에 표시됩니다.'),
              style: AkashaTypography.bodySecondary.copyWith(
                color: AkashaColors.textMuted,
              ),
            ),
          )
        else if (usingVaultFallback)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n?.helpDashboardContinueExploreFallback ??
                  '최근 추가한 작품부터 탐험해 보세요.',
              style: AkashaTypography.bodySecondary.copyWith(
                color: AkashaColors.textMuted,
              ),
            ),
          ),
        if (displayItems.isNotEmpty)
          SizedBox(
            height: _railHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    return _ExploreCard(
                      item: item,
                      isSelected: _isSelected(item),
                      onTap: () => widget.onItemTap(item),
                      onDoubleTap: widget.onItemDoubleTap == null
                          ? null
                          : () => widget.onItemDoubleTap!(item),
                    );
                  },
                ),
                if (_canScrollBack)
                  Positioned(
                    left: _scrollButtonInset,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ContinueExploreScrollButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: l10n?.actionPrev ?? '이전',
                        onPressed: () => _scrollByPages(-1),
                      ),
                    ),
                  ),
                if (_canScrollForward)
                  Positioned(
                    right: _scrollButtonInset,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ContinueExploreScrollButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: l10n?.actionNext ?? '다음',
                        onPressed: () => _scrollByPages(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ContinueExploreScrollButton extends StatefulWidget {
  const _ContinueExploreScrollButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_ContinueExploreScrollButton> createState() =>
      _ContinueExploreScrollButtonState();
}

class _ContinueExploreScrollButtonState
    extends State<_ContinueExploreScrollButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? palette.surfaceElevated
            : palette.surface.withValues(alpha: 0.94),
        elevation: _hovered ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: palette.borderSubtle(0.36)),
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          icon: Icon(widget.icon, size: 22, color: AkashaColors.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
  });

  static const cardWidth = 145.0;
  static const cardSpacing = 12.0;
  static const cardStride = cardWidth + cardSpacing;

  final AkashaItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final l10n = lookupAppL10n(context);
    final progress = explorationProgress(item);
    final progressLabel = explorationProgressPercent(item);
    final badgeLabel = l10n != null
        ? _getLocalizedBadgeLabel(item, l10n)
        : (switch (item) {
            EntityItem(:final entityType) => entityTypeDisplayLabel(entityType),
            _ => item.category.label,
          });
    final badgeColor = item is EntityItem
        ? HomeDashboardStyles.categoryColorFor(badgeLabel)
        : HomeDashboardStyles.categoryColor(item);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: cardSpacing),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? palette.accent : palette.borderSubtle(0.28),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                            Icon(
                              Icons.local_offer_outlined,
                              size: 10,
                              color: AkashaColors.textSecondary,
                            ),
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
                            Icon(
                              Icons.edit_document,
                              size: 10,
                              color: AkashaColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n?.labelHasRecord ?? '기록 있음',
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
                                backgroundColor: palette.borderSubtle(0.25),
                                valueColor: AlwaysStoppedAnimation(
                                  palette.accent,
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

  String _getLocalizedBadgeLabel(AkashaItem item, dynamic l10n) {
    if (item is EntityItem) {
      switch (item.entityType.name) {
        case 'work':
          return l10n.entityTypeWork;
        case 'person':
          return l10n.entityTypePerson;
        case 'concept':
          return l10n.entityTypeConcept;
        case 'event':
          return l10n.entityTypeEvent;
        case 'place':
          return l10n.entityTypePlace;
        case 'organization':
          return l10n.entityTypeOrganization;
        case 'object':
          return l10n.entityTypeObject;
        case 'unknown':
          return l10n.entityTypeUnknown;
        case 'custom':
          return l10n.entityTypeCustom;
        case 'phenomenon':
          return l10n.entityTypePhenomenon;
        default:
          return item.entityType.name;
      }
    } else {
      switch (item.category.name) {
        case 'manga':
          return l10n.mediaCategoryManga;
        case 'webtoon':
          return l10n.mediaCategoryWebtoon;
        case 'game':
          return l10n.mediaCategoryGame;
        case 'animation':
          return l10n.mediaCategoryAnimation;
        case 'book':
          return l10n.mediaCategoryBook;
        case 'movie':
          return l10n.mediaCategoryMovie;
        case 'drama':
          return l10n.mediaCategoryDrama;
        default:
          return item.category.label;
      }
    }
  }
}
