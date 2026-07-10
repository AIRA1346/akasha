import 'dart:io';

import 'package:akasha/services/local_derived_index_store.dart';
import 'package:akasha/services/local_derived_index_synchronizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'rebuild reports unreadable Work sources and syncs one changed path',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'akasha_derived_sync_',
      );
      final vault = Directory(p.join(root.path, 'vault'));
      final cache = Directory(p.join(root.path, 'app_cache'));
      final workFile = File(
        p.join(vault.path, 'works', 'movie', 'wk_u_alpha.md'),
      );
      final brokenFile = File(
        p.join(vault.path, 'works', 'movie', 'broken.md'),
      );
      await workFile.parent.create(recursive: true);
      await workFile.writeAsString(_workMarkdown(title: 'Alpha'));
      await brokenFile.writeAsString('title: Broken without frontmatter\n');

      final store = LocalDerivedIndexStore();
      final synchronizer = LocalDerivedIndexSynchronizer(store: store);
      final progress = <WorkSummaryRebuildProgress>[];
      final rebuild = await synchronizer.rebuildWorkSummaries(
        cacheRoot: cache.path,
        vaultPath: vault.path,
        onProgress: progress.add,
      );

      expect(rebuild.scanned, 2);
      expect(rebuild.indexed, 1);
      expect(rebuild.unreadable, 1);
      expect(rebuild.issueSamples.single.relativePath, 'works/movie/broken.md');
      expect(rebuild.issueSamples.single.errorCode, 'frontmatter_missing');
      expect(progress.last.indexed, 1);
      expect(progress.last.unreadable, 1);

      final database = await store.open(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      try {
        final first = await store.queryWorkSummaries(database: database);
        expect(first.summaries.single.title, 'Alpha');
      } finally {
        await database.close();
      }

      await workFile.writeAsString(_workMarkdown(title: 'Alpha revised'));
      final updated = await synchronizer.syncSourcePath(
        cacheRoot: cache.path,
        vaultPath: vault.path,
        absolutePath: workFile.path,
      );
      expect(updated.status, WorkSourceSyncStatus.indexed);

      final updatedDatabase = await store.open(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      try {
        final updatedPage = await store.queryWorkSummaries(
          database: updatedDatabase,
        );
        expect(updatedPage.summaries.single.title, 'Alpha revised');
      } finally {
        await updatedDatabase.close();
      }

      await workFile.writeAsString('not a frontmatter record\n');
      final unreadable = await synchronizer.syncSourcePath(
        cacheRoot: cache.path,
        vaultPath: vault.path,
        absolutePath: workFile.path,
      );
      expect(unreadable.status, WorkSourceSyncStatus.unreadable);
      expect(unreadable.errorCode, 'frontmatter_missing');

      final unreadableDatabase = await store.open(
        cacheRoot: cache.path,
        vaultPath: vault.path,
      );
      try {
        final empty = await store.queryWorkSummaries(
          database: unreadableDatabase,
        );
        expect(empty.summaries, isEmpty);
      } finally {
        await unreadableDatabase.close();
      }

      await workFile.delete();
      final deleted = await synchronizer.syncSourcePath(
        cacheRoot: cache.path,
        vaultPath: vault.path,
        absolutePath: workFile.path,
      );
      expect(deleted.status, WorkSourceSyncStatus.deleted);

      final outside = File(p.join(root.path, 'outside.md'));
      await outside.writeAsString(_workMarkdown(title: 'Outside'));
      final ignored = await synchronizer.syncSourcePath(
        cacheRoot: cache.path,
        vaultPath: vault.path,
        absolutePath: outside.path,
      );
      expect(ignored.status, WorkSourceSyncStatus.ignored);

      await root.delete(recursive: true);
    },
  );
}

String _workMarkdown({required String title}) =>
    '''
---
schema_version: 3
record_id: rec_wk_u_alpha
record_kind: workJournal
entity_type: work
entity_id: wk_u_alpha
work_id: wk_u_alpha
title: $title
category: movie
created_at: 2026-07-11T00:00:00.000Z
updated_at: 2026-07-11T00:00:00.000Z
source: user
work_status: Completed
my_status: Finished
tags:
  - night
---
Body
''';
