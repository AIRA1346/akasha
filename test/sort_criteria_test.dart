import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';

BrowseCard _card(String title, {double rating = 0}) {
  return BrowseCard(
    item: createItem(
      workId: 'wk_$title',
      title: title,
      category: MediaCategory.manga,
      rating: rating,
    ),
  );
}

void main() {
  group('SortCriteria.manualOrder', () {
    test('sortBrowseCards preserves pipeline order', () {
      final cards = [_card('Charlie'), _card('Alpha'), _card('Bravo')];
      final sorted = sortBrowseCards(cards, SortCriteria.manualOrder);
      expect(sorted.map((c) => c.item.title).toList(),
          ['Charlie', 'Alpha', 'Bravo']);
    });

    test('titleAsc still reorders curated view', () {
      final cards = [_card('Charlie'), _card('Alpha'), _card('Bravo')];
      final sorted = sortBrowseCards(cards, SortCriteria.titleAsc);
      expect(sorted.map((c) => c.item.title).toList(),
          ['Alpha', 'Bravo', 'Charlie']);
    });

    test('curatedLibraryCriteria includes manualOrder first', () {
      expect(
        SortCriteria.curatedLibraryCriteria.first,
        SortCriteria.manualOrder,
      );
      expect(
        SortCriteria.standardViewCriteria,
        isNot(contains(SortCriteria.manualOrder)),
      );
    });
  });
}
