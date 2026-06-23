import '../core/ports/record_link_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/user_catalog_entity.dart';
import '../screens/home/coordinators/home_shell_wiring.dart';
import '../utils/registry_search_utils.dart';
import '../utils/vault_work_presence.dart';
import 'registry_visibility_service.dart';
import 'works_registry.dart';

/// Registry Discovery Bridge 후보 출처 (R11).
enum RegistryDiscoveryReason {
  creator,
  tag,
  linkedEntity,
}

/// Vault 맥락에서 사전(Tier 1) 작품 제안.
class RegistryDiscoveryCandidate {
  const RegistryDiscoveryCandidate({
    required this.work,
    required this.score,
    required this.reason,
    this.matchDetail,
    this.bridgeLabel,
  });

  final RegistryWork work;
  final double score;
  final RegistryDiscoveryReason reason;
  final String? matchDetail;

  /// UI용 브리지 라벨 (예: creator 이름 · 연결 인물).
  final String? bridgeLabel;
}

/// Vault Graph → Registry Catalog 브리지 (Engine 변경 없음 · R11).
abstract final class RegistryDiscoveryCandidateService {
  static const double _scoreCreator = 10.0;
  static const double _scoreTag = 6.0;
  static const double _scoreLinkedEntity = 5.0;

  static Future<List<RegistryDiscoveryCandidate>> candidatesForVaultWork({
    required AkashaItem work,
    required List<AkashaItem> vaultItems,
    required UserCatalogPort userCatalog,
    required RecordLinkPort linkIndex,
    int limit = 6,
  }) async {
    if (work is EntityItem || work.workId.isEmpty) return const [];

    final vaultIds = VaultWorkPresence.vaultWorkIds(vaultItems);
    final merged = <String, RegistryDiscoveryCandidate>{};

    void put(RegistryDiscoveryCandidate candidate) {
      final id = candidate.work.workId;
      if (id.isEmpty) return;
      if (WorksRegistry.setContainsWorkId(vaultIds, id)) return;
      if (WorksRegistry.setContainsWorkId({work.workId}, id)) return;
      if (!RegistryVisibilityService.shouldMaterializeVirtual(
        workId: id,
        userWorkIds: vaultIds,
      )) {
        return;
      }
      final existing = merged[id];
      if (existing == null || candidate.score > existing.score) {
        merged[id] = candidate;
      }
    }

    final creator = work.creator.trim();
    if (creator.isNotEmpty) {
      for (final hit in WorksRegistry.search(creator)) {
        if (!_creatorMatches(hit.creator, creator)) continue;
        put(
          RegistryDiscoveryCandidate(
            work: hit,
            score: _scoreCreator,
            reason: RegistryDiscoveryReason.creator,
            matchDetail: creator,
            bridgeLabel: creator,
          ),
        );
      }
    }

    for (final tag in work.tags) {
      final normalized = _normalize(tag);
      if (normalized.isEmpty) continue;
      for (final hit in WorksRegistry.search(tag)) {
        final tagHit = hit.tags.any((t) => _normalize(t) == normalized);
        if (!tagHit) continue;
        put(
          RegistryDiscoveryCandidate(
            work: hit,
            score: _scoreTag,
            reason: RegistryDiscoveryReason.tag,
            matchDetail: tag,
            bridgeLabel: tag,
          ),
        );
      }
    }

    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: linkIndex,
      vaultItems: vaultItems,
    );
    await userCatalog.load();
    final linkedIds = await discovery.entityIdsForWork(work.workId);
    for (final entityId in linkedIds.take(6)) {
      final entity = userCatalog.getById(entityId);
      if (entity == null) continue;
      _putEntityBridge(entity, put: put);
    }

    return _finalize(merged, limit: limit);
  }

  static Future<List<RegistryDiscoveryCandidate>> candidatesForEntity({
    required UserCatalogEntity entity,
    required List<AkashaItem> vaultItems,
    required RecordLinkPort linkIndex,
    required UserCatalogPort userCatalog,
    int limit = 6,
  }) async {
    final vaultIds = VaultWorkPresence.vaultWorkIds(vaultItems);
    final merged = <String, RegistryDiscoveryCandidate>{};

    void put(RegistryDiscoveryCandidate candidate) {
      final id = candidate.work.workId;
      if (id.isEmpty) return;
      if (WorksRegistry.setContainsWorkId(vaultIds, id)) return;
      if (!RegistryVisibilityService.shouldMaterializeVirtual(
        workId: id,
        userWorkIds: vaultIds,
      )) {
        return;
      }
      final existing = merged[id];
      if (existing == null || candidate.score > existing.score) {
        merged[id] = candidate;
      }
    }

    _putEntityBridge(entity, put: put);

    final discovery = HomeShellWiring.createEntityRelatedWorksDiscovery(
      linkIndex: linkIndex,
      vaultItems: vaultItems,
    );
    final related = await discovery.discover(entity.entityId);
    await userCatalog.load();
    for (final workId in related.workIds.take(4)) {
      AkashaItem? vaultWork;
      for (final item in vaultItems) {
        if (item.workId == workId) {
          vaultWork = item;
          break;
        }
      }
      if (vaultWork == null) continue;
      final creator = vaultWork.creator.trim();
      if (creator.isEmpty) continue;
      for (final hit in WorksRegistry.search(creator)) {
        if (!_creatorMatches(hit.creator, creator)) continue;
        put(
          RegistryDiscoveryCandidate(
            work: hit,
            score: _scoreCreator,
            reason: RegistryDiscoveryReason.creator,
            matchDetail: creator,
            bridgeLabel: '${vaultWork.title} · $creator',
          ),
        );
      }
    }

    return _finalize(merged, limit: limit);
  }

  static List<RegistryDiscoveryCandidate> candidatesForRegistryWork({
    required RegistryWork work,
    required List<AkashaItem> vaultItems,
    int limit = 6,
  }) {
    final vaultIds = VaultWorkPresence.vaultWorkIds(vaultItems);
    final merged = <String, RegistryDiscoveryCandidate>{};

    void put(RegistryDiscoveryCandidate candidate) {
      final id = candidate.work.workId;
      if (id.isEmpty) return;
      if (WorksRegistry.setContainsWorkId(vaultIds, id)) return;
      if (WorksRegistry.setContainsWorkId({work.workId}, id)) return;
      if (!RegistryVisibilityService.shouldMaterializeVirtual(
        workId: id,
        userWorkIds: vaultIds,
      )) {
        return;
      }
      final existing = merged[id];
      if (existing == null || candidate.score > existing.score) {
        merged[id] = candidate;
      }
    }

    final creator = work.creator.trim();
    if (creator.isNotEmpty) {
      for (final hit in WorksRegistry.search(creator)) {
        if (!_creatorMatches(hit.creator, creator)) continue;
        put(
          RegistryDiscoveryCandidate(
            work: hit,
            score: _scoreCreator,
            reason: RegistryDiscoveryReason.creator,
            matchDetail: creator,
            bridgeLabel: creator,
          ),
        );
      }
    }

    for (final tag in work.tags) {
      final normalized = _normalize(tag);
      if (normalized.isEmpty) continue;
      for (final hit in WorksRegistry.search(tag)) {
        if (!hit.tags.any((t) => _normalize(t) == normalized)) continue;
        put(
          RegistryDiscoveryCandidate(
            work: hit,
            score: _scoreTag,
            reason: RegistryDiscoveryReason.tag,
            matchDetail: tag,
            bridgeLabel: tag,
          ),
        );
      }
    }

    return _finalize(merged, limit: limit);
  }

  static void _putEntityBridge(
    UserCatalogEntity entity, {
    required void Function(RegistryDiscoveryCandidate candidate) put,
  }) {
    final queries = <String>{
      entity.title,
      ...entity.aliases,
      ...entity.tags,
    }.where((q) => q.trim().isNotEmpty);

    for (final query in queries) {
      for (final hit in WorksRegistry.search(query)) {
        put(
          RegistryDiscoveryCandidate(
            work: hit,
            score: _scoreLinkedEntity,
            reason: RegistryDiscoveryReason.linkedEntity,
            matchDetail: query,
            bridgeLabel: entity.title,
          ),
        );
      }
    }
  }

  static List<RegistryDiscoveryCandidate> _finalize(
    Map<String, RegistryDiscoveryCandidate> merged, {
    required int limit,
  }) {
    final results = merged.values.toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return WorksRegistry.qualityScoreFor(b.work.workId)
            .compareTo(WorksRegistry.qualityScoreFor(a.work.workId));
      });
    return results.take(limit).toList();
  }

  static bool _creatorMatches(String registryCreator, String sourceCreator) {
    final a = _normalize(registryCreator);
    final b = _normalize(sourceCreator);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    return a.contains(b) || b.contains(a);
  }

  static String _normalize(String value) =>
      normalizeRegistryQuery(value.trim());
}
