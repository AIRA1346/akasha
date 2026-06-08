import 'package:flutter_test/flutter_test.dart';

import '../tool/dedupe_utils.dart';

void main() {
  group('normalizeTitle', () {
    test('strips case punctuation and spaces', () {
      expect(normalizeTitle('One Piece!'), 'onepiece');
      expect(normalizeTitle('원피스'), '원피스');
      expect(normalizeTitle('  Hunter × Hunter  '), 'hunterhunter');
    });
  });

  group('legacySlugStem', () {
    test('parses sub_manga slug with year', () {
      expect(
        legacySlugStem('sub_manga_one-piece_1997'),
        'one-piece',
      );
    });

    test('strips media suffixes', () {
      expect(
        legacySlugStem('sub_animation_demon-slayer-anime_2019'),
        'demon-slayer',
      );
    });

    test('returns null for wk_ ids', () {
      expect(legacySlugStem('wk_00000001'), isNull);
    });
  });

  group('pairKey', () {
    test('is order independent', () {
      expect(pairKey('wk_00000002', 'wk_00000001'), 'wk_00000001|wk_00000002');
      expect(pairKey('wk_00000001', 'wk_00000002'), 'wk_00000001|wk_00000002');
    });
  });
}
