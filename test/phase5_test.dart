import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/services/image_cache_service.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // path_provider MethodChannel Mocking
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.'; // 임의의 로컬 디렉토리 경로
  });

  group('Phase 5 — Reliability & Offline Completeness Tests', () {
    test('MarkdownParser rescues values from broken YAML front-matter', () {
      // 일부러 닫는 따옴표와 콜론 간격을 엉망으로 만든 깨진 YAML 데이터
      const brokenYamlContent = '''
---
work_id: "eldenring_2022
title: "엘든 링 (문법 깨짐)
category: game
domain: generalCulture
rating: 4.5
work_status: "출시됨"
my_status: "플레이 중"
is_hall_of_fame: true
---

# 🎬 명장면 & 명대사
> "나는 Malenia"

# 📖 감상문
정말 재미있다.
''';

      // 파싱 실패를 감지하더라도 비상 정규식 파서가 동작하여 값을 구출해야 함
      final item = MarkdownParser.deserialize(brokenYamlContent, '대체 타이틀');

      expect(item.workId, 'eldenring_2022');
      expect(item.title, '엘든 링 (문법 깨짐)');
      expect(item.category, MediaCategory.game);
      expect(item.domain, AppDomain.generalCulture);
      expect(item.rating, 4.5);
      expect(item.isHallOfFame, true);
      expect(item.myStatusLabel, '플레이 중');
      expect(item.workStatusLabel, '출시됨');
      expect(item.memorableQuotes, contains('"나는 Malenia"'));
      expect(item.review, '정말 재미있다.');
    });

    test('ImageCacheService generates unique hash-naming files for cache invalidation', () async {
      // path_provider가 기동되지 않는 순수 테스트용 해시코드 검증
      final service = ImageCacheService();
      
      // 동일 URL -> 동일 해시
      final url1 = 'https://example.com/poster1.jpg';
      final url2 = 'https://example.com/poster1.jpg';
      
      // 다른 URL -> 다른 해시
      final url3 = 'https://example.com/poster2.jpg';

      // ImageCacheService 내부의 비공개 _getUrlHash 메소드를 간접 테스트하기 위해
      // getLocalPosterFile의 파일명이 유일하고 유효한지 파일 basename 비교
      final file1 = await service.getLocalPosterFile('test_work', url1);
      final file2 = await service.getLocalPosterFile('test_work', url2);
      final file3 = await service.getLocalPosterFile('test_work', url3);

      expect(file1, isNotNull);
      expect(file2, isNotNull);
      expect(file3, isNotNull);

      expect(file1!.path, equals(file2!.path)); // 동일 이미지 주소면 동일한 로컬 파일명
      expect(file1.path, isNot(equals(file3!.path))); // 다른 이미지 주소면 무효화(새 파일명)
      expect(file1.path, contains('test_work_')); // prefix 확인
    });

    test('MarkdownParser serializes and deserializes custom poster path prioritizing it over registry defaults', () async {
      // 1. 커스텀 포스터 정보가 담긴 아이템 생성
      final item = createItem(
        workId: 'shigatsu_2011',
        title: '4월은 너의 거짓말',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        workStatus: '완결',
        myStatus: '전부 봄',
        creator: '아라카와 나오시',
        releaseYear: 2011,
        rating: 5.0,
        posterPath: 'posters/custom_poster.jpg',
        description: 'Mock description',
        memorableQuotes: [],
        review: 'Excellent.',
        isHallOfFame: true,
        tags: [],
      );

      // 직렬화 검증 (프론트 매터에 커스텀 값들이 작성되어야 함)
      final serialized = MarkdownParser.serialize(item);
      expect(serialized, contains('poster: "posters/custom_poster.jpg"'));
      expect(serialized, contains('creator: "아라카와 나오시"'));
      expect(serialized, contains('release_year: 2011'));

      // 역직렬화 검증 (사전 데이터가 존재해도 사용자가 수정한 커스텀 포스터 주소가 유지되는지)
      await WorksRegistry.loadCachedRegistry();
      final deserialized = MarkdownParser.deserialize(serialized, '4월은 너의 거짓말');

      expect(deserialized.posterPath, equals('posters/custom_poster.jpg'));
      expect(deserialized.creator, equals('아라카와 나오시'));
      expect(deserialized.releaseYear, equals(2011));
    });
  });
}
