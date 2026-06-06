import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.';
  });

  group('Phase 5 — Reliability & Offline Completeness Tests', () {
    test('MarkdownParser rescues values from broken YAML front-matter', () {
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

    test('MarkdownParser does not persist registry default CDN URL to YAML', () {
      final registry = WorksRegistry.getWorkById('shigatsu_2011');
      expect(registry, isNotNull);
      expect(registry!.posterPath, startsWith('http'));

      final item = createItem(
        workId: 'shigatsu_2011',
        title: '4월은 너의 거짓말',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        workStatus: '완결',
        myStatus: '전부 봄',
        rating: 5.0,
        posterPath: registry.posterPath,
        memorableQuotes: [],
        review: 'Great.',
        isHallOfFame: true,
        tags: [],
      );

      expect(MarkdownParser.shouldPersistPosterToYaml(item), isFalse);

      final serialized = MarkdownParser.serialize(item);
      expect(serialized, isNot(contains('poster:')));
    });

    test('MarkdownParser persists user-customized URL and posters/ relative path', () {
      final customUrlItem = createItem(
        workId: 'shigatsu_2011',
        title: '4월은 너의 거짓말',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        posterPath: 'https://example.com/my-custom-poster.jpg',
        memorableQuotes: [],
        review: '',
      );
      expect(MarkdownParser.shouldPersistPosterToYaml(customUrlItem), isTrue);
      final customSerialized = MarkdownParser.serialize(customUrlItem);
      expect(
        customSerialized,
        contains('poster: "https://example.com/my-custom-poster.jpg"'),
      );

      final localItem = createItem(
        workId: 'shigatsu_2011',
        title: '4월은 너의 거짓말',
        category: MediaCategory.manga,
        domain: AppDomain.subculture,
        posterPath: 'posters/custom_poster.jpg',
        memorableQuotes: [],
        review: 'Excellent.',
      );
      expect(MarkdownParser.shouldPersistPosterToYaml(localItem), isTrue);
      final localSerialized = MarkdownParser.serialize(localItem);
      expect(localSerialized, contains('poster: "posters/custom_poster.jpg"'));
    });

    test('MarkdownParser deserializes custom poster path prioritizing it over registry defaults', () async {
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

      final serialized = MarkdownParser.serialize(item);
      expect(serialized, contains('poster: "posters/custom_poster.jpg"'));
      expect(serialized, contains('creator: "아라카와 나오시"'));
      expect(serialized, contains('release_year: 2011'));

      await WorksRegistry.loadCachedRegistry();
      final deserialized = MarkdownParser.deserialize(serialized, '4월은 너의 거짓말');

      expect(deserialized.posterPath, equals('posters/custom_poster.jpg'));
      expect(deserialized.creator, equals('아라카와 나오시'));
      expect(deserialized.releaseYear, equals(2011));
    });
  });
}
