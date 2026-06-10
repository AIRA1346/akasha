import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/format_slot.dart';
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

  test('franchise card appears in every non-hidden format slot category', () {
    final frieren = BrowseCard(
      item: createItem(
        workId: 'sub_manga_frieren_2020',
        title: '장송의 프리렌',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      ),
      franchiseId: 'franchise_frieren',
      formatSlots: const [
        FormatSlot(
          workId: 'sub_manga_frieren_2020',
          category: MediaCategory.manga,
          shortLabel: '만화',
          state: FormatSlotState.catalogOnly,
        ),
        FormatSlot(
          workId: 'sub_animation_frieren_2023',
          category: MediaCategory.animation,
          shortLabel: '애니',
          state: FormatSlotState.catalogOnly,
        ),
      ],
    );

    final groups =
        BrowseCategoryGroups.fromCards([frieren], SortCriteria.titleAsc);

    expect(groups.byCategory[MediaCategory.manga], hasLength(1));
    expect(groups.byCategory[MediaCategory.animation], hasLength(1));
    expect(groups.byCategory[MediaCategory.manga]!.first, frieren);
    expect(groups.byCategory[MediaCategory.animation]!.first, frieren);
  });

  test('restrictToCategories limits franchise card to filtered media', () {
    final frieren = BrowseCard(
      item: createItem(
        workId: 'sub_manga_frieren_2020',
        title: '장송의 프리렌',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      ),
      formatSlots: const [
        FormatSlot(
          workId: 'sub_manga_frieren_2020',
          category: MediaCategory.manga,
          shortLabel: '만화',
          state: FormatSlotState.catalogOnly,
        ),
        FormatSlot(
          workId: 'sub_animation_frieren_2023',
          category: MediaCategory.animation,
          shortLabel: '애니',
          state: FormatSlotState.catalogOnly,
        ),
      ],
    );

    final groups = BrowseCategoryGroups.fromCards(
      [frieren],
      SortCriteria.titleAsc,
      restrictToCategories: {MediaCategory.manga},
    );

    expect(groups.orderedCategories, [MediaCategory.manga]);
    expect(groups.byCategory[MediaCategory.animation], isNull);
  });
}
