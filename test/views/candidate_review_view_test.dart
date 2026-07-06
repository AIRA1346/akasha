import 'package:akasha/core/archiving/archive_candidate.dart';
import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/views/candidate_review_view.dart';
import 'package:akasha/services/archive_candidate_store.dart';
import 'package:akasha/services/archive_operation_executor.dart';
import 'package:akasha/theme/akasha_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_user_catalog_port.dart';

class _FakeCandidateStore extends ArchiveCandidateStore {
  _FakeCandidateStore(List<ArchiveCandidate> seed)
    : candidates = List.of(seed);

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
      candidates[index] = candidates[index].markDismissed(
        updatedAt: updatedAt,
      );
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

ArchiveCandidate _candidate({
  String id = 'cand_person_test0001',
  EntityAnchorType type = EntityAnchorType.person,
  String title = 'Ars Almadel',
  double confidence = 0.9,
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
  );
}

Widget _wrap({
  required _FakeCandidateStore store,
  required _FakeExecutor executor,
  Future<void> Function(UserCatalogEntity entity)? onOpenEntity,
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
