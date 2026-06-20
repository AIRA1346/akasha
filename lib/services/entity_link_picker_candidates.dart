import '../core/archiving/entity_anchor.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/user_catalog_entity.dart';
import 'entity_archive_service.dart';
import 'entity_vault_loader.dart';
import 'file_service.dart';

/// Entity link picker 후보 목록 — archived 우선 · R1 type filter.
class EntityLinkPickerCandidate {
  const EntityLinkPickerCandidate({
    required this.entity,
    required this.isArchived,
  });

  final UserCatalogEntity entity;
  final bool isArchived;
}

abstract final class EntityLinkPickerCandidates {
  static const Set<EntityAnchorType> _linkableTypes = {
    EntityAnchorType.person,
    EntityAnchorType.event,
    EntityAnchorType.concept,
  };

  static Future<Set<String>> loadArchivedEntityIds({
    EntityVaultLoader? loader,
    String? vaultPath,
  }) async {
    final path = vaultPath ?? AkashaFileService().vaultPath;
    final vaultLoader = loader ?? const EntityVaultLoader();
    final journals = await vaultLoader.loadFromVault(path);
    return journals.map((e) => e.entityId).where((id) => id.isNotEmpty).toSet();
  }

  static Future<List<EntityLinkPickerCandidate>> build({
    required UserCatalogPort userCatalog,
    required String query,
    Set<String>? archivedEntityIds,
    EntityVaultLoader? loader,
    String? vaultPath,
  }) async {
    await userCatalog.load();
    final archived = archivedEntityIds ??
        await loadArchivedEntityIds(loader: loader, vaultPath: vaultPath);

    final trimmed = query.trim();
    final raw = trimmed.isEmpty
        ? userCatalog.all
        : userCatalog.search(trimmed);

    final filtered = raw.where(_isLinkableEntity).toList();

    final candidates = filtered
        .map(
          (entity) => EntityLinkPickerCandidate(
            entity: entity,
            isArchived: archived.contains(entity.entityId),
          ),
        )
        .toList();

    candidates.sort(_compareCandidates);
    return candidates;
  }

  static bool _isLinkableEntity(UserCatalogEntity entity) {
    if (entity.isWorkEntity) return false;
    if (!_linkableTypes.contains(entity.anchorType)) return false;
    return EntityArchiveService.usesArchiveFirstFlow(entity.anchorType);
  }

  static int _compareCandidates(
    EntityLinkPickerCandidate a,
    EntityLinkPickerCandidate b,
  ) {
    if (a.isArchived != b.isArchived) {
      return a.isArchived ? -1 : 1;
    }
    return a.entity.title.toLowerCase().compareTo(b.entity.title.toLowerCase());
  }
}
