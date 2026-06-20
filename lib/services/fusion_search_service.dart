import '../core/archiving/entity_anchor.dart';
import '../core/archiving/entity_journal_entry.dart';
import '../../core/ports/entity_registry_port.dart';
import '../core/ports/registry_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/franchise_group.dart';
import '../models/registry_work.dart';
import '../services/entity_vault_loader.dart';
import '../services/file_service.dart';
import '../services/franchise_registry.dart';
import '../services/franchise_representative_picker.dart';
import '../services/registry_visibility_service.dart';
import '../services/works_registry.dart';

enum FusionRegistrySource {
  userCatalog,
  globalRegistry,
}

class FusionRegistryHit {
  const FusionRegistryHit({
    required this.work,
    required this.source,
    this.hint = RegistryRemoteHint.available,
    this.entityType = EntityAnchorType.work,
    this.catalogOnly = false,
  });

  final RegistryWork work;
  final FusionRegistrySource source;
  final RegistryRemoteHint hint;
  final EntityAnchorType entityType;

  /// user catalog hit without archived entity journal (R1).
  final bool catalogOnly;

  bool get isUserLocalCatalog => source == FusionRegistrySource.userCatalog;

  bool get isWorkEntity => entityType == EntityAnchorType.work;
}

class FusionSearchResult {
  const FusionSearchResult({
    required this.localItems,
    required this.localEntityJournals,
    required this.registryHits,
  });

  final List<AkashaItem> localItems;
  final List<EntityJournalEntry> localEntityJournals;
  final List<FusionRegistryHit> registryHits;
}

/// Fusion: local work `.md` · local entity journal · user catalog · global.
abstract final class FusionSearchService {
  static Future<FusionSearchResult> search({
    required String query,
    required List<AkashaItem> localItems,
    required UserCatalogPort userCatalog,
    required RegistryPort registry,
    EntityRegistryPort? entityRegistry,
    EntityVaultLoader? entityLoader,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const FusionSearchResult(
        localItems: [],
        localEntityJournals: [],
        registryHits: [],
      );
    }

    final q = trimmed.toLowerCase();
    final local = FranchiseRepresentativePicker.dedupeLocalByFranchise(
      localItems.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.creator.toLowerCase().contains(q) ||
            item.tags.any((t) => t.toLowerCase().contains(q));
      }).toList(),
    );

    final loader = entityLoader ?? const EntityVaultLoader();
    final vaultPath = AkashaFileService().vaultPath;
    final allEntityJournals = await loader.loadFromVault(vaultPath);
    final localEntityJournals = allEntityJournals.where((entry) {
      if (entry.title.toLowerCase().contains(q)) return true;
      if (entry.body.toLowerCase().contains(q)) return true;
      for (final tag in entry.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();

    final archivedEntityIds = allEntityJournals
        .map((e) => e.entityId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final localWorkIds = local
        .map((e) => e.workId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final allLocalWorkIds = localItems
        .map((e) => e.workId)
        .where((id) => id.isNotEmpty)
        .toSet();

    await userCatalog.load();

    final catalogHits = <FusionRegistryHit>[];
    for (final entity in userCatalog.search(trimmed)) {
      if (WorksRegistry.setContainsWorkId(localWorkIds, entity.entityId)) {
        continue;
      }

      final isNonWork = !entity.isWorkEntity;
      if (isNonWork && archivedEntityIds.contains(entity.entityId)) {
        continue;
      }

      catalogHits.add(
        FusionRegistryHit(
          work: entity.toRegistryWork(),
          source: FusionRegistrySource.userCatalog,
          entityType: entity.anchorType,
          catalogOnly: isNonWork,
        ),
      );
    }

    final catalogIds = catalogHits.map((e) => e.work.workId).toSet();
    var excludeIds = {
      ...allLocalWorkIds,
      ...catalogIds,
      ...archivedEntityIds,
    };

    final entityGlobalHits = <FusionRegistryHit>[];
    if (entityRegistry != null) {
      await entityRegistry.init();
      for (final fact in entityRegistry.search(trimmed)) {
        if (excludeIds.contains(fact.entityId)) continue;
        entityGlobalHits.add(
          FusionRegistryHit(
            work: fact.toRegistryWork(),
            source: FusionRegistrySource.globalRegistry,
            entityType: fact.entityType,
          ),
        );
        excludeIds = {...excludeIds, fact.entityId};
      }
    }

    final globalWorks = await registry.searchAsync(trimmed);
    final globalEntries = globalWorks
        .where((work) => !WorksRegistry.setContainsWorkId(excludeIds, work.workId))
        .map(
          (work) => FusionRegistryHit(
            work: work,
            source: FusionRegistrySource.globalRegistry,
            hint: RegistryVisibilityService.remoteSearchHint(
              workId: work.workId,
              userWorkIds: allLocalWorkIds,
            ),
          ),
        )
        .toList();

    final dedupedGlobal = _dedupeFranchiseEntries(
      globalEntries,
      localItems: localItems,
    );

    return FusionSearchResult(
      localItems: local,
      localEntityJournals: localEntityJournals,
      registryHits: [...catalogHits, ...entityGlobalHits, ...dedupedGlobal],
    );
  }

  static List<FusionRegistryHit> _dedupeFranchiseEntries(
    List<FusionRegistryHit> entries, {
    required List<AkashaItem> localItems,
  }) {
    final localFranchiseIds = <String>{};
    for (final local in localItems) {
      final group = FranchiseRegistry.groupFor(local.workId);
      if (group != null) localFranchiseIds.add(group.id);
    }

    final emittedFranchises = <String>{};
    final result = <FusionRegistryHit>[];

    for (final entry in entries) {
      final group = FranchiseRegistry.groupFor(entry.work.workId);
      if (group == null) {
        result.add(entry);
        continue;
      }

      if (localFranchiseIds.contains(group.id)) continue;
      if (emittedFranchises.contains(group.id)) continue;
      emittedFranchises.add(group.id);

      final franchiseEntries = entries
          .where(
            (e) =>
                FranchiseRegistry.groupFor(e.work.workId)?.id == group.id,
          )
          .toList();

      final primaryWork =
          WorksRegistry.getWorkById(group.primaryWorkId) ?? entry.work;
      final hint = _mergeHints(franchiseEntries.map((e) => e.hint));

      result.add(
        FusionRegistryHit(
          work: primaryWork,
          source: FusionRegistrySource.globalRegistry,
          hint: hint,
        ),
      );
    }

    return result
      ..sort((a, b) {
        final order = RegistryVisibilityService.remoteHintSortOrder(a.hint)
            .compareTo(RegistryVisibilityService.remoteHintSortOrder(b.hint));
        if (order != 0) return order;
        final scoreCmp = WorksRegistry.qualityScoreFor(b.work.workId)
            .compareTo(WorksRegistry.qualityScoreFor(a.work.workId));
        if (scoreCmp != 0) return scoreCmp;
        return a.work.title.compareTo(b.work.title);
      });
  }

  static RegistryRemoteHint _mergeHints(Iterable<RegistryRemoteHint> hints) {
    if (hints.any((h) => h == RegistryRemoteHint.hidden)) {
      return RegistryRemoteHint.hidden;
    }
    if (hints.any((h) => h == RegistryRemoteHint.siblingTracked)) {
      return RegistryRemoteHint.siblingTracked;
    }
    return RegistryRemoteHint.available;
  }
}
