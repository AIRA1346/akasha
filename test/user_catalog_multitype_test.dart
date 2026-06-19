import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/entity_id_codec.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/fusion_search_service.dart';
import 'fakes/fake_registry_port.dart';
import 'fakes/fake_user_catalog_port.dart';

void main() {
  group('UserCatalogEntity multi-type', () {
    test('concept round-trip json', () {
      final entity = UserCatalogEntity.userLocal(
        entityId: EntityIdCodec.buildUserLocal(EntityAnchorType.concept),
        type: EntityAnchorType.concept,
        title: 'Tiger',
        aliases: ['호랑이', '백호'],
      );

      final restored = UserCatalogEntity.fromJson(entity.toJson());
      expect(restored.entityType, UserCatalogEntity.entityTypeConcept);
      expect(restored.title, 'Tiger');
      expect(restored.aliases, ['호랑이', '백호']);
      expect(restored.anchorType, EntityAnchorType.concept);
    });

    test('toRegistryWork carries entityType extension', () {
      final entity = UserCatalogEntity.userLocal(
        entityId: EntityIdCodec.buildUserLocal(EntityAnchorType.person),
        type: EntityAnchorType.person,
        title: '나비',
      );
      final work = entity.toRegistryWork();
      expect(work.extensions['entityType'], UserCatalogEntity.entityTypePerson);
    });
  });

  group('FusionSearchService multi-type catalog', () {
    test('finds concept in user catalog', () async {
      final catalog = FakeUserCatalogPort()
        ..seed([
          UserCatalogEntity.userLocal(
            entityId: EntityIdCodec.buildUserLocal(EntityAnchorType.concept),
            type: EntityAnchorType.concept,
            title: 'Tiger',
            aliases: ['호랑이'],
          ),
        ]);

      final result = await FusionSearchService.search(
        query: 'Tiger',
        localItems: const [],
        userCatalog: catalog,
        registry: FakeRegistryPort(),
      );

      expect(result.registryHits.length, 1);
      expect(result.registryHits.first.entityType, EntityAnchorType.concept);
      expect(result.registryHits.first.work.title, 'Tiger');
    });
  });
}
