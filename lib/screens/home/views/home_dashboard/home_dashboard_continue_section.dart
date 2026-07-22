import 'package:flutter/material.dart';

import '../../../../models/akasha_item.dart';
import '../../../../services/recent_exploration_resolver.dart';
import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_radius.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';
import '../../../../theme/akasha_theme_preset.dart';
import '../../../../utils/app_l10n.dart';
import '../../../../widgets/poster_image.dart';
import '../../../home/views/preview_record_view_model.dart';
import 'home_dashboard_styles.dart';

class HomeDashboardContinueSection extends StatefulWidget {
  const HomeDashboardContinueSection({
    super.key,
    required this.recentExploreItems,
    required this.selectedPreviewItem,
    required this.onItemTap,
    this.onItemDoubleTap,
    this.onExplore,
    this.selectedEntityPreviewId,
    this.isColdStart = false,
    this.fallbackVaultItems = const [],
  });

  static const railKey = ValueKey('home-dashboard-continue-rail');
  static const emptyActionKey = ValueKey(
    'home-dashboard-continue-empty-action',
  );
  static ValueKey<String> cardKey(String id) =>
      ValueKey<String>('home-dashboard-continue-card-$id');

  final List<AkashaItem> recentExploreItems;
  final AkashaItem? selectedPreviewItem;
  final String? selectedEntityPreviewId;
  final void Function(AkashaItem item) onItemTap;
  final void Function(AkashaItem item)? onItemDoubleTap;
  final VoidCallback? onExplore;
  final bool isColdStart;
  final List<AkashaItem> fallbackVaultItems;

  @override
  State<HomeDashboardContinueSection> createState() =>
      _HomeDashboardContinueSectionState();
}

class _HomeDashboardContinueSectionState
    extends State<HomeDashboardContinueSection> {
  static const _railHeight = 212.0;
  static const _scrollButtonInset = 8.0;
  static const _scrollPageCardCount = 2.5;

  late final ScrollController _scrollController;
  var _canScrollBack = false;
  var _canScrollForward = false;

  List<AkashaItem> _resolveDisplayItems([
    HomeDashboardContinueSection? source,
  ]) {
    final config = source ?? widget;
    if (config.recentExploreItems.isNotEmpty) {
      return config.recentExploreItems
          .take(homeContinueExploreDisplayLimit)
          .toList(growable: false);
    }
    final sorted = List<AkashaItem>.from(config.fallbackVaultItems)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.take(homeContinueExploreDisplayLimit).toList(growable: false);
  }

  List<String> _displayIdentity(HomeDashboardContinueSection source) {
    return _resolveDisplayItems(source)
        .map((item) {
          if (item is EntityItem) return 'entity:${item.entityId}';
          return 'work:${item.workId}';
        })
        .toList(growable: false);
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
    final oldIdentity = _displayIdentity(oldWidget);
    final newIdentity = _displayIdentity(widget);
    if (_sameIdentity(oldIdentity, newIdentity)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _updateScrollButtons();
    });
  }

  static bool _sameIdentity(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
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

    final delta = _ExploreCard.cardStride * _scrollPageCardCount * direction;
    final target = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    final duration =
        context.resolvedAkashaThemeVisuals.effects.motion.standardDuration;
    if (duration == Duration.zero) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: duration,
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
    final palette = context.akashaPalette;
    final countLabel = displayItems.isEmpty
        ? null
        : (l10n?.dashboardContinueItemCount(displayItems.length) ??
              '${displayItems.length}개');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeDashboardStyles.sectionHeader(
          context,
          l10n?.labelDashboardContinueExplore ?? '계속 탐험하기',
          countLabel: countLabel,
        ),
        const SizedBox(height: AkashaSpacing.md),
        if (displayItems.isEmpty)
          _ContinueEmptyState(
            message: widget.isColdStart
                ? (l10n?.helpDashboardContinueExploreColdStart ??
                      '탐험을 시작하면 최근에 본 작품과 인물이 여기에 표시됩니다.')
                : (l10n?.helpDashboardContinueExploreEmpty ??
                      '아직 탐색 기록이 없습니다. 작품이나 인물을 열면 여기에 표시됩니다.'),
            actionLabel: l10n?.sidebarExplore ?? '탐색',
            onExplore: widget.onExplore,
            palette: palette,
          )
        else ...[
          if (usingVaultFallback) ...[
            Text(
              l10n?.helpDashboardContinueExploreFallback ??
                  '최근 추가한 작품부터 탐험해 보세요.',
              style: AkashaTypography.bodySecondary.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: AkashaSpacing.sm),
          ],
          SizedBox(
            key: HomeDashboardContinueSection.railKey,
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
                    return FocusTraversalOrder(
                      order: NumericFocusOrder(index.toDouble()),
                      child: _ExploreCard(
                        key: HomeDashboardContinueSection.cardKey(
                          item is EntityItem ? item.entityId : item.workId,
                        ),
                        item: item,
                        isSelected: _isSelected(item),
                        onTap: () => widget.onItemTap(item),
                        onDoubleTap: widget.onItemDoubleTap == null
                            ? null
                            : () => widget.onItemDoubleTap!(item),
                      ),
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
      ],
    );
  }
}

class _ContinueEmptyState extends StatelessWidget {
  const _ContinueEmptyState({
    required this.message,
    required this.actionLabel,
    required this.onExplore,
    required this.palette,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onExplore;
  final AkashaPalette palette;

  @override
  Widget build(BuildContext context) {
    final messageContent = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: AkashaRadius.lgBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AkashaSpacing.sm),
            child: Icon(
              Icons.explore_outlined,
              color: palette.accent,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: AkashaSpacing.md),
        Expanded(
          child: Text(
            message,
            style: AkashaTypography.bodySecondary.copyWith(
              color: palette.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: palette.surfaceCard(radius: AkashaRadius.xl),
      child: Padding(
        padding: const EdgeInsets.all(AkashaSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (onExplore == null) return messageContent;
            final action = OutlinedButton.icon(
              key: HomeDashboardContinueSection.emptyActionKey,
              onPressed: onExplore,
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: Text(actionLabel),
            );
            if (constraints.maxWidth >= 560) {
              return Row(
                children: [
                  Expanded(child: messageContent),
                  const SizedBox(width: AkashaSpacing.lg),
                  action,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                messageContent,
                const SizedBox(height: AkashaSpacing.md),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          },
        ),
      ),
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
          borderRadius: AkashaRadius.mdBorder,
          side: BorderSide(color: palette.borderSubtle(0.36)),
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          icon: Icon(widget.icon, size: 22, color: palette.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
  });

  static const cardWidth = 156.0;
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
    final badgeLabel = l10n != null
        ? _getLocalizedBadgeLabel(item, l10n)
        : (switch (item) {
            EntityItem(:final entityType) => entityTypeDisplayLabel(entityType),
            _ => item.category.label,
          });
    final badgeColor = HomeDashboardStyles.categoryColor(item, palette);
    final metadata = _metadataLabel(item, l10n?.labelHasRecord ?? '기록 있음');

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${item.title}, $badgeLabel',
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: cardSpacing),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AkashaRadius.xl),
          border: Border.all(
            color: isSelected ? palette.accent : palette.borderSubtle(0.28),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AkashaRadius.lg),
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AkashaRadius.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PosterImage(item: item, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.background.withValues(alpha: 0),
                          palette.scrim.withValues(alpha: 0.94),
                        ],
                        stops: const [0.3, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AkashaSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.9),
                            borderRadius: AkashaRadius.smBorder,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            child: Text(
                              badgeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AkashaTypography.micro.copyWith(
                                color: AkashaPalette.bestForegroundOn(
                                  badgeColor,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AkashaSpacing.sm),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AkashaTypography.compactLabel.copyWith(
                            color: palette.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        if (metadata != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _metadataIcon(item),
                                size: 11,
                                color: palette.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  metadata,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AkashaTypography.micro.copyWith(
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _metadataLabel(AkashaItem item, String hasRecordLabel) {
    if (item is! EntityItem && item.myStatusLabel.trim().isNotEmpty) {
      return item.myStatusLabel.trim();
    }
    if (item.tags.isNotEmpty) return item.tags.take(2).join(' · ');
    if (item.creator.trim().isNotEmpty) return item.creator.trim();
    if (item.review.trim().isNotEmpty || item.bodyRaw.trim().isNotEmpty) {
      return hasRecordLabel;
    }
    return null;
  }

  static IconData _metadataIcon(AkashaItem item) {
    if (item is! EntityItem && item.myStatusLabel.trim().isNotEmpty) {
      return Icons.radio_button_checked_rounded;
    }
    if (item.tags.isNotEmpty) return Icons.sell_outlined;
    if (item.creator.trim().isNotEmpty) return Icons.person_outline_rounded;
    return Icons.edit_note_rounded;
  }

  String _getLocalizedBadgeLabel(AkashaItem item, dynamic l10n) {
    if (item is EntityItem) {
      return switch (item.entityType.name) {
        'work' => l10n.entityTypeWork,
        'person' => l10n.entityTypePerson,
        'concept' => l10n.entityTypeConcept,
        'event' => l10n.entityTypeEvent,
        'place' => l10n.entityTypePlace,
        'organization' => l10n.entityTypeOrganization,
        'object' => l10n.entityTypeObject,
        'unknown' => l10n.entityTypeUnknown,
        'custom' => l10n.entityTypeCustom,
        'phenomenon' => l10n.entityTypePhenomenon,
        _ => item.entityType.name,
      };
    }
    return switch (item.category.name) {
      'manga' => l10n.mediaCategoryManga,
      'webtoon' => l10n.mediaCategoryWebtoon,
      'game' => l10n.mediaCategoryGame,
      'animation' => l10n.mediaCategoryAnimation,
      'book' => l10n.mediaCategoryBook,
      'movie' => l10n.mediaCategoryMovie,
      'drama' => l10n.mediaCategoryDrama,
      _ => item.category.label,
    };
  }
}
