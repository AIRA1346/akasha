import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/my_library_pipeline.dart';
import 'package:akasha/utils/archived_works_query.dart';

void main() {
  group('ArchivedWorksQuery', () {
    ContentItem userItem({
      required String workId,
      String title = 'Test',
    }) =>
        ContentItem(
          workId: workId,
          title: title,
          category: MediaCategory.manga,
          domain: AppDomain.subculture,
        );

    test('isArchivedBrowseCard true when user item exists in library', () {
      final item = userItem(workId: 'sub_manga_demo_2020');
      item.filePath = '/vault/manga/demo.md';
      final items = [item];
      final card = BrowseCard(item: items.first);
      expect(ArchivedWorksQuery.isArchivedBrowseCard(card, items), isTrue);
    });

    test('isArchivedBrowseCard false for virtual card without user archive', () {
      final virtual = ContentItem(
        workId: 'sub_manga_registry-only_2021',
        title: 'Registry Only',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
      );
      final card = BrowseCard(item: virtual);
      expect(
        ArchivedWorksQuery.isArchivedBrowseCard(card, const []),
        isFalse,
      );
    });

    test('MyLibraryPipeline excludes registry-only virtual cards', () {
      final archived = userItem(
        workId: 'sub_manga_archived_2022',
        title: 'Archived',
      );
      archived.filePath = '/vault/manga/archived.md';
      final cards = MyLibraryPipeline.build([archived]);
      expect(cards, hasLength(1));
      expect(cards.first.item.title, 'Archived');
    });
  });
}
