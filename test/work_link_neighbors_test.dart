import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_related_works_discovery.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/record_link_index_service.dart';
import 'package:akasha/services/user_catalog_store.dart';
import 'package:akasha/utils/work_link_neighbors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('fetchWorkLinkNeighbors', () {
    late AkashaFileService fileService;
    late RecordLinkIndexService linkIndex;
    late UserCatalogStore catalog;
    late Directory tempDir;

    setUp(() async {
      fileService = AkashaFileService();
      linkIndex = RecordLinkIndexService(fileService: fileService);
      catalog = UserCatalogStore.instance..resetForTesting();
      tempDir = await Directory.systemTemp.createTemp('akasha_wln_');
      await fileService.setVaultPath(tempDir.path);
    });

    tearDown(() async {
      catalog.resetForTesting();
      await fileService.setVaultPath('');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<String> writeWork({
      required String workId,
      required String title,
      required String fileName,
      required String body,
    }) async {
      final worksDir = Directory(p.join(tempDir.path, 'works', 'book'));
      await worksDir.create(recursive: true);
      final workPath = p.join(worksDir.path, fileName);
      await File(workPath).writeAsString('''---
title: "$title"
work_id: "$workId"
---
$body
''');
      return p.normalize(workPath);
    }

    Future<void> writeEntityJournal({
      required String entityId,
      required String title,
      EntityAnchorType type = EntityAnchorType.person,
    }) async {
      final entityDir = Directory(
        p.join(tempDir.path, 'entities', type.name),
      );
      await entityDir.create(recursive: true);
      await File(p.join(entityDir.path, '$title.md')).writeAsString('''---
entity_type: ${type.name}
entity_id: "$entityId"
record_kind: entityJournal
title: "$title"
added_at: "2026-06-19T10:00:00.000"
---
본문
''');
    }

    ContentItem workItem({
      required String workId,
      required String title,
      required String workPath,
    }) {
      return ContentItem(
        workId: workId,
        title: title,
        category: MediaCategory.book,
        domain: AppDomain.subculture,
      )..filePath = workPath;
    }

    test('shows characters from title-only wiki links', () async {
      const emiliaId = 'pe_u_emilia01';
      const rezeroId = 'wk_u_rezero01';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: emiliaId,
          type: EntityAnchorType.person,
          title: '에밀리아',
        ),
      );

      final workPath = await writeWork(
        workId: rezeroId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '히로인 [[에밀리아]]',
      );
      final items = [
        workItem(workId: rezeroId, title: 'Re:Zero', workPath: workPath),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final discovery = RecordLinkEntityRelatedWorksDiscovery(
        linkIndex: linkIndex,
        vaultItems: items,
        vaultPath: tempDir.path,
      );

      final browseCardItem = ContentItem(
        workId: rezeroId,
        title: 'Re:Zero',
        category: MediaCategory.book,
        domain: AppDomain.subculture,
      );

      final neighbors = await fetchWorkLinkNeighbors(
        work: browseCardItem,
        userCatalog: catalog,
        discovery: discovery,
        linkIndex: linkIndex,
        vaultItems: items,
      );

      expect(
        neighbors.characters.map((e) => e.entityId),
        contains(emiliaId),
      );
    });

    test('falls back to vault journal when entity missing from catalog', () async {
      const emiliaId = 'pe_u_emilia01';
      const rezeroId = 'wk_u_rezero01';

      await writeEntityJournal(
        entityId: emiliaId,
        title: 'Emilia',
      );

      final workPath = await writeWork(
        workId: rezeroId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '[[pe_u_emilia01|에밀리아]]',
      );
      final items = [
        workItem(workId: rezeroId, title: 'Re:Zero', workPath: workPath),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final discovery = RecordLinkEntityRelatedWorksDiscovery(
        linkIndex: linkIndex,
        vaultItems: items,
        vaultPath: tempDir.path,
      );

      final neighbors = await fetchWorkLinkNeighbors(
        work: items.first,
        userCatalog: catalog,
        discovery: discovery,
        linkIndex: linkIndex,
        vaultItems: items,
      );

      expect(neighbors.characters, hasLength(1));
      expect(neighbors.characters.first.entityId, emiliaId);
      expect(neighbors.characters.first.title, 'Emilia');
    });

    test('resolves vault work when preview item lacks filePath', () async {
      const subaruId = 'pe_u_subaru01';
      const rezeroId = 'wk_u_rezero01';

      await catalog.upsert(
        UserCatalogEntity.userLocal(
          entityId: subaruId,
          type: EntityAnchorType.person,
          title: '스바루',
        ),
      );

      final workPath = await writeWork(
        workId: rezeroId,
        title: 'Re:Zero',
        fileName: 'Re_Zero.md',
        body: '[[pe_u_subaru01|스바루]]',
      );
      final items = [
        workItem(workId: rezeroId, title: 'Re:Zero', workPath: workPath),
      ];
      await linkIndex.rebuildIndex(userCatalog: catalog, vaultItems: items);

      final discovery = RecordLinkEntityRelatedWorksDiscovery(
        linkIndex: linkIndex,
        vaultItems: items,
        vaultPath: tempDir.path,
      );

      final previewItem = ContentItem(
        workId: rezeroId,
        title: 'Re:Zero',
        category: MediaCategory.book,
        domain: AppDomain.subculture,
      );

      final neighbors = await fetchWorkLinkNeighbors(
        work: previewItem,
        userCatalog: catalog,
        discovery: discovery,
        linkIndex: linkIndex,
        vaultItems: items,
      );

      expect(
        neighbors.characters.map((e) => e.entityId),
        contains(subaruId),
      );
    });
  });
}
