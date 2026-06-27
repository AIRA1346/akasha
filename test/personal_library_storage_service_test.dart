import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/models/personal_library_config.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/personal_library_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempVault;
  late AkashaFileService fileService;

  setUp(() async {
    tempVault = await Directory.systemTemp.createTemp('akasha_vault_test_');
    SharedPreferences.setMockInitialValues({});
    fileService = AkashaFileService();
    await fileService.setVaultPath(tempVault.path);
  });

  tearDown(() async {
    await fileService.setVaultPath('');
    if (await tempVault.exists()) {
      await tempVault.delete(recursive: true);
    }
  });

  group('PersonalLibraryStorageService', () {
    test('saves to vault .akasha and removes prefs on load', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PersonalLibraryStorageService.librariesPrefsKey,
        '[{"id":"master_archive","name":"master_archive"}]',
      );

      final storage = PersonalLibraryStorageService();
      final loaded = await storage.load();

      expect(loaded.first.id, PersonalLibraryConfig.masterArchiveId);
      expect(
        prefs.getString(PersonalLibraryStorageService.librariesPrefsKey),
        isNull,
      );

      final vaultFile = File(
        p.join(
          tempVault.path,
          PersonalLibraryStorageService.akashaDirName,
          PersonalLibraryStorageService.vaultFileName,
        ),
      );
      expect(await vaultFile.exists(), isTrue);
    });

    test('migrates prefs to vault on first vault connect', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PersonalLibraryStorageService.librariesPrefsKey,
        '[{"id":"master_archive","name":"master_archive"},{"id":"personal_1","name":"커스텀","mode":"curated","memberOrder":["wk_1"]}]',
      );

      final storage = PersonalLibraryStorageService();
      final loaded = await storage.load();

      expect(loaded, hasLength(2));
      expect(loaded[1].isCurated, isTrue);
      expect(loaded[1].memberOrder, ['wk_1']);
      expect(
        prefs.getString(PersonalLibraryStorageService.librariesPrefsKey),
        isNull,
      );
    });

    test('uses prefs only when vault not connected', () async {
      await fileService.setVaultPath('');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PersonalLibraryStorageService.librariesPrefsKey,
        '[{"id":"master_archive","name":"master_archive"}]',
      );

      final storage = PersonalLibraryStorageService();
      final loaded = await storage.load();

      expect(loaded.first.id, PersonalLibraryConfig.masterArchiveId);
      expect(
        prefs.getString(PersonalLibraryStorageService.librariesPrefsKey),
        isNotNull,
      );
    });
  });
}
