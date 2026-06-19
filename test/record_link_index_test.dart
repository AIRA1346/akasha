import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/record_link_index_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecordLinkIndexService', () {
    test('rebuildIndex builds outgoing and incoming for explicit links', () async {
      final service = AkashaFileService();
      final index = RecordLinkIndexService(fileService: service);
      final tempDir = await Directory.systemTemp.createTemp('akasha_w5_link_');

      try {
        await service.setVaultPath(tempDir.path);

        final worksDir = Directory(p.join(tempDir.path, 'works'));
        await worksDir.create(recursive: true);
        final workPath = p.join(worksDir.path, 'demo.md');
        await File(workPath).writeAsString('''---
title: "Demo"
work_id: "wk_u_demo0001"
---
감상 [[pe_u_target01|작가]] 참고
''');

        final entityDir = Directory(
          p.join(tempDir.path, EntityJournalParser.entitiesDirName, 'person'),
        );
        await entityDir.create(recursive: true);
        await File(p.join(entityDir.path, '작가.md')).writeAsString('''---
entity_type: person
entity_id: "pe_u_target01"
record_kind: entityJournal
title: "작가"
added_at: "2026-06-19T10:00:00.000"
---
[[wk_u_demo0001]]
''');

        await index.rebuildIndex();

        final normalizedWork = p.normalize(workPath);
        final outgoing = await index.outgoingLinks(normalizedWork);
        expect(outgoing.length, 1);
        expect(outgoing.first.kind, RecordLinkKind.explicitId);
        expect(outgoing.first.targetEntityId, 'pe_u_target01');
        expect(outgoing.first.displayLabel, '작가');

        final incoming = await index.incomingRecordPaths('pe_u_target01');
        expect(incoming.length, 1);
        expect(p.normalize(incoming.first), normalizedWork);

        final indexFile = File(
          p.join(tempDir.path, RecordLinkIndexService.indexDirName,
              RecordLinkIndexService.indexFileName),
        );
        expect(indexFile.existsSync(), isTrue);
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('title-only links are outgoing but not indexed as incoming', () async {
      final service = AkashaFileService();
      final index = RecordLinkIndexService(fileService: service);
      final tempDir = await Directory.systemTemp.createTemp('akasha_w5_title_');

      try {
        await service.setVaultPath(tempDir.path);

        final journalDir = Directory(p.join(tempDir.path, 'journal'));
        await journalDir.create(recursive: true);
        final journalPath = p.join(journalDir.path, 'note.md');
        await File(journalPath).writeAsString('''---
record_kind: freeformJournal
record_id: "j1"
title: "Note"
added_at: "2026-06-19T10:00:00.000"
---
[[Tiger]] concept
''');

        await index.rebuildIndex();

        final outgoing = await index.outgoingLinks(p.normalize(journalPath));
        expect(outgoing.length, 1);
        expect(outgoing.first.kind, RecordLinkKind.titleOnly);
        expect(outgoing.first.targetTitle, 'Tiger');

        final incoming = await index.incomingRecordPaths('Tiger');
        expect(incoming, isEmpty);
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
