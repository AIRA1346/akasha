import '../models/browse_card.dart';
import '../models/enums.dart';
import 'helpers.dart';

/// 작품 카탈로그 섹션용 매체(장르)별 그룹화
class BrowseCategoryGroups {
  final List<MediaCategory> orderedCategories;
  final Map<MediaCategory, List<BrowseCard>> byCategory;

  const BrowseCategoryGroups({
    required this.orderedCategories,
    required this.byCategory,
  });

  static BrowseCategoryGroups fromCards(
    List<BrowseCard> cards,
    SortCriteria sort,
  ) {
    final grouped = <MediaCategory, List<BrowseCard>>{};

    for (final card in cards) {
      grouped.putIfAbsent(card.item.category, () => []).add(card);
    }

    for (final category in grouped.keys.toList()) {
      grouped[category] = sortBrowseCards(grouped[category]!, sort);
    }

    final ordered = MediaCategory.values
        .where((category) => grouped.containsKey(category))
        .toList();

    return BrowseCategoryGroups(
      orderedCategories: ordered,
      byCategory: grouped,
    );
  }
}
