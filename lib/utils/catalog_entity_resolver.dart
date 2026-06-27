import '../core/app_vault.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../core/archiving/record_link.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../services/entity_vault_loader.dart';
import '../services/record_link_navigator.dart';

/// 링크 대상 entity id 해석 + 카탈로그·볼트 journal 폴백.
abstract final class CatalogEntityResolver {
  static String? recordLinkEntityId(
    RecordLink link, {
    required UserCatalogPort userCatalog,
    required List<AkashaItem> vaultItems,
  }) {
    final explicit = link.targetEntityId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    if (link.kind == RecordLinkKind.titleOnly) {
      final title = link.targetTitle ?? link.raw;
      return RecordLinkNavigator.resolveTitleToEntityId(
        title,
        userCatalog: userCatalog,
        vaultItems: vaultItems,
      );
    }
    return null;
  }

  static Future<Map<String, UserCatalogEntity>> resolveMany({
    required Iterable<String> entityIds,
    required UserCatalogPort userCatalog,
    EntityVaultLoader? vaultLoader,
    String? vaultPath,
  }) async {
    await userCatalog.load();
    final unique = entityIds.where((id) => id.isNotEmpty).toSet();
    if (unique.isEmpty) return const {};

    final loader = vaultLoader ?? const EntityVaultLoader();
    final root = vaultPath ?? AppVault.port.vaultPath;
    Map<String, EntityJournalEntry>? journalsById;

    Future<EntityJournalEntry?> journalFor(String id) async {
      journalsById ??= {
        for (final entry in await loader.loadFromVault(root)) entry.entityId: entry,
      };
      return journalsById![id];
    }

    final resolved = <String, UserCatalogEntity>{};
    for (final id in unique) {
      final fromCatalog = userCatalog.getById(id);
      if (fromCatalog != null) {
        resolved[id] = fromCatalog;
        continue;
      }
      final journal = await journalFor(id);
      if (journal == null) continue;
      resolved[id] = UserCatalogEntity.userLocal(
        entityId: journal.entityId,
        type: journal.entityType,
        title: journal.title,
        tags: journal.tags,
        addedAt: journal.addedAt,
        posterPath: journal.posterPath,
      );
    }
    return resolved;
  }
}
