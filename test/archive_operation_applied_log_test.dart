import 'dart:convert';
import 'dart:io';

import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/services/archive_operation_applied_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveOperationAppliedLog', () {
    test('appendApplied writes JSONL under system/ops folder', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_applied_log_',
      );
      const log = ArchiveOperationAppliedLog();
      try {
        final entry = await log.appendApplied(
          vaultPath: tempDir.path,
          operation: _operation(),
          recordPath: '${tempDir.path}/entities/person/pe_u_target01.md',
          appliedAt: DateTime.utc(2026, 7, 4),
        );

        expect(entry.operationId, 'op_promote_candidate_001');
        expect(entry.result, ArchiveOperationAppliedLog.appliedResult);
        expect(entry.recordPath, 'entities/person/pe_u_target01.md');

        final file = File('${tempDir.path}/system/ops/applied.jsonl');
        expect(await file.exists(), isTrue);
        final lines = await file.readAsLines();
        expect(lines, hasLength(1));

        final decoded = jsonDecode(lines.single) as Map<String, dynamic>;
        expect(
          decoded['schemaVersion'],
          ArchiveOperationAppliedEntry.schemaVersion,
        );
        expect(decoded['operationId'], 'op_promote_candidate_001');
        expect(decoded['targetEntityId'], 'pe_u_target01');
        expect(decoded['candidateId'], 'cand_person_alpha001');

        final lookedUp = await log.lookup(
          tempDir.path,
          'op_promote_candidate_001',
        );
        expect(lookedUp?.recordPath, 'entities/person/pe_u_target01.md');
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('appendApplied keeps operationId idempotent', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'akasha_applied_log_',
      );
      const log = ArchiveOperationAppliedLog();
      try {
        final first = await log.appendApplied(
          vaultPath: tempDir.path,
          operation: _operation(),
          appliedAt: DateTime.utc(2026, 7, 4),
        );
        final second = await log.appendApplied(
          vaultPath: tempDir.path,
          operation: _operation(),
          appliedAt: DateTime.utc(2026, 7, 5),
        );

        expect(second.appliedAt, first.appliedAt);
        expect(await log.load(tempDir.path), hasLength(1));
        expect(
          await File('${tempDir.path}/system/ops/applied.jsonl').readAsLines(),
          hasLength(1),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}

ArchiveOperation _operation() {
  return ArchiveOperation(
    operationId: 'op_promote_candidate_001',
    type: ArchiveOperationType.promoteCandidate,
    recordKind: RecordKind.entityJournal,
    source: ArchiveOperationSource.agent,
    createdAt: DateTime.utc(2026, 7, 3),
    targetEntity: const EntityAnchor(
      entityId: 'pe_u_target01',
      type: EntityAnchorType.person,
    ),
    payload: const {'candidateId': 'cand_person_alpha001'},
  );
}
