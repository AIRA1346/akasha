import '../core/archiving/entity_anchor.dart';
import '../core/ports/record_link_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/entity_id_codec.dart';
import '../models/user_catalog_entity.dart';
import '../services/entity_related_works_discovery.dart';

/// Entity 기준 링크 이웃 — 작품·엔티티·incoming 수.
class EntityLinkNeighbors {
  const EntityLinkNeighbors({
    this.connectedWorks = const [],
    this.persons = const [],
    this.events = const [],
    this.concepts = const [],
    this.incomingLinkCount = 0,
  });

  final List<AkashaItem> connectedWorks;
  final List<UserCatalogEntity> persons;
  final List<UserCatalogEntity> events;
  final List<UserCatalogEntity> concepts;
  final int incomingLinkCount;

  bool get hasAnyLink =>
      connectedWorks.isNotEmpty ||
      persons.isNotEmpty ||
      events.isNotEmpty ||
      concepts.isNotEmpty ||
      incomingLinkCount > 0;
}

Future<EntityLinkNeighbors> fetchEntityLinkNeighbors({
  required UserCatalogEntity entity,
  required UserCatalogPort userCatalog,
  required EntityRelatedWorksDiscovery discovery,
  required RecordLinkPort linkIndex,
  required List<AkashaItem> vaultItems,
  int workLimit = 4,
  int personLimit = 4,
  int eventLimit = 3,
  int conceptLimit = 3,
}) async {
  await userCatalog.load();
  final related = await discovery.discover(entity.entityId);
  final incomingCount =
      discovery.cachedIncomingRecordCount(entity.entityId) ?? 0;

  final connectedWorks = <AkashaItem>[];
  for (final workId in related.workIds) {
    if (connectedWorks.length >= workLimit) break;
    for (final item in vaultItems) {
      if (item.workId == workId) {
        connectedWorks.add(item);
        break;
      }
    }
  }

  final persons = <UserCatalogEntity>[];
  final events = <UserCatalogEntity>[];
  final concepts = <UserCatalogEntity>[];

  final journal = discovery.cachedJournal(entity.entityId);
  if (journal != null) {
    final outgoing = await linkIndex.outgoingLinks(journal.storagePath);
    for (final link in outgoing) {
      final targetId = link.targetEntityId;
      if (targetId == null || targetId == entity.entityId) continue;
      final type = EntityIdCodec.typeFromId(targetId);
      if (type == EntityAnchorType.work) continue;
      final linked = userCatalog.getById(targetId);
      if (linked == null) continue;
      switch (type) {
        case EntityAnchorType.person:
          if (persons.length < personLimit &&
              !persons.any((e) => e.entityId == linked.entityId)) {
            persons.add(linked);
          }
        case EntityAnchorType.event:
          if (events.length < eventLimit &&
              !events.any((e) => e.entityId == linked.entityId)) {
            events.add(linked);
          }
        case EntityAnchorType.concept:
          if (concepts.length < conceptLimit &&
              !concepts.any((e) => e.entityId == linked.entityId)) {
            concepts.add(linked);
          }
        default:
          break;
      }
    }
  }

  return EntityLinkNeighbors(
    connectedWorks: connectedWorks,
    persons: persons,
    events: events,
    concepts: concepts,
    incomingLinkCount: incomingCount,
  );
}
