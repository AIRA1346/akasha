import 'dart:io';

import 'package:akasha/core/ports/vault_change.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/services/file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('absolute paths become normalized Vault-relative changes', () {
    final root =
        '${Directory.systemTemp.path}${Platform.pathSeparator}vault_root';
    final batch = VaultChangeBatch.fromAbsolutePaths(
      vaultPath: root,
      deletedPaths: [
        '$root${Platform.pathSeparator}works${Platform.pathSeparator}movie${Platform.pathSeparator}old.md',
      ],
      upsertedPaths: [
        '$root${Platform.pathSeparator}works${Platform.pathSeparator}movie${Platform.pathSeparator}new.md',
      ],
    );

    expect(batch.changes.map((change) => change.relativePath), [
      'works/movie/old.md',
      'works/movie/new.md',
    ]);
    expect(batch.changes.map((change) => change.kind), [
      VaultPathChangeKind.delete,
      VaultPathChangeKind.upsert,
    ]);
    expect(batch.reconciliationRequired, isFalse);
  });

  test('absolute paths outside the Vault are rejected', () {
    final root =
        '${Directory.systemTemp.path}${Platform.pathSeparator}vault_root';
    final outside =
        '${Directory.systemTemp.path}${Platform.pathSeparator}other${Platform.pathSeparator}record.md';

    expect(
      () => VaultChangeBatch.fromAbsolutePaths(
        vaultPath: root,
        upsertedPaths: [outside],
      ),
      throwsArgumentError,
    );
  });

  test(
    'work save emits a precise batch and retains the legacy refresh stream',
    () async {
      final service = AkashaFileService();
      final vaultDir = await Directory.systemTemp.createTemp('akasha_change_');
      try {
        await service.setVaultPath(vaultDir.path);
        final detailed = service.onVaultChanges.firstWhere(
          (batch) => batch.changes.any(
            (change) => change.kind == VaultPathChangeKind.upsert,
          ),
        );
        final legacy = service.onVaultUpdated.first;

        await service.saveItem(
          ContentItem(
            title: 'Change event work',
            category: MediaCategory.movie,
            workId: 'wk_u_change01',
            domain: AppDomain.subculture,
          ),
        );

        final batch = await detailed.timeout(const Duration(seconds: 5));
        await legacy.timeout(const Duration(seconds: 5));
        expect(batch.reconciliationRequired, isFalse);
        expect(batch.changes, hasLength(1));
        expect(batch.changes.single.kind, VaultPathChangeKind.upsert);
        expect(batch.changes.single.relativePath, endsWith('.md'));
        expect(batch.changes.single.relativePath, isNot(contains('..')));
        expect(batch.changes.single.relativePath, isNot(startsWith('/')));
      } finally {
        await service.setVaultPath('');
        if (await vaultDir.exists()) {
          await vaultDir.delete(recursive: true);
        }
      }
    },
  );

  test('native Vault watch reports the changed Markdown path', () async {
    final service = AkashaFileService();
    final vaultDir = await Directory.systemTemp.createTemp('akasha_watch_');
    const relativePath = 'works/movie/external_watch.md';
    try {
      await service.setVaultPath(vaultDir.path);
      final changed = service.onVaultChanges.firstWhere(
        (batch) => batch.changes.any(
          (change) =>
              change.relativePath == relativePath &&
              change.kind == VaultPathChangeKind.upsert,
        ),
      );

      await File(
        p.join(vaultDir.path, 'works', 'movie', 'external_watch.md'),
      ).writeAsString('---\ntitle: External watch\n---\n');

      final batch = await changed.timeout(const Duration(seconds: 5));
      expect(batch.reconciliationRequired, isFalse);
      expect(
        batch.changes.any(
          (change) =>
              change.relativePath == relativePath &&
              change.kind == VaultPathChangeKind.upsert,
        ),
        isTrue,
      );
    } finally {
      await service.setVaultPath('');
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    }
  });

  test('native Vault watch includes Canvas layout artifacts', () async {
    final service = AkashaFileService();
    final vaultDir = await Directory.systemTemp.createTemp('akasha_canvas_');
    const relativePath = 'canvases/map-01/layout.json';
    try {
      await service.setVaultPath(vaultDir.path);
      final changed = service.onVaultChanges.firstWhere(
        (batch) => batch.changes.any(
          (change) =>
              change.relativePath == relativePath &&
              change.kind == VaultPathChangeKind.upsert,
        ),
      );
      final layoutPath = p.join(
        vaultDir.path,
        'canvases',
        'map-01',
        'layout.json',
      );
      await File(layoutPath).parent.create(recursive: true);
      await File(layoutPath).writeAsString('{"nodes": []}');

      final batch = await changed.timeout(const Duration(seconds: 5));
      expect(batch.reconciliationRequired, isFalse);
      expect(
        batch.changes.any(
          (change) =>
              change.relativePath == relativePath &&
              change.kind == VaultPathChangeKind.upsert,
        ),
        isTrue,
      );
    } finally {
      await service.setVaultPath('');
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    }
  });
}
