import 'package:akasha/features/workbench/presentation/entity_detail_archive_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EntityDetailArchiveOps.resolveBodyForSave', () {
    testWidgets('returns trimmed body when non-empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));
      final result = EntityDetailArchiveOps.resolveBodyForSave(
        context,
        rawBody: '  본문  ',
        posterPath: '',
        tags: const [],
      );
      expect(result.body, '본문');
      expect(result.usedPlaceholder, isFalse);
    });

    testWidgets('returns null when body and meta are empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));
      final result = EntityDetailArchiveOps.resolveBodyForSave(
        context,
        rawBody: '   ',
        posterPath: '',
        tags: const [],
      );
      expect(result.body, isNull);
    });

    testWidgets('uses placeholder when only meta is present', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));
      final result = EntityDetailArchiveOps.resolveBodyForSave(
        context,
        rawBody: '',
        posterPath: 'https://example.com/poster.jpg',
        tags: const [],
      );
      expect(result.body, kEntityJournalPlaceholderBody);
      expect(result.usedPlaceholder, isTrue);
    });

    testWidgets('uses placeholder when tags are present', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));
      final result = EntityDetailArchiveOps.resolveBodyForSave(
        context,
        rawBody: '',
        posterPath: '',
        tags: const ['태그'],
      );
      expect(result.body, kEntityJournalPlaceholderBody);
      expect(result.usedPlaceholder, isTrue);
    });
  });

  testWidgets('saveSuccessMessage includes entity title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    final entity = UserCatalogEntity(
      entityId: 'ent_person_test',
      entityType: UserCatalogEntity.entityTypePerson,
      title: '테스트 인물',
      subtype: MediaCategory.manga,
      addedAt: DateTime.utc(2024, 1, 1),
    );
    expect(
      EntityDetailArchiveOps.saveSuccessMessage(context, entity),
      contains('테스트 인물'),
    );
  });

  test('hasJournal reflects journal presence', () {
    expect(EntityDetailArchiveOps.hasJournal(null), isFalse);
  });
}
