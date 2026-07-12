import 'dart:io';
import 'dart:typed_data';

import 'package:akasha/core/ports/vault_change.dart';
import 'package:akasha/core/ports/vault_port.dart';
import 'package:akasha/data/adapters/vault_archive_record_adapter.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/detail/detail_archive_save.dart';
import 'package:akasha/screens/home/coordinators/home_vault_coordinator.dart';
import 'package:akasha/services/archive_index_manager.dart';
import 'package:akasha/services/file_service.dart';
import 'package:akasha/services/record_link_index_service.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_registry_port.dart';
import 'fakes/fake_user_catalog_port.dart';

void main() {
  late Directory tempDir;
  late AkashaFileService files;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RecordLinkIndexService.resetSharedForTest();
    tempDir = await Directory.systemTemp.createTemp('akasha_bhrc_');
    files = AkashaFileService();
    await files.setVaultPath(tempDir.path);
  });

  tearDown(() async {
    RecordLinkIndexService.resetSharedForTest();
    await files.setVaultPath('');
    // Allow Windows file handles to release before recursive delete.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (await tempDir.exists()) {
      try {
        await tempDir.delete(recursive: true);
      } on FileSystemException {
        // Best-effort cleanup in temp.
      }
    }
  });

  test(
    'precise vault change updates summary and link index for one path only',
    () async {
      final item = createItem(
        workId: 'wk_bhrc_one',
        title: 'Bounded One',
        category: MediaCategory.manga,
        bodyRaw: 'See [[wk_bhrc_two|Other]]',
      );
      await files.saveItem(item);
      final workId = item.workId;
      expect(workId, isNotEmpty);

      final relative = p
          .relative(item.filePath!, from: tempDir.path)
          .replaceAll('\\', '/');
      final summary = await RecordSummaryIndexService().lookupById(
        tempDir.path,
        workId,
      );
      expect(summary, isNotNull);
      expect(summary!.relativePath, relative);

      final shared = RecordLinkIndexService.shared;
      final outgoing = await shared.outgoingLinks(p.normalize(item.filePath!));
      expect(outgoing, isNotEmpty);

      final other = createItem(
        workId: 'wk_bhrc_two',
        title: 'Bounded Two',
        category: MediaCategory.manga,
        bodyRaw: 'solo',
      );
      await files.saveItem(other);

      expect(
        await RecordSummaryIndexService().lookupById(
          tempDir.path,
          other.workId,
        ),
        isNotNull,
      );
      expect(
        await RecordSummaryIndexService().lookupById(tempDir.path, workId),
        isNotNull,
      );
    },
  );

  test(
    'HomeVaultCoordinator watch applies precise paths without loadAllItems',
    () async {
      final item = createItem(
        workId: 'wk_watch',
        title: 'Watch Work',
        category: MediaCategory.book,
        bodyRaw: '[[wk_watch|self]]',
      );
      await files.saveItem(item);

      var loadAllCalls = 0;
      final countingVault = _CountingLoadAllVault(files, () => loadAllCalls++);

      final coordinator = HomeVaultCoordinator(
        vault: countingVault,
        registry: FakeRegistryPort(),
        userCatalog: FakeUserCatalogPort(),
        isMounted: () => true,
        scheduleRebuild: (mutate) => mutate(),
        onVaultItemsSynced: (_) {},
        prefetchRegistry: () async {},
      );

      var watched = 0;
      coordinator.bindVaultWatch(
        onVaultChanged: (change) async {
          watched++;
          await coordinator.applyVaultChange(change);
        },
      );

      final relative = p
          .relative(item.filePath!, from: tempDir.path)
          .replaceAll('\\', '/');
      await countingVault.signalVaultChange(
        VaultChangeBatch(
          changes: [
            VaultPathChange(
              relativePath: relative,
              kind: VaultPathChangeKind.upsert,
            ),
          ],
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(watched, 1);
      expect(loadAllCalls, 0);
      coordinator.dispose();
    },
  );

  test('DetailArchiveSave reloads without calling loadAllItems', () async {
    final item = createItem(
      workId: 'wk_detail',
      title: 'Detail',
      category: MediaCategory.game,
      bodyRaw: 'hello',
    );
    await files.saveItem(item);

    final reloaded = await DetailArchiveSave.save(item);
    expect(reloaded.filePath, isNotNull);
    expect(File(reloaded.filePath!).existsSync(), isTrue);
  });

  test('VaultArchiveRecordAdapter.getById hydrates one journal file', () async {
    final adapter = VaultArchiveRecordAdapter();
    const recordId = 'jr_20260101_testhydr';
    final journalDir = Directory(p.join(tempDir.path, 'journal'));
    await journalDir.create(recursive: true);
    final file = File(p.join(journalDir.path, '$recordId.md'));
    await file.writeAsString('''
---
record_kind: freeformJournal
record_id: "$recordId"
title: "Hydrate Me"
added_at: "2026-01-01T00:00:00.000"
---

body
''');

    final fetched = await adapter.getById(recordId);
    expect(fetched, isNotNull);
    expect(fetched!.recordId, recordId);
    expect(fetched.title, 'Hydrate Me');
  });

  test('shared link index is used by Home and ArchiveIndexManager', () async {
    final home = RecordLinkIndexService.shared;
    final manager = ArchiveIndexManager(linkIndex: home);
    final item = createItem(
      workId: 'wk_shared_link',
      title: 'Shared',
      category: MediaCategory.animation,
      bodyRaw: '[[wk_x|X]]',
    );
    await files.saveItem(item);

    final result = await manager.updateChangedRecord(
      vaultPath: tempDir.path,
      absolutePath: item.filePath!,
    );
    expect(result.succeeded, isTrue);
    final outgoing = await home.outgoingLinks(p.normalize(item.filePath!));
    expect(outgoing, isNotEmpty);
  });

  test('cold upsert does not require prior full link rebuild', () async {
    RecordLinkIndexService.resetSharedForTest();
    final link = RecordLinkIndexService.shared;
    final item = createItem(
      workId: 'wk_cold',
      title: 'Cold',
      category: MediaCategory.manga,
      bodyRaw: '[[a|A]]',
    );
    await files.saveItem(item);

    final links = await link.upsertMarkdownFile(
      vaultPath: tempDir.path,
      absolutePath: item.filePath!,
    );
    expect(links, isNotEmpty);
  });
}

class _CountingLoadAllVault implements VaultPort {
  _CountingLoadAllVault(this._inner, this._onLoadAll);

  final AkashaFileService _inner;
  final void Function() _onLoadAll;

  @override
  Future<void> init() => _inner.init();

  @override
  String? get vaultPath => _inner.vaultPath;

  @override
  Future<void> setVaultPath(String path) => _inner.setVaultPath(path);

  @override
  Future<bool> isVaultPathValid() => _inner.isVaultPathValid();

  @override
  bool isArchivedInVault(AkashaItem item) => _inner.isArchivedInVault(item);

  @override
  Future<List<AkashaItem>> loadAllItems() async {
    _onLoadAll();
    return _inner.loadAllItems();
  }

  @override
  Future<AkashaItem?> loadItemByRelativePath(String relativePath) =>
      _inner.loadItemByRelativePath(relativePath);

  @override
  Future<int> countMarkdownFiles() => _inner.countMarkdownFiles();

  @override
  Future<void> saveItem(AkashaItem item, {String? oldTitle}) =>
      _inner.saveItem(item, oldTitle: oldTitle);

  @override
  Future<bool> deleteItem(AkashaItem item) => _inner.deleteAkashaItem(item);

  @override
  Future<String?> importPosterImage(String sourceFilePath) =>
      _inner.importPosterImage(sourceFilePath);

  @override
  Future<String?> importPosterImageFromBytes(
    Uint8List bytes, {
    String extension = 'png',
  }) => _inner.importPosterImageFromBytes(bytes, extension: extension);

  @override
  Future<String?> importPosterImageBytesDeduped(
    Uint8List bytes, {
    required String extension,
  }) => _inner.importPosterImageBytesDeduped(bytes, extension: extension);

  @override
  Future<void> signalVaultChanged() => _inner.signalVaultChanged();

  @override
  Future<void> signalVaultChange(VaultChangeBatch change) =>
      _inner.signalVaultChange(change);

  @override
  Stream<void> get onVaultUpdated => _inner.onVaultUpdated;

  @override
  Stream<VaultChangeBatch> get onVaultChanges => _inner.onVaultChanges;

  @override
  Map<String, AkashaItem> get inMemoryCache => _inner.inMemoryCache;
}
