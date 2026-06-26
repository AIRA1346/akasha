import 'package:flutter/material.dart';

import '../models/akasha_item.dart';
import '../models/format_slot.dart';
import '../models/enums.dart';
import '../services/file_service.dart';
import 'poster_card_layouts.dart';
import 'poster_card_style.dart';

export 'poster_card_style.dart' show iconForEntityAnchorType;

// ════════════════════════════════════════════════════════════════
//  포스터 카드 위젯 (AKASHA 대시보드 스타일)
// ════════════════════════════════════════════════════════════════

class PosterCard extends StatefulWidget {
  final AkashaItem item;
  final List<FormatSlot> formatSlots;
  final String? franchiseId;
  final bool showPoster;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
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
    this.onDoubleTap,
    this.onOpenLibraryMenu,
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
    final chrome = PosterCardStyle.resolveChrome(
      item: item,
      highlighted: widget.highlighted,
      showPoster: widget.showPoster,
      gradColors: gradColors,
    );

    final cardBody = GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onSecondaryTapDown: _hasContextMenu
          ? (d) => _openContextMenu(d.globalPosition)
          : null,
      onLongPress:
          _hasContextMenu ? () => _openContextMenu(_cardCenterGlobal()) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -4.0, 0.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(10),
          border: chrome.border,
          boxShadow: PosterCardStyle.cardShadows(
            hovered: _isHovered,
            glowColor: chrome.glowColor,
            softGlow: chrome.softGlow,
          ),
        ),
        child: widget.showPoster
            ? PosterCardPosterLayout(
                item: item,
                showArchivedBadge: showArchivedBadge,
                curatedLibraryCount: widget.curatedLibraryCount,
                formatSlots: widget.formatSlots,
                incomingRecordCount: widget.incomingRecordCount,
                onHideFormatSlot: widget.onHideFormatSlot,
              )
            : PosterCardFactCardLayout(
                item: item,
                showArchivedBadge: showArchivedBadge,
                curatedLibraryCount: widget.curatedLibraryCount,
                formatSlots: widget.formatSlots,
                incomingRecordCount: widget.incomingRecordCount,
                onHideFormatSlot: widget.onHideFormatSlot,
              ),
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

  Offset _cardCenterGlobal() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _openContextMenu(Offset globalPosition) {
    widget.onOpenLibraryMenu?.call(globalPosition);
  }
}
