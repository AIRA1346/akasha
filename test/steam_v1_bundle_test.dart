import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/works_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.';
  });

  setUpAll(() async {
    await WorksRegistry.init();
    await WorksRegistry.prefetchMasterCatalog();
  });

  group('Steam v1 bundle smoke (dogfood pre-check)', () {
    test('bundled catalog exposes 370 works after prefetch', () {
      expect(WorksRegistry.allWorks.length, 370);
    });

    test('webtoon migration resolves legacy manga work_id', () {
      final solo = WorksRegistry.getWorkById('sub_manga_solo-leveling_2018');
      expect(solo, isNotNull);
      expect(solo!.workId, 'sub_webtoon_solo-leveling_2018');
      expect(solo.category, MediaCategory.webtoon);
      expect(solo.posterPath, startsWith('http'));
    });

    test('webtoon category filter returns migrated pair', () async {
      final works = await WorksRegistry.getFilteredWorks(
        category: MediaCategory.webtoon,
      );
      expect(works.length, 2);
      final ids = works.map((w) => w.workId).toSet();
      expect(ids, contains('sub_webtoon_solo-leveling_2018'));
      expect(ids, contains('sub_webtoon_tower-of-god_2010'));
    });
  });
}
