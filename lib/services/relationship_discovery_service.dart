import '../core/archiving/entity_anchor.dart';
import '../core/ports/record_link_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/entity_id_codec.dart';
import '../models/user_catalog_entity.dart';
import 'entity_related_works_discovery.dart';

/// Work 연결 브리지 종류 (R13 Level 3).
enum WorkConnectionBridgeKind {
  directWorkLink,
  sharedPerson,
  sharedEvent,
  sharedConcept,
  sharedPlace,
  sharedOrganization,
}

/// Work A ↔ Work B 연결 이유 — 링크 증명 기반 (R13).
class WorkConnectionBridge {
  const WorkConnectionBridge({
    required this.connectedWorkId,
    required this.kind,
    this.bridgeEntity,
  });

  final String connectedWorkId;
  final WorkConnectionBridgeKind kind;
  final UserCatalogEntity? bridgeEntity;

  String get label => RelationshipDiscoveryService.bridgeLabelFor(
        kind: kind,
        entityTitle: bridgeEntity?.title,
      );
}

/// Concept Entity 기준 Theme Cluster (R13).
class ConceptThemeCluster {
  const ConceptThemeCluster({
    required this.concept,
    required this.workIds,
  });

  final UserCatalogEntity concept;
  final List<String> workIds;

  int get workCount => workIds.length;
}

/// Discovery Level 3 — read-only 관계 분석 (Engine 변경 없음 · R13).
abstract final class RelationshipDiscoveryService {
  static const int defaultMinThemeWorks = 3;

  static const List<EntityAnchorType> _bridgeTypePriority = [
    EntityAnchorType.concept,
    EntityAnchorType.person,
    EntityAnchorType.event,
    EntityAnchorType.place,
    EntityAnchorType.organization,
  ];

  static WorkConnectionBridgeKind kindForEntityType(EntityAnchorType type) {
    return switch (type) {
      EntityAnchorType.person => WorkConnectionBridgeKind.sharedPerson,
      EntityAnchorType.event => WorkConnectionBridgeKind.sharedEvent,
      EntityAnchorType.concept => WorkConnectionBridgeKind.sharedConcept,
      EntityAnchorType.place => WorkConnectionBridgeKind.sharedPlace,
      EntityAnchorType.organization => WorkConnectionBridgeKind.sharedOrganization,
      _ => WorkConnectionBridgeKind.sharedPerson,
    };
  }

  static String bridgeLabelFor({
    required WorkConnectionBridgeKind kind,
    String? entityTitle,
  }) {
    return switch (kind) {
      WorkConnectionBridgeKind.directWorkLink => '직접 링크',
      WorkConnectionBridgeKind.sharedPerson =>
        '${entityTitle ?? '인물'} 때문에 연결',
      WorkConnectionBridgeKind.sharedConcept =>
        '${entityTitle ?? '개념'} 개념 때문에 연결',
      WorkConnectionBridgeKind.sharedEvent =>
        '${entityTitle ?? '사건'} 사건 때문에 연결',
      WorkConnectionBridgeKind.sharedPlace =>
        '${entityTitle ?? '장소'} 장소 때문에 연결',
      WorkConnectionBridgeKind.sharedOrganization =>
        '${entityTitle ?? '조직'} 때문에 연결',
    };
  }

  static Future<WorkConnectionBridge?> bridgeBetweenWorks({
    required AkashaItem sourceWork,
    required AkashaItem targetWork,
    required EntityRelatedWorksDiscovery discovery,
    required UserCatalogPort userCatalog,
    required RecordLinkPort linkIndex,
  }) async {
    if (sourceWork.workId.isEmpty || targetWork.workId.isEmpty) return null;

    if (await _hasDirectWorkLink(
      sourceWork: sourceWork,
      targetWorkId: targetWork.workId,
      linkIndex: linkIndex,
    )) {
      return WorkConnectionBridge(
        connectedWorkId: targetWork.workId,
        kind: WorkConnectionBridgeKind.directWorkLink,
      );
    }

    await userCatalog.load();
    final sourceIds = await discovery.entityIdsForWork(sourceWork.workId);
    final targetIds = await discovery.entityIdsForWork(targetWork.workId);
    final shared = sourceIds.intersection(targetIds);
    if (shared.isEmpty) return null;

    final bridgeEntity = _pickBestBridgeEntity(shared, userCatalog);
    if (bridgeEntity == null) return null;

    return WorkConnectionBridge(
      connectedWorkId: targetWork.workId,
      kind: kindForEntityType(bridgeEntity.anchorType),
      bridgeEntity: bridgeEntity,
    );
  }

  static Future<Map<String, String>> bridgeLabelsForConnectedWorks({
    required AkashaItem sourceWork,
    required List<AkashaItem> connectedWorks,
    required EntityRelatedWorksDiscovery discovery,
    required UserCatalogPort userCatalog,
    required RecordLinkPort linkIndex,
  }) async {
    final labels = <String, String>{};
    for (final connected in connectedWorks) {
      final bridge = await bridgeBetweenWorks(
        sourceWork: sourceWork,
        targetWork: connected,
        discovery: discovery,
        userCatalog: userCatalog,
        linkIndex: linkIndex,
      );
      if (bridge != null) {
        labels[connected.workId] = bridge.label;
      }
    }
    return labels;
  }

  static Future<List<ConceptThemeCluster>> conceptThemeClusters({
    required List<AkashaItem> vaultItems,
    required UserCatalogPort userCatalog,
    required EntityRelatedWorksDiscovery discovery,
    int minWorks = defaultMinThemeWorks,
    int limit = 6,
    String? forWorkId,
  }) async {
    await userCatalog.load();
    final conceptToWorks = <String, Set<String>>{};

    for (final work in vaultItems) {
      if (work.workId.isEmpty) continue;
      final linkedIds = await discovery.entityIdsForWork(work.workId);
      for (final entityId in linkedIds) {
        if (EntityIdCodec.typeFromId(entityId) != EntityAnchorType.concept) {
          continue;
        }
        conceptToWorks.putIfAbsent(entityId, () => {}).add(work.workId);
      }
    }

    final clusters = <ConceptThemeCluster>[];
    for (final entry in conceptToWorks.entries) {
      if (entry.value.length < minWorks) continue;
      if (forWorkId != null && !entry.value.contains(forWorkId)) continue;

      final concept = userCatalog.getById(entry.key);
      if (concept == null) continue;

      clusters.add(
        ConceptThemeCluster(
          concept: concept,
          workIds: entry.value.toList()..sort(),
        ),
      );
    }

    clusters.sort((a, b) {
      final byCount = b.workCount.compareTo(a.workCount);
      if (byCount != 0) return byCount;
      return a.concept.title.compareTo(b.concept.title);
    });

    return clusters.take(limit).toList();
  }

  static Future<List<ConceptThemeCluster>> conceptThemeClustersForWork({
    required String workId,
    required List<AkashaItem> vaultItems,
    required UserCatalogPort userCatalog,
    required EntityRelatedWorksDiscovery discovery,
    int minWorks = defaultMinThemeWorks,
    int limit = 3,
  }) {
    return conceptThemeClusters(
      vaultItems: vaultItems,
      userCatalog: userCatalog,
      discovery: discovery,
      minWorks: minWorks,
      limit: limit,
      forWorkId: workId,
    );
  }

  static Future<bool> _hasDirectWorkLink({
    required AkashaItem sourceWork,
    required String targetWorkId,
    required RecordLinkPort linkIndex,
  }) async {
    final filePath = sourceWork.filePath;
    if (filePath == null || filePath.isEmpty) return false;

    final outgoing = await linkIndex.outgoingLinks(filePath);
    for (final link in outgoing) {
      final targetId = link.targetEntityId;
      if (targetId == targetWorkId) return true;
    }
    return false;
  }

  static UserCatalogEntity? _pickBestBridgeEntity(
    Set<String> sharedEntityIds,
    UserCatalogPort userCatalog,
  ) {
    for (final type in _bridgeTypePriority) {
      final candidates = <UserCatalogEntity>[];
      for (final entityId in sharedEntityIds) {
        if (EntityIdCodec.typeFromId(entityId) != type) continue;
        final entity = userCatalog.getById(entityId);
        if (entity != null) candidates.add(entity);
      }
      if (candidates.isEmpty) continue;
      candidates.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      return candidates.first;
    }
    return null;
  }
}
