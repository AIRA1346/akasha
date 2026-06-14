import 'package:akasha/core/archiving/archive_record_mapper.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/record_kind.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchiveRecordMapper', () {
    test('work journal maps entity anchor from workId', () {
      final item = ContentItem(
        workId: 'wk_test123',
        title: 'Frieren',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
      )..filePath = r'C:\vault\animation\Frieren.md';

      final record = ArchiveRecordMapper.fromAkashaItem(item);

      expect(record.kind, RecordKind.workJournal);
      expect(record.entity?.entityId, 'wk_test123');
      expect(record.entity?.type, EntityAnchorType.work);
      expect(record.recordId, 'wk_test123');
      expect(record.storagePath, item.filePath);
    });

    test('freeform journal when workId empty', () {
      final item = ContentItem(
        workId: '',
        title: '오늘의 메모',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
      )..filePath = r'C:\vault\notes\today.md';

      final record = ArchiveRecordMapper.fromAkashaItem(item);

      expect(record.kind, RecordKind.freeformJournal);
      expect(record.entity, isNull);
      expect(record.recordId, item.filePath);
    });
  });
}
