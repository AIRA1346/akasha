import '../models/browse_card.dart';
import 'helpers.dart';

/// 연도별 라이브러리 섹션용 그룹화
class BrowseYearGroups {
  final Map<int, List<BrowseCard>> byYear;
  final List<BrowseCard> noYear;
  final List<int> sortedYears;

  const BrowseYearGroups({
    required this.byYear,
    required this.noYear,
    required this.sortedYears,
  });

  static BrowseYearGroups fromLibraryCards(
    List<BrowseCard> libraryCards,
    SortCriteria yearlySort,
  ) {
    final grouped = <int, List<BrowseCard>>{};
    final noYear = <BrowseCard>[];

    for (final card in libraryCards) {
      final year = card.item.releaseYear;
      if (year != null) {
        grouped.putIfAbsent(year, () => []).add(card);
      } else {
        noYear.add(card);
      }
    }

    final sortedYears = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final year in sortedYears) {
      grouped[year] = sortBrowseCards(grouped[year]!, yearlySort);
    }

    return BrowseYearGroups(
      byYear: grouped,
      noYear: sortBrowseCards(noYear, yearlySort),
      sortedYears: sortedYears,
    );
  }
}
