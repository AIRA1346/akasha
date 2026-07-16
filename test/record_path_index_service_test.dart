import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:akasha/services/derived_index_atomic_write.dart';
import 'package:akasha/services/record_path_index_service.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vault;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('akasha_record_path_index_');
  });

  tearDown(() async {
    if (await vault.exists()) await vault.delete(recursive: true);
  });

  test(
    'rebuilds bounded stable-id lookups and preserves duplicate ids',
    () async {
      final index = const RecordPathIndexService();
      final first = File(p.join(vault.path, 'works', 'movie', 'first.md'));
      final duplicate = File(p.join(vault.path, 'journals', 'duplicate.md'));
      await first.parent.create(recursive: true);
      await duplicate.parent.create(recursive: true);
      await first.writeAsString(
        _work(workId: 'wk_u_path001', recordId: 'rec_path001'),
      );
      await duplicate.writeAsString(_journal(recordId: 'rec_path001'));

      final stats = await index.rebuildFromVault(vault.path);

      expect(stats.records, 2);
      expect(await index.isAvailable(vault.path), isTrue);
      final lookup = await index.lookup(vault.path, 'rec_path001');
      expect(lookup.isAmbiguous, isTrue);
      expect(
        lookup.entries.map((entry) => entry.relativePath.replaceAll('\\', '/')),
        containsAll(['works/movie/first.md', 'journals/duplicate.md']),
      );
    },
  );

  test('incremental update removes the old id for one changed path', () async {
    final index = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_old_path001'));

    expect(
      await index.upsertMarkdownFile(
        vaultPath: vault.path,
        absolutePath: file.path,
      ),
      'jr_old_path001',
    );
    await file.writeAsString(_journal(recordId: 'jr_new_path001'));
    await index.upsertMarkdownFile(
      vaultPath: vault.path,
      absolutePath: file.path,
    );

    expect((await index.lookup(vault.path, 'jr_old_path001')).entries, isEmpty);
    expect(
      (await index.lookup(vault.path, 'jr_new_path001')).relativePath,
      'journals/source.md',
    );
  });

  test('failed replace leaves the previous good shard intact', () async {
    final index = RecordPathIndexService(
      atomicWrite: DerivedIndexAtomicWrite(
        beforeReplace: (_) async {
          throw StateError('injected replace failure');
        },
      ),
    );
    final file = File(p.join(vault.path, 'journals', 'keep.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_keep_path001'));
    await const RecordPathIndexService().rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_keep_path001');
    final before = await shard.readAsString();

    final other = File(p.join(vault.path, 'journals', 'other.md'));
    await other.writeAsString(_journal(recordId: 'jr_other_path001'));
    await expectLater(
      () => index.upsertMarkdownFile(
        vaultPath: vault.path,
        absolutePath: other.path,
      ),
      throwsA(isA<StateError>()),
    );

    expect(await shard.readAsString(), before);
    expect(
      (await const RecordPathIndexService().lookup(
        vault.path,
        'jr_keep_path001',
      )).isFound,
      isTrue,
    );
  });

  test(
    'missing target + valid bak restores without Markdown rebuild',
    () async {
      final seed = const RecordPathIndexService();
      final file = File(p.join(vault.path, 'journals', 'source.md'));
      await file.parent.create(recursive: true);
      await file.writeAsString(_journal(recordId: 'jr_bak_restore001'));
      await seed.rebuildFromVault(vault.path);

      final shard = _idShardFile(vault.path, 'jr_bak_restore001');
      final good = await shard.readAsString();
      await shard.rename('${shard.path}.bak');
      expect(await shard.exists(), isFalse);

      // Delete Markdown so a full rebuild could not recreate this shard.
      await file.delete();

      final lookup = await seed.lookup(vault.path, 'jr_bak_restore001');
      expect(lookup.isCorrupt, isFalse);
      expect(lookup.isFound, isTrue);
      expect(lookup.relativePath, 'journals/source.md');
      expect(await shard.exists(), isTrue);
      expect(await shard.readAsString(), good);
      expect(await File('${shard.path}.bak').exists(), isFalse);
    },
  );

  test('corrupt target + valid bak restores from bak', () async {
    final index = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_bak_corrupt001'));
    await index.rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_bak_corrupt001');
    final good = await shard.readAsString();
    await File('${shard.path}.bak').writeAsString(good);
    await shard.writeAsString('{truncated');

    final lookup = await index.lookup(vault.path, 'jr_bak_corrupt001');
    expect(lookup.isFound, isTrue);
    expect(await shard.readAsString(), good);
  });

  test('corrupt target + corrupt bak is explicit corrupt', () async {
    final index = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_both_bad001'));
    await index.rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_both_bad001');
    await File('${shard.path}.bak').writeAsString('{bad-bak');
    await shard.writeAsString('{bad-target');

    final lookup = await index.lookup(vault.path, 'jr_both_bad001');
    expect(lookup.isCorrupt, isTrue);
    expect(lookup.isFound, isFalse);
  });

  test('missing target + stale tmp is not promoted', () async {
    final index = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_stale_tmp001'));
    await index.rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_stale_tmp001');
    final good = await shard.readAsString();
    await shard.delete();
    await File('${shard.path}.tmp').writeAsString(good);

    final lookup = await index.lookup(vault.path, 'jr_stale_tmp001');
    expect(lookup.isFound, isFalse);
    expect(lookup.isCorrupt, isFalse);
    expect(await shard.exists(), isFalse);
    expect(await File('${shard.path}.tmp').exists(), isFalse);

    expect(await index.isAvailable(vault.path), isTrue);
    await index.ensureIndex(vault.path);
    // ensure sees available manifest; shard remains missing until rebuild.
    expect(
      (await index.lookup(vault.path, 'jr_stale_tmp001')).isFound,
      isFalse,
    );
    await index.rebuildFromVault(vault.path);
    expect((await index.lookup(vault.path, 'jr_stale_tmp001')).isFound, isTrue);
  });

  test('valid target + stale tmp keeps target and cleans tmp', () async {
    final index = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_clean_tmp001'));
    await index.rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_clean_tmp001');
    final good = await shard.readAsString();
    await File('${shard.path}.tmp').writeAsString('{stale');

    final lookup = await index.lookup(vault.path, 'jr_clean_tmp001');
    expect(lookup.isFound, isTrue);
    expect(await shard.readAsString(), good);
    expect(await File('${shard.path}.tmp').exists(), isFalse);
  });

  test('valid target + stale bak keeps target and cleans bak', () async {
    final index = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_clean_bak001'));
    await index.rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_clean_bak001');
    final good = await shard.readAsString();
    await File('${shard.path}.bak').writeAsString('{stale-bak');

    final lookup = await index.lookup(vault.path, 'jr_clean_bak001');
    expect(lookup.isFound, isTrue);
    expect(await shard.readAsString(), good);
    expect(await File('${shard.path}.bak').exists(), isFalse);
  });

  test('failed bak restore does not destroy the bak', () async {
    final index = RecordPathIndexService(
      atomicWrite: DerivedIndexAtomicWrite(
        beforeBakRestore: (_, bak) async {
          throw StateError('injected restore failure');
        },
      ),
    );
    final seed = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_restore_fail001'));
    await seed.rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_restore_fail001');
    final good = await shard.readAsString();
    await shard.rename('${shard.path}.bak');

    final lookup = await index.lookup(vault.path, 'jr_restore_fail001');
    expect(lookup.isFound, isFalse);
    expect(await File('${shard.path}.bak').exists(), isTrue);
    expect(await File('${shard.path}.bak').readAsString(), good);
    expect(await shard.exists(), isFalse);
  });

  test('failed sidecar cleanup does not destroy valid target', () async {
    final index = RecordPathIndexService(
      atomicWrite: DerivedIndexAtomicWrite(
        beforeSidecarCleanup: (_) async {
          throw StateError('injected cleanup failure');
        },
      ),
    );
    final seed = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_cleanup_fail001'));
    await seed.rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_cleanup_fail001');
    final good = await shard.readAsString();
    await File('${shard.path}.tmp').writeAsString('{stale');

    final lookup = await index.lookup(vault.path, 'jr_cleanup_fail001');
    expect(lookup.isFound, isTrue);
    expect(await shard.readAsString(), good);
  });

  test('rebuildFromVault recovers when bak cannot', () async {
    final index = const RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'source.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_rebuild_path001'));
    await index.rebuildFromVault(vault.path);

    final shard = _idShardFile(vault.path, 'jr_rebuild_path001');
    await shard.writeAsString('{truncated');
    await File('${shard.path}.bak').writeAsString('{also-bad');
    expect(
      (await index.lookup(vault.path, 'jr_rebuild_path001')).isCorrupt,
      isTrue,
    );

    await index.rebuildFromVault(vault.path);
    expect(
      (await index.lookup(vault.path, 'jr_rebuild_path001')).isFound,
      isTrue,
    );
  });

  test('concurrent upserts preserve both record locator entries', () async {
    final firstReachedReplace = Completer<void>();
    final releaseFirst = Completer<void>();
    var blocked = false;
    final first = RecordPathIndexService(
      atomicWrite: DerivedIndexAtomicWrite(
        beforeReplace: (_) async {
          if (blocked) return;
          blocked = true;
          firstReachedReplace.complete();
          await releaseFirst.future;
        },
      ),
    );
    const second = RecordPathIndexService();
    final firstFile = File(p.join(vault.path, 'journals', 'concurrent-1.md'));
    final secondFile = File(p.join(vault.path, 'journals', 'concurrent-2.md'));
    await firstFile.parent.create(recursive: true);
    await firstFile.writeAsString(_journal(recordId: 'jr_concurrent001'));
    await secondFile.writeAsString(_journal(recordId: 'jr_concurrent002'));

    final firstMutation = first.upsertMarkdownFile(
      vaultPath: vault.path,
      absolutePath: firstFile.path,
    );
    await firstReachedReplace.future;
    final secondMutation = second.upsertMarkdownFile(
      vaultPath: vault.path,
      absolutePath: secondFile.path,
    );

    releaseFirst.complete();
    await Future.wait([firstMutation, secondMutation]);

    expect(
      (await second.lookup(vault.path, 'jr_concurrent001')).isFound,
      isTrue,
    );
    expect(
      (await second.lookup(vault.path, 'jr_concurrent002')).isFound,
      isTrue,
    );
    await _expectAllIndexJsonParsable(vault.path);
  });

  test(
    'same record id concurrent upserts preserve deterministic duplicates',
    () async {
      final firstReachedReplace = Completer<void>();
      final releaseFirst = Completer<void>();
      var blocked = false;
      final first = RecordPathIndexService(
        atomicWrite: DerivedIndexAtomicWrite(
          beforeReplace: (_) async {
            if (blocked) return;
            blocked = true;
            firstReachedReplace.complete();
            await releaseFirst.future;
          },
        ),
      );
      const second = RecordPathIndexService();
      final firstFile = File(p.join(vault.path, 'journals', 'same-1.md'));
      final secondFile = File(p.join(vault.path, 'journals', 'same-2.md'));
      await firstFile.parent.create(recursive: true);
      await firstFile.writeAsString(_journal(recordId: 'jr_same_concurrent'));
      await secondFile.writeAsString(_journal(recordId: 'jr_same_concurrent'));

      final firstMutation = first.upsertMarkdownFile(
        vaultPath: vault.path,
        absolutePath: firstFile.path,
      );
      await firstReachedReplace.future;
      final secondMutation = second.upsertMarkdownFile(
        vaultPath: vault.path,
        absolutePath: secondFile.path,
      );

      releaseFirst.complete();
      await Future.wait([firstMutation, secondMutation]);

      final lookup = await second.lookup(vault.path, 'jr_same_concurrent');
      expect(lookup.isAmbiguous, isTrue);
      expect(
        lookup.entries.map((entry) => entry.relativePath),
        orderedEquals(['journals/same-1.md', 'journals/same-2.md']),
      );
      await _expectAllIndexJsonParsable(vault.path);
    },
  );

  test('queued record upsert then delete leaves valid locator JSON', () async {
    final firstReachedReplace = Completer<void>();
    final releaseFirst = Completer<void>();
    var blocked = false;
    final first = RecordPathIndexService(
      atomicWrite: DerivedIndexAtomicWrite(
        beforeReplace: (_) async {
          if (blocked) return;
          blocked = true;
          firstReachedReplace.complete();
          await releaseFirst.future;
        },
      ),
    );
    const second = RecordPathIndexService();
    final file = File(p.join(vault.path, 'journals', 'upsert-delete.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_journal(recordId: 'jr_upsert_delete'));

    final upsert = first.upsertMarkdownFile(
      vaultPath: vault.path,
      absolutePath: file.path,
    );
    await firstReachedReplace.future;
    final remove = second.removeByAbsolutePath(
      vaultPath: vault.path,
      absolutePath: file.path,
    );

    releaseFirst.complete();
    await upsert;
    expect(await remove, 'jr_upsert_delete');
    expect(
      (await second.lookup(vault.path, 'jr_upsert_delete')).entries,
      isEmpty,
    );
    await _expectAllIndexJsonParsable(vault.path);
  });
}

Future<void> _expectAllIndexJsonParsable(String vaultPath) async {
  final root = Directory(p.join(vaultPath, '.akasha', 'record_path_index'));
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    expect(jsonDecode(await entity.readAsString()), isA<Map>());
  }
}

File _idShardFile(String vaultPath, String recordId) {
  final shard = crypto.sha256
      .convert(utf8.encode(recordId))
      .toString()
      .substring(0, 2);
  return File(
    p.join(vaultPath, '.akasha', 'record_path_index', 'id', '$shard.json'),
  );
}

String _work({required String workId, required String recordId}) =>
    '''
---
record_id: "$recordId"
work_id: "$workId"
entity_type: work
title: "Path Work"
category: movie
---

body
''';

String _journal({required String recordId}) =>
    '''
---
record_id: "$recordId"
title: "Path Journal"
---

body
''';
