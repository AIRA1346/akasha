import 'package:flutter/material.dart';

import '../models/browse_card.dart';
import '../theme/akasha_theme_preset.dart';

/// DnD-B — curated 서재 그리드 내 순서 변경 (좌측 핸들만)
///
/// 비스크롤 [Wrap]을 사용해 중첩 Scrollbar를 방지합니다.
class CuratedReorderGrid extends StatelessWidget {
  final List<BrowseCard> cards;
  final Widget Function(BrowseCard card) cardBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final double cardMinWidth;
  final double childAspectRatio;

  const CuratedReorderGrid({
    super.key,
    required this.cards,
    required this.cardBuilder,
    required this.onReorder,
    this.cardMinWidth = 170,
    this.childAspectRatio = 0.48,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        const verticalPadding = 8.0;
        const spacing = 12.0;

        final crossAxisCount = (constraints.maxWidth / cardMinWidth)
            .floor()
            .clamp(2, 8);
        final contentWidth = constraints.maxWidth - horizontalPadding * 2;
        final cellWidth =
            (contentWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final cellHeight = cellWidth / childAspectRatio;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (var index = 0; index < cards.length; index++)
                SizedBox(
                  width: cellWidth,
                  height: cellHeight,
                  child: _reorderCell(index),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _reorderCell(int index) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        onReorder(details.data, index);
      },
      builder: (context, candidate, rejected) {
        final highlighted = candidate.isNotEmpty;
        final motion = context.resolvedAkashaThemeVisuals.effects.motion;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: motion.quickDuration,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: highlighted
                    ? Border.all(
                        color: Colors.tealAccent.withValues(alpha: 0.7),
                        width: 2,
                      )
                    : null,
              ),
              child: cardBuilder(cards[index]),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Draggable<int>(
                data: index,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.85,
                    child: Container(
                      width: 56,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.tealAccent.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(
                        Icons.swap_vert,
                        size: 18,
                        color: Colors.tealAccent,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: const SizedBox.shrink(),
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.swap_vert,
                      size: 14,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
