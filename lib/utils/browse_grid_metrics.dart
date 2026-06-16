import 'package:flutter/material.dart';

import '../models/browse_card.dart';

/// SliverGrid·스크롤 안정용 카드 stable key (load more 시 findChildIndexCallback)
String browseCardStableKey(BrowseCard card) {
  final workId = card.item.workId;
  if (workId.isNotEmpty) return workId;
  return '${card.item.title}|${card.item.category.name}';
}

/// browse 그리드 열 수·delegate — 뷰포트당 1회 계산
class BrowseGridMetrics {
  final int crossAxisCount;
  final SliverGridDelegate gridDelegate;

  const BrowseGridMetrics({
    required this.crossAxisCount,
    required this.gridDelegate,
  });

  static const double defaultHorizontalPadding = 16;
  static const double defaultSpacing = 12;

  static BrowseGridMetrics resolve({
    required double maxWidth,
    required double cardMinWidth,
    required double childAspectRatio,
    double horizontalPadding = defaultHorizontalPadding,
    double spacing = defaultSpacing,
  }) {
    final crossAxisCount =
        (maxWidth / cardMinWidth).floor().clamp(2, 8);

    return BrowseGridMetrics(
      crossAxisCount: crossAxisCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
    );
  }
}
