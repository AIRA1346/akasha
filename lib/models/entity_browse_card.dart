import '../core/archiving/entity_journal_entry.dart';
import 'user_catalog_entity.dart';

/// Entity gallery grid — 1 cell view model (Phase 1 derived fields only).
class EntityBrowseCard {
  const EntityBrowseCard({
    required this.entity,
    this.journal,
    required this.isArchived,
    this.incomingRecordCount = 0,
    this.bodyPreview = '',
  });

  final UserCatalogEntity entity;
  final EntityJournalEntry? journal;
  final bool isArchived;
  final int incomingRecordCount;
  final String bodyPreview;
}
