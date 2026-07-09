import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/personal_library_membership_service.dart';

import 'fakes/fake_registry_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('curated library flow', () {
    test('create curated library and add work via membership', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = HomePersonalLibraryController();
      controller.libraries = [PersonalLibraryConfig.masterArchive()];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());

      final lib = PersonalLibraryConfig(
        id: 'lib_new',
        name: '인생 명작',
        mode: PersonalLibraryMode.curated,
      );
      controller.libraries.add(lib);

      await membership.addWork('lib_new', 'wk_test_001');
      await membership.addWork('lib_new', 'wk_test_002');

      expect(lib.memberOrder, ['wk_test_001', 'wk_test_002']);
      expect(membership.librariesContaining('wk_test_001'), {'lib_new'});
    });

    test('applyMembershipChanges moves work between libraries', () async {
      final controller = HomePersonalLibraryController();
      controller.libraries = [
        PersonalLibraryConfig.masterArchive(),
        PersonalLibraryConfig(
          id: 'a',
          name: 'A',
          mode: PersonalLibraryMode.curated,
        ),
        PersonalLibraryConfig(
          id: 'b',
          name: 'B',
          mode: PersonalLibraryMode.curated,
        ),
      ];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());

      await membership.applyMembershipChanges(
        workId: 'wk_x',
        addToLibraryIds: {'a', 'b'},
        removeFromLibraryIds: {},
      );
      await membership.applyMembershipChanges(
        workId: 'wk_x',
        addToLibraryIds: {},
        removeFromLibraryIds: {'a'},
      );

      expect(membership.librariesContaining('wk_x'), {'b'});
    });

    test('pruneOrphans removes missing vault ids', () async {
      final controller = HomePersonalLibraryController();
      final lib = PersonalLibraryConfig(
        id: 'lib',
        name: '테스트',
        mode: PersonalLibraryMode.curated,
        memberOrder: ['wk_keep', 'wk_gone'],
      );
      controller.libraries = [PersonalLibraryConfig.masterArchive(), lib];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());

      final removed = await membership.pruneOrphans(lib, {'wk_keep'});
      expect(removed, 1);
      expect(lib.memberOrder, ['wk_keep']);
    });
  });
}
