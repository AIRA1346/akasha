import 'package:flutter/material.dart';
import '../models/browse_card.dart';

/// browse 카드 그리드 (HomeScreen·대시보드 공용)
///
/// GridView(shrinkWrap) 대신 비스크롤 [Wrap] 레이아웃 — Windows에서 중첩
/// Scrollable마다 Scrollbar가 생겨 우측 스크롤바가 겹치는 문제를 방지.
class BrowsePosterGrid extends StatelessWidget {
  final List<BrowseCard> cards;
  final Widget Function(BrowseCard card) cardBuilder;
  final double cardMinWidth;
  final double childAspectRatio;

  const BrowsePosterGrid({
    super.key,
    required this.cards,
    required this.cardBuilder,
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

        final crossAxisCount =
            (constraints.maxWidth / cardMinWidth).floor().clamp(2, 8);
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
              for (final card in cards)
                SizedBox(
                  width: cellWidth,
                  height: cellHeight,
                  child: cardBuilder(card),
                ),
            ],
          ),
        );
      },
    );
  }
}
