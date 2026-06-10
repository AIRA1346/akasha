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
    });

    test('webtoon category filter returns wk_ pair (probes hidden)', () async {
      final works = await WorksRegistry.getFilteredWorks(
        category: MediaCategory.webtoon,
      );
      expect(works.length, 2);
    });
  });
}
