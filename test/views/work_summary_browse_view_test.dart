import 'dart:async';

import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/core/ports/vault_change.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/screens/home/views/work_summary_browse_view.dart';
import 'package:akasha/services/local_derived_index_lifecycle.dart';
import 'package:akasha/services/local_derived_index_store.dart';
import 'package:akasha/services/local_derived_index_synchronizer.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLifecycle extends LocalDerivedIndexLifecycle {
  _FakeLifecycle({required this.page, required this.item}) : super();

  WorkSummaryPage page;
  final AkashaItem item;
  final StreamController<LocalDerivedIndexLifecycleStatus> _statuses =
      StreamController<LocalDerivedIndexLifecycleStatus>.broadcast();
  final StreamController<VaultChangeBatch> _updates =
      StreamController<VaultChangeBatch>.broadcast();
  final List<WorkSummaryQuery> queries = [];
  final List<String> hydratedIds = [];

  @override
  LocalDerivedIndexLifecycleStatus get status =>
      LocalDerivedIndexLifecycleStatus.fromCacheStatus(
        vaultPath: 'C:/vault',
        cacheStatus: const WorkSummaryCacheStatus(
          state: WorkSummaryCacheState.ready,
        ),
      );

  @override
  Stream<LocalDerivedIndexLifecycleStatus> get statuses => _statuses.stream;

  @override
  Stream<VaultChangeBatch> get workSummaryUpdates => _updates.stream;

  @override
  Future<WorkSummaryRebuildResult?> ensureWorkSummariesReady({
    void Function(WorkSummaryRebuildProgress progress)? onProgress,
  }) async => null;

  @override
  Future<WorkSummaryPage> queryWorkSummaries({
    WorkSummaryQuery query = const WorkSummaryQuery(),
  }) async {
    queries.add(query);
    return page;
  }

  @override
  Future<SelectedWorkHydration> hydrateSelectedWork(String workId) async {
    hydratedIds.add(workId);
    return SelectedWorkHydration.hydrated(
      item: item,
      relativePath: 'works/movie/alpha.md',
    );
  }

  void emitWorkSummaryUpdate() {
    _updates.add(
      VaultChangeBatch(
        changes: [
          VaultPathChange(
            relativePath: 'works/movie/alpha.md',
            kind: VaultPathChangeKind.upsert,
          ),
        ],
      ),
    );
  }

  Future<void> close() async {
    await _statuses.close();
    await _updates.close();
  }
}

void main() {
  testWidgets('renders a summary then hydrates the selected Work', (
    tester,
  ) async {
    final item = ContentItem(
      workId: 'wk_u_alph0001',
      title: 'Alpha',
      category: MediaCategory.movie,
      domain: AppDomain.subculture,
    );
    final lifecycle = _FakeLifecycle(
      item: item,
      page: WorkSummaryPage(
        summaries: [
          VaultRecordSummary(
            id: item.workId,
            recordKind: RecordKind.workJournal,
            entityType: 'work',
            title: item.title,
            relativePath: 'works/movie/alpha.md',
            category: MediaCategory.movie.name,
            creator: 'Creator',
            rating: 4.5,
            myStatus: 'Finished',
            tags: const ['night'],
          ),
        ],
      ),
    );
    AkashaItem? previewed;
    addTearDown(lifecycle.close);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 700,
          height: 600,
          child: WorkSummaryBrowseView(
            categories: {MediaCategory.movie},
            workStatuses: const {},
            myStatuses: const {},
            vaultPath: 'C:/vault',
            lifecycle: lifecycle,
            onPreviewWork: (item) => previewed = item,
            onOpenWorkDetail: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Alpha'), findsOneWidget);
    expect(lifecycle.queries.single.categories, [MediaCategory.movie.name]);

    final card = tester.widget<InkWell>(
      find.byKey(const ValueKey('work_summary_card_wk_u_alph0001')),
    );
    expect(card.onTap, isNotNull);
    card.onTap!();
    await tester.pump();
    await tester.pump();

    expect(lifecycle.hydratedIds, [item.workId]);
    expect(previewed, same(item));
  });

  testWidgets('refreshes the bounded page after an indexed Work change', (
    tester,
  ) async {
    final item = ContentItem(
      workId: 'wk_u_alph0001',
      title: 'Alpha',
      category: MediaCategory.movie,
      domain: AppDomain.subculture,
    );
    final lifecycle = _FakeLifecycle(
      item: item,
      page: _pageFor(item, title: 'Alpha'),
    );
    addTearDown(lifecycle.close);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 700,
          height: 600,
          child: WorkSummaryBrowseView(
            categories: {MediaCategory.movie},
            workStatuses: const {},
            myStatuses: const {},
            vaultPath: 'C:/vault',
            lifecycle: lifecycle,
            onPreviewWork: (_) {},
            onOpenWorkDetail: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Alpha'), findsOneWidget);

    lifecycle.page = _pageFor(item, title: 'Alpha revised');
    lifecycle.emitWorkSummaryUpdate();
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump();

    expect(find.text('Alpha revised'), findsOneWidget);
  });
}

WorkSummaryPage _pageFor(AkashaItem item, {required String title}) {
  return WorkSummaryPage(
    summaries: [
      VaultRecordSummary(
        id: item.workId,
        recordKind: RecordKind.workJournal,
        entityType: 'work',
        title: title,
        relativePath: 'works/movie/alpha.md',
        category: MediaCategory.movie.name,
      ),
    ],
  );
}
