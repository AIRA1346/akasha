import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/akasha_item.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/utils/work_related_characters.dart';

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
  UserCatalogEntity? getById(String entityId) => null;

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
  group('relatedCharactersForWork', () {
    test('returns person entities sharing tags with work', () {
      final work = ContentItem(
        workId: 'work-1',
        title: 'Re:Zero',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
        tags: const ['이세계', '환생'],
      );

      final emilia = UserCatalogEntity.userLocal(
        entityId: 'person:emilia',
        type: EntityAnchorType.person,
        title: '에밀리아',
        subtype: MediaCategory.animation,
        addedAt: DateTime(2024),
        tags: const ['이세계', '마왕'],
      );
      final unrelated = UserCatalogEntity.userLocal(
        entityId: 'person:other',
        type: EntityAnchorType.person,
        title: '다른 인물',
        subtype: MediaCategory.animation,
        addedAt: DateTime(2024),
        tags: const ['스포츠'],
      );

      final result = relatedCharactersForWork(
        work: work,
        catalog: _FakeCatalog([emilia, unrelated]),
      );

      expect(result, [emilia]);
    });

    test('returns empty for entity items', () {
      final entity = EntityItem(
        entityType: EntityAnchorType.person,
        entityId: 'person:test',
        title: 'Test',
        category: MediaCategory.animation,
        domain: AppDomain.subculture,
      );

      expect(
        relatedCharactersForWork(work: entity, catalog: _FakeCatalog(const [])),
        isEmpty,
      );
    });
  });
}
