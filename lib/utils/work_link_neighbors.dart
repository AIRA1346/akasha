import '../core/archiving/entity_anchor.dart';
import '../core/ports/record_link_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/entity_id_codec.dart';
import '../models/user_catalog_entity.dart';
import '../services/entity_related_works_discovery.dart';
import '../services/relationship_discovery_service.dart';
import '../services/works_registry.dart';
import 'catalog_entity_resolver.dart';
import 'work_link_resolution.dart';
import 'work_related_characters.dart';

/// 작품 기준 링크 인덱스 이웃 — 인물·연결 작품.
class WorkLinkNeighbors {
  const WorkLinkNeighbors({
    this.characters = const [],
    this.connectedWorks = const [],
    this.events = const [],
    this.concepts = const [],
    this.places = const [],
    this.organizations = const [],
    this.connectedWorkBridgeLabels = const {},
    this.themeClusters = const [],
  });

  final List<UserCatalogEntity> characters;
  final List<AkashaItem> connectedWorks;
  final List<UserCatalogEntity> events;
  final List<UserCatalogEntity> concepts;
  final List<UserCatalogEntity> places;
  final List<UserCatalogEntity> organizations;
  final Map<String, String> connectedWorkBridgeLabels;
  final List<ConceptThemeCluster> themeClusters;

  bool get hasAnyLink =>
      characters.isNotEmpty ||
      connectedWorks.isNotEmpty ||
      events.isNotEmpty ||
      concepts.isNotEmpty ||
      places.isNotEmpty ||
      organizations.isNotEmpty;

  String? bridgeLabelForWork(String workId) =>
      connectedWorkBridgeLabels[workId];
}

Future<WorkLinkNeighbors> fetchWorkLinkNeighbors({
  required AkashaItem work,
  required UserCatalogPort userCatalog,
  required EntityRelatedWorksDiscovery discovery,
  required RecordLinkPort linkIndex,
  required List<AkashaItem> vaultItems,
  int characterLimit = 4,
  int connectedWorkLimit = 4,
  int eventLimit = 3,
  int conceptLimit = 3,
  int placeLimit = 3,
  int organizationLimit = 3,
}) async {
  if (work is EntityItem || work.workId.isEmpty) {
    return const WorkLinkNeighbors();
  }

  await userCatalog.load();
  final effectiveWork = WorkLinkResolution.vaultWorkForLinks(work, vaultItems);
  final linkedEntityIds =
      await discovery.entityIdsForWork(effectiveWork.workId);
  final allLinkedIds = linkedEntityIds.toSet();

  final filePath = effectiveWork.filePath;
  if (filePath != null && filePath.isNotEmpty) {
    final outgoing = await linkIndex.outgoingLinks(filePath);
    for (final link in outgoing) {
      final targetId = CatalogEntityResolver.recordLinkEntityId(
        link,
        userCatalog: userCatalog,
        vaultItems: vaultItems,
      );
      if (targetId == null ||
          WorkLinkResolution.workIdsReferToSame(targetId, effectiveWork.workId)) {
        continue;
      }
      if (EntityIdCodec.typeFromId(targetId) == EntityAnchorType.work) continue;
      allLinkedIds.add(targetId);
    }
  }

  final resolvedEntities = await CatalogEntityResolver.resolveMany(
    entityIds: allLinkedIds,
    userCatalog: userCatalog,
  );

  final characters = <UserCatalogEntity>[];
  final events = <UserCatalogEntity>[];
  final concepts = <UserCatalogEntity>[];
  final places = <UserCatalogEntity>[];
  final organizations = <UserCatalogEntity>[];

  for (final entityId in allLinkedIds) {
    final entity = resolvedEntities[entityId];
    if (entity == null) continue;
    switch (EntityIdCodec.typeFromId(entityId)) {
      case EntityAnchorType.person:
        if (characters.length < characterLimit) characters.add(entity);
      case EntityAnchorType.event:
        if (events.length < eventLimit) events.add(entity);
      case EntityAnchorType.concept:
        if (concepts.length < conceptLimit) concepts.add(entity);
      case EntityAnchorType.place:
        if (places.length < placeLimit) places.add(entity);
      case EntityAnchorType.organization:
        if (organizations.length < organizationLimit) {
          organizations.add(entity);
        }
      default:
        break;
    }
  }

  if (characters.length < characterLimit) {
    for (final entity in relatedCharactersForWork(
      work: effectiveWork,
      catalog: userCatalog,
      limit: characterLimit,
    )) {
      if (characters.any((c) => c.entityId == entity.entityId)) continue;
      characters.add(entity);
      if (characters.length >= characterLimit) break;
    }
  }

  final workScores = <String, int>{};
  final selfId = effectiveWork.workId;
  if (filePath != null && filePath.isNotEmpty) {
    final outgoing = await linkIndex.outgoingLinks(filePath);
    for (final link in outgoing) {
      final targetId = CatalogEntityResolver.recordLinkEntityId(
        link,
        userCatalog: userCatalog,
        vaultItems: vaultItems,
      );
      if (targetId == null ||
          WorkLinkResolution.workIdsReferToSame(targetId, selfId)) {
        continue;
      }
      if (EntityIdCodec.typeFromId(targetId) == EntityAnchorType.work) {
        workScores[targetId] = (workScores[targetId] ?? 0) + 3;
      }
    }
  }

  if (allLinkedIds.isNotEmpty) {
    final relatedByEntity = await discovery.discoverAll(allLinkedIds);
    for (final related in relatedByEntity.values) {
      for (final workId in related.workIds) {
        if (WorkLinkResolution.workIdsReferToSame(workId, selfId)) continue;
        workScores[workId] = (workScores[workId] ?? 0) + 1;
      }
    }
  }

  final sortedWorkIds = workScores.keys.toList()
    ..sort((a, b) {
      final byScore = workScores[b]!.compareTo(workScores[a]!);
      if (byScore != 0) return byScore;
      return a.compareTo(b);
    });

  final connectedWorks = <AkashaItem>[];
  for (final workId in sortedWorkIds) {
    if (connectedWorks.length >= connectedWorkLimit) break;
    for (final item in vaultItems) {
      if (WorksRegistry.setContainsWorkId({workId}, item.workId)) {
        connectedWorks.add(item);
        break;
      }
    }
  }

  final bridgeLabels =
      await RelationshipDiscoveryService.bridgeLabelsForConnectedWorks(
    sourceWork: effectiveWork,
    connectedWorks: connectedWorks,
    discovery: discovery,
    userCatalog: userCatalog,
    linkIndex: linkIndex,
  );

  final themeClusters =
      await RelationshipDiscoveryService.conceptThemeClustersForWork(
    workId: effectiveWork.workId,
    vaultItems: vaultItems,
    userCatalog: userCatalog,
    discovery: discovery,
  );

  return WorkLinkNeighbors(
    characters: characters,
    connectedWorks: connectedWorks,
    events: events,
    concepts: concepts,
    places: places,
    organizations: organizations,
    connectedWorkBridgeLabels: bridgeLabels,
    themeClusters: themeClusters,
  );
}
