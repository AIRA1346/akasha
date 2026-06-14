import 'package:test/test.dart';

import '../tool/discovery/wikidata_ko_fetch.dart';

void main() {
  group('wikidataKoLabelSparql', () {
    test('requires Korean label and manga P31', () {
      final q = wikidataKoLabelSparql(
        category: 'manga',
        limit: 10,
        offset: 0,
      );
      expect(q, contains('FILTER(LANG(?itemLabelKo) = "ko")'));
      expect(q, contains('wd:Q21198342'));
      expect(q, contains('LIMIT 10'));
      expect(q, contains('OFFSET 0'));
    });

    test('animation includes multiple P31 values', () {
      final q = wikidataKoLabelSparql(
        category: 'animation',
        limit: 5,
        offset: 100,
      );
      expect(q, contains('wd:Q63952888'));
      expect(q, contains('wd:Q20650540'));
      expect(q, contains('OFFSET 100'));
    });

    test('rejects unknown category', () {
      expect(
        () => p31QidsForCategory('podcast'),
        throwsArgumentError,
      );
    });
  });

  group('wikidataKoSupportedCategories', () {
    test('covers all main media types', () {
      expect(wikidataKoSupportedCategories, contains('manga'));
      expect(wikidataKoSupportedCategories, contains('animation'));
      expect(wikidataKoSupportedCategories, contains('movie'));
      expect(wikidataKoSupportedCategories, contains('book'));
      expect(wikidataKoSupportedCategories, contains('drama'));
      expect(wikidataKoSupportedCategories, contains('game'));
    });
  });
}
