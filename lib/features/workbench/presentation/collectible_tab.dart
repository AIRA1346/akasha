import '../../../core/archiving/entity_journal_entry.dart';
import '../../../models/akasha_item.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../services/file_service.dart';

/// Workbench tab — Work or Entity collectible (Phase 6).
sealed class CollectibleTab {
  String get id;
  String get title;
  bool get isDirty;
  set isDirty(bool value);
}

final class WorkCollectibleTab extends CollectibleTab {
  WorkCollectibleTab({
    required this.id,
    required this.item,
    this.isDirty = false,
  });

  @override
  final String id;

  AkashaItem item;

  @override
  bool isDirty;

  @override
  String get title => item.title;

  static String idFor(AkashaItem item) {
    if (item.workId.isNotEmpty) return item.workId;
    return AkashaFileService.cacheKeyFor(item);
  }
}

final class EntityCollectibleTab extends CollectibleTab {
  EntityCollectibleTab({
    required this.entity,
    this.journal,
    this.isDirty = false,
  }) : id = idFor(entity.entityId);

  @override
  final String id;

  UserCatalogEntity entity;
  EntityJournalEntry? journal;

  @override
  bool isDirty;

  @override
  String get title => entity.title;

  static String idFor(String entityId) => entityId;
}
