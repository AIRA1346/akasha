import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/personal_library_membership_service.dart';

import 'fakes/fake_registry_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('applyCheckboxDiff', () {
    late PersonalLibraryMembershipService membership;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
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
      membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());
    });

    test('adds to multiple libraries', () async {
      final result = await membership.applyCheckboxDiff(
        workIds: ['wk_x'],
        desiredChecked: {'a': true, 'b': true},
        initialChecked: {'a': false, 'b': false},
      );
      expect(result.addedLibraryCount, 2);
      expect(membership.librariesContaining('wk_x'), {'a', 'b'});
    });

    test('removes from library on uncheck', () async {
      await membership.addWork('a', 'wk_y');
      final result = await membership.applyCheckboxDiff(
        workIds: ['wk_y'],
        desiredChecked: {'a': false},
        initialChecked: {'a': true},
      );
      expect(result.removedLibraryCount, 1);
      expect(result.removedLibraryNames, ['A']);
      expect(membership.librariesContaining('wk_y'), isEmpty);
    });

    test('no-op when unchanged', () async {
      await membership.addWork('a', 'wk_z');
      final result = await membership.applyCheckboxDiff(
        workIds: ['wk_z'],
        desiredChecked: {'a': true},
        initialChecked: {'a': true},
      );
      expect(result.hasChanges, isFalse);
    });

    test('T24 partial IP uncheck removes contained works', () async {
      await membership.addWork('a', 'wk_1');
      final result = await membership.applyCheckboxDiff(
        workIds: ['wk_1', 'wk_2', 'wk_3'],
        desiredChecked: {'a': false},
        initialChecked: {'a': null},
      );
      expect(result.removedLibraryCount, 1);
      expect(membership.librariesContaining('wk_1'), isEmpty);
    });
  });
}
