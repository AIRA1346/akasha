import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/archive_operation_validator.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveOperationValidator', () {
    test('accepts ID-based work create operation', () {
      final operation = ArchiveOperation(
        operationId: 'op_create_work_001',
        type: ArchiveOperationType.createRecord,
        recordKind: RecordKind.workJournal,
        source: ArchiveOperationSource.agent,
        createdAt: DateTime.utc(2026, 7, 3),
        targetEntity: const EntityAnchor(
          entityId: 'wk_u_abc12345',
          type: EntityAnchorType.work,
        ),
        title: 'Action Movie',
        payload: const {
          'body': 'Great opening theme.',
          'tags': ['action', 'ost'],
        },
      );

      final result = ArchiveOperationValidator.validate(operation);

      expect(result.isValid, isTrue);
      expect(operation.effectiveRecordId, 'rec_wk_u_abc12345');
    });

    test('requires target entity when creating work or entity record', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_create_missing_entity',
          type: ArchiveOperationType.createRecord,
          recordKind: RecordKind.entityJournal,
          source: ArchiveOperationSource.agent,
          createdAt: DateTime.utc(2026, 7, 3),
          title: 'A Character',
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('entity_required'));
    });

    test('blocks identity mutation and direct path fields', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_update_identity',
          type: ArchiveOperationType.updateFrontmatter,
          recordKind: RecordKind.workJournal,
          source: ArchiveOperationSource.agent,
          createdAt: DateTime.utc(2026, 7, 3),
          targetRecordId: 'rec_wk_u_abc12345',
          payload: const {
            'title': 'Renamed',
            'entity_id': 'wk_u_other123',
            'path': 'works/movie/renamed.md',
          },
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('immutable_frontmatter'));
      expect(_codes(result), contains('payload_path_forbidden'));
    });

    test('accepts append section with derived primary record id', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_append_reflection',
          type: ArchiveOperationType.appendSection,
          recordKind: RecordKind.entityJournal,
          source: ArchiveOperationSource.user,
          createdAt: DateTime.utc(2026, 7, 3),
          targetEntity: const EntityAnchor(
            entityId: 'pe_u_abc12345',
            type: EntityAnchorType.person,
          ),
          payload: const {'heading': '감상', 'body': '이 인물은 작품의 리듬을 바꾼다.'},
        ),
      );

      expect(result.isValid, isTrue);
    });

    test('rejects invalid rating range', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_bad_rating',
          type: ArchiveOperationType.setRating,
          recordKind: RecordKind.workJournal,
          source: ArchiveOperationSource.agent,
          createdAt: DateTime.utc(2026, 7, 3),
          targetRecordId: 'rec_wk_u_abc12345',
          payload: const {'rating': 7},
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('rating_range'));
    });

    test('rejects blank tags', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_blank_tags',
          type: ArchiveOperationType.addTags,
          recordKind: RecordKind.workJournal,
          source: ArchiveOperationSource.agent,
          createdAt: DateTime.utc(2026, 7, 3),
          targetRecordId: 'rec_wk_u_abc12345',
          payload: const {
            'tags': ['action', ''],
          },
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('tag_blank'));
    });

    test('validates link target entity id safety', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_bad_link',
          type: ArchiveOperationType.addLink,
          recordKind: RecordKind.workJournal,
          source: ArchiveOperationSource.agent,
          createdAt: DateTime.utc(2026, 7, 3),
          targetRecordId: 'rec_wk_u_abc12345',
          payload: const {'targetEntityId': '../pe_u_abc12345'},
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('entity_id_unsafe'));
    });

    test('validates candidate promotion target', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_promote_candidate',
          type: ArchiveOperationType.promoteCandidate,
          recordKind: RecordKind.entityJournal,
          source: ArchiveOperationSource.agent,
          createdAt: DateTime.utc(2026, 7, 3),
          targetEntity: const EntityAnchor(
            entityId: 'co_u_abc12345',
            type: EntityAnchorType.concept,
          ),
          payload: const {'candidateId': 'cand_co_001'},
        ),
      );

      expect(result.isValid, isTrue);
    });

    test('rejects unsafe candidate id on promotion operation', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_promote_bad_candidate',
          type: ArchiveOperationType.promoteCandidate,
          recordKind: RecordKind.entityJournal,
          source: ArchiveOperationSource.agent,
          createdAt: DateTime.utc(2026, 7, 3),
          targetEntity: const EntityAnchor(
            entityId: 'co_u_abc12345',
            type: EntityAnchorType.concept,
          ),
          payload: const {'candidateId': '../bad'},
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('candidate_id_unsafe'));
    });

    test('rejects merge with same canonical and duplicate id', () {
      final result = ArchiveOperationValidator.validate(
        ArchiveOperation(
          operationId: 'op_merge_same',
          type: ArchiveOperationType.mergeDuplicate,
          recordKind: RecordKind.entityJournal,
          source: ArchiveOperationSource.user,
          createdAt: DateTime.utc(2026, 7, 3),
          payload: const {
            'canonicalEntityId': 'pe_u_abc12345',
            'duplicateEntityId': 'pe_u_abc12345',
          },
        ),
      );

      expect(result.isValid, isFalse);
      expect(_codes(result), contains('merge_ids_same'));
    });

    test('round-trips operation JSON', () {
      final operation = ArchiveOperation(
        operationId: 'op_json_round_trip',
        type: ArchiveOperationType.setStatus,
        recordKind: RecordKind.workJournal,
        source: ArchiveOperationSource.script,
        createdAt: DateTime.utc(2026, 7, 3),
        targetEntity: const EntityAnchor(
          entityId: 'wk_u_abc12345',
          type: EntityAnchorType.work,
        ),
        payload: const {'status': 'favorite'},
      );

      final restored = ArchiveOperation.fromJson(operation.toJson());

      expect(restored.operationId, operation.operationId);
      expect(restored.type, operation.type);
      expect(restored.source, operation.source);
      expect(restored.targetEntity?.entityId, 'wk_u_abc12345');
      expect(restored.payload['status'], 'favorite');
    });
  });
}

Set<String> _codes(ArchiveOperationValidationResult result) =>
    result.issues.map((issue) => issue.code).toSet();
