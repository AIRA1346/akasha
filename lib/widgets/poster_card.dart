import 'package:flutter/material.dart';
import '../core/archiving/entity_anchor.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../models/format_slot.dart';
import '../services/file_service.dart';
import '../utils/catalog_display_title.dart';
import '../utils/status_helpers.dart';
import '../screens/home/dialogs/add_catalog_entity_dialog.dart';
import 'format_chip_row.dart';
import 'poster_image.dart';
import 'star_rating.dart';

// ════════════════════════════════════════════════════════════════
//  포스터 카드 위젯 (AKASHA 대시보드 스타일)
// ════════════════════════════════════════════════════════════════

class PosterCard extends StatefulWidget {
  final AkashaItem item;
  final List<FormatSlot> formatSlots;
  final String? franchiseId;
  final bool showPoster;
  final VoidCallback? onTap;
  final void Function(Offset globalPosition)? onOpenLibraryMenu;
  final void Function(FormatSlot slot)? onHideFormatSlot;
  final int curatedLibraryCount;
  final int incomingRecordCount;
  final bool highlighted;

  const PosterCard({
    super.key,
    required this.item,
    this.formatSlots = const [],
    this.franchiseId,
    this.showPoster = true,
    this.curatedLibraryCount = 0,
    this.incomingRecordCount = 0,
    this.highlighted = false,
    this.onTap,
    this.onOpenLibraryMenu,
    this.onHideFormatSlot,
  });

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard> {
  static const double _yearRowHeight = 14;

  static const double _borderWidthNotStarted = 2.0;
  static const double _borderWidthActive = 2.5;

  static const double _depthShadowBlur = 8;
  static const double _depthShadowOffsetY = 3;
  static const double _idleGlowBlur = 11;
  static const double _hoverGlowBlur = 21;
  static const double _hoverGlowOffsetY = 8;

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final showArchivedBadge = AkashaFileService().isArchivedInVault(item);
    final gradColors = categoryGradient(item.category);

    final isNotStarted = isWatchlistItem(item);
    final isFinished = isFinishedItem(item);
    final categoryAccent = _categoryAccent(item.category);

    Border cardBorder;
    Color glowColor;
    final isEntity = item is EntityItem;

    if (widget.highlighted) {
      cardBorder = Border.all(
        color: Colors.tealAccent,
        width: 2.0,
      );
      glowColor = Colors.tealAccent;
    } else if (isEntity) {
      cardBorder = Border.all(
        color: Colors.tealAccent.withValues(alpha: 0.35),
        width: 1.0,
      );
      glowColor = Colors.tealAccent;
    } else if (isNotStarted) {
      cardBorder = Border.all(
        color: widget.showPoster
            ? Colors.white.withValues(alpha: 0.17)
            : categoryAccent.withValues(alpha: 0.44),
        width: _borderWidthNotStarted,
      );
      glowColor = widget.showPoster ? gradColors[0] : categoryAccent;
    } else if (isFinished) {
      cardBorder = Border.all(
        color: const Color(0xFF9D4EDD).withValues(alpha: 0.75),
        width: _borderWidthActive,
      );
      glowColor = const Color(0xFF9D4EDD);
    } else {
      cardBorder = Border.all(
        color: Colors.greenAccent.withValues(alpha: 0.65),
        width: _borderWidthActive,
      );
      glowColor = Colors.greenAccent;
    }

    final cardBody = GestureDetector(
      onTap: widget.onTap,
      onSecondaryTapDown: _hasContextMenu
          ? (d) => _openContextMenu(d.globalPosition)
          : null,
      onLongPress:
          _hasContextMenu ? () => _openContextMenu(_cardCenterGlobal()) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(10),
          border: cardBorder,
          boxShadow: _cardShadows(
            hovered: _isHovered,
            glowColor: glowColor,
            isNotStarted: isNotStarted || isEntity,
          ),
          ),
          child: widget.showPoster
              ? _buildPosterLayout(item, showArchivedBadge, gradColors)
              : _buildFactCardLayout(item, showArchivedBadge),
        ),
      );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: cardBody,
    );
  }

  bool get _hasContextMenu => widget.onOpenLibraryMenu != null;

  List<BoxShadow> _cardShadows({
    required bool hovered,
    required Color glowColor,
    required bool isNotStarted,
  }) {
    final depth = BoxShadow(
      color: Colors.black.withValues(alpha: hovered ? 0.32 : 0.28),
      blurRadius: _depthShadowBlur,
      offset: Offset(0, hovered ? _depthShadowOffsetY + 1 : _depthShadowOffsetY),
    );

    if (hovered) {
      return [
        depth,
        BoxShadow(
          color: glowColor.withValues(alpha: isNotStarted ? 0.35 : 0.55),
          blurRadius: _hoverGlowBlur,
          spreadRadius: 0.5,
          offset: const Offset(0, _hoverGlowOffsetY),
        ),
      ];
    }

    return [
      depth,
      BoxShadow(
        color: glowColor.withValues(alpha: isNotStarted ? 0.08 : 0.12),
        blurRadius: _idleGlowBlur,
        offset: Offset.zero,
      ),
    ];
  }

  Offset _cardCenterGlobal() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _openContextMenu(Offset globalPosition) {
    widget.onOpenLibraryMenu?.call(globalPosition);
  }

  String _getStatusTextWithEmoji(AkashaItem item) =>
      watchlistStatusEmojiLabel(item);

  Color _categoryAccent(MediaCategory category) {
    if (widget.item is EntityItem) {
      return Colors.tealAccent;
    }
    switch (category) {
      case MediaCategory.manga:
        return const Color(0xFF818CF8);
      case MediaCategory.webtoon:
        return const Color(0xFF34D399);
      case MediaCategory.animation:
        return const Color(0xFFF472B6);
      case MediaCategory.game:
        return const Color(0xFF4ADE80);
      case MediaCategory.book:
        return const Color(0xFFFBBF24);
      case MediaCategory.movie:
        return const Color(0xFF60A5FA);
      case MediaCategory.drama:
        return const Color(0xFFA78BFA);
    }
  }

  Widget _buildLibraryCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.amberAccent.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        '★${widget.curatedLibraryCount}',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.amberAccent,
        ),
      ),
    );
  }

  Widget _buildArchivedBadge({double size = 24}) {
    return Tooltip(
      message: 'Sanctum vault 연동됨',
      child: Semantics(
        label: '아카이브됨',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFCCCCCC),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.description_outlined,
            size: size * 0.58,
            color: const Color(0xFFCCCCCC),
          ),
        ),
      ),
    );
  }

  Widget _buildCardMeta(AkashaItem item) {
    final displayTitle = resolveCatalogDisplayTitle(item);
    final isEntity = item is EntityItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.creator.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.creator,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (isEntity)
          _buildEntityMetaRow(item as EntityItem)
        else ...[
          _buildRatingStatusRow(item),
          const SizedBox(height: 2),
          _buildYearRow(item),
          const SizedBox(height: 2),
          _buildFormatSlotRow(),
        ],
      ],
    );
  }

  Widget _buildEntityMetaRow(EntityItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.tealAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            entityTypeBadgeLabel(item.entityType),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.tealAccent,
            ),
          ),
        ),
        const Spacer(),
        if (widget.incomingRecordCount > 0)
          Text(
            '🔗 ${widget.incomingRecordCount}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.tealAccent,
            ),
          ),
      ],
    );
  }

  Widget _buildYearRow(AkashaItem item) {
    return SizedBox(
      height: _yearRowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: item.releaseYear != null
            ? Text(
                '🗓️ ${item.releaseYear}년',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFormatSlotRow() {
    return SizedBox(
      height: FormatChipRow.rowHeight,
      child: widget.formatSlots.isNotEmpty
          ? FormatChipRow(
              slots: widget.formatSlots,
              onHideSlot: widget.onHideFormatSlot,
            )
          : const SizedBox.shrink(),
    );
  }

  /// 포스터 카드 — 평점(좌) · 나의 상태(우) 한 줄.
  Widget _buildRatingStatusRow(AkashaItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (item.rating > 0)
          StarRating(rating: item.rating, size: 14)
        else
          const Text(
            '⏳ 평가 대기',
            style: TextStyle(
              fontSize: 11,
              color: Colors.amber,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _getStatusTextWithEmoji(item),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[300],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFactCardFooter(AkashaItem item, Color accent) {
    return Row(
      children: [
        _metaPill(
          _getStatusTextWithEmoji(item),
          accent.withValues(alpha: 0.2),
          accent,
        ),
        const Spacer(),
        if (item.rating > 0) StarRating(rating: item.rating, size: 12),
      ],
    );
  }

  Widget _metaPill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPosterLayout(
    AkashaItem item,
    bool showArchivedBadge,
    List<Color> gradColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: PosterImage(
                  item: item,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              if (widget.curatedLibraryCount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildLibraryCountBadge(),
                ),
              if (showArchivedBadge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildArchivedBadge(),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: _buildCardMeta(item),
          ),
        ),
      ],
    );
  }

  Widget _buildFactCardLayout(AkashaItem item, bool showArchivedBadge) {
    final isEntity = item is EntityItem;
    final accent = isEntity ? Colors.tealAccent : _categoryAccent(item.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.42),
                        const Color(0xFF252536),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: -6,
                child: Icon(
                  isEntity
                      ? iconForEntityAnchorType(item.entityType)
                      : item.category.icon,
                  size: 56,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        isEntity
                            ? iconForEntityAnchorType(item.entityType)
                            : item.category.icon,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEntity
                            ? entityTypeBadgeLabel(item.entityType)
                            : item.category.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.curatedLibraryCount > 0) ...[
                      _buildLibraryCountBadge(),
                      const SizedBox(width: 6),
                    ],
                    if (showArchivedBadge)
                      _buildArchivedBadge(size: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resolveCatalogDisplayTitle(item),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                if (item.creator.isNotEmpty)
                  Text(
                    item.creator,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const Spacer(),
                if (isEntity)
                  Row(
                    children: [
                      _metaPill(
                        entityTypeBadgeLabel(item.entityType),
                        accent.withValues(alpha: 0.15),
                        accent,
                      ),
                      const Spacer(),
                      if (widget.incomingRecordCount > 0)
                        Text(
                          '🔗 ${widget.incomingRecordCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.tealAccent,
                          ),
                        ),
                    ],
                  )
                else ...[
                  _buildFactCardFooter(item, accent),
                  const SizedBox(height: 4),
                  _buildFormatSlotRow(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared icon map for entity gallery cards.
IconData iconForEntityAnchorType(EntityAnchorType type) {
  return switch (type) {
    EntityAnchorType.person => Icons.person_outline,
    EntityAnchorType.concept => Icons.lightbulb_outline,
    EntityAnchorType.event => Icons.event_outlined,
    EntityAnchorType.place => Icons.place_outlined,
    EntityAnchorType.organization => Icons.groups_outlined,
    _ => Icons.category_outlined,
  };
}
