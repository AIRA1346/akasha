import '../core/archiving/entity_anchor.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/entity_fact.dart';
import '../models/user_catalog_entity.dart';
import '../utils/discovery_linkable_types.dart';
import 'entity_seed_catalog_promotion.dart';
import 'entity_vault_loader.dart';
import 'file_service.dart';
import 'person_seed_registry.dart';

/// Entity link picker 후보 출처 (R8 P0).
enum EntityLinkPickerCandidateOrigin {
  catalog,
  seed,
}

/// Entity link picker 후보 목록 — archived 우선 · R1 type filter · seed fallback.
class EntityLinkPickerCandidate {
  const EntityLinkPickerCandidate({
    required this.entity,
    required this.isArchived,
    this.origin = EntityLinkPickerCandidateOrigin.catalog,
    this.seedFact,
  });

  final UserCatalogEntity entity;
  final bool isArchived;
  final EntityLinkPickerCandidateOrigin origin;

  /// [origin] == seed 일 때 승격에 사용하는 원본 Fact.
  final EntityFact? seedFact;

  bool get isSeed => origin == EntityLinkPickerCandidateOrigin.seed;
}

abstract final class EntityLinkPickerCandidates {
  static const Set<EntityAnchorType> _linkableTypes = DiscoveryLinkableTypes.types;

  static const int _maxSeedCandidates = 12;

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
    EntityAnchorType? anchorTypeFilter,
  }) async {
    await userCatalog.load();
    final archived = archivedEntityIds ??
        await loadArchivedEntityIds(loader: loader, vaultPath: vaultPath);

    final trimmed = query.trim();
    final raw = trimmed.isEmpty
        ? userCatalog.all
        : userCatalog.search(trimmed);

    final filtered = raw.where(_isLinkableEntity).where((entity) {
      if (anchorTypeFilter == null) return true;
      return entity.anchorType == anchorTypeFilter;
    }).toList();

    final catalogCandidates = filtered
        .map(
          (entity) => EntityLinkPickerCandidate(
            entity: entity,
            isArchived: archived.contains(entity.entityId),
            origin: EntityLinkPickerCandidateOrigin.catalog,
          ),
        )
        .toList();

    catalogCandidates.sort(_compareCandidates);

    if (catalogCandidates.isNotEmpty) {
      return catalogCandidates;
    }

    return _buildSeedFallback(
      userCatalog: userCatalog,
      query: trimmed,
      anchorTypeFilter: anchorTypeFilter,
    );
  }

  static Future<List<EntityLinkPickerCandidate>> _buildSeedFallback({
    required UserCatalogPort userCatalog,
    required String query,
    EntityAnchorType? anchorTypeFilter,
  }) async {
    if (!_seedFallbackAllowed(anchorTypeFilter)) return const [];

    await PersonSeedRegistry.instance.init();
    final facts = query.isEmpty
        ? PersonSeedRegistry.instance.listFacts(type: anchorTypeFilter)
        : PersonSeedRegistry.instance.search(query, type: anchorTypeFilter);

    final catalogIds = userCatalog.all.map((e) => e.entityId).toSet();

    final candidates = <EntityLinkPickerCandidate>[];
    for (final fact in facts) {
      if (!_linkableTypes.contains(fact.entityType)) continue;
      if (catalogIds.contains(fact.entityId)) continue;

      candidates.add(
        EntityLinkPickerCandidate(
          entity: EntitySeedCatalogPromotion.entityFromFact(fact),
          isArchived: false,
          origin: EntityLinkPickerCandidateOrigin.seed,
          seedFact: fact,
        ),
      );
      if (candidates.length >= _maxSeedCandidates) break;
    }

    candidates.sort(
      (a, b) => a.entity.title.toLowerCase().compareTo(
            b.entity.title.toLowerCase(),
          ),
    );
    return candidates;
  }

  /// Event/Concept seed 번들 없음 — Person Cold Graph만 seed fallback.
  static bool _seedFallbackAllowed(EntityAnchorType? anchorTypeFilter) {
    if (anchorTypeFilter == null) return true;
    return anchorTypeFilter == EntityAnchorType.person;
  }

  static bool _isLinkableEntity(UserCatalogEntity entity) {
    return DiscoveryLinkableTypes.isCatalogLinkable(entity);
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
