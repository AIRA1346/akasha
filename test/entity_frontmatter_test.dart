import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/entity_frontmatter.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/work_id_codec.dart';

void main() {
  group('EntityFrontmatter.inferFromYaml', () {
    test('legacy work_id only infers work entity', () {
      final meta = EntityFrontmatter.inferFromYaml(
        {
          'work_id': 'sub_manga_legacy_2020',
          'category': 'manga',
        },
        categoryFallback: MediaCategory.animation,
      );

      expect(meta.entityType, EntityAnchorType.work);
      expect(meta.entityId, 'sub_manga_legacy_2020');
      expect(meta.subtype, MediaCategory.manga);
      expect(meta.recordKind, RecordKind.workJournal);
    });

    test('entity_id wins over work_id', () {
      final meta = EntityFrontmatter.inferFromYaml(
        {
          'entity_id': 'wk_u_abc12345',
          'work_id': 'wk_000000001',
          'entity_type': 'work',
          'subtype': 'animation',
        },
        categoryFallback: MediaCategory.manga,
      );

      expect(meta.entityId, 'wk_u_abc12345');
      expect(meta.subtype, MediaCategory.animation);
    });

    test('v2 full frontmatter round-trips lazy fields', () {
      const workId = 'wk_u_fixt0001';
      final meta = EntityFrontmatter.forWorkItem(
        workId: workId,
        category: MediaCategory.animation,
      );
      final fields = meta.toLazyWriteFields();

      expect(fields['entity_type'], 'work');
      expect(fields['entity_id'], workId);
      expect(fields['subtype'], 'animation');
      expect(fields['record_kind'], 'workJournal');
    });

    test('wk_u id forces work type even if entity_type differs', () {
      final meta = EntityFrontmatter.inferFromYaml(
        {
          'entity_id': 'wk_u_test1234',
          'entity_type': 'person',
        },
        categoryFallback: MediaCategory.manga,
      );

      expect(meta.entityType, EntityAnchorType.work);
      expect(WorkIdCodec.isUserLocalWorkId(meta.entityId), isTrue);
    });
  });
}
