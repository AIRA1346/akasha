import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/library_membership_apply.dart';
import 'package:akasha/utils/helpers.dart';

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
}
