import 'package:akasha/features/workbench/presentation/entity_detail_archive_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntityDetailArchiveOps.resolveBodyForSave', () {
    test('returns trimmed body when non-empty', () {
      final result = EntityDetailArchiveOps.resolveBodyForSave(
        rawBody: '  본문  ',
        posterPath: '',
        tags: const [],
      );
      expect(result.body, '본문');
      expect(result.usedPlaceholder, isFalse);
    });

    test('returns null when body and meta are empty', () {
      final result = EntityDetailArchiveOps.resolveBodyForSave(
        rawBody: '   ',
        posterPath: '',
        tags: const [],
      );
      expect(result.body, isNull);
    });

    test('uses placeholder when only meta is present', () {
      final result = EntityDetailArchiveOps.resolveBodyForSave(
        rawBody: '',
        posterPath: 'https://example.com/poster.jpg',
        tags: const [],
      );
      expect(result.body, kEntityJournalPlaceholderBody);
      expect(result.usedPlaceholder, isTrue);
    });

    test('uses placeholder when tags are present', () {
      final result = EntityDetailArchiveOps.resolveBodyForSave(
        rawBody: '',
        posterPath: '',
        tags: const ['태그'],
      );
      expect(result.body, kEntityJournalPlaceholderBody);
      expect(result.usedPlaceholder, isTrue);
    });
  });

  test('saveSuccessMessage includes entity title', () {
    final entity = UserCatalogEntity(
      entityId: 'ent_person_test',
      entityType: UserCatalogEntity.entityTypePerson,
      title: '테스트 인물',
      subtype: MediaCategory.manga,
      addedAt: DateTime.utc(2024, 1, 1),
    );
    expect(
      EntityDetailArchiveOps.saveSuccessMessage(entity),
      contains('테스트 인물'),
    );
  });

  test('hasJournal reflects journal presence', () {
    expect(EntityDetailArchiveOps.hasJournal(null), isFalse);
  });
}
