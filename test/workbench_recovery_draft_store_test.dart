import 'dart:io';

import 'package:akasha/services/workbench_recovery_draft_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory vaultDir;

  setUp(() async {
    vaultDir = await Directory.systemTemp.createTemp('akasha_recovery_');
  });

  tearDown(() async {
    if (await vaultDir.exists()) {
      await vaultDir.delete(recursive: true);
    }
  });

  test('save and load round-trips a work recovery draft', () async {
    const store = WorkbenchRecoveryDraftStore();
    final updatedAt = DateTime.utc(2026, 7, 1, 9, 10, 11);

    await store.save(
      vaultPath: vaultDir.path,
      draft: WorkbenchRecoveryDraft(
        kind: WorkbenchRecoveryRecordKind.work,
        recordId: 'wk_u_recovery01',
        updatedAt: updatedAt,
        title: 'Recovery Work',
        posterPath: 'posters/recovery.webp',
        bodyText: 'body draft',
        fileText: 'full md draft',
        tags: const ['vocaloid', 'ost'],
        pageView: 'body',
        rating: 4.5,
        workStatus: '완결',
        myStatus: '전부 봄',
        hallOfFame: true,
      ),
    );

    final loaded = await store.load(
      vaultPath: vaultDir.path,
      kind: WorkbenchRecoveryRecordKind.work,
      recordId: 'wk_u_recovery01',
    );

    expect(loaded, isNotNull);
    expect(loaded!.updatedAt, updatedAt);
    expect(loaded.title, 'Recovery Work');
    expect(loaded.posterPath, 'posters/recovery.webp');
    expect(loaded.bodyText, 'body draft');
    expect(loaded.fileText, 'full md draft');
    expect(loaded.tags, ['vocaloid', 'ost']);
    expect(loaded.pageView, 'body');
    expect(loaded.rating, 4.5);
    expect(loaded.workStatus, '완결');
    expect(loaded.myStatus, '전부 봄');
    expect(loaded.hallOfFame, isTrue);
  });

  test('delete removes a recovery draft', () async {
    const store = WorkbenchRecoveryDraftStore();
    await store.save(
      vaultPath: vaultDir.path,
      draft: WorkbenchRecoveryDraft(
        kind: WorkbenchRecoveryRecordKind.entity,
        recordId: 'pe_u_recovery01',
        updatedAt: DateTime.utc(2026, 7, 1),
        bodyText: 'entity body',
        fileText: 'entity file',
      ),
    );

    await store.delete(
      vaultPath: vaultDir.path,
      kind: WorkbenchRecoveryRecordKind.entity,
      recordId: 'pe_u_recovery01',
    );

    final loaded = await store.load(
      vaultPath: vaultDir.path,
      kind: WorkbenchRecoveryRecordKind.entity,
      recordId: 'pe_u_recovery01',
    );
    expect(loaded, isNull);
  });

  test(
    'record ids with path separators stay inside recovery directory',
    () async {
      const store = WorkbenchRecoveryDraftStore();
      await store.save(
        vaultPath: vaultDir.path,
        draft: WorkbenchRecoveryDraft(
          kind: WorkbenchRecoveryRecordKind.work,
          recordId: '../unsafe/work:id',
          updatedAt: DateTime.utc(2026, 7, 1),
          bodyText: 'safe body',
          fileText: 'safe file',
        ),
      );

      final recoveryDir = Directory(
        p.join(
          vaultDir.path,
          '.akasha',
          WorkbenchRecoveryDraftStore.recoveryDirName,
        ),
      );
      final files = await recoveryDir
          .list()
          .where((entity) => entity is File)
          .toList();

      expect(files, hasLength(1));
      expect(p.isWithin(recoveryDir.path, files.single.path), isTrue);
      expect(p.basename(files.single.path), isNot(contains('..')));
      expect(p.basename(files.single.path), isNot(contains('/')));
    },
  );
}
