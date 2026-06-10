import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../tool/discovery/wikidata_entity_labels.dart';

void main() {
  group('pickKoTitle', () {
    test('prefers label over alias and kowiki', () {
      final pick = pickKoTitle(
        const WikidataEntityLocaleFacts(
          labels: {'ko': '원피스'},
          koAliases: ['해적왕'],
          kowikiTitle: '원피스_(만화)',
        ),
      );
      expect(pick.ko, '원피스');
      expect(pick.source, 'label');
    });

    test('uses kowiki sitelink when label missing', () {
      final pick = pickKoTitle(
        const WikidataEntityLocaleFacts(
          labels: {'en': 'Puella Magi Madoka Magica'},
          kowikiTitle: '마법소녀_마도카☆마기카',
        ),
      );
      expect(pick.ko, '마법소녀 마도카☆마기카');
      expect(pick.source, 'kowiki');
    });

    test('returns null when no plausible ko', () {
      final pick = pickKoTitle(
        const WikidataEntityLocaleFacts(
          labels: {'en': 'Obscure Title'},
        ),
      );
      expect(pick.ko, isNull);
    });
  });

  group('disambiguateRelatedKoTitle', () {
    test('appends season suffix from en title', () {
      expect(
        disambiguateRelatedKoTitle(
          relatedKo: '갤럭시 엔젤',
          titles: {'en': 'Galaxy Angel 2nd'},
        ),
        '갤럭시 엔젤 2nd',
      );
    });
  });

  group('normalizeKowikiSitelinkTitle', () {
    test('replaces underscores with spaces', () {
      expect(
        normalizeKowikiSitelinkTitle('마법소녀_마도카☆마기카'),
        '마법소녀 마도카☆마기카',
      );
    });
  });
}
