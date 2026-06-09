import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/registry_models.dart';
import 'package:akasha/utils/registry_search_utils.dart';

void main() {
  group('Registry search utils — on-demand shard resolution', () {
    final index = [
      const RegistrySearchIndexEntry(
        workId: 'sub_manga_kimetsu-no-yaiba_2016',
        title: '귀멸의 칼날',
        shardId: 'manga_K',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        creator: '고토게 요시히로',
        tags: ['액션'],
      ),
      const RegistrySearchIndexEntry(
        workId: 'sub_animation_frieren_2023',
        title: '장송의 프리렌',
        shardId: 'animation_F',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
        creator: '야마다 카네히토',
        tags: ['판타지'],
      ),
      const RegistrySearchIndexEntry(
        workId: 'gen_game_minecraft_2011',
        title: '마인크래프트',
        shardId: 'game_M',
        category: MediaCategory.game,
        domain: AppDomain.generalCulture,
      ),
    ];

    test('shardIdsForQuery dedupes entries in the same shard', () {
      final ids = shardIdsForQuery(index, '귀멸');
      expect(ids, {'manga_K'});
    });

    test('shardIdsForQuery matches creator', () {
      final ids = shardIdsForQuery(index, '고토게');
      expect(ids, {'manga_K'});
    });

    test('shardIdsForQuery matches tags', () {
      final ids = shardIdsForQuery(index, '판타지');
      expect(ids, {'animation_F'});
    });

    test('shardIdsForQuery returns empty for blank query', () {
      expect(shardIdsForQuery(index, ''), isEmpty);
      expect(shardIdsForQuery(index, '   '), isEmpty);
    });

    test('registryEntryMatchesQuery is case and space insensitive', () {
      expect(
        registryEntryMatchesQuery(index[1], '프리 렌'),
        isTrue,
      );
    });

    test('registryEntryMatchesQuery strips delimiter variants', () {
      const entry = RegistrySearchIndexEntry(
        workId: 'wk_hunter',
        title: '헌터×헌터',
        shardId: 'manga_H',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        searchTokens: ['헌터×헌터'],
      );
      expect(registryEntryMatchesQuery(entry, '헌터 헌터'), isTrue);
      expect(registryEntryMatchesQuery(entry, '헌터헌터'), isTrue);

      const fate = RegistrySearchIndexEntry(
        workId: 'wk_fate',
        title: '페이트/그랜드 오더',
        shardId: 'game_F',
        category: MediaCategory.game,
        domain: AppDomain.subculture,
        searchTokens: ['페이트/그랜드 오더'],
      );
      expect(registryEntryMatchesQuery(fate, '페이트 그랜드 오더'), isTrue);
    });

    test('shardIdsForFilters returns only matching category shards', () {
      final ids = shardIdsForFilters(
        index,
        category: MediaCategory.animation,
      );
      expect(ids, {'animation_F'});
    });

    test('shardIdsForFilters dedupes and respects domain', () {
      final ids = shardIdsForFilters(
        index,
        domain: AppDomain.generalCulture,
      );
      expect(ids, {'game_M'});
    });

    test('prefetch scope empty when no domain and no category filter', () {
      expect(shardIdsForFilters(index), isEmpty);
    });
  });
}
