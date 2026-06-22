import '../core/archiving/entity_anchor.dart';
import '../core/ports/record_link_port.dart';
import '../core/ports/user_catalog_port.dart';
import '../models/akasha_item.dart';
import '../models/entity_id_codec.dart';
import '../models/user_catalog_entity.dart';
import '../services/entity_related_works_discovery.dart';
import 'work_related_characters.dart';

/// 작품 기준 링크 인덱스 이웃 — 인물·연결 작품.
class WorkLinkNeighbors {
  const WorkLinkNeighbors({
    this.characters = const [],
    this.connectedWorks = const [],
    this.events = const [],
    this.concepts = const [],
  });

  final List<UserCatalogEntity> characters;
  final List<AkashaItem> connectedWorks;
  final List<UserCatalogEntity> events;
  final List<UserCatalogEntity> concepts;

  bool get hasAnyLink =>
      characters.isNotEmpty ||
      connectedWorks.isNotEmpty ||
      events.isNotEmpty ||
      concepts.isNotEmpty;
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
}) async {
  if (work is EntityItem || work.workId.isEmpty) {
    return const WorkLinkNeighbors();
  }

  await userCatalog.load();
  final linkedEntityIds = await discovery.entityIdsForWork(work.workId);

  final characters = <UserCatalogEntity>[];
  final events = <UserCatalogEntity>[];
  final concepts = <UserCatalogEntity>[];

  for (final entityId in linkedEntityIds) {
    final type = EntityIdCodec.typeFromId(entityId);
    final entity = userCatalog.getById(entityId);
    if (entity == null) continue;
    switch (type) {
      case EntityAnchorType.person:
        if (characters.length < characterLimit) characters.add(entity);
      case EntityAnchorType.event:
        if (events.length < eventLimit) events.add(entity);
      case EntityAnchorType.concept:
        if (concepts.length < conceptLimit) concepts.add(entity);
      default:
        break;
    }
  }

  if (characters.length < characterLimit) {
    for (final entity in relatedCharactersForWork(
      work: work,
      catalog: userCatalog,
      limit: characterLimit,
    )) {
      if (characters.any((c) => c.entityId == entity.entityId)) continue;
      characters.add(entity);
      if (characters.length >= characterLimit) break;
    }
  }

  final workScores = <String, int>{};
  final selfId = work.workId;
  final filePath = work.filePath;
  if (filePath != null && filePath.isNotEmpty) {
    final outgoing = await linkIndex.outgoingLinks(filePath);
    for (final link in outgoing) {
      final targetId = link.targetEntityId;
      if (targetId == null || targetId == selfId) continue;
      if (EntityIdCodec.typeFromId(targetId) == EntityAnchorType.work) {
        workScores[targetId] = (workScores[targetId] ?? 0) + 3;
      }
    }
  }

  if (linkedEntityIds.isNotEmpty) {
    final relatedByEntity = await discovery.discoverAll(linkedEntityIds);
    for (final related in relatedByEntity.values) {
      for (final workId in related.workIds) {
        if (workId == selfId) continue;
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
      if (item.workId == workId) {
        connectedWorks.add(item);
        break;
      }
    }
  }

  return WorkLinkNeighbors(
    characters: characters,
    connectedWorks: connectedWorks,
    events: events,
    concepts: concepts,
  );
}
