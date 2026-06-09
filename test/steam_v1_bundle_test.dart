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
    test('bundled catalog exposes 430 works after prefetch', () {
      expect(WorksRegistry.allWorks.length, 430);
    });

    test('legacy sub_* resolves to wk_ via legacy_aliases', () {
      final solo = WorksRegistry.getWorkById('sub_manga_solo-leveling_2018');
      expect(solo, isNotNull);
      expect(solo!.workId, startsWith('wk_'));
      expect(solo.category, MediaCategory.webtoon);
      expect(solo.posterPath, startsWith('http'));
    });

    test('webtoon category filter returns wk_ pair plus scale stubs', () async {
      final works = await WorksRegistry.getFilteredWorks(
        category: MediaCategory.webtoon,
      );
      expect(works.length, 5);
      // 정식 카탈로그 2작 (솔로 레벨링 · 신의 탑) — 나머지는 A5 Scale sub_* 스텁
      final canonical = works.where((w) => w.workId.startsWith('wk_'));
      expect(canonical.length, 2);
    });
  });
}
