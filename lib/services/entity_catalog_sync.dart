import '../core/archiving/entity_journal_entry.dart';
import '../models/user_catalog_entity.dart';

/// journal save 후 catalog JSON mirror — Archive-First R1.
abstract final class EntityCatalogSync {
  static UserCatalogEntity mirrorFromJournal({
    required UserCatalogEntity draft,
    required EntityJournalEntry entry,
  }) {
    return UserCatalogEntity(
      entityId: entry.entityId,
      entityType: entry.entityType.name,
      subtype: draft.subtype,
      title: entry.title,
      titles: draft.titles,
      creator: draft.creator,
      releaseYear: draft.releaseYear,
      domain: draft.domain,
      aliases: draft.aliases,
      addedAt: entry.addedAt,
    );
  }
}
