import 'dart:io';

import 'package:akasha/services/registry_bundle_only_migration.dart';
import 'package:akasha/services/registry_cache_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory documents;
  late Directory vault;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('akasha_bundle_migration_');
    documents = Directory(p.join(root.path, 'application_documents'))
      ..createSync(recursive: true);
    vault = Directory(p.join(root.path, 'vault'))..createSync(recursive: true);
    SharedPreferences.setMockInitialValues({
      RegistryCacheContract.lastSyncPreferenceKey: '2026-06-19T00:00:00Z',
      RegistryCacheContract.customDbUrlPreferenceKey: 'https://example.test/',
      'theme_id': 'nocturne',
    });
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('removes only registry-owned cache and is idempotent', () async {
    final cache = Directory(
      p.join(documents.path, RegistryCacheContract.cacheDirectoryName),
    )..createSync(recursive: true);
    File(p.join(cache.path, 'manifest.json')).writeAsBytesSync([1, 2, 3]);
    final legacy = File(
      p.join(documents.path, RegistryCacheContract.legacyRegistryFileName),
    )..writeAsBytesSync([4, 5, 6]);
    final unrelated = Directory(p.join(documents.path, 'unrelated_cache'))
      ..createSync();
    File(p.join(unrelated.path, 'image.bin')).writeAsBytesSync([7, 8, 9]);
    final userSettings = File(p.join(documents.path, 'user_settings'))
      ..writeAsBytesSync([10, 11]);

    for (final relativePath in const [
      'works/a.md',
      'entities/b.md',
      'posters/c.png',
      'system/state.json',
      '.akasha/config.json',
      '.trash/deleted.md',
    ]) {
      final file = File(p.join(vault.path, relativePath));
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(utf8Bytes(relativePath));
    }
    final vaultBefore = _snapshot(vault);

    final migration = RegistryBundleOnlyMigration(
      documentsDirectoryProvider: () async => documents,
    );
    final first = await migration.run();

    expect(first.completed, isTrue);
    expect(first.alreadyCompleted, isFalse);
    expect(cache.existsSync(), isFalse);
    expect(legacy.existsSync(), isFalse);
    expect(File(p.join(unrelated.path, 'image.bin')).readAsBytesSync(), [
      7,
      8,
      9,
    ]);
    expect(userSettings.readAsBytesSync(), [10, 11]);
    expect(_snapshot(vault), vaultBefore);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(
        RegistryCacheContract.bundleOnlyMigrationPreferenceKey,
      ),
      isTrue,
    );
    expect(
      preferences.containsKey(RegistryCacheContract.lastSyncPreferenceKey),
      isFalse,
    );
    expect(
      preferences.containsKey(RegistryCacheContract.customDbUrlPreferenceKey),
      isFalse,
    );
    expect(preferences.getString('theme_id'), 'nocturne');

    final documentsBeforeSecondRun = _snapshot(documents);
    final second = await migration.run();
    expect(second.completed, isTrue);
    expect(second.alreadyCompleted, isTrue);
    expect(second.removedPaths, isEmpty);
    expect(_snapshot(documents), documentsBeforeSecondRun);
    expect(_snapshot(vault), vaultBefore);
  });

  test('failed migration leaves the flag unset and retries next run', () async {
    var documentLookupCount = 0;
    final migration = RegistryBundleOnlyMigration(
      documentsDirectoryProvider: () async {
        documentLookupCount++;
        if (documentLookupCount == 1) {
          throw FileSystemException('injected documents lookup failure');
        }
        return documents;
      },
    );

    final failed = await migration.run();
    expect(failed.completed, isFalse);
    var preferences = await SharedPreferences.getInstance();
    expect(
      preferences.containsKey(
        RegistryCacheContract.bundleOnlyMigrationPreferenceKey,
      ),
      isFalse,
    );

    final retried = await migration.run();
    expect(retried.completed, isTrue);
    expect(retried.alreadyCompleted, isFalse);
    preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(
        RegistryCacheContract.bundleOnlyMigrationPreferenceKey,
      ),
      isTrue,
    );
  });
}

List<int> utf8Bytes(String value) => value.codeUnits;

Map<String, List<int>> _snapshot(Directory root) {
  final result = <String, List<int>>{};
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    result[p.relative(entity.path, from: root.path)] = entity.readAsBytesSync();
  }
  return result;
}
