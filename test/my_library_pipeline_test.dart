import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/services/browse_pipeline.dart';
import 'package:akasha/data/adapters/works_registry_adapter.dart';
import 'package:akasha/services/my_library_pipeline.dart';
import 'package:akasha/utils/helpers.dart';

import 'support/registry_test_harness.dart';

void main() {
  setUpAll(() async {
    await initRegistryForFranchiseFixtures();
  });

  tearDownAll(clearRegistryTestFetcher);

  AkashaItem archivedItem({
    required String workId,
    required String title,
    required MediaCategory category,
  }) {
    final item = createItem(
      workId: workId,
      title: title,
      category: category,
      domain: AppDomain.subculture,
      myStatus: ContentMyStatus.notStarted.label,
      workStatus: ContentWorkStatus.completed.label,
      rating: 0.0,
    );
    item.filePath = '/vault/${category.name}/$title.md';
    return item;
  }

  group('MyLibraryPipeline', () {
    late MyLibraryPipeline pipeline;

    setUp(() {
      pipeline = MyLibraryPipeline(WorksRegistryAdapter());
    });

    test('filter mode matches archived vault items with fusion', () {
      final manga = archivedItem(
        workId: 'sub_manga_rezero_2014',
        title: 'Re:제로 만화',
        category: MediaCategory.manga,
      );
      final anime = archivedItem(
        workId: 'sub_animation_rezero-anime_2016',
        title: 'Re:제로 애니',
        category: MediaCategory.animation,
      );

      final library = PersonalLibraryConfig.masterArchive();
      final cards = pipeline.build(
        [manga, anime],
        library: library,
      );

      expect(cards, hasLength(1));
      expect(cards.first.franchiseId, 'franchise_rezero');
    });

    test('curated shows only member works', () {
      final manga = archivedItem(
        workId: 'sub_manga_rezero_2014',
        title: 'Re:제로 만화',
        category: MediaCategory.manga,
      );
      final anime = archivedItem(
        workId: 'sub_animation_rezero-anime_2016',
        title: 'Re:제로 애니',
        category: MediaCategory.animation,
      );
      final other = archivedItem(
        workId: 'sub_manga_86-eighty-six_2017',
        title: '86',
        category: MediaCategory.manga,
      );

      final library = PersonalLibraryConfig(
        id: 'lib_test',
        name: '테스트',
        mode: PersonalLibraryMode.curated,
        memberOrder: [manga.workId, other.workId],
      );

      final cards = pipeline.build(
        [manga, anime, other],
        library: library,
      );

      expect(cards, hasLength(2));
      expect(cards.map((c) => c.item.workId), contains(manga.workId));
      expect(cards.map((c) => c.item.workId), contains(other.workId));
      expect(cards.any((c) => c.franchiseId == 'franchise_rezero'), isFalse);
    });

    test('curated scoped fusion when manga and anime both members', () {
      final manga = archivedItem(
        workId: 'sub_manga_rezero_2014',
        title: 'Re:제로 만화',
        category: MediaCategory.manga,
      );
      final anime = archivedItem(
        workId: 'sub_animation_rezero-anime_2016',
        title: 'Re:제로 애니',
        category: MediaCategory.animation,
      );

      final library = PersonalLibraryConfig(
        id: 'lib_test',
        name: '테스트',
        mode: PersonalLibraryMode.curated,
        memberOrder: [manga.workId, anime.workId],
      );

      final cards = pipeline.build(
        [manga, anime],
        library: library,
      );

      expect(cards, hasLength(1));
      expect(cards.first.franchiseId, 'franchise_rezero');
      expect(cards.first.formatSlots, hasLength(2));
    });

    test('curated empty memberOrder yields no cards', () {
      final library = PersonalLibraryConfig(
        id: 'lib_empty',
        name: '빈 서재',
        mode: PersonalLibraryMode.curated,
      );
      expect(
        pipeline.build(const [], library: library),
        isEmpty,
      );
    });

    test('curated respects category filter on members', () {
      final manga = archivedItem(
        workId: 'sub_manga_rezero_2014',
        title: 'Re:제로 만화',
        category: MediaCategory.manga,
      );
      final other = archivedItem(
        workId: 'sub_manga_86-eighty-six_2017',
        title: '86',
        category: MediaCategory.manga,
      );

      final library = PersonalLibraryConfig(
        id: 'lib_test',
        name: '테스트',
        mode: PersonalLibraryMode.curated,
        memberOrder: [manga.workId, other.workId],
      );

      final cards = pipeline.build(
        [manga, other],
        library: library,
        filters: const BrowseFilterState(
          categories: {MediaCategory.animation},
        ),
      );

      expect(cards, isEmpty);
    });

    test('curated sorts by memberOrder', () {
      final first = archivedItem(
        workId: 'sub_manga_86-eighty-six_2017',
        title: '86',
        category: MediaCategory.manga,
      );
      final second = archivedItem(
        workId: 'sub_manga_rezero_2014',
        title: 'Re:제로',
        category: MediaCategory.manga,
      );

      final library = PersonalLibraryConfig(
        id: 'lib_test',
        name: '테스트',
        mode: PersonalLibraryMode.curated,
        memberOrder: [second.workId, first.workId],
      );

      final cards = pipeline.build(
        [first, second],
        library: library,
      );

      expect(cards.first.item.workId, second.workId);
      expect(cards.last.item.workId, first.workId);
    });
  });
}
