import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:akasha/services/record_summary_index_service.dart';

void main() {
  group('YAML Implicit Typing Type Guard Test', () {
    late Directory tempDir;
    late String vaultPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('akasha_yaml_test');
      vaultPath = tempDir.path;
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('Bypasses YAML implicit cast and recovers original raw strings (no, 86, yes)', () async {
      // 1. Create a dummy markdown file with dangerous YAML implicit casting values
      final file = File(p.join(vaultPath, 'manga', 'test_work.md'));
      await file.parent.create(recursive: true);
      await file.writeAsString('''---
schema_version: 3
record_id: "rec_no"
record_kind: workJournal
work_id: no
entity_id: 86
title: "Implicit Test"
rating: 4.5
is_hall_of_fame: yes
---
## Memo

This is a test body.
''', flush: true);

      // 2. Perform index summary parsing
      final indexService = RecordSummaryIndexService();
      
      final summary = await indexService.upsertMarkdownFile(
        vaultPath: vaultPath,
        absolutePath: file.path,
      );

      // 3. Verify that the values are recovered as Strings not casted to Boolean/Int
      expect(summary, isNotNull);
      expect(summary!.id, equals('no')); // Must NOT be 'false'
      
      // Let's also lookup directly from the index to ensure it was properly upserted
      final lookedUp = await indexService.lookupById(vaultPath, 'no');
      expect(lookedUp, isNotNull);
      expect(lookedUp!.id, equals('no'));
    });
  });
}
