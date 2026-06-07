import 'package:flutter/material.dart';
import '../models/browse_card.dart';

/// browse 카드 그리드 (HomeScreen·대시보드 공용)
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
          itemBuilder: (_, i) => cardBuilder(cards[i]),
        );
      },
    );
  }
}
