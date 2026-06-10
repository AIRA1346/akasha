import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/browse_category_groups.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BrowseCategoryGroups groups all cards by media category', () {
    final cards = [
      BrowseCard(
        item: createItem(
          workId: 'wk_manga',
          title: '만화 A',
          category: MediaCategory.manga,
          domain: AppDomain.subculture,
        ),
      ),
      BrowseCard(
        item: createItem(
          workId: 'wk_game',
          title: '게임 B',
          category: MediaCategory.game,
          domain: AppDomain.subculture,
        ),
      ),
      BrowseCard(
        item: createItem(
          workId: 'wk_manga2',
          title: '만화 C',
          category: MediaCategory.manga,
          domain: AppDomain.subculture,
        ),
      ),
    ];

    final groups = BrowseCategoryGroups.fromCards(cards, SortCriteria.titleAsc);

    expect(groups.orderedCategories.first, MediaCategory.manga);
    expect(groups.byCategory[MediaCategory.manga], hasLength(2));
    expect(groups.byCategory[MediaCategory.game], hasLength(1));
  });
}
