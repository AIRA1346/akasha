import 'dart:io';

import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/services/local_derived_index_store.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'cache is outside the Vault and can be discarded then recreated',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'akasha_derived_index_',
      );
      final vault = Directory(p.join(root.path, 'vault'));
      final cache = Directory(p.join(root.path, 'app_cache'));
      await vault.create(recursive: true);

      final store = LocalDerivedIndexStore();
      final databaseFile = store.databaseFileFor(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      expect(p.isWithin(vault.path, databaseFile.path), isFalse);

      final database = await store.open(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      try {
        final metadata = await database.query(
          'cache_meta',
          where: 'key = ?',
          whereArgs: ['vault_root'],
        );
        expect(
          metadata.single['value'],
          LocalDerivedIndexStore.normalizedVaultRoot(vault.path),
        );

        await expectLater(
          database.transaction((transaction) async {
            await transaction.insert('source_files', {
              'relative_path': 'works/movie/wk_u_probe.md',
              'record_id': 'rec_wk_u_probe',
              'record_kind': 'workJournal',
              'readability_state': 'readable',
            });
            throw StateError('rollback probe');
          }),
          throwsStateError,
        );
        expect(
          await database.query(
            'source_files',
            where: 'relative_path = ?',
            whereArgs: ['works/movie/wk_u_probe.md'],
          ),
          isEmpty,
        );
      } finally {
        await database.close();
      }

      expect(await databaseFile.exists(), isTrue);
      await store.deleteCache(cacheRoot: cache.path, vaultPath: vault.path);
      expect(await databaseFile.exists(), isFalse);
      expect(await vault.exists(), isTrue);

      final rebuilt = await store.open(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      await rebuilt.close();
      expect(await databaseFile.exists(), isTrue);

      await root.delete(recursive: true);
    },
  );

  test(
    'Work summary updates and pages stay bounded in the local cache',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'akasha_derived_query_',
      );
      final vault = Directory(p.join(root.path, 'vault'));
      final cache = Directory(p.join(root.path, 'app_cache'));
      await vault.create(recursive: true);
      final store = LocalDerivedIndexStore();
      final database = await store.open(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      try {
        final newest = _workSummary(
          id: 'wk_u_newest',
          path: 'works/movie/wk_u_newest.md',
          title: 'Newest',
          category: 'movie',
          myStatus: 'Finished',
          tags: const ['night', 'science-fiction'],
          updatedAt: DateTime.utc(2026, 7, 10),
        );
        final middle = _workSummary(
          id: 'wk_u_middle',
          path: 'works/book/wk_u_middle.md',
          title: 'Middle',
          category: 'book',
          myStatus: 'Watching',
          tags: const ['night'],
          updatedAt: DateTime.utc(2026, 7, 9),
        );
        final oldest = _workSummary(
          id: 'wk_u_oldest',
          path: 'works/movie/wk_u_oldest.md',
          title: 'Oldest',
          category: 'movie',
          myStatus: 'Finished',
          tags: const ['archive'],
          updatedAt: DateTime.utc(2026, 7, 8),
        );
        await store.upsertWorkSummary(database: database, summary: newest);
        await store.upsertWorkSummary(database: database, summary: middle);
        await store.upsertWorkSummary(database: database, summary: oldest);

        final firstPage = await store.queryWorkSummaries(
          database: database,
          query: const WorkSummaryQuery(limit: 2),
        );
        expect(firstPage.summaries.map((summary) => summary.id), [
          'wk_u_newest',
          'wk_u_middle',
        ]);
        expect(firstPage.nextCursor, isNotNull);

        final secondPage = await store.queryWorkSummaries(
          database: database,
          query: WorkSummaryQuery(limit: 2, cursor: firstPage.nextCursor),
        );
        expect(secondPage.summaries.map((summary) => summary.id), [
          'wk_u_oldest',
        ]);
        expect(secondPage.nextCursor, isNull);

        final filtered = await store.queryWorkSummaries(
          database: database,
          query: const WorkSummaryQuery(
            categories: ['movie'],
            myStatuses: ['Finished'],
            tag: 'NIGHT',
          ),
        );
        expect(filtered.summaries.map((summary) => summary.id), [
          'wk_u_newest',
        ]);

        await store.upsertWorkSummary(
          database: database,
          summary: _workSummary(
            id: newest.id,
            path: newest.relativePath,
            title: 'Newest revised',
            category: 'movie',
            myStatus: 'Finished',
            tags: const ['revised'],
            updatedAt: DateTime.utc(2026, 7, 11),
          ),
        );
        final revised = await store.queryWorkSummaries(
          database: database,
          query: const WorkSummaryQuery(tag: 'revised'),
        );
        expect(revised.summaries.single.title, 'Newest revised');

        await store.removeBySourcePath(
          database: database,
          relativePath: oldest.relativePath,
        );
        final remaining = await store.queryWorkSummaries(database: database);
        expect(remaining.summaries.map((summary) => summary.id), [
          'wk_u_newest',
          'wk_u_middle',
        ]);
      } finally {
        await database.close();
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'v1 cache upgrades its Work entity identifier without touching the Vault',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'akasha_derived_upgrade_',
      );
      final vault = Directory(p.join(root.path, 'vault'));
      final cache = Directory(p.join(root.path, 'app_cache'));
      await vault.create(recursive: true);
      final store = LocalDerivedIndexStore();
      final databaseFile = store.databaseFileFor(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      await databaseFile.parent.create(recursive: true);

      sqfliteFfiInit();
      final v1 = await databaseFactoryFfi.openDatabase(
        databaseFile.path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, version) async {
            await database.execute('''
              CREATE TABLE cache_meta (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
              )
            ''');
            await database.execute('''
              CREATE TABLE source_files (
                relative_path TEXT PRIMARY KEY,
                record_id TEXT,
                record_kind TEXT,
                content_hash TEXT,
                size_bytes INTEGER,
                modified_at_utc TEXT,
                indexed_at_utc TEXT,
                readability_state TEXT NOT NULL
              )
            ''');
          },
        ),
      );
      await v1.close();

      final upgraded = await store.open(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      try {
        final columns = await upgraded.rawQuery(
          'PRAGMA table_info(source_files)',
        );
        expect(columns.map((column) => column['name']), contains('entity_id'));
        expect(await vault.exists(), isTrue);
      } finally {
        await upgraded.close();
        await root.delete(recursive: true);
      }
    },
  );
}

VaultRecordSummary _workSummary({
  required String id,
  required String path,
  required String title,
  required String category,
  required String myStatus,
  required List<String> tags,
  required DateTime updatedAt,
}) {
  return VaultRecordSummary(
    id: id,
    recordKind: RecordKind.workJournal,
    entityType: 'work',
    title: title,
    relativePath: path,
    category: category,
    creator: 'Creator',
    rating: 4.5,
    workStatus: 'Completed',
    myStatus: myStatus,
    tags: tags,
    addedAt: updatedAt.subtract(const Duration(days: 1)),
    updatedAt: updatedAt,
  );
}
