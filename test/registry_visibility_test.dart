import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/services/franchise_registry.dart';
import 'package:akasha/services/registry_visibility_service.dart';
import 'package:akasha/services/user_registry_preferences.dart';
import 'package:akasha/services/works_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await WorksRegistry.init();
    await FranchiseRegistry.init();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserRegistryPreferences.instance.load();
  });

  group('RegistryVisibilityService', () {
    test('hides sibling media when user archived primary manga 86', () {
      const userIds = {'sub_manga_86-eighty-six_2017'};

      expect(
        RegistryVisibilityService.shouldMaterializeVirtual(
          workId: 'sub_book_86-light-novel_2016',
          userWorkIds: userIds,
        ),
        isFalse,
      );
      expect(
        RegistryVisibilityService.shouldMaterializeVirtual(
          workId: 'sub_manga_86-eighty-six_2017',
          userWorkIds: userIds,
        ),
        isFalse,
      );
    });

    test('grid always hides franchise siblings', () {
      const userIds = {'sub_manga_86-eighty-six_2017'};

      expect(
        RegistryVisibilityService.shouldMaterializeVirtual(
          workId: 'sub_book_86-light-novel_2016',
          userWorkIds: userIds,
        ),
        isFalse,
      );
    });

    test('respects user hidden work ids', () async {
      await UserRegistryPreferences.instance
          .hideWork('sub_book_86-light-novel_2016');

      expect(
        RegistryVisibilityService.shouldMaterializeVirtual(
          workId: 'sub_book_86-light-novel_2016',
          userWorkIds: const {},
        ),
        isFalse,
      );
    });

    test('auto archive skips non-primary franchise members', () {
      expect(
        RegistryVisibilityService.shouldAutoArchiveRegistryWork(
          workId: 'sub_book_86-light-novel_2016',
          userWorkIds: const {},
        ),
        isFalse,
      );
      expect(
        RegistryVisibilityService.shouldAutoArchiveRegistryWork(
          workId: 'sub_manga_86-eighty-six_2017',
          userWorkIds: const {},
        ),
        isTrue,
      );
    });

    test('auto archive skips sibling when primary already archived', () {
      const userIds = {'sub_manga_86-eighty-six_2017'};

      expect(
        RegistryVisibilityService.shouldAutoArchiveRegistryWork(
          workId: 'sub_book_86-light-novel_2016',
          userWorkIds: userIds,
        ),
        isFalse,
      );
    });

    test('remote search hints sibling and hidden separately', () async {
      const userIds = {'sub_manga_86-eighty-six_2017'};

      expect(
        RegistryVisibilityService.remoteSearchHint(
          workId: 'sub_book_86-light-novel_2016',
          userWorkIds: userIds,
        ),
        RegistryRemoteHint.siblingTracked,
      );

      await UserRegistryPreferences.instance
          .hideWork('sub_manga_kimetsu-no-yaiba_2016');
      expect(
        RegistryVisibilityService.remoteSearchHint(
          workId: 'sub_manga_kimetsu-no-yaiba_2016',
          userWorkIds: const {},
        ),
        RegistryRemoteHint.hidden,
      );
    });
  });
}
