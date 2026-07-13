import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/models/enums.dart';

void main() {
  group('RegistryWork.fromJson', () {
    test('parses valid work JSON correctly', () {
      final jsonMap = {
        'workId': 'custom_game_id',
        'title': '커스텀 테스트 게임',
        'category': 'game',
        'domain': 'subculture',
        'creator': '테스트 제작사',
        'releaseYear': 2026,
        'tags': ['테스트', '인디'],
      };

      final work = RegistryWork.fromJson(jsonMap);

      expect(work.workId, 'custom_game_id');
      expect(work.title, '커스텀 테스트 게임');
      expect(work.category, MediaCategory.game);
      expect(work.domain, AppDomain.subculture);
      expect(work.creator, '테스트 제작사');
      expect(work.releaseYear, 2026);
      expect(work.tags, contains('테스트'));
    });

    test('ignores legacy Tier 1 presentation fields', () {
      final work = RegistryWork.fromJson({
        'workId': 'legacy_presentation',
        'title': '레거시 작품',
        'category': 'movie',
        'domain': 'subculture',
        'description': '글로벌 설명',
        'posterPath': 'https://image.tmdb.org/t/p/w500/legacy.jpg',
      });

      expect(work.description, isEmpty);
      expect(work.posterPath, isNull);
    });

    test('defaults on invalid category/domain', () {
      final jsonMap = {
        'workId': 'invalid_test',
        'title': '잘못된 카테고리 테스트',
        'category': 'nonsense',
        'domain': 'fantasy',
      };

      final work = RegistryWork.fromJson(jsonMap);

      expect(work.category, MediaCategory.manga);
      expect(work.domain, AppDomain.subculture);
    });
  });
}
