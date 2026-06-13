import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/services/browse_pipeline.dart';
import 'package:akasha/services/my_library_pipeline.dart';
import 'package:akasha/utils/archived_works_query.dart';

import 'fakes/fake_registry_port.dart';

void main() {
  final pipeline = MyLibraryPipeline(FakeRegistryPort());

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
      final cards = pipeline.build(
        [archived],
        library: PersonalLibraryConfig.masterArchive(),
      );
      expect(cards, hasLength(1));
      expect(cards.first.item.title, 'Archived');
    });

    test('MyLibraryPipeline applies top filter chips on master_archive', () {
      final manga = userItem(workId: 'sub_manga_a', title: 'Manga A');
      manga.filePath = '/vault/manga/a.md';
      final movie = ContentItem(
        workId: 'sub_movie_b',
        title: 'Movie B',
        category: MediaCategory.movie,
        domain: AppDomain.generalCulture,
      );
      movie.filePath = '/vault/movie/b.md';
      final cards = pipeline.build(
        [manga, movie],
        library: PersonalLibraryConfig.masterArchive(),
        filters: const BrowseFilterState(
          categories: {MediaCategory.manga},
        ),
      );
      expect(cards, hasLength(1));
      expect(cards.first.item.title, 'Manga A');
    });

    test('MyLibraryPipeline filters by category in filter state', () {
      final manga = userItem(workId: 'sub_manga_a', title: 'Manga A');
      manga.filePath = '/vault/manga/a.md';
      final movie = ContentItem(
        workId: 'sub_movie_b',
        title: 'Movie B',
        category: MediaCategory.movie,
        domain: AppDomain.generalCulture,
      );
      movie.filePath = '/vault/movie/b.md';
      final cards = pipeline.build(
        [manga, movie],
        library: PersonalLibraryConfig.masterArchive(),
        filters: const BrowseFilterState(
          categories: {MediaCategory.manga},
        ),
      );
      expect(cards, hasLength(1));
      expect(cards.first.item.title, 'Manga A');
    });
  });
}
