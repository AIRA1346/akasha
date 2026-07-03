import 'dart:io';

import 'package:akasha/core/archiving/archive_record.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_vault_store.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/journal_vault_store.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:akasha/services/taste_index_service.dart';
import 'package:akasha/services/timeline_vault_store.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory vaultDir;
  late AkashaFileService vault;
  late RecordSummaryIndexService index;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    vaultDir = await Directory.systemTemp.createTemp('akasha_record_index_');
    vault = AkashaFileService();
    index = RecordSummaryIndexService();
    await vault.setVaultPath(vaultDir.path);
  });

  tearDown(() async {
    await vault.setVaultPath('');
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
  });

  test(
    'save flows maintain record index summaries for all record kinds',
    () async {
      final work = createItem(
        workId: 'wk_u_idx00001',
        title: 'Favorite Song Feeling',
        category: MediaCategory.animation,
        rating: 5,
        tags: ['vocaloid', 'night'],
      );
      await vault.saveItem(work);

      await EntityVaultStore().saveCatalogEntity(
        vaultPath: vaultDir.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'co_u_record01',
          type: EntityAnchorType.concept,
          title: 'Lonely Night',
          tags: const ['night'],
        ),
        body: 'concept memo',
      );

      await const JournalVaultStore().save(
        vaultPath: vaultDir.path,
        record: ArchiveRecord(
          recordId: 'jr_20260630_idx001',
          kind: RecordKind.freeformJournal,
          title: 'Dogfood note',
        ),
        body: 'freeform memo',
      );

      await const TimelineVaultStore().save(
        vaultPath: vaultDir.path,
        record: ArchiveRecord(
          recordId: 'tl_20260630_idx001',
          kind: RecordKind.timelineEntry,
          title: 'Taste moment',
          timeAnchor: DateTime.utc(2026, 6, 30, 12),
        ),
        body: 'timeline memo',
      );

      final summaries = await index.load(vaultDir.path);
      expect(
        summaries.map((s) => s.id),
        containsAll([
          'wk_u_idx00001',
          'co_u_record01',
          'jr_20260630_idx001',
          'tl_20260630_idx001',
        ]),
      );

      final workSummary = await index.lookupById(
        vaultDir.path,
        'wk_u_idx00001',
      );
      expect(workSummary?.recordKind, RecordKind.workJournal);
      expect(workSummary?.category, MediaCategory.animation.name);
      expect(workSummary?.rating, 5);
      expect(workSummary?.relativePath, endsWith('.md'));

      final nightRecords = await index.queryByTag(vaultDir.path, 'NIGHT');
      expect(
        nightRecords.map((s) => s.id),
        containsAll(['wk_u_idx00001', 'co_u_record01']),
      );

      final taste = TasteIndexService();
      expect(
        (await taste.queryByTarget(
          vaultDir.path,
          'tag:vocaloid',
        )).map((signal) => signal.sourceRecordId),
        contains('rec_wk_u_idx00001'),
      );
      expect(
        (await taste.queryByTarget(
          vaultDir.path,
          'tag:night',
        )).map((signal) => signal.sourceRecordId),
        containsAll(['rec_wk_u_idx00001', 'rec_co_u_record01']),
      );
    },
  );

  test(
    'delete and rebuild keep record index aligned with markdown files',
    () async {
      final work = createItem(
        workId: 'wk_u_del00001',
        title: 'Delete Me',
        category: MediaCategory.manga,
        tags: ['cleanup'],
      );
      await vault.saveItem(work);

      expect(await index.lookupById(vaultDir.path, 'wk_u_del00001'), isNotNull);

      final deleted = await vault.deleteAkashaItem(work);
      expect(deleted, isTrue);
      expect(await index.lookupById(vaultDir.path, 'wk_u_del00001'), isNull);
      expect(
        await TasteIndexService().queryByTarget(vaultDir.path, 'tag:cleanup'),
        isEmpty,
      );

      final survivor = createItem(
        workId: 'wk_u_reb00001',
        title: 'Rebuild Me',
        category: MediaCategory.movie,
        tags: ['rebuild'],
      );
      await vault.saveItem(survivor);

      final indexFile = File(
        p.join(
          vaultDir.path,
          '.akasha',
          RecordSummaryIndexService.indexFileName,
        ),
      );
      await indexFile.delete();

      await index.rebuildFromVault(vaultDir.path);
      expect(await index.lookupById(vaultDir.path, 'wk_u_reb00001'), isNotNull);
      expect(await index.lookupById(vaultDir.path, 'wk_u_del00001'), isNull);
    },
  );
}
