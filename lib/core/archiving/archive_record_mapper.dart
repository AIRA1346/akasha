import '../../models/akasha_item.dart';
import '../../services/file_service.dart';
import 'archive_record.dart';
import 'entity_anchor.dart';
import 'record_kind.dart';
import 'timeline_entry.dart';

/// Phase 0 [AkashaItem] ↔ Phase 1 [ArchiveRecord] ([ADR-008]).
abstract final class ArchiveRecordMapper {
  static ArchiveRecord fromAkashaItem(AkashaItem item) {
    final recordId = _recordIdFor(item);
    final entity = _entityFor(item);

    return ArchiveRecord(
      recordId: recordId,
      kind: entity == null ? RecordKind.freeformJournal : RecordKind.workJournal,
      entity: entity,
      timeAnchor: item.addedAt,
      storagePath: item.filePath,
      title: item.title,
    );
  }

  static EntityAnchor? _entityFor(AkashaItem item) {
    final id = item.workId.trim();
    if (id.isEmpty) return null;
    return EntityAnchor(entityId: id, type: EntityAnchorType.work);
  }

  static String _recordIdFor(AkashaItem item) {
    final workId = item.workId.trim();
    if (workId.isNotEmpty) return workId;
    if (item.filePath != null && item.filePath!.isNotEmpty) {
      return item.filePath!;
    }
    return AkashaFileService.cacheKeyFor(item);
  }

  static ArchiveRecord fromTimelineEntry(TimelineEntry entry) {
    EntityAnchor? entity;
    final entityId = entry.entityId?.trim();
    if (entityId != null && entityId.isNotEmpty) {
      entity = EntityAnchor(
        entityId: entityId,
        type: entityId.startsWith('wk_')
            ? EntityAnchorType.work
            : EntityAnchorType.custom,
      );
    }

    return ArchiveRecord(
      recordId: entry.recordId,
      kind: RecordKind.timelineEntry,
      entity: entity,
      timeAnchor: entry.occurredAt,
      storagePath: entry.storagePath,
      title: entry.title,
    );
  }
}
