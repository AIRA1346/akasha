import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/personal_library_membership_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonalLibraryMembershipService', () {
    late HomePersonalLibraryController controller;
    late PersonalLibraryMembershipService membership;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      controller = HomePersonalLibraryController();
      controller.libraries = [
        PersonalLibraryConfig.masterArchive(),
        PersonalLibraryConfig(
          id: 'lib_a',
          name: '인생 명작',
          mode: PersonalLibraryMode.curated,
        ),
        PersonalLibraryConfig(
          id: 'lib_b',
          name: '읽을 예정',
          mode: PersonalLibraryMode.curated,
        ),
      ];
      membership = PersonalLibraryMembershipService(controller);
    });

    test('addWork appends to memberOrder', () async {
      await membership.addWork('lib_a', 'wk_000000001');
      expect(controller.libraries[1].memberOrder, ['wk_000000001']);
    });

    test('addWork is no-op for duplicate', () async {
      await membership.addWork('lib_a', 'wk_000000001');
      await membership.addWork('lib_a', 'wk_000000001');
      expect(controller.libraries[1].memberOrder, hasLength(1));
    });

    test('librariesContaining returns curated membership', () async {
      await membership.addWork('lib_a', 'wk_000000001');
      await membership.addWork('lib_b', 'wk_000000001');
      expect(
        membership.librariesContaining('wk_000000001'),
        {'lib_a', 'lib_b'},
      );
    });

    test('applyMembershipChanges adds and removes', () async {
      await membership.addWork('lib_a', 'wk_000000001');
      await membership.applyMembershipChanges(
        workId: 'wk_000000001',
        addToLibraryIds: {'lib_b'},
        removeFromLibraryIds: {'lib_a'},
      );
      expect(membership.librariesContaining('wk_000000001'), {'lib_b'});
    });

    test('removeWork drops id from order', () async {
      await membership.addWork('lib_a', 'wk_000000001');
      await membership.addWork('lib_a', 'wk_000000002');
      await membership.removeWork('lib_a', 'wk_000000001');
      expect(controller.libraries[1].memberOrder, ['wk_000000002']);
    });
  });
}
