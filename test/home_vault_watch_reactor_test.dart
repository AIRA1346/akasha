import 'dart:async';
import 'dart:io';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/entity_journal_entry.dart';
import 'package:akasha/core/ports/vault_change.dart';
import 'package:akasha/features/workbench/data/workbench_controller.dart';
import 'package:akasha/features/workbench/presentation/collectible_tab.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/coordinators/home_vault_coordinator.dart';
import 'package:akasha/screens/home/coordinators/home_vault_watch_reactor.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_registry_port.dart';
import 'fakes/fake_user_catalog_port.dart';
import 'fakes/fake_vault_port.dart';

void main() {
  group('HomeVaultWatchReactor dispose races', () {
    test('dispose during applyVaultChange skips later fan-out steps', () async {
      final reactor = HomeVaultWatchReactor();
      final applyGate = Completer<void>();
      var recent = 0;
      var sync = 0;
      var timeline = 0;

      final run = reactor.onVaultChanged(
        applyVaultChange: () async {
          await applyGate.future;
        },
        refreshRecentExploration: () async {
          recent++;
        },
        syncEntityTabs: () async {
          sync++;
        },
        bumpTimelineReload: () {
          timeline++;
        },
      );

      reactor.dispose();
      applyGate.complete();
      await run;

      expect(recent, 0);
      expect(sync, 0);
      expect(timeline, 0);
    });

    test(
      'dispose during refreshRecentExploration skips workbench and timeline',
      () async {
        final reactor = HomeVaultWatchReactor();
        final recentGate = Completer<void>();
        var sync = 0;
        var timeline = 0;

        final run = reactor.onVaultChanged(
          applyVaultChange: () async {},
          refreshRecentExploration: () async {
            await recentGate.future;
          },
          syncEntityTabs: () async {
            sync++;
          },
          bumpTimelineReload: () {
            timeline++;
          },
        );

        await Future<void>.delayed(Duration.zero);
        reactor.dispose();
        recentGate.complete();
        await run;

        expect(sync, 0);
        expect(timeline, 0);
      },
    );

    test('dispose during syncEntityTabs skips timeline bump', () async {
      final reactor = HomeVaultWatchReactor();
      final syncGate = Completer<void>();
      var timeline = 0;

      final run = reactor.onVaultChanged(
        applyVaultChange: () async {},
        refreshRecentExploration: () async {},
        syncEntityTabs: () async {
          await syncGate.future;
        },
        bumpTimelineReload: () {
          timeline++;
        },
      );

      await Future<void>.delayed(Duration.zero);
      reactor.dispose();
      syncGate.complete();
      await run;

      expect(timeline, 0);
    });

    test('happy path runs each fan-out step once in order', () async {
      final reactor = HomeVaultWatchReactor();
      final order = <String>[];

      await reactor.onVaultChanged(
        applyVaultChange: () async {
          order.add('apply');
        },
        refreshRecentExploration: () async {
          order.add('recent');
        },
        syncEntityTabs: () async {
          order.add('sync');
        },
        bumpTimelineReload: () {
          order.add('timeline');
        },
      );

      expect(order, ['apply', 'recent', 'sync', 'timeline']);
    });

    test('dispose is idempotent and rejects new fan-out', () async {
      final reactor = HomeVaultWatchReactor();
      reactor.dispose();
      reactor.dispose();

      var apply = 0;
      await reactor.onVaultChanged(
        applyVaultChange: () async {
          apply++;
        },
        refreshRecentExploration: () async {},
        syncEntityTabs: () async {},
        bumpTimelineReload: () {},
      );

      expect(reactor.isDisposed, isTrue);
      expect(apply, 0);
    });
  });

  group('WorkbenchController.syncEntityTabs lifecycle', () {
    test(
      'dispose during file IO prevents mutation and notifyListeners',
      () async {
        final dir = await Directory.systemTemp.createTemp(
          'akasha_sync_entity_tabs_',
        );
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });

        final path = '${dir.path}${Platform.pathSeparator}person.md';
        final content = EntityJournalParser.serialize(
          entityType: EntityAnchorType.person,
          entityId: 'pe_u_synctab1',
          title: 'Person',
          body: 'updated-body',
          addedAt: DateTime.utc(2026, 7, 13),
          aliases: const [],
          tags: const ['new'],
        );
        await File(path).writeAsString(content);

        final workbench = WorkbenchController();
        final entity = UserCatalogEntity.userLocal(
          entityId: 'pe_u_synctab1',
          type: EntityAnchorType.person,
          title: 'Person',
        );
        final journal = EntityJournalEntry(
          entityType: EntityAnchorType.person,
          entityId: 'pe_u_synctab1',
          title: 'Person',
          body: 'old-body',
          addedAt: DateTime.utc(2026, 7, 13),
          storagePath: path,
          tags: const ['old'],
        );
        workbench.openEntity(entity, journal: journal);

        final ioGate = Completer<void>();
        workbench.debugSyncEntityTabsBeforeFileIo = () => ioGate.future;

        var notifiedAfterDispose = false;
        workbench.addListener(() {
          if (workbench.isDisposed) {
            notifiedAfterDispose = true;
          }
        });

        final sync = workbench.syncEntityTabs(dir.path);
        await Future<void>.delayed(Duration.zero);
        workbench.dispose();
        ioGate.complete();

        await expectLater(sync, completes);
        expect(notifiedAfterDispose, isFalse);
        expect(workbench.isDisposed, isTrue);
        final tab = workbench.tabs.whereType<EntityCollectibleTab>().single;
        expect(tab.journal?.body, 'old-body');
        expect(tab.journal?.tags, ['old']);
      },
    );

    test('normal syncEntityTabs still updates journal and notifies', () async {
      final dir = await Directory.systemTemp.createTemp(
        'akasha_sync_entity_ok_',
      );
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });

      final path = '${dir.path}${Platform.pathSeparator}person.md';
      final content = EntityJournalParser.serialize(
        entityType: EntityAnchorType.person,
        entityId: 'pe_u_synctab2',
        title: 'Person',
        body: 'updated-body',
        addedAt: DateTime.utc(2026, 7, 13),
        aliases: const [],
        tags: const ['new'],
      );
      await File(path).writeAsString(content);

      final workbench = WorkbenchController();
      workbench.openEntity(
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_synctab2',
          type: EntityAnchorType.person,
          title: 'Person',
        ),
        journal: EntityJournalEntry(
          entityType: EntityAnchorType.person,
          entityId: 'pe_u_synctab2',
          title: 'Person',
          body: 'old-body',
          addedAt: DateTime.utc(2026, 7, 13),
          storagePath: path,
          tags: const ['old'],
        ),
      );

      var notified = 0;
      workbench.addListener(() => notified++);

      await workbench.syncEntityTabs(dir.path);

      final tab = workbench.tabs.whereType<EntityCollectibleTab>().single;
      expect(tab.journal?.body, 'updated-body');
      expect(tab.journal?.tags, ['new']);
      expect(notified, greaterThan(0));
      workbench.dispose();
    });
  });

  group('vault debounce + reactor dispose', () {
    test('dispose before debounce timer starts no fan-out', () async {
      final vault = FakeVaultPort();
      await vault.setVaultPath('/fake/vault');

      final reactor = HomeVaultWatchReactor();
      var fanOut = 0;

      final coordinator = HomeVaultCoordinator(
        vault: vault,
        registry: FakeRegistryPort(),
        userCatalog: FakeUserCatalogPort(),
        isMounted: () => !reactor.isDisposed,
        scheduleRebuild: (_) {},
        onVaultItemsSynced: (_) {},
        prefetchRegistry: () async {},
      );
      coordinator.bindVaultWatch(
        onVaultChanged: (_) => reactor.onVaultChanged(
          applyVaultChange: () async {
            fanOut++;
          },
          refreshRecentExploration: () async {
            fanOut++;
          },
          syncEntityTabs: () async {
            fanOut++;
          },
          bumpTimelineReload: () {
            fanOut++;
          },
        ),
      );

      await vault.signalVaultChange(
        VaultChangeBatch(
          changes: [
            VaultPathChange(
              relativePath: 'works/a.md',
              kind: VaultPathChangeKind.upsert,
            ),
          ],
        ),
      );

      // Cancel before 400ms debounce fires.
      reactor.dispose();
      coordinator.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(fanOut, 0);
    });
  });
}
