import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/akasha_item.dart';
import '../models/format_slot.dart';
import '../services/file_service.dart';
import '../utils/status_helpers.dart';
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
  final VoidCallback? onHideFromRegistry;
  final VoidCallback? onHideFranchise;
  final void Function(FormatSlot slot)? onHideFormatSlot;

  const PosterCard({
    super.key,
    required this.item,
    this.formatSlots = const [],
    this.franchiseId,
    this.showPoster = true,
    this.onTap,
    this.onHideFromRegistry,
    this.onHideFranchise,
    this.onHideFormatSlot,
  });

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final showArchivedBadge = AkashaFileService().isArchivedInVault(item);
    final gradColors = categoryGradient(item.category);

    final isNotStarted = isWatchlistItem(item);
    final isFinished = isFinishedItem(item);

    Border cardBorder;
    Color glowColor;

    if (isNotStarted) {
      cardBorder = Border.all(
        color: Colors.white.withValues(alpha: 0.12),
        width: 1.5,
      );
      glowColor = gradColors[0];
    } else if (isFinished) {
      cardBorder = Border.all(
        color: const Color(0xFF9D4EDD).withValues(alpha: 0.7),
        width: 2.0,
      );
      glowColor = const Color(0xFF9D4EDD);
    } else {
      cardBorder = Border.all(
        color: Colors.greenAccent.withValues(alpha: 0.6),
        width: 2.0,
      );
      glowColor = Colors.greenAccent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTap: (widget.onHideFromRegistry != null ||
                widget.onHideFranchise != null)
            ? () => _showRegistryContextMenu(context)
            : null,
        onLongPress: (widget.onHideFromRegistry != null ||
                widget.onHideFranchise != null)
            ? () => _showRegistryContextMenu(context)
            : null,
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
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color:
                          glowColor.withValues(alpha: isNotStarted ? 0.25 : 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.showPoster
              ? _buildPosterLayout(item, showArchivedBadge)
              : _buildCompactLayout(item, showArchivedBadge),
        ),
      ),
    );
  }

  void _showRegistryContextMenu(BuildContext context) {
    final hide = widget.onHideFromRegistry;
    final hideFranchise = widget.onHideFranchise;
    if (hide == null && hideFranchise == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hideFranchise != null)
              ListTile(
                leading: const Icon(Icons.layers_clear_outlined),
                title: const Text('이 작품(IP) 전체 숨기기'),
                subtitle: const Text('모든 매체 버전을 그리드에서 숨깁니다'),
                onTap: () {
                  Navigator.pop(ctx);
                  hideFranchise();
                },
              ),
            if (hide != null)
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text(
                  hideFranchise != null ? '대표 매체만 숨기기' : '이 매체 버전 숨기기',
                ),
                subtitle: const Text('그리드에서 이 사전 항목을 표시하지 않습니다'),
                onTap: () {
                  Navigator.pop(ctx);
                  hide();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusTextWithEmoji(AkashaItem item) =>
      watchlistStatusEmojiLabel(item);

  Widget _buildArchivedBadge() {
    return Tooltip(
      message: 'Sanctum vault 연동됨',
      child: Semantics(
        label: '아카이브됨',
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFCCCCCC),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.description_outlined,
            size: 14,
            color: Color(0xFFCCCCCC),
          ),
        ),
      ),
    );
  }

  Widget _buildCardMeta(AkashaItem item, {required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontSize: compact ? 14 : 13,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          maxLines: compact ? 3 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        if (item.creator.isNotEmpty)
          Text(
            item.creator,
            style: TextStyle(
              fontSize: compact ? 12 : 11,
              color: Colors.grey[400],
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (compact) ...[
          const SizedBox(height: 6),
          Chip(
            avatar: Icon(item.category.icon, size: 14),
            label: Text(
              item.category.label,
              style: const TextStyle(fontSize: 10),
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
          ),
        ],
        if (!compact) const Spacer(),
        if (compact) const SizedBox(height: 8),
        if (item.rating > 0)
          StarRating(rating: item.rating, size: compact ? 13 : 14)
        else if (!compact)
          const Row(
            children: [
              Text(
                '⏳ 평가 대기',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.amber,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        if (!compact) const SizedBox(height: 5),
        if (compact) const SizedBox(height: 6),
        Text(
          _getStatusTextWithEmoji(item),
          style: TextStyle(
            fontSize: compact ? 11 : 11,
            color: Colors.grey[300],
            fontWeight: FontWeight.w500,
          ),
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (item.releaseYear != null) ...[
          SizedBox(height: compact ? 4 : 5),
          Text(
            '🗓️ ${item.releaseYear}년',
            style: TextStyle(
              fontSize: compact ? 10 : 10,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormatSlotsRow() {
    if (widget.formatSlots.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: FormatChipRow(
        slots: widget.formatSlots,
        onHideSlot: widget.onHideFormatSlot,
      ),
    );
  }

  Widget _buildPosterLayout(AkashaItem item, bool showArchivedBadge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
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
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: _buildCardMeta(item, compact: false),
          ),
        ),
        _buildFormatSlotsRow(),
      ],
    );
  }

  Widget _buildCompactLayout(AkashaItem item, bool showArchivedBadge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Stack(
              children: [
                _buildCardMeta(item, compact: true),
                if (showArchivedBadge)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildArchivedBadge(),
                  ),
              ],
            ),
          ),
        ),
        _buildFormatSlotsRow(),
      ],
    );
  }
}
