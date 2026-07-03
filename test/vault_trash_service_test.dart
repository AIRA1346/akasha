import 'dart:convert';
import 'dart:io';

import 'package:akasha/models/enums.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/vault_trash_service.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory vaultDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    vaultDir = await Directory.systemTemp.createTemp('akasha_trash_');
  });

  tearDown(() async {
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
  });

  test(
    'moveFileToTrash preserves original relative path and manifest',
    () async {
      final sourcePath = p.join(vaultDir.path, 'works', 'manga', 'Demo.md');
      await Directory(p.dirname(sourcePath)).create(recursive: true);
      await File(sourcePath).writeAsString('demo', flush: true);

      final entry = await const VaultTrashService().moveFileToTrash(
        vaultPath: vaultDir.path,
        absolutePath: sourcePath,
      );

      expect(entry, isNotNull);
      expect(await File(sourcePath).exists(), isFalse);
      expect(await File(entry!.trashPath).exists(), isTrue);
      expect(
        p.split(entry.trashPath),
        containsAllInOrder([
          VaultTrashService.trashDirName,
          'works',
          'manga',
          'Demo.md',
        ]),
      );

      final manifest = File(
        p.join(
          p.dirname(p.dirname(p.dirname(entry.trashPath))),
          VaultTrashService.manifestFileName,
        ),
      );
      final manifestJson =
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
      expect(manifestJson['originalPath'], p.normalize(p.absolute(sourcePath)));
      expect(manifestJson['trashPath'], entry.trashPath);
    },
  );

  test(
    'restoreFile moves a trashed record back to its original path',
    () async {
      final sourcePath = p.join(vaultDir.path, 'journal', 'jr_demo.md');
      await Directory(p.dirname(sourcePath)).create(recursive: true);
      await File(sourcePath).writeAsString('journal body', flush: true);

      final entry = await const VaultTrashService().moveFileToTrash(
        vaultPath: vaultDir.path,
        absolutePath: sourcePath,
      );
      expect(entry, isNotNull);

      final restored = await const VaultTrashService().restoreFile(entry!);

      expect(restored, isTrue);
      expect(await File(sourcePath).readAsString(), 'journal body');
      expect(await File(entry.trashPath).exists(), isFalse);
      expect(
        await const VaultTrashService().listEntries(vaultPath: vaultDir.path),
        isEmpty,
      );
    },
  );

  test(
    'listEntries returns trashed records and deleteEntryPermanently purges them',
    () async {
      final sourcePath = p.join(vaultDir.path, 'timeline', 'tl_demo.md');
      await Directory(p.dirname(sourcePath)).create(recursive: true);
      await File(sourcePath).writeAsString('timeline body', flush: true);

      final service = const VaultTrashService();
      final entry = await service.moveFileToTrash(
        vaultPath: vaultDir.path,
        absolutePath: sourcePath,
      );
      expect(entry, isNotNull);

      final entries = await service.listEntries(vaultPath: vaultDir.path);
      expect(entries, hasLength(1));
      expect(entries.single.originalFileName, 'tl_demo.md');
      expect(
        entries.single.originalPathRelativeToVault(),
        p.join('timeline', 'tl_demo.md'),
      );

      final deleted = await service.deleteEntryPermanently(entries.single);

      expect(deleted, isTrue);
      expect(await File(entry!.trashPath).exists(), isFalse);
      expect(await service.listEntries(vaultPath: vaultDir.path), isEmpty);
    },
  );

  test(
    'deleteAkashaItem hides work from vault scan but keeps it in trash',
    () async {
      final vault = AkashaFileService();
      await vault.setVaultPath(vaultDir.path);
      addTearDown(() async => vault.setVaultPath(''));

      final item = createItem(
        workId: 'wk_u_trash001',
        title: 'Trash Demo',
        category: MediaCategory.manga,
        tags: const ['safety'],
      );
      await vault.saveItem(item);
      final originalPath = item.filePath!;
      expect(await File(originalPath).exists(), isTrue);

      final deleted = await vault.deleteAkashaItem(item);

      expect(deleted, isTrue);
      expect(await File(originalPath).exists(), isFalse);
      expect(await vault.loadAllItems(), isEmpty);

      final trashFiles =
          await Directory(p.join(vaultDir.path, VaultTrashService.trashDirName))
              .list(recursive: true)
              .where(
                (entity) =>
                    entity is File && entity.path.endsWith('wk_u_trash001.md'),
              )
              .toList();
      expect(trashFiles, hasLength(1));
    },
  );
}
