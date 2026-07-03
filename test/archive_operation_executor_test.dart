import 'dart:convert';
import 'dart:io';

import 'package:akasha/core/archiving/archive_candidate.dart';
import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/archive_candidate_store.dart';
import 'package:akasha/services/archive_operation_executor.dart';
import 'package:akasha/services/archive_record_revision_service.dart';
import 'package:akasha/services/entity_journal_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_user_catalog_port.dart';

void main() {
  group('ArchiveOperationExecutor', () {
    test(
      'promoteCandidate creates entity journal, catalog mirror, and closes candidate',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_operation_executor_',
        );
        final candidateStore = ArchiveCandidateStore();
        final executor = ArchiveOperationExecutor(
          candidateStore: candidateStore,
        );
        final catalog = FakeUserCatalogPort();
        try {
          await candidateStore.upsert(
            vaultPath: tempDir.path,
            candidate: _candidate(),
          );

          final result = await executor.execute(
            vaultPath: tempDir.path,
            userCatalog: catalog,
            operation: _promoteOperation(),
          );

          expect(result.isSuccess, isTrue);
          expect(result.entity?.entityId, 'pe_u_target01');
          expect(result.entry?.entityId, 'pe_u_target01');
          expect(result.candidate?.status, ArchiveCandidateStatus.promoted);
          expect(result.appliedEntry?.operationId, 'op_promote_candidate_001');
          expect(catalog.getById('pe_u_target01')?.title, 'Hero');

          final entityFile = File(
            '${tempDir.path}/entities/person/pe_u_target01.md',
          );
          expect(await entityFile.exists(), isTrue);
          final parsed = EntityJournalParser.parse(
            await entityFile.readAsString(),
            entityFile.path,
          );
          expect(parsed?.title, 'Hero');
          expect(parsed?.body, contains('User-approved promotion note.'));

          final candidateFile = File('${tempDir.path}/catalog/candidates.json');
          final candidatesJson =
              jsonDecode(await candidateFile.readAsString()) as Map;
          final candidates = candidatesJson['candidates'] as List;
          expect(candidates.single['status'], 'promoted');
          expect(candidates.single['proposedEntityId'], 'pe_u_target01');

          expect(
            await File(
              '${tempDir.path}/.akasha/entity_path_index.json',
            ).exists(),
            isTrue,
          );
          expect(
            await File('${tempDir.path}/.akasha/record_index.json').exists(),
            isTrue,
          );
          expect(
            await File('${tempDir.path}/.akasha/ops/applied.jsonl').exists(),
            isTrue,
          );
        } finally {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test(
      'replays same operation as already applied without rewriting files',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'akasha_operation_executor_',
        );
        final candidateStore = ArchiveCandidateStore();
        final executor = ArchiveOperationExecutor(
          candidateStore: candidateStore,
        );
        final catalog = FakeUserCatalogPort();
        try {
          await candidateStore.upsert(
            vaultPath: tempDir.path,
            candidate: _candidate(),
          );
          final operation = _promoteOperation();

          final first = await executor.execute(
            vaultPath: tempDir.path,
            userCatalog: catalog,
            operation: operation,
          );
          final entityFile = File(
            '${tempDir.path}/entities/person/pe_u_target01.md',
          );
          final firstContents = await entityFile.readAsString();
          final logFile = File('${tempDir.path}/.akasha/ops/applied.jsonl');
          expect(await logFile.readAsLines(), hasLength(1));

          final second = await executor.execute(
            vaultPath: tempDir.path,
            userCatalog: catalog,
            operation: operation,
          );

          expect(first.isSuccess, isTrue);
          expect(second.isSuccess, isTrue);
          expect(second.applied, isFalse);
          expect(second.alreadyApplied, isTrue);
          expect(second.appliedEntry?.operationId, operation.operationId);
          expect(await entityFile.readAsString(), firstContents);
          expect(await logFile.readAsLines(), hasLength(1));
          expect(
            (await candidateStore.lookup(
              tempDir.path,
              'cand_person_alpha001',
            ))?.status,
            ArchiveCandidateStatus.promoted,
          );
        } finally {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    test('rejects duplicate catalog title before writing files', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_operation_executor_',
      );
      final candidateStore = ArchiveCandidateStore();
      final executor = ArchiveOperationExecutor(candidateStore: candidateStore);
      final catalog = FakeUserCatalogPort()
        ..seed([
          UserCatalogEntity.userLocal(
            entityId: 'pe_u_exists01',
            type: EntityAnchorType.person,
            title: 'Hero',
            subtype: MediaCategory.manga,
          ),
        ]);
      try {
        await candidateStore.upsert(
          vaultPath: tempDir.path,
          candidate: _candidate(),
        );

        final result = await executor.execute(
          vaultPath: tempDir.path,
          userCatalog: catalog,
          operation: _promoteOperation(),
        );

        expect(result.isSuccess, isFalse);
        expect(_codes(result), contains('candidate_title_duplicate'));
        expect(
          await File(
            '${tempDir.path}/entities/person/pe_u_target01.md',
          ).exists(),
          isFalse,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('rejects duplicate operation title before writing files', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_operation_executor_',
      );
      final candidateStore = ArchiveCandidateStore();
      final executor = ArchiveOperationExecutor(candidateStore: candidateStore);
      final catalog = FakeUserCatalogPort()
        ..seed([
          UserCatalogEntity.userLocal(
            entityId: 'pe_u_exists01',
            type: EntityAnchorType.person,
            title: 'Renamed Hero',
            subtype: MediaCategory.manga,
          ),
        ]);
      try {
        await candidateStore.upsert(
          vaultPath: tempDir.path,
          candidate: _candidate(),
        );

        final result = await executor.execute(
          vaultPath: tempDir.path,
          userCatalog: catalog,
          operation: _promoteOperation(title: 'Renamed Hero'),
        );

        expect(result.isSuccess, isFalse);
        expect(_codes(result), contains('candidate_title_duplicate'));
        expect(
          await File(
            '${tempDir.path}/entities/person/pe_u_target01.md',
          ).exists(),
          isFalse,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('rejects existing target record before writing files', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_operation_executor_',
      );
      final candidateStore = ArchiveCandidateStore();
      final executor = ArchiveOperationExecutor(candidateStore: candidateStore);
      final entityFile = File(
        '${tempDir.path}/entities/person/pe_u_target01.md',
      );
      try {
        await entityFile.parent.create(recursive: true);
        await entityFile.writeAsString(
          'existing entity should not be overwritten',
          flush: true,
        );
        await candidateStore.upsert(
          vaultPath: tempDir.path,
          candidate: _candidate(),
        );

        final result = await executor.execute(
          vaultPath: tempDir.path,
          userCatalog: FakeUserCatalogPort(),
          operation: _promoteOperation(),
        );

        expect(result.isSuccess, isFalse);
        expect(_codes(result), contains('operation_conflict'));
        expect(
          await entityFile.readAsString(),
          'existing entity should not be overwritten',
        );
        expect(
          (await candidateStore.lookup(
            tempDir.path,
            'cand_person_alpha001',
          ))?.status,
          ArchiveCandidateStatus.candidate,
        );
        expect(
          await File('${tempDir.path}/.akasha/ops/applied.jsonl').exists(),
          isFalse,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('rejects stale expectedRevision before writing files', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_operation_executor_',
      );
      final candidateStore = ArchiveCandidateStore();
      final executor = ArchiveOperationExecutor(candidateStore: candidateStore);
      try {
        await candidateStore.upsert(
          vaultPath: tempDir.path,
          candidate: _candidate(),
        );

        final result = await executor.execute(
          vaultPath: tempDir.path,
          userCatalog: FakeUserCatalogPort(),
          operation: _promoteOperation(expectedRevision: 'v1:stale'),
        );

        expect(result.isSuccess, isFalse);
        expect(_codes(result), contains('operation_conflict'));
        expect(
          await File(
            '${tempDir.path}/entities/person/pe_u_target01.md',
          ).exists(),
          isFalse,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('accepts explicit missing expectedRevision for new target', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_operation_executor_',
      );
      final candidateStore = ArchiveCandidateStore();
      final executor = ArchiveOperationExecutor(candidateStore: candidateStore);
      try {
        await candidateStore.upsert(
          vaultPath: tempDir.path,
          candidate: _candidate(),
        );

        final result = await executor.execute(
          vaultPath: tempDir.path,
          userCatalog: FakeUserCatalogPort(),
          operation: _promoteOperation(
            expectedRevision: ArchiveRecordRevision.missing,
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(result.applied, isTrue);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('rejects missing candidate', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_operation_executor_',
      );
      final executor = ArchiveOperationExecutor();
      try {
        final result = await executor.execute(
          vaultPath: tempDir.path,
          userCatalog: FakeUserCatalogPort(),
          operation: _promoteOperation(),
        );

        expect(result.isSuccess, isFalse);
        expect(_codes(result), contains('candidate_not_found'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('rejects unsupported operation without side effects', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_operation_executor_',
      );
      final executor = ArchiveOperationExecutor();
      try {
        final result = await executor.execute(
          vaultPath: tempDir.path,
          userCatalog: FakeUserCatalogPort(),
          operation: ArchiveOperation(
            operationId: 'op_append_001',
            type: ArchiveOperationType.appendSection,
            recordKind: RecordKind.entityJournal,
            source: ArchiveOperationSource.agent,
            createdAt: DateTime.utc(2026, 7, 3),
            targetRecordId: 'rec_pe_u_target01',
            payload: const {'body': 'Not executable here.'},
          ),
        );

        expect(result.isSuccess, isFalse);
        expect(_codes(result), contains('operation_not_supported'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}

ArchiveCandidate _candidate() {
  return ArchiveCandidate(
    candidateId: 'cand_person_alpha001',
    entityType: EntityAnchorType.person,
    title: 'Hero',
    sourceRecordId: 'rec_wk_u_source1',
    evidence: 'Appears in the third scene.',
    confidence: 0.86,
    aliases: const ['The Hero'],
    tags: const ['pilot'],
    createdAt: DateTime.utc(2026, 7, 3),
    updatedAt: DateTime.utc(2026, 7, 3),
  );
}

ArchiveOperation _promoteOperation({String? title, String? expectedRevision}) {
  return ArchiveOperation(
    operationId: 'op_promote_candidate_001',
    type: ArchiveOperationType.promoteCandidate,
    recordKind: RecordKind.entityJournal,
    source: ArchiveOperationSource.agent,
    createdAt: DateTime.utc(2026, 7, 3),
    title: title,
    expectedRevision: expectedRevision,
    targetEntity: const EntityAnchor(
      entityId: 'pe_u_target01',
      type: EntityAnchorType.person,
    ),
    payload: const {
      'candidateId': 'cand_person_alpha001',
      'body': 'User-approved promotion note.',
    },
  );
}

Set<String> _codes(ArchiveOperationExecutionResult result) =>
    result.issues.map((issue) => issue.code).toSet();
