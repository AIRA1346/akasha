import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/record_link_index_service.dart';
import 'package:akasha/services/record_link_navigator.dart';
import 'package:akasha/services/user_catalog_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RecordLinkNavigator.findVaultItemForRecordPath', () {
    test('matches by work_id when vault item filePath is stale', () async {
      final service = AkashaFileService();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r2a_path_');
      try {
        await service.setVaultPath(tempDir.path);

        final worksDir = Directory(p.join(tempDir.path, 'works', 'book'));
        await worksDir.create(recursive: true);
        final actualPath = p.join(worksDir.path, 'Re_Zero.md');
        await File(actualPath).writeAsString('''---
title: "Re:Zero"
work_id: "wk_u_rezero01"
---
본문
''');

        final staleItem = ContentItem(
          workId: 'wk_u_rezero01',
          title: 'Re:Zero',
          category: MediaCategory.book,
          domain: AppDomain.subculture,
        )..filePath = p.join(tempDir.path, 'book', 'Re_Zero.md');

        final found = await RecordLinkNavigator.findVaultItemForRecordPath(
          storagePath: p.normalize(actualPath),
          vaultItems: [staleItem],
        );

        expect(found, isNotNull);
        expect(found!.workId, 'wk_u_rezero01');
      } finally {
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('matches by case-insensitive path on Windows-style paths', () async {
      if (!Platform.isWindows) return;

      final item = ContentItem(
        workId: 'wk_u_case001',
        title: 'Case Test',
        category: MediaCategory.book,
        domain: AppDomain.subculture,
      )..filePath = r'C:\Vault\works\book\Case Test.md';

      final found = await RecordLinkNavigator.findVaultItemForRecordPath(
        storagePath: r'c:\vault\works\book\case test.md',
        vaultItems: [item],
      );

      expect(found, same(item));
    });
  });

  group('R2-A dogfood loop', () {
    test('title link indexes incoming and resolves work for return', () async {
      final service = AkashaFileService();
      final index = RecordLinkIndexService();
      final catalog = UserCatalogStore.instance..resetForTesting();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r2a_loop_');

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
등장인물 [[나츠키 스바루]]
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

        const parsedLink = ParsedRecordLink(
          kind: RecordLinkKind.titleOnly,
          raw: '나츠키 스바루',
          targetTitle: '나츠키 스바루',
        );
        final resolvedId = RecordLinkNavigator.resolveTitleToEntityId(
          parsedLink.targetTitle!,
          userCatalog: catalog,
          vaultItems: [workItem],
        );
        expect(resolvedId, entityId);

        final incoming = await index.incomingRecordPaths(entityId);
        expect(incoming.length, 1);
        expect(p.normalize(incoming.first), p.normalize(workPath));

        final returnItem = await RecordLinkNavigator.findVaultItemForRecordPath(
          storagePath: incoming.first,
          vaultItems: [workItem],
        );
        expect(returnItem?.title, 'Re:Zero');
        expect(returnItem?.workId, 'wk_u_rezero01');
      } finally {
        catalog.resetForTesting();
        await service.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
