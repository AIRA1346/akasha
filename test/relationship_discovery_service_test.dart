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
import 'package:akasha/services/relationship_discovery_service.dart';

class _FakeUserCatalog implements UserCatalogPort {
  _FakeUserCatalog(this._entities);

  final List<UserCatalogEntity> _entities;

  @override
  List<UserCatalogEntity> get all => List.unmodifiable(_entities);

  @override
  Stream<void> get onChanged => const Stream.empty();

  @override
  Future<void> load() async {}

  @override
  UserCatalogEntity? getById(String entityId) {
    for (final e in _entities) {
      if (e.entityId == entityId) return e;
    }
    return null;
  }

  @override
  List<UserCatalogEntity> search(
    String query, {
    MediaCategory? subtype,
    EntityAnchorType? entityType,
  }) =>
      const [];

  @override
  Future<void> upsert(UserCatalogEntity entity) async {}

  @override
  Future<void> remove(String entityId) async {}
}

class _FakeDiscovery implements EntityRelatedWorksDiscovery {
  _FakeDiscovery({required Map<String, Set<String>> workToEntities})
      : _workToEntities = workToEntities;

  final Map<String, Set<String>> _workToEntities;

  @override
  Future<EntityRelatedWorks> discover(String entityId) async {
    final workIds = <String>{};
    for (final entry in _workToEntities.entries) {
      if (entry.value.contains(entityId)) workIds.add(entry.key);
    }
    return EntityRelatedWorks(entityId: entityId, workIds: workIds);
  }

  @override
  Future<Map<String, EntityRelatedWorks>> discoverAll(
    Iterable<String> entityIds,
  ) async {
    final result = <String, EntityRelatedWorks>{};
    for (final entityId in entityIds) {
      result[entityId] = await discover(entityId);
    }
    return result;
  }

  @override
  int? cachedIncomingRecordCount(String entityId) => null;

  @override
  EntityJournalEntry? cachedJournal(String entityId) => null;

  @override
  Map<String, EntityJournalEntry>? get cachedJournalsByEntityId => null;

  @override
  Future<Set<String>> entityIdsForWork(String workId) async =>
      _workToEntities[workId] ?? {};
}

class _FakeLinkIndex implements RecordLinkPort {
  _FakeLinkIndex({this.outgoingByPath = const {}});

  final Map<String, List<RecordLink>> outgoingByPath;

  @override
  Future<void> rebuildIndex({
    String? changedPath,
    UserCatalogPort? userCatalog,
    List<AkashaItem> vaultItems = const [],
  }) async {}

  @override
  Future<List<RecordLink>> outgoingLinks(String sourcePath) async =>
      outgoingByPath[sourcePath] ?? const [];

  @override
  Future<List<String>> incomingRecordPaths(String entityId) async => const [];

  @override
  Future<Iterable<String>> incomingEntityIds() async => const [];
}

ContentItem _work({
  required String workId,
  required String title,
  String? filePath,
}) {
  final item = ContentItem(
    workId: workId,
    title: title,
    category: MediaCategory.movie,
    domain: AppDomain.subculture,
  );
  if (filePath != null) item.filePath = filePath;
  return item;
}

void main() {
  group('RelationshipDiscoveryService', () {
    test('shared person produces bridge label', () async {
      const personId = 'pe_000000001';
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: personId,
          type: EntityAnchorType.person,
          title: 'Christopher Nolan',
        ),
      ]);
      final discovery = _FakeDiscovery(
        workToEntities: {
          'wk_a': {personId},
          'wk_b': {personId},
        },
      );

      final bridge = await RelationshipDiscoveryService.bridgeBetweenWorks(
        sourceWork: _work(workId: 'wk_a', title: 'Inception'),
        targetWork: _work(workId: 'wk_b', title: 'Interstellar'),
        discovery: discovery,
        userCatalog: catalog,
        linkIndex: _FakeLinkIndex(),
      );

      expect(bridge, isNotNull);
      expect(bridge!.kind, WorkConnectionBridgeKind.sharedPerson);
      expect(bridge.label, 'Christopher Nolan 때문에 연결');
    });

    test('shared concept produces concept bridge label', () async {
      const conceptId = 'co_000000001';
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: conceptId,
          type: EntityAnchorType.concept,
          title: '시간 여행',
        ),
      ]);
      final discovery = _FakeDiscovery(
        workToEntities: {
          'wk_a': {conceptId},
          'wk_b': {conceptId},
        },
      );

      final bridge = await RelationshipDiscoveryService.bridgeBetweenWorks(
        sourceWork: _work(workId: 'wk_a', title: 'Back to the Future'),
        targetWork: _work(workId: 'wk_b', title: 'Primer'),
        discovery: discovery,
        userCatalog: catalog,
        linkIndex: _FakeLinkIndex(),
      );

      expect(bridge, isNotNull);
      expect(bridge!.kind, WorkConnectionBridgeKind.sharedConcept);
      expect(bridge.label, '시간 여행 개념 때문에 연결');
    });

    test('direct work link takes priority over shared entity', () async {
      const personId = 'pe_000000001';
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: personId,
          type: EntityAnchorType.person,
          title: 'Christopher Nolan',
        ),
      ]);
      final discovery = _FakeDiscovery(
        workToEntities: {
          'wk_a': {personId},
          'wk_b': {personId},
        },
      );
      final linkIndex = _FakeLinkIndex(
        outgoingByPath: {
          '/vault/a.md': [
            const RecordLink(
              sourceRecordId: '/vault/a.md',
              kind: RecordLinkKind.explicitId,
              raw: '[[wk_b]]',
              targetEntityId: 'wk_b',
            ),
          ],
        },
      );

      final bridge = await RelationshipDiscoveryService.bridgeBetweenWorks(
        sourceWork: _work(
          workId: 'wk_a',
          title: 'Inception',
          filePath: '/vault/a.md',
        ),
        targetWork: _work(workId: 'wk_b', title: 'Interstellar'),
        discovery: discovery,
        userCatalog: catalog,
        linkIndex: linkIndex,
      );

      expect(bridge, isNotNull);
      expect(bridge!.kind, WorkConnectionBridgeKind.directWorkLink);
      expect(bridge.label, '직접 링크');
    });

    test('concept theme cluster requires at least three works', () async {
      const conceptId = 'co_000000001';
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: conceptId,
          type: EntityAnchorType.concept,
          title: '우주 탐사',
        ),
      ]);
      final discovery = _FakeDiscovery(
        workToEntities: {
          'wk_1': {conceptId},
          'wk_2': {conceptId},
          'wk_3': {conceptId},
          'wk_4': {conceptId},
        },
      );
      final vaultItems = [
        _work(workId: 'wk_1', title: 'Gravity'),
        _work(workId: 'wk_2', title: 'The Martian'),
        _work(workId: 'wk_3', title: 'Interstellar'),
        _work(workId: 'wk_4', title: 'Arrival'),
      ];

      final clusters = await RelationshipDiscoveryService.conceptThemeClusters(
        vaultItems: vaultItems,
        userCatalog: catalog,
        discovery: discovery,
        minWorks: 3,
      );

      expect(clusters, hasLength(1));
      expect(clusters.first.concept.title, '우주 탐사');
      expect(clusters.first.workCount, 4);
    });

    test('concept theme cluster below minWorks is excluded', () async {
      const conceptId = 'co_000000001';
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: conceptId,
          type: EntityAnchorType.concept,
          title: 'AI',
        ),
      ]);
      final discovery = _FakeDiscovery(
        workToEntities: {
          'wk_1': {conceptId},
          'wk_2': {conceptId},
        },
      );
      final vaultItems = [
        _work(workId: 'wk_1', title: 'Her'),
        _work(workId: 'wk_2', title: 'Ex Machina'),
      ];

      final clusters = await RelationshipDiscoveryService.conceptThemeClusters(
        vaultItems: vaultItems,
        userCatalog: catalog,
        discovery: discovery,
        minWorks: 3,
      );

      expect(clusters, isEmpty);
    });

    test('conceptThemeClustersForWork filters to source work', () async {
      const sharedConcept = 'co_000000001';
      const otherConcept = 'co_000000002';
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: sharedConcept,
          type: EntityAnchorType.concept,
          title: '정체성',
        ),
        UserCatalogEntity.userLocal(
          entityId: otherConcept,
          type: EntityAnchorType.concept,
          title: '우주 탐사',
        ),
      ]);
      final discovery = _FakeDiscovery(
        workToEntities: {
          'wk_a': {sharedConcept},
          'wk_b': {sharedConcept},
          'wk_c': {sharedConcept},
          'wk_d': {otherConcept},
          'wk_e': {otherConcept},
          'wk_f': {otherConcept},
        },
      );
      final vaultItems = [
        _work(workId: 'wk_a', title: 'A'),
        _work(workId: 'wk_b', title: 'B'),
        _work(workId: 'wk_c', title: 'C'),
        _work(workId: 'wk_d', title: 'D'),
        _work(workId: 'wk_e', title: 'E'),
        _work(workId: 'wk_f', title: 'F'),
      ];

      final clusters =
          await RelationshipDiscoveryService.conceptThemeClustersForWork(
        workId: 'wk_a',
        vaultItems: vaultItems,
        userCatalog: catalog,
        discovery: discovery,
      );

      expect(clusters, hasLength(1));
      expect(clusters.first.concept.title, '정체성');
      expect(clusters.first.workIds, contains('wk_a'));
    });
  });
}
