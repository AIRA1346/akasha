import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/catalog_entity_add_result.dart';
import '../models/user_catalog_entity.dart';
import 'entity_catalog_sync.dart';
import 'entity_vault_store.dart';
import 'file_service.dart';

/// Person · Event · Concept Archive-First save — R1.
abstract final class EntityArchiveService {
  static bool usesArchiveFirstFlow(EntityAnchorType type) {
    return type == EntityAnchorType.person ||
        type == EntityAnchorType.concept ||
        type == EntityAnchorType.event;
  }

  static Future<({UserCatalogEntity entity, EntityJournalEntry? entry})>
      saveFromAddResult({
    required CatalogEntityAddResult result,
    required String vaultPath,
    required UserCatalogPort userCatalog,
    EntityVaultStore? vaultStore,
  }) async {
    await userCatalog.load();
    final store = vaultStore ?? EntityVaultStore();

    if (result.nameOnly) {
      await userCatalog.upsert(result.entity);
      return (entity: result.entity, entry: null);
    }

    final saved = await store.saveCatalogEntity(
      vaultPath: vaultPath,
      entity: result.entity,
      body: result.journalBody,
    );
    final mirrored = EntityCatalogSync.mirrorFromJournal(
      draft: result.entity,
      entry: saved,
    );
    await userCatalog.upsert(mirrored);
    await AkashaFileService().signalVaultChanged();
    return (entity: mirrored, entry: saved);
  }

  /// Entity Sheet save 후 catalog mirror — R1.1 Step 1.
  static Future<UserCatalogEntity> syncCatalogFromJournal({
    required UserCatalogEntity draft,
    required EntityJournalEntry entry,
    required UserCatalogPort userCatalog,
  }) async {
    final mirrored = EntityCatalogSync.mirrorFromJournal(
      draft: draft,
      entry: entry,
    );
    await userCatalog.upsert(mirrored);
    return mirrored;
  }

  /// Entity 삭제 — `.md` 삭제 성공 후 catalog remove. R1.1 Step 2.
  static Future<bool> deleteArchivedEntity({
    required EntityJournalEntry entry,
    required UserCatalogPort userCatalog,
    EntityVaultStore? vaultStore,
  }) async {
    final store = vaultStore ?? EntityVaultStore();
    final deleted = await store.deleteEntry(entry.storagePath);
    if (!deleted) return false;
    await userCatalog.remove(entry.entityId);
    return true;
  }

  static Future<EntityJournalEntry> promoteCatalogOnly({
    required UserCatalogEntity entity,
    required String vaultPath,
    EntityVaultStore? vaultStore,
  }) async {
    final store = vaultStore ?? EntityVaultStore();
    return store.saveCatalogEntity(
      vaultPath: vaultPath,
      entity: entity,
      body: '',
    );
  }
}
