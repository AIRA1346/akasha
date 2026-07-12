import 'package:akasha/core/archiving/archive_candidate.dart';
import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/views/candidate_review_view.dart';
import 'package:akasha/services/archive_candidate_store.dart';
import 'package:akasha/services/archive_operation_executor.dart';
import 'package:akasha/services/archive_record_revision_service.dart';
import 'package:akasha/services/record_summary_index_service.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_user_catalog_port.dart';

class _FakeCandidateStore extends ArchiveCandidateStore {
  _FakeCandidateStore(List<ArchiveCandidate> seed) : candidates = List.of(seed);

  final List<ArchiveCandidate> candidates;
  final List<String> dismissed = [];

  @override
  Future<List<ArchiveCandidate>> openCandidates(String vaultPath) async {
    return candidates.where((c) => c.isOpen).toList(growable: false);
  }

  @override
  Future<ArchiveCandidate?> lookup(String vaultPath, String candidateId) async {
    for (final candidate in candidates) {
      if (candidate.candidateId == candidateId) return candidate;
    }
    return null;
  }

  @override
  Future<void> dismiss({
    required String vaultPath,
    required String candidateId,
    DateTime? updatedAt,
  }) async {
    dismissed.add(candidateId);
    final index = candidates.indexWhere((c) => c.candidateId == candidateId);
    if (index >= 0) {
      candidates[index] = candidates[index].markDismissed(updatedAt: updatedAt);
    }
  }
}

class _FakeExecutor extends ArchiveOperationExecutor {
  _FakeExecutor(this.store);

  final _FakeCandidateStore store;
  final List<ArchiveOperation> executed = [];

  @override
  Future<ArchiveOperationExecutionResult> execute({
    required String vaultPath,
    required ArchiveOperation operation,
    required UserCatalogPort userCatalog,
  }) async {
    executed.add(operation);
    final candidateId = operation.payload['candidateId']!.toString();
    final target = operation.targetEntity!;
    final index = store.candidates.indexWhere(
      (c) => c.candidateId == candidateId,
    );
    if (index >= 0) {
      store.candidates[index] = store.candidates[index].markPromoted(
        entityId: target.entityId,
      );
    }
    return ArchiveOperationExecutionResult(
      applied: true,
      entity: UserCatalogEntity.userLocal(
        entityId: target.entityId,
        type: target.type,
        title: operation.title ?? store.candidates[index].title,
        subtype: MediaCategory.manga,
      ),
    );
  }
}

class _FakeRecordSummaryIndex extends RecordSummaryIndexService {
  @override
  Future<VaultRecordSummary?> lookupById(
    String vaultPath,
    String recordId,
  ) async => null;
}

class _FakeRevisionService extends ArchiveRecordRevisionService {
  _FakeRevisionService(this.revision);

  final ArchiveRecordRevision revision;

  @override
  Future<ArchiveRecordRevision> currentForRecordId({
    required String vaultPath,
    required String recordId,
  }) async => revision;
}

ArchiveCandidate _candidate({
  String id = 'cand_person_test0001',
  EntityAnchorType type = EntityAnchorType.person,
  String title = 'Ars Almadel',
  double confidence = 0.9,
  String? actorLabel,
  String? sourceOperationId,
  String? sourceRecordRevision,
}) {
  return ArchiveCandidate(
    candidateId: id,
    entityType: type,
    title: title,
    sourceRecordId: 'rec_wk_u_source01',
    evidence: 'Mentioned as the main author in the imported document.',
    createdAt: DateTime.utc(2026, 7, 1),
    updatedAt: DateTime.utc(2026, 7, 1),
    confidence: confidence,
    actorLabel: actorLabel,
    sourceOperationId: sourceOperationId,
    sourceRecordRevision: sourceRecordRevision,
  );
}

Widget _wrap({
  required _FakeCandidateStore store,
  required _FakeExecutor executor,
  Future<void> Function(UserCatalogEntity entity)? onOpenEntity,
  RecordSummaryIndexService? recordSummaryIndexService,
  ArchiveRecordRevisionService? revisionService,
}) {
  return MaterialApp(
    theme: AkashaTheme.dark(),
    home: Scaffold(
      body: CandidateReviewView(
        vaultPath: 'C:/fake/vault',
        userCatalog: FakeUserCatalogPort(),
        onOpenEntity: onOpenEntity,
        candidateStore: store,
        operationExecutor: executor,
        recordSummaryIndexService: recordSummaryIndexService,
        revisionService: revisionService,
      ),
    ),
  );
}

void main() {
  testWidgets('lists open candidates with approve/reject actions', (
    tester,
  ) async {
    final store = _FakeCandidateStore([
      _candidate(),
      _candidate(
        id: 'cand_concept_test0002',
        type: EntityAnchorType.concept,
        title: 'Semantic Local Time',
        confidence: 0,
      ),
    ]);
    await tester.pumpWidget(
      _wrap(store: store, executor: _FakeExecutor(store)),
    );
    await tester.pumpAndSettle();

    expect(find.text('제안된 후보 (2)'), findsOneWidget);
    expect(find.text('Ars Almadel'), findsOneWidget);
    expect(find.text('Semantic Local Time'), findsOneWidget);
    expect(find.text('Person'), findsOneWidget);
    expect(find.text('Concept'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('수락'), findsNWidgets(2));
    expect(find.text('반려'), findsNWidgets(2));
  });

  testWidgets('shows empty state when no candidates', (tester) async {
    final store = _FakeCandidateStore(const []);
    await tester.pumpWidget(
      _wrap(store: store, executor: _FakeExecutor(store)),
    );
    await tester.pumpAndSettle();

    expect(find.text('검토할 후보가 없습니다.'), findsOneWidget);
  });

  testWidgets('shows candidate provenance in details', (tester) async {
    final store = _FakeCandidateStore([
      _candidate(
        actorLabel: 'Local analysis tool',
        sourceOperationId: 'op_candidate_001',
        sourceRecordRevision: 'v2:sha256:source;bytes:128',
      ),
    ]);
    await tester.pumpWidget(
      _wrap(
        store: store,
        executor: _FakeExecutor(store),
        recordSummaryIndexService: _FakeRecordSummaryIndex(),
        revisionService: _FakeRevisionService(
          const ArchiveRecordRevision(
            value: 'v2:sha256:source;bytes:128',
            exists: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local analysis tool'), findsOneWidget);
    expect(find.text('원본 rec_wk_u_source01'), findsOneWidget);

    await tester.tap(find.text('상세'));
    await tester.pumpAndSettle();

    expect(find.text('Ars Almadel 후보 정보'), findsOneWidget);
    expect(find.text('제안 주체'), findsOneWidget);
    expect(find.text('op_candidate_001'), findsOneWidget);
    expect(find.text('rec_wk_u_source01'), findsOneWidget);
    expect(find.text('v2:sha256:source;bytes:128'), findsOneWidget);
    expect(find.text('후보 제안 당시와 같은 원본입니다'), findsOneWidget);
  });

  testWidgets('approve executes promoteCandidate and removes candidate', (
    tester,
  ) async {
    final store = _FakeCandidateStore([_candidate()]);
    final executor = _FakeExecutor(store);
    final opened = <UserCatalogEntity>[];
    await tester.pumpWidget(
      _wrap(
        store: store,
        executor: executor,
        onOpenEntity: (entity) async => opened.add(entity),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('수락'));
    await tester.pumpAndSettle();
    expect(find.text('후보 수락'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '수락').last);
    await tester.pumpAndSettle();

    expect(executor.executed, hasLength(1));
    final operation = executor.executed.single;
    expect(operation.type, ArchiveOperationType.promoteCandidate);
    expect(operation.source, ArchiveOperationSource.user);
    expect(operation.payload['candidateId'], 'cand_person_test0001');
    expect(operation.targetEntity?.type, EntityAnchorType.person);
    expect(opened, hasLength(1));
    expect(find.text('검토할 후보가 없습니다.'), findsOneWidget);
  });

  testWidgets('reject dismisses candidate after confirmation', (tester) async {
    final store = _FakeCandidateStore([_candidate()]);
    final executor = _FakeExecutor(store);
    await tester.pumpWidget(_wrap(store: store, executor: executor));
    await tester.pumpAndSettle();

    await tester.tap(find.text('반려'));
    await tester.pumpAndSettle();
    expect(find.text('후보 반려'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '반려'));
    await tester.pumpAndSettle();

    expect(store.dismissed, ['cand_person_test0001']);
    expect(executor.executed, isEmpty);
    expect(find.text('검토할 후보가 없습니다.'), findsOneWidget);
  });

  testWidgets('work candidates cannot be approved in this view', (
    tester,
  ) async {
    final store = _FakeCandidateStore([
      _candidate(
        id: 'cand_work_test0003',
        type: EntityAnchorType.work,
        title: 'Some Manga',
      ),
    ]);
    await tester.pumpWidget(
      _wrap(store: store, executor: _FakeExecutor(store)),
    );
    await tester.pumpAndSettle();

    final approveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '수락'),
    );
    expect(approveButton.onPressed, isNull);
  });
}
