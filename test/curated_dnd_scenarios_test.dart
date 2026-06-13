import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/personal_library_membership_service.dart';
import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';

import 'fakes/fake_registry_port.dart';

BrowseCard _card(String title) => BrowseCard(
      item: createItem(
        workId: 'wk_$title',
        title: title,
        category: MediaCategory.manga,
      ),
    );

/// §7.10 · §7.13.8 시나리오 — 서비스·모델 계층 검증 (UI DnD는 별도 위젯 테스트 후보)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T9 vault gate (UI policy)', () {
    test('curated 담기는 볼트 연결 + curated 서재 1개 이상 필요', () {
      bool canAddToLibrary({
        required bool vaultConnected,
        required List<PersonalLibraryConfig> libraries,
      }) {
        return vaultConnected &&
            libraries.any((l) => l.isCurated);
      }

      final libs = [
        PersonalLibraryConfig.masterArchive(),
        PersonalLibraryConfig(
          id: 'c',
          name: '큐레이션',
          mode: PersonalLibraryMode.curated,
        ),
      ];

      expect(canAddToLibrary(vaultConnected: false, libraries: libs), isFalse);
      expect(canAddToLibrary(vaultConnected: true, libraries: libs), isTrue);
      expect(
        canAddToLibrary(
          vaultConnected: true,
          libraries: [PersonalLibraryConfig.masterArchive()],
        ),
        isFalse,
      );
    });
  });

  group('T11/T12 membership sheet diff', () {
    late PersonalLibraryMembershipService membership;
    late HomePersonalLibraryController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      controller = HomePersonalLibraryController();
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

    test('T11 add to two libraries at once', () async {
      await membership.applyMembershipChanges(
        workId: 'wk_multi',
        addToLibraryIds: {'a', 'b'},
        removeFromLibraryIds: {},
      );
      expect(membership.librariesContaining('wk_multi'), {'a', 'b'});
    });

    test('T12 uncheck removes from library', () async {
      await membership.addWork('a', 'wk_rm');
      await membership.applyMembershipChanges(
        workId: 'wk_rm',
        addToLibraryIds: {},
        removeFromLibraryIds: {'a'},
      );
      expect(membership.librariesContaining('wk_rm'), isEmpty);
    });
  });

  group('T16/T18 drop to curated library', () {
    test('T16 addWork appends member for archived workId', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = HomePersonalLibraryController();
      final lib = PersonalLibraryConfig(
        id: 'lib',
        name: '인생',
        mode: PersonalLibraryMode.curated,
      );
      controller.libraries = [PersonalLibraryConfig.masterArchive(), lib];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());

      await membership.addWork('lib', 'wk_000000001');
      expect(lib.memberOrder, ['wk_000000001']);
    });

    test('T18 duplicate addWork is no-op', () async {
      final controller = HomePersonalLibraryController();
      final lib = PersonalLibraryConfig(
        id: 'lib',
        name: '인생',
        mode: PersonalLibraryMode.curated,
        memberOrder: ['wk_dup'],
      );
      controller.libraries = [lib];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());

      await membership.addWork('lib', 'wk_dup');
      expect(lib.memberOrder, ['wk_dup']);
      expect(membership.containsWork(lib, 'wk_dup'), isTrue);
    });
  });

  group('T17/T20 drop target eligibility', () {
    bool libraryAcceptsWorkDrop(PersonalLibraryConfig lib) => lib.isCurated;

    test('T20 master_archive rejects drop (not curated)', () {
      expect(
        libraryAcceptsWorkDrop(PersonalLibraryConfig.masterArchive()),
        isFalse,
      );
    });

    test('T17 filter-mode custom library rejects drop', () {
      final filterLib = PersonalLibraryConfig(
        id: 'legacy',
        name: '만화만',
        mode: PersonalLibraryMode.filter,
      );
      expect(libraryAcceptsWorkDrop(filterLib), isFalse);
    });

    test('curated library accepts drop', () {
      final curated = PersonalLibraryConfig(
        id: 'c',
        name: 'C',
        mode: PersonalLibraryMode.curated,
      );
      expect(libraryAcceptsWorkDrop(curated), isTrue);
    });
  });

  group('T19 memberOrder reorder persist', () {
    test('E9-style reorder updates memberOrder', () async {
      final controller = HomePersonalLibraryController();
      final lib = PersonalLibraryConfig(
        id: 'lib',
        name: '정렬',
        mode: PersonalLibraryMode.curated,
        memberOrder: ['wk_a', 'wk_b', 'wk_c'],
      );
      controller.libraries = [lib];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());

      await membership.setMemberOrder('lib', ['wk_c', 'wk_a', 'wk_b']);
      expect(lib.memberOrder, ['wk_c', 'wk_a', 'wk_b']);
    });
  });

  group('T21 remove from curated (DnD-C)', () {
    test('removeWork keeps other members', () async {
      final controller = HomePersonalLibraryController();
      final lib = PersonalLibraryConfig(
        id: 'lib',
        name: 'L',
        mode: PersonalLibraryMode.curated,
        memberOrder: ['wk_keep', 'wk_drop'],
      );
      controller.libraries = [lib];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());

      await membership.removeWork('lib', 'wk_drop');
      expect(lib.memberOrder, ['wk_keep']);
    });
  });

  group('직접 배치 순 vs 보기 정렬', () {
    test('manualOrder preserves order; titleAsc changes view only', () {
      final pipeline = [_card('Charlie'), _card('Alpha')];
      final manual = sortBrowseCards(pipeline, SortCriteria.manualOrder);
      final byTitle = sortBrowseCards(pipeline, SortCriteria.titleAsc);
      expect(manual.map((c) => c.item.title).toList(), ['Charlie', 'Alpha']);
      expect(byTitle.map((c) => c.item.title).toList(), ['Alpha', 'Charlie']);
    });
  });
}
