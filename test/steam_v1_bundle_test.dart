import 'dart:convert';
import 'dart:io';

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
    test('bundled catalog matches manifest entryCount after prefetch', () {
      final manifestFile = File('akasha-db/manifest.json');
      expect(manifestFile.existsSync(), isTrue);
      final manifest = json.decode(manifestFile.readAsStringSync()) as Map;
      final entryCount = manifest['entryCount'] as int;
      expect(WorksRegistry.allWorks.length, entryCount);
    });

    test('legacy sub_* resolves to wk_ via legacy_aliases', () {
      final solo = WorksRegistry.getWorkById('sub_manga_solo-leveling_2018');
      expect(solo, isNotNull);
      expect(solo!.workId, startsWith('wk_'));
      expect(solo.category, MediaCategory.webtoon);
    });

    test('webtoon category filter returns wk_ works (probes hidden)', () async {
      final works = await WorksRegistry.getFilteredWorks(
        category: MediaCategory.webtoon,
      );
      expect(works.length, greaterThanOrEqualTo(2));
      expect(works.every((w) => w.workId.startsWith('wk_')), isTrue);
    });
  });
}
