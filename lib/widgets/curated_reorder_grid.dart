import 'package:flutter/material.dart';

import '../models/browse_card.dart';

/// DnD-B — curated 서재 그리드 내 순서 변경 (좌측 핸들만)
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
        final crossAxisCount =
            (constraints.maxWidth / cardMinWidth).floor().clamp(2, 8);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return DragTarget<int>(
              onWillAcceptWithDetails: (details) => details.data != index,
              onAcceptWithDetails: (details) {
                onReorder(details.data, index);
              },
              builder: (context, candidate, rejected) {
                final highlighted = candidate.isNotEmpty;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
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
                                  color:
                                      Colors.tealAccent.withValues(alpha: 0.6),
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
          },
        );
      },
    );
  }
}
