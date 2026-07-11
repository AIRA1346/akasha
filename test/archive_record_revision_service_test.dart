import 'dart:io';

import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/services/archive_record_revision_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveRecordRevisionService', () {
    test('returns missing for absent operation target', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_revision_');
      const service = ArchiveRecordRevisionService();
      try {
        final revision = await service.currentForOperation(
          vaultPath: tempDir.path,
          operation: _operation(),
        );

        expect(revision.exists, isFalse);
        expect(revision.value, ArchiveRecordRevision.missing);
        expect(
          revision.absolutePath?.replaceAll('\\', '/'),
          endsWith('entities/person/pe_u_target01.md'),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('revision changes when file content changes', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_revision_');
      const service = ArchiveRecordRevisionService();
      final file = File('${tempDir.path}/entities/person/pe_u_target01.md');
      try {
        await file.parent.create(recursive: true);
        await file.writeAsString('first', flush: true);

        final first = await service.currentForPath(file.path);
        await file.writeAsString('second', flush: true);
        final second = await service.currentForPath(file.path);

        expect(first.exists, isTrue);
        expect(second.exists, isTrue);
        expect(first.value, isNot(second.value));
        expect(first.value, startsWith('v2:sha256:'));
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('revision ignores a modification-time-only change', () async {
      final tempDir = await Directory.systemTemp.createTemp('akasha_revision_');
      const service = ArchiveRecordRevisionService();
      final file = File('${tempDir.path}/journals/source.md');
      try {
        await file.parent.create(recursive: true);
        await file.writeAsString('same content', flush: true);
        final first = await service.currentForPath(file.path);

        await file.setLastModified(DateTime.utc(2030, 1, 1));
        final second = await service.currentForPath(file.path);

        expect(first.value, second.value);
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
    operationId: 'op_revision_001',
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
