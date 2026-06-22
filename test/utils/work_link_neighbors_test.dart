import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/archiving/entity_journal_entry.dart';
import 'package:akasha/core/archiving/record_link.dart';
import 'package:akasha/core/ports/record_link_port.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/entity_related_works.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/entity_related_works_discovery.dart';
import 'package:akasha/utils/work_link_neighbors.dart';

class _FakeLinkIndex implements RecordLinkPort {
  final Map<String, List<RecordLink>> outgoing;
  final Map<String, List<String>> incoming;

  _FakeLinkIndex({
    this.outgoing = const {},
    this.incoming = const {},
  });

  @override
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {}

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async =>
      outgoing[sourcePath] ?? const [];

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async =>
      incoming[entityId] ?? const [];

  @override
  Future<Iterable<String>> incomingEntityIds() async => incoming.keys;
}

class _FakeDiscovery implements EntityRelatedWorksDiscovery {
  _FakeDiscovery({
    required this.entitiesForWork,
    required this.worksForEntity,
  });

  final Map<String, Set<String>> entitiesForWork;
  final Map<String, Set<String>> worksForEntity;

  @override
  Future<EntityRelatedWorks> discover(String entityId) async =>
      EntityRelatedWorks(
        entityId: entityId,
        workIds: worksForEntity[entityId] ?? const {},
      );

  @override
  Future<Map<String, EntityRelatedWorks>> discoverAll(
    Iterable<String> entityIds,
  ) async {
    return {
      for (final id in entityIds)
        id: EntityRelatedWorks(
          entityId: id,
          workIds: worksForEntity[id] ?? const {},
        ),
    };
  }

  @override
  int? cachedIncomingRecordCount(String entityId) => null;

  @override
  EntityJournalEntry? cachedJournal(String entityId) => null;

  @override
  Map<String, EntityJournalEntry>? get cachedJournalsByEntityId => null;

  @override
  Future<Set<String>> entityIdsForWork(String workId) async =>
      entitiesForWork[workId] ?? const {};
}

class _FakeCatalog implements UserCatalogPort {
  _FakeCatalog(this.entities);

  final List<UserCatalogEntity> entities;

  @override
  List<UserCatalogEntity> get all => entities;

  @override
  Stream<void> get onChanged => const Stream.empty();

  @override
  Future<void> load() async {}

  @override
  UserCatalogEntity? getById(String entityId) {
    for (final entity in entities) {
      if (entity.entityId == entityId) return entity;
    }
    return null;
  }

  @override
  Future<void> remove(String entityId) async {}

  @override
  List<UserCatalogEntity> search(
    String query, {
    MediaCategory? subtype,
    EntityAnchorType? entityType,
  }) =>
      const [];

  @override
  Future<void> upsert(UserCatalogEntity entity) async {}
}

void main() {
  test('fetchWorkLinkNeighbors returns linked person and related work', () async {
    const personId = 'pe_u_abcdefgh';
    const workA = 'wk_u_workaaaa';
    const workB = 'wk_u_workbbbb';

    final work = ContentItem(
      workId: workA,
      title: 'Work A',
      category: MediaCategory.animation,
      domain: AppDomain.subculture,
    )..filePath = r'C:\vault\work-a.md';
    final other = ContentItem(
      workId: workB,
      title: 'Work B',
      category: MediaCategory.animation,
      domain: AppDomain.subculture,
    );
    final person = UserCatalogEntity.userLocal(
      entityId: personId,
      type: EntityAnchorType.person,
      title: 'Hero',
      subtype: MediaCategory.animation,
      addedAt: DateTime(2024),
    );

    final discovery = _FakeDiscovery(
      entitiesForWork: {workA: {personId}},
      worksForEntity: {personId: {workA, workB}},
    );
    final linkIndex = _FakeLinkIndex(
      incoming: {
        personId: [r'C:\vault\work-a.md'],
      },
    );

    final neighbors = await fetchWorkLinkNeighbors(
      work: work,
      userCatalog: _FakeCatalog([person]),
      discovery: discovery,
      linkIndex: linkIndex,
      vaultItems: [work, other],
    );

    expect(neighbors.characters.map((e) => e.entityId), [personId]);
    expect(neighbors.connectedWorks.map((w) => w.workId), [workB]);
  });
}
