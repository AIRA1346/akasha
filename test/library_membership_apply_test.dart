import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/screens/home/home_personal_library_controller.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/personal_library_membership_service.dart';
import 'package:akasha/services/library_membership_apply.dart';
import 'package:akasha/utils/helpers.dart';

import 'fakes/fake_registry_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryMembershipApply.needsVaultMd', () {
    late Directory vaultDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      vaultDir = await Directory.systemTemp.createTemp('akasha_apply_test');
      await AkashaFileService().setVaultPath(vaultDir.path);
    });

    tearDown(() async {
      await AkashaFileService().setVaultPath('');
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    });

    test('returns true when add diff and draft not in vault', () {
      final draft = createItem(
        workId: 'wk_registry',
        title: '테스트',
        category: MediaCategory.manga,
      );

      expect(
        LibraryMembershipApply.needsVaultMd(
          draft: draft,
          desired: {'lib_a': true},
          initial: {'lib_a': false},
        ),
        isTrue,
      );
    });

    test('returns false when only remove diff', () {
      final draft = createItem(
        workId: 'wk_registry',
        title: '테스트',
        category: MediaCategory.manga,
      );

      expect(
        LibraryMembershipApply.needsVaultMd(
          draft: draft,
          desired: {'lib_a': false},
          initial: {'lib_a': true},
        ),
        isFalse,
      );
    });

    test('returns false when no diff', () {
      final draft = createItem(
        workId: 'wk_registry',
        title: '테스트',
        category: MediaCategory.manga,
      );

      expect(
        LibraryMembershipApply.needsVaultMd(
          draft: draft,
          desired: {'lib_a': true},
          initial: {'lib_a': true},
        ),
        isFalse,
      );
    });
  });

  group('ensureVaultMd (DnD-A)', () {
    late Directory vaultDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      vaultDir = await Directory.systemTemp.createTemp('akasha_md_test');
      await AkashaFileService().setVaultPath(vaultDir.path);
    });

    tearDown(() async {
      await AkashaFileService().setVaultPath('');
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    });

    test('T34 saves md with default title', () async {
      final draft = createItem(
        workId: 'wk_drop',
        title: '드롭 작품',
        category: MediaCategory.manga,
      );

      final saved = await LibraryMembershipApply.ensureVaultMd(draft: draft);
      expect(saved.filePath, isNotNull);
      expect(File(saved.filePath!).existsSync(), isTrue);
    });
  });

  group('applyPanel (E1 popover 적용)', () {
    late Directory vaultDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      vaultDir = await Directory.systemTemp.createTemp('akasha_panel_test');
      await AkashaFileService().setVaultPath(vaultDir.path);
    });

    tearDown(() async {
      await AkashaFileService().setVaultPath('');
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    });

    test('T28 md 없음 + check + apply creates md and memberOrder', () async {
      final controller = HomePersonalLibraryController();
      controller.libraries = [
        PersonalLibraryConfig.masterArchive(),
        PersonalLibraryConfig(
          id: 'lib_a',
          name: '테스트 서재',
          mode: PersonalLibraryMode.curated,
        ),
      ];
      final membership = PersonalLibraryMembershipService(controller, FakeRegistryPort());
      final draft = createItem(
        workId: 'wk_new_panel',
        title: '패널 담기',
        category: MediaCategory.manga,
      );

      expect(AkashaFileService().isArchivedInVault(draft), isFalse);

      final result = await LibraryMembershipApply.applyPanel(
        draft: draft,
        input: const WorkLibraryPanelApplyInput(
          titleOverride: '패널 담기',
          useEntireIp: false,
          desiredChecked: {'lib_a': true},
          initialChecked: {'lib_a': false},
        ),
        membership: membership,
        reloadItems: () async {},
        resolveWorkIds: (_) => ['wk_new_panel'],
      );

      expect(result.addedLibraryCount, 1);
      expect(draft.filePath, isNotNull);
      expect(File(draft.filePath!).existsSync(), isTrue);
      expect(membership.librariesContaining('wk_new_panel'), {'lib_a'});
    });
  });
}
