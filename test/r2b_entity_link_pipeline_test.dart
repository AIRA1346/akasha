import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/features/workbench/presentation/work_detail_draft_ops.dart';
import 'package:akasha/models/catalog_entity_add_result.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_archive_service.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/record_link_index_service.dart';
import 'package:akasha/services/record_link_navigator.dart';
import 'package:akasha/services/record_link_parser.dart';
import 'package:akasha/services/user_catalog_store.dart';
import 'package:akasha/services/works_registry.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/utils/markdown_edit_actions.dart';

/// R2-B Step 4 — Person → Work wiki link → save → index → Entity Sheet → reopen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await WorksRegistry.init();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'explicit entity link pipeline: insert → save → index → incoming → reopen',
    () async {
      const entityId = 'pe_u_natsuki1';
      const personTitle = '나츠키 스바루';
      const canonical = '[[pe_u_natsuki1|나츠키 스바루]]';
      const workId = 'wk_u_r2btest1';
      const workTitle = 'Re_Zero R2B';

      final fileService = AkashaFileService();
      final index = RecordLinkIndexService();
      final catalog = UserCatalogStore.instance..resetForTesting();
      final tempDir = await Directory.systemTemp.createTemp('akasha_r2b_e2e_');
      late String workPath;

      try {
        await fileService.setVaultPath(tempDir.path);

        // 1) Person 생성
        await EntityArchiveService.saveFromAddResult(
          result: CatalogEntityAddResult(
            entity: UserCatalogEntity.userLocal(
              entityId: entityId,
              type: EntityAnchorType.person,
              title: personTitle,
            ),
            journalBody: 'Person journal',
          ),
          vaultPath: tempDir.path,
          userCatalog: catalog,
        );

        // 2) Work 본문 — Entity Picker와 동일 insertWikiLink
        const memoPrefix = '# 📝 메모\n';
        const selected = '주인공';
        final initialBody = '$memoPrefix$selected';
        final patch = MarkdownEditActions.insertWikiLink(
          text: initialBody,
          selection: TextSelection(
            baseOffset: memoPrefix.length,
            extentOffset: memoPrefix.length + selected.length,
          ),
          entityId: entityId,
          title: personTitle,
        );
        expect(patch.text, '$memoPrefix$canonical');

        final workItem = createItem(
          workId: workId,
          title: workTitle,
          category: MediaCategory.book,
          domain: AppDomain.subculture,
        );
        final bodyCtrl = TextEditingController(text: patch.text);
        addTearDown(bodyCtrl.dispose);
        WorkDetailDraftOps.syncBodyFromEditor(workItem, bodyCtrl);

        // 3) Work 저장 — Sanctum buildSaveDraft와 동일 sync 후 vault write
        await fileService.saveItem(workItem);
        workPath = workItem.filePath!;
        expect(File(workPath).existsSync(), isTrue);

        final diskMd = await File(workPath).readAsString();
        expect(diskMd, contains(canonical));

        // 4) RecordLinkParser — explicitId
        final parsedLinks = RecordLinkParser.parseFromRecordContent(diskMd);
        expect(parsedLinks, hasLength(1));
        expect(parsedLinks.first.kind, RecordLinkKind.explicitId);
        expect(parsedLinks.first.targetEntityId, entityId);
        expect(parsedLinks.first.displayLabel, personTitle);

        final vaultItems = [workItem];

        // 5) index rebuild → incoming
        await index.rebuildIndex(
          userCatalog: catalog,
          vaultItems: vaultItems,
        );
        final incoming = await index.incomingRecordPaths(entityId);
        expect(incoming, hasLength(1));
        expect(p.normalize(incoming.first), p.normalize(workPath));

        // 6) Entity Sheet — incoming (same API as _loadIncoming)
        final sheetIncoming = await index.incomingRecordPaths(entityId);
        expect(sheetIncoming, incoming);

        // 7) openRecordPath → onOpenWork (navigator)
        final viaNavigator = await RecordLinkNavigator.findVaultItemForRecordPath(
          storagePath: incoming.first,
          vaultItems: vaultItems,
        );
        expect(viaNavigator?.workId, workId);
        expect(viaNavigator?.title, workTitle);
      } finally {
        catalog.resetForTesting();
        await fileService.setVaultPath('');
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    },
  );
}
