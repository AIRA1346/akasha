import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/record_link_index_service.dart';
import 'package:akasha/services/record_link_navigator.dart';
import 'package:akasha/services/user_catalog_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecordLinkIndexService', () {
    test(
      'rebuildIndex builds outgoing and incoming for explicit links',
      () async {
        final service = AkashaFileService();
        final index = RecordLinkIndexService();
        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_w5_link_',
        );

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

          final summary = await index.loadSummary();
          expect(summary.totalLinkCount, 2);
          expect(summary.linkedRecordCount, 2);
          expect(summary.connectedEntityCount, 2);

          final indexFile = File(
            p.join(
              tempDir.path,
              RecordLinkIndexService.indexDirName,
              RecordLinkIndexService.indexFileName,
            ),
          );
          expect(indexFile.existsSync(), isTrue);
        } finally {
          await service.setVaultPath('');
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'title-only link indexes incoming when catalog resolves title',
      () async {
        final service = AkashaFileService();
        final index = RecordLinkIndexService();
        final catalog = UserCatalogStore.instance..resetForTesting();
        final tempDir = await Directory.systemTemp.createTemp('akasha_r2a_');

        try {
          await service.setVaultPath(tempDir.path);

          const entityId = 'pe_u_natsuki1';
          await catalog.upsert(
            UserCatalogEntity.userLocal(
              entityId: entityId,
              type: EntityAnchorType.person,
              title: '나츠키 스바루',
            ),
          );

          final worksDir = Directory(p.join(tempDir.path, 'works', 'book'));
          await worksDir.create(recursive: true);
          final workPath = p.join(worksDir.path, 'Re_Zero.md');
          await File(workPath).writeAsString('''---
title: "Re:Zero"
work_id: "wk_u_rezero01"
---
감상 [[나츠키 스바루]] 등장
''');

          final workItem = ContentItem(
            workId: 'wk_u_rezero01',
            title: 'Re:Zero',
            category: MediaCategory.book,
            domain: AppDomain.subculture,
          )..filePath = p.normalize(workPath);

          await index.rebuildIndex(
            userCatalog: catalog,
            vaultItems: [workItem],
          );

          final normalizedWork = p.normalize(workPath);
          final outgoing = await index.outgoingLinks(normalizedWork);
          expect(outgoing.length, 1);
          expect(outgoing.first.kind, RecordLinkKind.titleOnly);
          expect(outgoing.first.targetTitle, '나츠키 스바루');

          final incoming = await index.incomingRecordPaths(entityId);
          expect(incoming.length, 1);
          expect(p.normalize(incoming.first), normalizedWork);

          var openedTitle = '';
          final returnItem =
              await RecordLinkNavigator.findVaultItemForRecordPath(
                storagePath: incoming.first,
                vaultItems: [workItem],
              );
          if (returnItem != null) openedTitle = returnItem.title;
          expect(openedTitle, 'Re:Zero');
        } finally {
          catalog.resetForTesting();
          await service.setVaultPath('');
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test('title-only link skipped when title does not resolve', () async {
      final service = AkashaFileService();
      final index = RecordLinkIndexService();
      final catalog = UserCatalogStore.instance..resetForTesting();
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

        await index.rebuildIndex(userCatalog: catalog);

        final outgoing = await index.outgoingLinks(p.normalize(journalPath));
        expect(outgoing.length, 1);
        expect(outgoing.first.kind, RecordLinkKind.titleOnly);
        expect(outgoing.first.targetTitle, 'Tiger');

        expect(await index.incomingRecordPaths('Tiger'), isEmpty);
        expect(await index.incomingRecordPaths('co_u_unknown'), isEmpty);
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('incremental upsert and remove refresh source links only', () async {
      final service = AkashaFileService();
      final index = RecordLinkIndexService();
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_w5_incremental_',
      );

      try {
        await service.setVaultPath(tempDir.path);

        final worksDir = Directory(p.join(tempDir.path, 'works', 'movie'));
        await worksDir.create(recursive: true);
        final workPath = p.join(worksDir.path, 'wk_u_link_increment.md');
        await File(workPath).writeAsString('''---
title: "Incremental Link"
work_id: "wk_u_link_increment"
---
Old [[pe_u_old00001]]
''');

        await index.rebuildIndex();
        expect(
          (await index.incomingRecordPaths('pe_u_old00001')).map(p.normalize),
          contains(p.normalize(workPath)),
        );

        await File(workPath).writeAsString('''---
title: "Incremental Link"
work_id: "wk_u_link_increment"
---
New [[pe_u_new00001]]
''');
        final links = await index.upsertMarkdownFile(
          vaultPath: tempDir.path,
          absolutePath: workPath,
        );

        expect(links.single.targetEntityId, 'pe_u_new00001');
        expect(await index.incomingRecordPaths('pe_u_old00001'), isEmpty);
        expect(
          (await index.incomingRecordPaths('pe_u_new00001')).map(p.normalize),
          contains(p.normalize(workPath)),
        );

        await index.removeBySourcePath(
          vaultPath: tempDir.path,
          absolutePath: workPath,
        );

        expect(await index.outgoingLinks(workPath), isEmpty);
        expect(await index.incomingRecordPaths('pe_u_new00001'), isEmpty);
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
