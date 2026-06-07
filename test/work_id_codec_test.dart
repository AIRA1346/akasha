import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/work_id_codec.dart';

void main() {
  group('WorkIdCodec — master ID rules', () {
    test('parses slug-based manga id', () {
      final parsed = WorkIdCodec.parse('sub_manga_kimetsu-no-yaiba_2016');
      expect(parsed, isNotNull);
      expect(parsed!.domain, AppDomain.subculture);
      expect(parsed.category, MediaCategory.manga);
      expect(parsed.identifierType, WorkIdIdentifierType.slug);
      expect(parsed.identifier, 'kimetsu-no-yaiba');
      expect(parsed.releaseYear, 2016);
      expect(parsed.shardKey, 'manga_K');
    });

    test('parses steam app id game entry', () {
      final parsed = WorkIdCodec.parse('gen_game_appid1245620_2022');
      expect(parsed, isNotNull);
      expect(parsed!.identifierType, WorkIdIdentifierType.steamAppId);
      expect(parsed.identifier, 'appid1245620');
      expect(parsed.shardKey, startsWith('game_steam_'));
    });

    test('parses slug-based webtoon id', () {
      final parsed = WorkIdCodec.parse('sub_webtoon_solo-leveling_2018');
      expect(parsed, isNotNull);
      expect(parsed!.category, MediaCategory.webtoon);
      expect(parsed.shardKey, 'webtoon_S');
    });

    test('buildCustom generates custom token id', () {
      final id = WorkIdCodec.buildCustom(
        domain: AppDomain.subculture,
        category: MediaCategory.animation,
        releaseYear: 2026,
        suffix: 'abc123',
      );
      expect(id, 'sub_animation_custom_abc123_2026');
      expect(WorkIdCodec.isMasterFormat(id), isTrue);
    });
  });
}
