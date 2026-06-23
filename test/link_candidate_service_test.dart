import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/entity_fact.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/link_candidate_service.dart';
import 'package:akasha/services/person_seed_registry.dart';

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
  Future<void> upsert(UserCatalogEntity entity) async {
    _entities.add(entity);
  }

  @override
  Future<void> remove(String entityId) async {}
}

ContentItem _work({
  String creator = '',
  List<String> tags = const [],
}) {
  return ContentItem(
    workId: 'wk_test001',
    title: 'Spirited Away',
    category: MediaCategory.animation,
    domain: AppDomain.subculture,
    creator: creator,
    tags: tags,
  );
}

void main() {
  setUp(() {
    PersonSeedRegistry.instance.resetForTesting();
    PersonSeedRegistry.instance.seedForTesting([
      const EntityFact(
        entityId: 'pe_000000004',
        entityType: EntityAnchorType.person,
        title: 'Hayao Miyazaki',
        aliases: ['미야자키'],
      ),
      const EntityFact(
        entityId: 'pe_000000001',
        entityType: EntityAnchorType.person,
        title: 'Albert Einstein',
      ),
    ]);
  });

  group('LinkCandidateService', () {
    test('creator match ranks highest', () async {
      final results = await LinkCandidateService.candidatesForWork(
        work: _work(creator: 'Hayao Miyazaki'),
        userCatalog: _FakeUserCatalog([]),
        typeFilter: EntityAnchorType.person,
      );

      expect(results, isNotEmpty);
      expect(results.first.title, 'Hayao Miyazaki');
      expect(results.first.reason, LinkCandidateReason.creator);
      expect(results.first.score, greaterThanOrEqualTo(7.0));
    });

    test('tag overlap produces tag reason', () async {
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_1',
          type: EntityAnchorType.person,
          title: '미야자키 인물',
          tags: ['미야자키'],
        ),
      ]);

      final results = await LinkCandidateService.candidatesForWork(
        work: _work(tags: ['미야자키']),
        userCatalog: catalog,
        typeFilter: EntityAnchorType.person,
      );

      expect(results.any((c) => c.reason == LinkCandidateReason.tag), isTrue);
      final tagHit = results.firstWhere((c) => c.entityId == 'pe_u_1');
      expect(tagHit.score, greaterThanOrEqualTo(3.0));
    });

    test('seed browse when no creator or tag signal', () async {
      final results = await LinkCandidateService.candidatesForWork(
        work: _work(),
        userCatalog: _FakeUserCatalog([]),
        typeFilter: EntityAnchorType.person,
        limit: 2,
      );

      expect(results.length, 2);
      expect(results.every((c) => c.reason == LinkCandidateReason.seed), isTrue);
      expect(results.first.score, 2.0);
    });

    test('catalog fallback is lowest score', () async {
      PersonSeedRegistry.instance.resetForTesting();
      PersonSeedRegistry.instance.seedForTesting(const []);

      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_low',
          type: EntityAnchorType.person,
          title: 'Unrelated Person',
        ),
      ]);

      final results = await LinkCandidateService.candidatesForWork(
        work: _work(),
        userCatalog: catalog,
        typeFilter: EntityAnchorType.person,
      );

      expect(results.length, 1);
      expect(results.first.reason, LinkCandidateReason.catalog);
      expect(results.first.score, 1.0);
    });

    test('results sorted by score descending', () async {
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: 'pe_u_tag',
          type: EntityAnchorType.person,
          title: 'Tag Person',
          tags: ['미야자키'],
        ),
      ]);

      final results = await LinkCandidateService.candidatesForWork(
        work: _work(creator: 'Hayao Miyazaki', tags: ['미야자키']),
        userCatalog: catalog,
        typeFilter: EntityAnchorType.person,
      );

      for (var i = 0; i < results.length - 1; i++) {
        expect(results[i].score, greaterThanOrEqualTo(results[i + 1].score));
      }
    });

    test('excludes linked entity ids', () async {
      final results = await LinkCandidateService.candidatesForWork(
        work: _work(creator: 'Hayao Miyazaki'),
        userCatalog: _FakeUserCatalog([]),
        excludeEntityIds: {'pe_000000004'},
        typeFilter: EntityAnchorType.person,
      );

      expect(results.any((c) => c.entityId == 'pe_000000004'), isFalse);
    });

    test('type filter limits to person', () async {
      final results = await LinkCandidateService.candidatesForWork(
        work: _work(creator: 'Hayao Miyazaki'),
        userCatalog: _FakeUserCatalog([]),
        typeFilter: EntityAnchorType.event,
      );

      expect(results, isEmpty);
    });

    test('includes catalog place entities', () async {
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: 'pl_u_tokyo01',
          type: EntityAnchorType.place,
          title: 'Tokyo',
          tags: const ['urban', 'japan'],
        ),
      ]);

      final results = await LinkCandidateService.candidatesForWork(
        work: _work(tags: const ['japan']),
        userCatalog: catalog,
        typeFilter: EntityAnchorType.place,
      );

      expect(results, isNotEmpty);
      expect(results.first.entityId, 'pl_u_tokyo01');
      expect(results.first.reason, LinkCandidateReason.tag);
    });

    test('includes catalog organization entities', () async {
      final catalog = _FakeUserCatalog([
        UserCatalogEntity.userLocal(
          entityId: 'or_u_gibli01',
          type: EntityAnchorType.organization,
          title: 'Studio Ghibli',
        ),
      ]);

      final results = await LinkCandidateService.candidatesForWork(
        work: _work(creator: 'Studio Ghibli'),
        userCatalog: catalog,
        typeFilter: EntityAnchorType.organization,
      );

      expect(results, isNotEmpty);
      expect(results.first.entityId, 'or_u_gibli01');
    });
  });
}
