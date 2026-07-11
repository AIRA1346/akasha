import 'dart:io';

import 'package:akasha/core/ports/vault_change.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/services/local_derived_index_lifecycle.dart';
import 'package:akasha/services/local_derived_index_store.dart';
import 'package:akasha/services/local_derived_index_synchronizer.dart';
import 'package:akasha/services/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'fakes/fake_vault_port.dart';

class _HydrationVaultPort extends FakeVaultPort {
  AkashaItem? selectedItem;

  @override
  Future<AkashaItem?> loadItemByRelativePath(String relativePath) async =>
      relativePath == 'works/movie/alpha.md' ? selectedItem : null;
}

void main() {
  test(
    'lifecycle prepares one shared rebuild then applies one source path',
    () async {
      final root = await Directory.systemTemp.createTemp('akasha_lifecycle_');
      final vaultDirectory = Directory(p.join(root.path, 'vault'));
      final cacheDirectory = Directory(p.join(root.path, 'cache'));
      final work = File(
        p.join(vaultDirectory.path, 'works', 'movie', 'alpha.md'),
      );
      await work.parent.create(recursive: true);
      await work.writeAsString(_workMarkdown(title: 'Alpha'));

      final vault = _HydrationVaultPort();
      await vault.setVaultPath(vaultDirectory.path);
      final store = LocalDerivedIndexStore();
      final lifecycle = LocalDerivedIndexLifecycle(
        vault: vault,
        store: store,
        cacheRootResolver: () async => cacheDirectory.path,
      );
      try {
        await lifecycle.start();
        expect(
          lifecycle.status.state,
          LocalDerivedIndexLifecycleState.rebuildRequired,
        );

        final preparation = lifecycle.ensureWorkSummariesReady();
        expect(
          identical(preparation, lifecycle.ensureWorkSummariesReady()),
          isTrue,
        );
        final rebuilt = await preparation;
        expect(rebuilt?.indexed, 1);
        expect(lifecycle.status.state, LocalDerivedIndexLifecycleState.ready);
        expect(await lifecycle.ensureWorkSummariesReady(), isNull);
        final page = await lifecycle.queryWorkSummaries();
        expect(page.summaries.map((summary) => summary.id), ['wk_u_alph0001']);
        vault.selectedItem = MarkdownParser.deserialize(
          _workMarkdown(title: 'Alpha'),
          'alpha.md',
        );
        final hydrated = await lifecycle.hydrateSelectedWork('wk_u_alph0001');
        expect(hydrated.state, SelectedWorkHydrationState.hydrated);
        expect(hydrated.item?.title, 'Alpha');
        final targeted = await lifecycle.findWorkSummariesByIds([
          'wk_u_missing',
          'wk_u_alph0001',
        ]);
        expect(targeted.map((summary) => summary.id), ['wk_u_alph0001']);

        await work.writeAsString(_workMarkdown(title: 'Alpha revised'));
        final update = lifecycle.workSummaryUpdates.first;
        await lifecycle.handleVaultChange(
          VaultChangeBatch.fromAbsolutePaths(
            vaultPath: vaultDirectory.path,
            upsertedPaths: [work.path],
          ),
        );
        final updateBatch = await update;
        expect(updateBatch.changes.map((change) => change.relativePath), [
          'works/movie/alpha.md',
        ]);
        final database = await store.open(
          cacheRoot: cacheDirectory.path,
          vaultPath: vaultDirectory.path,
        );
        try {
          final summary = await store.findWorkSummaryById(
            database: database,
            workId: 'wk_u_alph0001',
          );
          expect(summary?.title, 'Alpha revised');
        } finally {
          await database.close();
        }

        await lifecycle.handleVaultChange(VaultChangeBatch.reconciliation);
        expect(
          lifecycle.status.state,
          LocalDerivedIndexLifecycleState.repairRequired,
        );
        expect(lifecycle.status.reason, 'vault_reconciliation_required');
      } finally {
        await lifecycle.dispose();
        await root.delete(recursive: true);
      }
    },
  );

  test('cancelling explicit rebuild quarantines the partial cache', () async {
    final root = await Directory.systemTemp.createTemp(
      'akasha_lifecycle_cancel_',
    );
    final vaultDirectory = Directory(p.join(root.path, 'vault'));
    final cacheDirectory = Directory(p.join(root.path, 'cache'));
    final works = Directory(p.join(vaultDirectory.path, 'works', 'movie'));
    await works.create(recursive: true);
    for (var index = 0; index < 100; index++) {
      await File(p.join(works.path, '$index.md')).writeAsString(
        _workMarkdown(
          title: 'Work $index',
          workId: 'wk_u_${index.toString().padLeft(8, '0')}',
        ),
      );
    }

    final vault = FakeVaultPort();
    await vault.setVaultPath(vaultDirectory.path);
    final lifecycle = LocalDerivedIndexLifecycle(
      vault: vault,
      cacheRootResolver: () async => cacheDirectory.path,
    );
    try {
      await lifecycle.start();
      await expectLater(
        lifecycle.rebuildWorkSummaries(
          onProgress: (_) => lifecycle.cancelRebuild(),
        ),
        throwsA(isA<WorkSummaryRebuildCancelled>()),
      );
      expect(
        lifecycle.status.state,
        LocalDerivedIndexLifecycleState.repairRequired,
      );
      expect(lifecycle.status.reason, 'rebuild_interrupted');
    } finally {
      await lifecycle.dispose();
      await root.delete(recursive: true);
    }
  });
}

String _workMarkdown({
  required String title,
  String workId = 'wk_u_alph0001',
}) =>
    '''
---
schema_version: 3
record_id: rec_$workId
record_kind: workJournal
entity_type: work
entity_id: $workId
work_id: $workId
title: $title
category: movie
created_at: 2026-07-11T00:00:00.000Z
updated_at: 2026-07-11T00:00:00.000Z
source: user
work_status: Completed
my_status: Finished
tags:
  - night
---
Body
''';
