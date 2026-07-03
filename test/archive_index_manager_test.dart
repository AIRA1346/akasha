import 'dart:io';

import 'package:akasha/core/archiving/archive_candidate.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/archive_candidate_store.dart';
import 'package:akasha/services/archive_index_manager.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vaultDir;
  late ArchiveCandidateStore candidateStore;
  late ArchiveIndexManager manager;

  setUp(() async {
    vaultDir = await Directory.systemTemp.createTemp('akasha_index_manager_');
    candidateStore = ArchiveCandidateStore();
    manager = ArchiveIndexManager(candidateStore: candidateStore);
  });

  tearDown(() async {
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
  });

  test('rebuildAll refreshes every derived index surface', () async {
    final work = createItem(
      workId: 'wk_u_manager01',
      title: 'Manager Work',
      category: MediaCategory.movie,
      rating: 4,
      tags: ['Action OST'],
    );
    work.bodyRaw = 'Related [[pe_u_manager01|Manager Person]]';
    final workFile = File(
      p.join(vaultDir.path, 'works', 'movie', 'wk_u_manager01.md'),
    );
    await workFile.parent.create(recursive: true);
    await workFile.writeAsString(MarkdownParser.serialize(work), flush: true);

    final entityFile = File(
      p.join(vaultDir.path, 'entities', 'person', 'pe_u_manager01.md'),
    );
    await entityFile.parent.create(recursive: true);
    await entityFile.writeAsString(
      EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_manager01',
        title: 'Manager Person',
        body: 'Appears in [[wk_u_manager01|Manager Work]]',
      ),
      flush: true,
    );

    await candidateStore.upsert(
      vaultPath: vaultDir.path,
      candidate: ArchiveCandidate(
        candidateId: 'cand_person_manager01',
        entityType: EntityAnchorType.person,
        title: 'Manager Person',
        sourceRecordId: 'rec_wk_u_manager01',
        evidence: 'Mentioned in Manager Work.',
        createdAt: DateTime.utc(2026, 7, 3),
        updatedAt: DateTime.utc(2026, 7, 3),
      ),
    );

    await _deleteIfExists(
      File(p.join(vaultDir.path, '.akasha', 'record_index.json')),
    );
    await _deleteIfExists(
      File(p.join(vaultDir.path, '.akasha', 'entity_path_index.json')),
    );
    await _deleteIfExists(
      File(p.join(vaultDir.path, '.akasha', 'link_index.json')),
    );
    await _deleteIfExists(
      File(p.join(vaultDir.path, '.akasha', 'indexes', 'taste_index.json')),
    );
    await _deleteDirIfExists(
      Directory(p.join(vaultDir.path, '.akasha', 'candidates', 'name_index')),
    );

    final result = await manager.rebuildAll(
      vaultPath: vaultDir.path,
      vaultItems: [work],
    );

    expect(result.succeeded, isTrue);
    expect(
      result.entries.map((entry) => entry.indexName),
      containsAll([
        ArchiveIndexManager.recordIndexName,
        ArchiveIndexManager.entityPathIndexName,
        ArchiveIndexManager.linkIndexName,
        ArchiveIndexManager.candidateIndexName,
        ArchiveIndexManager.tasteIndexName,
      ]),
    );
    expect(
      result.entry(ArchiveIndexManager.recordIndexName)?.stats['records'],
      2,
    );
    expect(
      result.entry(ArchiveIndexManager.entityPathIndexName)?.stats['entities'],
      1,
    );
    expect(
      result.entry(ArchiveIndexManager.linkIndexName)?.stats['outgoingSources'],
      2,
    );
    expect(
      result
          .entry(ArchiveIndexManager.candidateIndexName)
          ?.stats['openCandidates'],
      1,
    );
    expect(
      result.entry(ArchiveIndexManager.tasteIndexName)?.stats['signals'],
      greaterThan(0),
    );

    expect(
      await File(
        p.join(vaultDir.path, '.akasha', 'record_index.json'),
      ).exists(),
      isTrue,
    );
    expect(
      await File(
        p.join(vaultDir.path, '.akasha', 'entity_path_index.json'),
      ).exists(),
      isTrue,
    );
    expect(
      await File(p.join(vaultDir.path, '.akasha', 'link_index.json')).exists(),
      isTrue,
    );
    expect(
      await File(
        p.join(vaultDir.path, '.akasha', 'indexes', 'taste_index.json'),
      ).exists(),
      isTrue,
    );
    expect(
      await Directory(
        p.join(vaultDir.path, '.akasha', 'candidates', 'name_index', 'person'),
      ).exists(),
      isTrue,
    );
  });

  test('rebuildAll returns a failure result for missing vault path', () async {
    final result = await manager.rebuildAll(vaultPath: '');

    expect(result.succeeded, isFalse);
    expect(result.entries, hasLength(1));
    expect(result.entries.single.indexName, 'vault');
    expect(result.entries.single.error, 'vault_path_required');
  });
}

Future<void> _deleteIfExists(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}

Future<void> _deleteDirIfExists(Directory dir) async {
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
