import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/archive_operation.dart';
import 'package:akasha/core/archiving/archive_operation_validator.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/core/archiving/relation_vocabulary.dart';

void main() {
  group('RelationVocabulary', () {
    test('accepts every core relation', () {
      for (final relation in RelationVocabulary.core) {
        expect(RelationVocabulary.isConforming(relation), isTrue,
            reason: '"$relation" is core vocabulary');
      }
    });

    test('accepts well-formed user-namespaced relations', () {
      expect(RelationVocabulary.isConforming('u:voiced_by'), isTrue);
      expect(RelationVocabulary.isConforming('u:pet_of'), isTrue);
      expect(RelationVocabulary.isConforming('u:a'), isTrue);
    });

    test('rejects non-conforming relations', () {
      expect(RelationVocabulary.isConforming('voiced_by'), isFalse);
      expect(RelationVocabulary.isConforming('u:'), isFalse);
      expect(RelationVocabulary.isConforming('u:Voiced By'), isFalse);
      expect(RelationVocabulary.isConforming('u:한국어'), isFalse);
      expect(
        RelationVocabulary.isConforming('u:${'a' * 41}'),
        isFalse,
        reason: 'token longer than 40 chars',
      );
    });

    test('core vocabulary is frozen at the spec §4.1 set', () {
      expect(RelationVocabulary.core, {
        'related',
        'about',
        'appears_in',
        'created_by',
        'part_of',
        'member_of',
        'located_in',
        'inspired_by',
      });
    });
  });

  group('ArchiveOperationValidator addLink relation', () {
    ArchiveOperation buildAddLink(Map<String, dynamic> payload) {
      return ArchiveOperation(
        operationId: 'op_link_relation',
        type: ArchiveOperationType.addLink,
        recordKind: RecordKind.workJournal,
        source: ArchiveOperationSource.agent,
        createdAt: DateTime.utc(2026, 7, 6),
        targetRecordId: 'rec_wk_u_abc12345',
        payload: payload,
      );
    }

    test('accepts core relation', () {
      final result = ArchiveOperationValidator.validate(
        buildAddLink(const {
          'targetEntityId': 'pe_u_abc12345',
          'relation': 'appears_in',
        }),
      );
      expect(result.isValid, isTrue);
    });

    test('accepts user-namespaced relation', () {
      final result = ArchiveOperationValidator.validate(
        buildAddLink(const {
          'targetEntityId': 'pe_u_abc12345',
          'relation': 'u:voiced_by',
        }),
      );
      expect(result.isValid, isTrue);
    });

    test('accepts omitted relation (defaults to related)', () {
      final result = ArchiveOperationValidator.validate(
        buildAddLink(const {'targetEntityId': 'pe_u_abc12345'}),
      );
      expect(result.isValid, isTrue);
    });

    test('rejects non-conforming relation', () {
      final result = ArchiveOperationValidator.validate(
        buildAddLink(const {
          'targetEntityId': 'pe_u_abc12345',
          'relation': 'voiced_by',
        }),
      );
      expect(result.isValid, isFalse);
      expect(
        result.errors.map((issue) => issue.code),
        contains('link_relation_unknown'),
      );
    });
  });
}
