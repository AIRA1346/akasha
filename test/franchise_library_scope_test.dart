import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/franchise_library_scope.dart';
import 'package:akasha/services/personal_library_membership_service.dart';
import 'package:akasha/utils/helpers.dart';

import 'fakes/fake_registry_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FranchiseLibraryScope', () {
    test('single format card has no IP scope option', () {
      final card = BrowseCard(
        item: createItem(
          workId: 'wk_solo',
          title: 'Solo',
          category: MediaCategory.manga,
        ),
      );
      expect(
        FranchiseLibraryScope.offersEntireIpOption(card, const []),
        isFalse,
      );
    });

    test('librariesContainingAll requires every workId', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = HomePersonalLibraryController();
      final lib = PersonalLibraryConfig(
        id: 'lib',
        name: 'L',
        mode: PersonalLibraryMode.curated,
      );
      controller.libraries = [PersonalLibraryConfig.masterArchive(), lib];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());

      await membership.addWork('lib', 'wk_a');
      expect(membership.librariesContainingAll(['wk_a']), {'lib'});
      expect(membership.librariesContainingAll(['wk_a', 'wk_b']), isEmpty);

      await membership.addWork('lib', 'wk_b');
      expect(membership.librariesContainingAll(['wk_a', 'wk_b']), {'lib'});
    });

    test('countLibrariesContainingAny unions across workIds', () async {
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
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());
      await membership.addWork('a', 'wk_1');
      await membership.addWork('b', 'wk_2');

      expect(membership.countLibrariesContainingAny(['wk_1', 'wk_2']), 2);
      expect(membership.countLibrariesContainingAny(['wk_1']), 1);
    });
  });
}
