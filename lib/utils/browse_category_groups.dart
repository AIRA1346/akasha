import '../models/browse_card.dart';
import '../models/enums.dart';
import '../models/format_slot.dart';
import 'helpers.dart';

/// 작품 카탈로그 섹션용 매체(장르)별 그룹화
class BrowseCategoryGroups {
  final List<MediaCategory> orderedCategories;
  final Map<MediaCategory, List<BrowseCard>> byCategory;

  const BrowseCategoryGroups({
    required this.orderedCategories,
    required this.byCategory,
  });

  /// IP 통합 카드는 포함 매체(formatSlots)마다 섹션에 중복 배치합니다.
  static Set<MediaCategory> categoriesForCard(BrowseCard card) {
    if (card.formatSlots.isNotEmpty) {
      final fromSlots = card.formatSlots
          .where((slot) => slot.state != FormatSlotState.hidden)
          .map((slot) => slot.category)
          .toSet();
      if (fromSlots.isNotEmpty) return fromSlots;
    }
    return {card.item.category};
  }

  static BrowseCategoryGroups fromCards(
    List<BrowseCard> cards,
    SortCriteria sort, {
    Set<MediaCategory> restrictToCategories = const {},
  }) {
    final grouped = <MediaCategory, List<BrowseCard>>{};

    for (final card in cards) {
      var categories = categoriesForCard(card);
      if (restrictToCategories.isNotEmpty) {
        categories = categories.intersection(restrictToCategories);
        if (categories.isEmpty) continue;
      }
      for (final category in categories) {
        grouped.putIfAbsent(category, () => []).add(card);
      }
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
