import 'dart:io';

import 'package:akasha/services/file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late AkashaFileService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('akasha_selected_read_');
    service = AkashaFileService();
    await service.setVaultPath(root.path);
  });

  tearDown(() async {
    await service.setVaultPath('');
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('hydrates exactly one selected Work Markdown source', () async {
    final file = File(p.join(root.path, 'works', 'movie', 'alpha.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(_workMarkdown(title: 'Alpha'));

    final item = await service.loadItemByRelativePath('works/movie/alpha.md');

    expect(item?.workId, 'wk_u_alph0001');
    expect(item?.title, 'Alpha');
    expect(item?.filePath, file.path);
    expect(item?.openedRevision, isNotNull);
  });

  test('rejects paths outside or excluded from the Vault', () async {
    await Directory(p.join(root.path, '.akasha')).create(recursive: true);
    await File(
      p.join(root.path, '.akasha', 'hidden.md'),
    ).writeAsString(_workMarkdown(title: 'Hidden'));

    expect(await service.loadItemByRelativePath('../outside.md'), isNull);
    expect(await service.loadItemByRelativePath('.akasha/hidden.md'), isNull);
    expect(await service.loadItemByRelativePath('/absolute.md'), isNull);
  });
}

String _workMarkdown({required String title}) =>
    '''
---
schema_version: 3
record_id: rec_wk_u_alph0001
record_kind: workJournal
entity_type: work
entity_id: wk_u_alph0001
work_id: wk_u_alph0001
title: $title
category: movie
created_at: 2026-07-11T00:00:00.000Z
updated_at: 2026-07-11T00:00:00.000Z
source: user
work_status: Completed
my_status: Finished
---
Body
''';
