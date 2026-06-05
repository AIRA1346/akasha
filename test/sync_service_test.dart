import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/models/enums.dart';

void main() {
  group('WorksRegistry & RegistryWork JSON Merge Test', () {
    test('RegistryWork.fromJson parses valid work JSON correctly', () {
      final jsonMap = {
        'workId': 'custom_game_id',
        'title': '커스텀 테스트 게임',
        'category': 'game',
        'domain': 'subculture',
        'creator': '테스트 제작사',
        'releaseYear': 2026,
        'description': '테스트용 설명',
        'tags': ['테스트', '인디'],
        'posterPath': 'posters/test.png'
      };

      final work = RegistryWork.fromJson(jsonMap);

      expect(work.workId, 'custom_game_id');
      expect(work.title, '커스텀 테스트 게임');
      expect(work.category, MediaCategory.game);
      expect(work.domain, AppDomain.subculture);
      expect(work.creator, '테스트 제작사');
      expect(work.releaseYear, 2026);
      expect(work.tags, contains('테스트'));
      expect(work.posterPath, 'posters/test.png');
    });

    test('RegistryWork.fromJson defaults on invalid category/domain', () {
      final jsonMap = {
        'workId': 'invalid_test',
        'title': '잘못된 카테고리 테스트',
        'category': 'nonsense', // 존재하지 않는 카테고리
        'domain': 'fantasy',    // 존재하지 않는 도메인
      };

      final work = RegistryWork.fromJson(jsonMap);

      expect(work.category, MediaCategory.manga); // manga로 폴백
      expect(work.domain, AppDomain.subculture); // subculture로 폴백
    });
  });
}
