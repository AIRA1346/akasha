import 'dart:async';
import 'dart:io';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/core/ports/vault_change.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/coordinators/home_vault_coordinator.dart';
import 'package:akasha/services/archive_index_manager.dart';
import 'package:akasha/services/entity_path_index_service.dart';
import 'package:akasha/services/entity_vault_store.dart';
import 'package:akasha/services/file_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_registry_port.dart';
import 'fakes/fake_user_catalog_port.dart';
import 'fakes/fake_vault_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VaultPathChange.derivedIndexesUpdated', () {
    test('defaults to false for compatibility', () {
      const change = VaultPathChange(
        relativePath: 'entities/person/x.md',
        kind: VaultPathChangeKind.upsert,
      );
      expect(change.derivedIndexesUpdated, isFalse);

      final root =
          '${Directory.systemTemp.path}${Platform.pathSeparator}vault_root';
      final batch = VaultChangeBatch.fromAbsolutePaths(
        vaultPath: root,
        upsertedPaths: [
          '$root${Platform.pathSeparator}entities${Platform.pathSeparator}person${Platform.pathSeparator}x.md',
        ],
      );
      expect(batch.changes.single.derivedIndexesUpdated, isFalse);
    });

    test('true and false for same path coalesce to false', () {
      final merged = VaultChangeBatch.coalesceChanges([
        const VaultPathChange(
          relativePath: 'entities/person/x.md',
          kind: VaultPathChangeKind.upsert,
          derivedIndexesUpdated: true,
        ),
        const VaultPathChange(
          relativePath: 'entities/person/x.md',
          kind: VaultPathChangeKind.upsert,
          derivedIndexesUpdated: false,
        ),
      ]);
      expect(merged, hasLength(1));
      expect(merged.single.derivedIndexesUpdated, isFalse);
    });

    test('true and true for same path stays true', () {
      final merged = VaultChangeBatch.coalesceChanges([
        const VaultPathChange(
          relativePath: 'entities/person/x.md',
          kind: VaultPathChangeKind.upsert,
          derivedIndexesUpdated: true,
        ),
        const VaultPathChange(
          relativePath: 'entities/person/x.md',
          kind: VaultPathChangeKind.upsert,
          derivedIndexesUpdated: true,
        ),
      ]);
      expect(merged.single.derivedIndexesUpdated, isTrue);
    });
  });

  group('Entity derivedIndexesUpdated + Home', () {
    late Directory vault;
    late _CountingArchiveIndexManager counter;
    late EntityVaultStore store;
    late HomeVaultCoordinator coordinator;
    late StreamSubscription<VaultChangeBatch> changeSub;
    VaultChangeBatch? lastBatch;
    var rebuilds = 0;

    setUp(() async {
      vault = await Directory.systemTemp.createTemp('akasha_entity_idx_flag_');
      await AkashaFileService().setVaultPath(vault.path);
      counter = _CountingArchiveIndexManager();
      store = EntityVaultStore(archiveIndex: counter);
      final fakeVault = FakeVaultPort();
      await fakeVault.setVaultPath(vault.path);
      rebuilds = 0;
      lastBatch = null;
      changeSub = AkashaFileService().onVaultChanges.listen((batch) {
        lastBatch = batch;
      });
      coordinator = HomeVaultCoordinator(
        vault: fakeVault,
        registry: FakeRegistryPort(),
        userCatalog: FakeUserCatalogPort(),
        isMounted: () => true,
        scheduleRebuild: (fn) {
          rebuilds++;
          fn();
        },
        onVaultItemsSynced: (_) {},
        prefetchRegistry: () async {},
        archiveIndexManager: counter,
      );
    });

    tearDown(() async {
      await changeSub.cancel();
      await AkashaFileService().setVaultPath('');
      if (await vault.exists()) await vault.delete(recursive: true);
    });

    Future<VaultChangeBatch> waitBatch() async {
      for (var i = 0; i < 50; i++) {
        final batch = lastBatch;
        if (batch != null && batch.hasPrecisePaths) return batch;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      fail('timed out waiting for precise vault change');
    }

    test('Entity save + Home apply calls updateChangedRecord once', () async {
      lastBatch = null;
      final saved = await store.saveCatalogEntity(
        vaultPath: vault.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_flag01',
          type: EntityAnchorType.person,
          title: 'Flag One',
        ),
        body: 'body',
      );
      expect(counter.updateChangedRecordCalls, 1);

      final signaled = await waitBatch();
      expect(signaled.changes.single.derivedIndexesUpdated, isTrue);

      await coordinator.applyVaultChange(signaled);
      expect(counter.updateChangedRecordCalls, 1);
      expect(rebuilds, 1);

      final paths = await EntityPathIndexService().loadPaths(vault.path);
      expect(paths['pe_u_flag01'], isNotNull);
      expect(File(saved.storagePath).existsSync(), isTrue);
    });

    test('Entity delete + Home apply calls removeRecord once', () async {
      await store.saveCatalogEntity(
        vaultPath: vault.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_flagdel',
          type: EntityAnchorType.person,
          title: 'Flag Del',
        ),
        body: 'body',
      );
      final savedPath =
          (await EntityPathIndexService().lookupAbsolutePath(
            vault.path,
            'pe_u_flagdel',
          ))!;
      counter.reset();
      lastBatch = null;
      rebuilds = 0;

      final ok = await store.deleteEntry(savedPath);
      expect(ok, isTrue);
      expect(counter.removeRecordCalls, 1);

      final signaled = await waitBatch();
      expect(signaled.changes.single.kind, VaultPathChangeKind.delete);
      expect(signaled.changes.single.derivedIndexesUpdated, isTrue);

      await coordinator.applyVaultChange(signaled);
      expect(counter.removeRecordCalls, 1);
      expect(rebuilds, 1);
    });

    test('derivedIndexesUpdated true skips Home mutation but rebuilds', () async {
      counter.reset();
      rebuilds = 0;
      await coordinator.applyVaultChange(
        VaultChangeBatch(
          changes: [
            VaultPathChange(
              relativePath: 'entities/person/pe_u_skip.md',
              kind: VaultPathChangeKind.upsert,
              derivedIndexesUpdated: true,
            ),
          ],
        ),
      );
      expect(counter.updateChangedRecordCalls, 0);
      expect(rebuilds, 1);
    });

    test('false/default event still mutates indexes in Home', () async {
      await store.saveCatalogEntity(
        vaultPath: vault.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_flagext',
          type: EntityAnchorType.person,
          title: 'External',
        ),
        body: 'body',
      );
      counter.reset();
      rebuilds = 0;

      await coordinator.applyVaultChange(
        VaultChangeBatch(
          changes: [
            VaultPathChange(
              relativePath: 'entities/person/pe_u_flagext.md',
              kind: VaultPathChangeKind.upsert,
            ),
          ],
        ),
      );
      expect(counter.updateChangedRecordCalls, 1);
      expect(rebuilds, 1);
    });

    test('store without Home keeps indexes via pre-update', () async {
      final solo = _CountingArchiveIndexManager();
      final soloStore = EntityVaultStore(archiveIndex: solo);
      await soloStore.saveCatalogEntity(
        vaultPath: vault.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_solo01',
          type: EntityAnchorType.person,
          title: 'Solo',
        ),
        body: 'body',
      );
      expect(solo.updateChangedRecordCalls, 1);
      final paths = await EntityPathIndexService().loadPaths(vault.path);
      expect(paths['pe_u_solo01'], isNotNull);
    });

    test('coalesced true+false forces Home mutation', () async {
      await store.saveCatalogEntity(
        vaultPath: vault.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_merge01',
          type: EntityAnchorType.person,
          title: 'Merge',
        ),
        body: 'body',
      );
      counter.reset();
      final merged = VaultChangeBatch(
        changes: VaultChangeBatch.coalesceChanges([
          const VaultPathChange(
            relativePath: 'entities/person/pe_u_merge01.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: true,
          ),
          const VaultPathChange(
            relativePath: 'entities/person/pe_u_merge01.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: false,
          ),
        ]),
      );
      expect(merged.changes.single.derivedIndexesUpdated, isFalse);
      await coordinator.applyVaultChange(merged);
      expect(counter.updateChangedRecordCalls, 1);
    });

    test('failed index mutation does not set derivedIndexesUpdated', () async {
      final failing = _FailingUpdateArchiveIndexManager();
      final failStore = EntityVaultStore(archiveIndex: failing);
      lastBatch = null;

      await failStore.saveCatalogEntity(
        vaultPath: vault.path,
        entity: UserCatalogEntity.userLocal(
          entityId: 'pe_u_failidx',
          type: EntityAnchorType.person,
          title: 'Fail Idx',
        ),
        body: 'body',
      );
      final batch = await waitBatch();
      expect(batch.changes.single.derivedIndexesUpdated, isFalse);
    });
  });

  group('Home debounce cross-batch coalesce', () {
    late FakeVaultPort fakeVault;
    late _CountingArchiveIndexManager counter;
    late HomeVaultCoordinator coordinator;
    var rebuilds = 0;

    setUp(() async {
      fakeVault = FakeVaultPort();
      await fakeVault.setVaultPath('/fake/vault');
      counter = _CountingArchiveIndexManager();
      rebuilds = 0;
      coordinator = HomeVaultCoordinator(
        vault: fakeVault,
        registry: FakeRegistryPort(),
        userCatalog: FakeUserCatalogPort(),
        isMounted: () => true,
        scheduleRebuild: (fn) {
          rebuilds++;
          fn();
        },
        onVaultItemsSynced: (_) {},
        prefetchRegistry: () async {},
        archiveIndexManager: counter,
      );
      coordinator.bindVaultWatch(
        onVaultChanged: coordinator.applyVaultChange,
      );
    });

    tearDown(() {
      coordinator.dispose();
    });

    Future<void> emitThenWait(List<VaultPathChange> first, List<VaultPathChange> second) async {
      await fakeVault.signalVaultChange(VaultChangeBatch(changes: first));
      await fakeVault.signalVaultChange(VaultChangeBatch(changes: second));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    test('true then false within debounce mutates once', () async {
      await emitThenWait(
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_deb01.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: true,
          ),
        ],
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_deb01.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: false,
          ),
        ],
      );
      expect(counter.updateChangedRecordCalls, 1);
      expect(rebuilds, 1);
    });

    test('false then true within debounce mutates once', () async {
      await emitThenWait(
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_deb02.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: false,
          ),
        ],
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_deb02.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: true,
          ),
        ],
      );
      expect(
        counter.updateChangedRecordCalls,
        1,
        reason: 'false must survive later true via AND coalesce',
      );
      expect(rebuilds, 1);
    });

    test('true then true within debounce skips mutation', () async {
      await emitThenWait(
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_deb03.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: true,
          ),
        ],
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_deb03.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: true,
          ),
        ],
      );
      expect(counter.updateChangedRecordCalls, 0);
      expect(rebuilds, 1);
    });

    test('false then false within debounce mutates once', () async {
      await emitThenWait(
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_deb04.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: false,
          ),
        ],
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_deb04.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: false,
          ),
        ],
      );
      expect(counter.updateChangedRecordCalls, 1);
      expect(rebuilds, 1);
    });

    test('different paths keep independent flags', () async {
      await emitThenWait(
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_a.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: true,
          ),
        ],
        const [
          VaultPathChange(
            relativePath: 'entities/person/pe_u_b.md',
            kind: VaultPathChangeKind.upsert,
            derivedIndexesUpdated: false,
          ),
        ],
      );
      // Only pe_u_b needs mutation.
      expect(counter.updateChangedRecordCalls, 1);
      expect(rebuilds, 1);
    });
  });
}

class _CountingArchiveIndexManager extends ArchiveIndexManager {
  int updateChangedRecordCalls = 0;
  int removeRecordCalls = 0;

  void reset() {
    updateChangedRecordCalls = 0;
    removeRecordCalls = 0;
  }

  @override
  Future<ArchiveIndexRebuildResult> updateChangedRecord({
    required String vaultPath,
    required String absolutePath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {
    updateChangedRecordCalls++;
    return super.updateChangedRecord(
      vaultPath: vaultPath,
      absolutePath: absolutePath,
      userCatalog: userCatalog,
      vaultItems: vaultItems,
    );
  }

  @override
  Future<ArchiveIndexRebuildResult> removeRecord({
    required String vaultPath,
    required String absolutePath,
    String? sourceRecordId,
    String? entityId,
  }) async {
    removeRecordCalls++;
    return super.removeRecord(
      vaultPath: vaultPath,
      absolutePath: absolutePath,
      sourceRecordId: sourceRecordId,
      entityId: entityId,
    );
  }
}

class _FailingUpdateArchiveIndexManager extends ArchiveIndexManager {
  @override
  Future<ArchiveIndexRebuildResult> updateChangedRecord({
    required String vaultPath,
    required String absolutePath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {
    final now = DateTime.now().toUtc();
    return ArchiveIndexRebuildResult(
      startedAt: now,
      finishedAt: now,
      entries: const [
        ArchiveIndexRebuildEntry(
          indexName: 'record',
          status: ArchiveIndexRebuildStatus.failed,
          durationMs: 0,
          error: 'injected_failure',
        ),
      ],
    );
  }
}
