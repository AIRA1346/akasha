import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/home_auto_archive.dart';
import 'package:akasha/services/franchise_registry.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:flutter_test/flutter_test.dart';

RegistryWork _work(String workId, {String title = 'Test'}) {
  return RegistryWork(
    workId: workId,
    title: title,
    category: MediaCategory.manga,
    domain: AppDomain.subculture,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await WorksRegistry.init();
    await FranchiseRegistry.init();
  });

  group('HomeAutoArchive.pendingRegistryWorks', () {
    test('skips works already in vault by workId', () {
      final pending = HomeAutoArchive.pendingRegistryWorks(
        registryWorks: [_work('wk_a'), _work('wk_b')],
        localWorkIds: {'wk_a'},
        localKeys: const {},
      );

      expect(pending.map((w) => w.workId), ['wk_b']);
    });

    test('skips franchise non-primary members', () {
      final pending = HomeAutoArchive.pendingRegistryWorks(
        registryWorks: [
          _work('sub_book_86-light-novel_2016'),
          _work('sub_manga_86-eighty-six_2017'),
        ],
        localWorkIds: const {},
        localKeys: const {},
      );

      expect(
        pending.map((w) => w.workId),
        ['sub_manga_86-eighty-six_2017'],
      );
    });

    test('skips sibling when primary already archived', () {
      final pending = HomeAutoArchive.pendingRegistryWorks(
        registryWorks: [_work('sub_book_86-light-novel_2016')],
        localWorkIds: {'sub_manga_86-eighty-six_2017'},
        localKeys: const {},
      );

      expect(pending, isEmpty);
    });
  });
}
