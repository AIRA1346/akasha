import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/browse_card.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/data/adapters/markdown_vault_adapter.dart';
import 'package:akasha/screens/home/coordinators/home_membership_coordinator.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/library_membership_apply.dart';
import 'package:akasha/services/personal_library_membership_service.dart';
import 'package:akasha/utils/helpers.dart';

import '../fakes/fake_storage_service.dart';
import '../fakes/fake_registry_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeMembershipCoordinator', () {
    late FakeStorageService fakeStorage;
    late HomePersonalLibraryController libraryController;
    late PersonalLibraryMembershipService membership;
    late HomeMembershipCoordinator coordinator;
    late List<AkashaItem> vaultItems;
    Directory? vaultDir;

    HomeMembershipCoordinator buildCoordinator({
      AkashaItem Function(AkashaItem)? resolveItemForOpen,
      Future<void> Function()? reloadItems,
    }) {
      return HomeMembershipCoordinator(
        vault: MarkdownVaultAdapter(),
        personalLibraryController: libraryController,
        membership: membership,
        resolveItemForOpen: resolveItemForOpen ??
            (item) {
              for (final existing in vaultItems) {
                if (item.workId.isNotEmpty && existing.workId == item.workId) {
                  return existing;
                }
                if (existing.title == item.title &&
                    existing.category == item.category) {
                  return existing;
                }
              }
              return item;
            },
        reloadItems: reloadItems ?? () async {},
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeStorage = FakeStorageService([
        PersonalLibraryConfig.masterArchive(),
        PersonalLibraryConfig(
          id: 'lib_a',
          name: '테스트 서재',
          mode: PersonalLibraryMode.curated,
        ),
      ]);
      libraryController = HomePersonalLibraryController();
      libraryController.libraries =
          PersonalLibraryConfig.normalizeLibraries(fakeStorage.libraries);
      membership = PersonalLibraryMembershipService(libraryController, FakeRegistryPort());
      vaultItems = [];
      coordinator = buildCoordinator();
    });

    tearDown(() async {
      await AkashaFileService().setVaultPath('');
      final dir = vaultDir;
      if (dir != null && await dir.exists()) {
        await dir.delete(recursive: true);
      }
      vaultDir = null;
    });

    test('constructs with injected controller and membership', () {
      expect(coordinator.personalLibraryController, same(libraryController));
      expect(coordinator.membership, same(membership));
    });

    test('reads curated library config seeded via FakeStorageService', () {
      final library = coordinator.personalLibraryController.libraries
          .singleWhere((l) => l.id == 'lib_a');

      expect(library.name, '테스트 서재');
      expect(library.isCurated, isTrue);
    });

    test('membership service mutates injected controller state', () async {
      await coordinator.membership.addWork('lib_a', 'wk_000000001');

      final library = coordinator.personalLibraryController.libraries
          .singleWhere((l) => l.id == 'lib_a');
      expect(library.memberOrder, ['wk_000000001']);
    });

    group('addWorkToLibrary', () {
      setUp(() async {
        final dir = await Directory.systemTemp
            .createTemp('akasha_membership_coord_add');
        vaultDir = dir;
        await AkashaFileService().setVaultPath(dir.path);
        coordinator = buildCoordinator(
          reloadItems: () async {
            // home_screen._loadItems와 동일하게 reload 후 resolve 가능하도록 유지
          },
        );
      });

      test('creates vault md and adds work to curated library', () async {
        final item = createItem(
          workId: 'wk_drop_coord',
          title: '코디네이터 담기',
          category: MediaCategory.manga,
        );

        final outcome = await coordinator.addWorkToLibrary(
          libraryId: 'lib_a',
          item: item,
        );

        expect(outcome.skipped, isFalse);
        expect(outcome.vaultMdError, isNull);
        expect(outcome.alreadyInLibrary, isFalse);
        expect(outcome.libraryName, '테스트 서재');
        expect(item.filePath, isNotNull);
        expect(File(item.filePath!).existsSync(), isTrue);

        final library = libraryController.libraries
            .singleWhere((l) => l.id == 'lib_a');
        expect(library.memberOrder, hasLength(1));
        expect(membership.librariesContaining(item.workId), {'lib_a'});
      });

      test('returns alreadyPresent when work is already in library', () async {
        final item = createItem(
          workId: 'wk_already_coord',
          title: '중복 담기',
          category: MediaCategory.manga,
        );
        await AkashaFileService().saveItem(item);

        await coordinator.addWorkToLibrary(libraryId: 'lib_a', item: item);
        final outcome = await coordinator.addWorkToLibrary(
          libraryId: 'lib_a',
          item: item,
        );

        expect(outcome.alreadyInLibrary, isTrue);
        expect(outcome.libraryName, '테스트 서재');
      });

      test('skips non-curated library id', () async {
        final item = createItem(
          workId: 'wk_skip_coord',
          title: '스킵',
          category: MediaCategory.manga,
        );
        await AkashaFileService().saveItem(item);

        final outcome = await coordinator.addWorkToLibrary(
          libraryId: PersonalLibraryConfig.masterArchiveId,
          item: item,
        );

        expect(outcome.skipped, isTrue);
        expect(outcome.libraryName, isNull);
      });
    });

    group('applyWorkLibraryPanel', () {
      setUp(() async {
        final dir = await Directory.systemTemp
            .createTemp('akasha_membership_coord_panel');
        vaultDir = dir;
        await AkashaFileService().setVaultPath(dir.path);
        coordinator = buildCoordinator();
      });

      test('creates md and applies checkbox diff to curated library', () async {
        final draft = createItem(
          workId: 'wk_panel_coord',
          title: '패널 담기',
          category: MediaCategory.manga,
        );
        final card = BrowseCard(item: draft);

        final result = await coordinator.applyWorkLibraryPanel(
          card,
          draft: draft,
          input: const WorkLibraryPanelApplyInput(
            titleOverride: '패널 담기',
            useEntireIp: false,
            desiredChecked: {'lib_a': true},
            initialChecked: {'lib_a': false},
          ),
          vaultItems: [],
        );

        expect(result.addedLibraryCount, 1);
        expect(draft.filePath, isNotNull);
        expect(File(draft.filePath!).existsSync(), isTrue);
        expect(membership.librariesContaining(draft.workId), {'lib_a'});
      });

      test('returns empty result when no work ids resolve', () async {
        final draft = createItem(
          workId: 'wk_empty_coord',
          title: '변경 없음',
          category: MediaCategory.manga,
        );
        await AkashaFileService().saveItem(draft);

        final result = await coordinator.applyWorkLibraryPanel(
          BrowseCard(item: draft),
          draft: draft,
          input: const WorkLibraryPanelApplyInput(
            titleOverride: null,
            useEntireIp: false,
            desiredChecked: {'lib_a': true},
            initialChecked: {'lib_a': true},
          ),
          vaultItems: [draft],
        );

        expect(result.hasChanges, isFalse);
      });
    });
  });
}
