import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/config/catalog_locale.dart';
import 'package:akasha/models/registry_models.dart';
import 'package:akasha/models/work_titles.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/registry_search_utils.dart';
import 'package:akasha/utils/work_title_resolver.dart';

void main() {
  group('WorkTitles', () {
    test('resolveForLocale uses fallback chain', () {
      final withKo = WorkTitles({
        'ko': '귀멸의 칼날',
        'en': 'Demon Slayer',
      });
      expect(
        withKo.resolveForLocale(CatalogLocale.ko, legacyTitle: ''),
        '귀멸의 칼날',
      );

      final enFallback = WorkTitles({
        'en': 'Demon Slayer',
        'ja': '鬼滅の刃',
      });
      expect(
        enFallback.resolveForLocale(CatalogLocale.ko, legacyTitle: '레거시'),
        'Demon Slayer',
      );
      expect(
        enFallback.resolveForLocale(CatalogLocale.en, legacyTitle: ''),
        'Demon Slayer',
      );
    });
  });

  group('buildWorkSearchTokens', () {
    test('includes all title variants and aliases', () {
      final tokens = buildWorkSearchTokens(
        legacyTitle: '귀멸의 칼날',
        titles: WorkTitles({
          'en': 'Demon Slayer',
          'ja': '鬼滅の刃',
        }),
        aliases: ['KNY'],
      );
      expect(tokens.any((t) => t.contains('demonslayer')), isTrue);
      expect(tokens.any((t) => t.contains('鬼滅')), isTrue);
      expect(tokens, contains('KNY'));
    });
  });

  group('RegistryWork v3', () {
    test('parses titles and externalIds from extensions', () {
      final work = RegistryWork.fromJson({
        'workId': 'sub_manga_test_2020',
        'title': '테스트',
        'category': 'manga',
        'domain': 'subculture',
        'titles': {'en': 'Test Work'},
        'extensions': {'anilistId': 42, 'steamAppId': '730'},
      });

      expect(work.titles['en'], 'Test Work');
      expect(work.externalIds['anilist'], '42');
      expect(work.externalIds['steam'], '730');
      expect(work.searchTokens, isNotEmpty);
    });

    test('search matches english title when legacy is korean', () {
      final work = RegistryWork.fromJson({
        'workId': 'sub_manga_kimetsu_2016',
        'title': '귀멸의 칼날',
        'category': 'manga',
        'domain': 'subculture',
        'titles': {
          'ko': '귀멸의 칼날',
          'en': 'Demon Slayer Kimetsu no Yaiba',
        },
      });

      expect(
        work.searchTokens.any((t) => registryTokenMatchesQuery(t, 'Demon Slayer')),
        isTrue,
      );
    });
  });

  group('RegistrySearchIndexEntry v3', () {
    test('registryEntryMatchesQuery uses searchTokens', () {
      final entry = RegistrySearchIndexEntry.fromJson({
        'workId': 'sub_manga_x_2020',
        'title': '원피스',
        'shardId': 'manga_O',
        'category': 'manga',
        'domain': 'subculture',
        'searchTokens': ['onepiece', '원피스', 'one piece'],
      });

      expect(registryEntryMatchesQuery(entry, 'one piece'), isTrue);
      expect(registryEntryMatchesQuery(entry, 'naruto'), isFalse);
    });
  });
}
