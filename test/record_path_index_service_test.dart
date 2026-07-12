import 'dart:io';

import 'package:akasha/services/record_path_index_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vault;
  late RecordPathIndexService index;

  setUp(() async {
    vault = await Directory.systemTemp.createTemp('akasha_record_path_index_');
    index = const RecordPathIndexService();
  });

  tearDown(() async {
    if (await vault.exists()) await vault.delete(recursive: true);
  });

  test(
    'rebuilds bounded stable-id lookups and preserves duplicate ids',
    () async {
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

    await file.delete();
    expect(
      await index.removeByAbsolutePath(
        vaultPath: vault.path,
        absolutePath: file.path,
      ),
      'jr_new_path001',
    );
    expect((await index.lookup(vault.path, 'jr_new_path001')).entries, isEmpty);
  });
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
