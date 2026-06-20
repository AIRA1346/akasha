import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/core/ports/user_catalog_port.dart';
import 'package:akasha/models/collectible_kind.dart';
import 'package:akasha/models/collectible_ref.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/services/open_collectible.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('openRef dispatches work ref to onOpenWork', () async {
    UserCatalogEntity? openedEntity;
    String? openedWorkId;
    final item = createItem(
      workId: 'wk_test',
      title: 'Test Work',
      category: MediaCategory.manga,
    );

    await CollectibleOpener.openRef(
      ref: const CollectibleRef(kind: CollectibleKind.work, id: 'wk_test'),
      userCatalog: _FakeCatalog(const []),
      vaultItems: [item],
      onOpenWork: (opened) => openedWorkId = opened.workId,
      onOpenEntity: (entity) async => openedEntity = entity,
    );

    expect(openedWorkId, 'wk_test');
    expect(openedEntity, isNull);
  });

  test('openRef dispatches person ref to onOpenEntity', () async {
    UserCatalogEntity? openedEntity;
    final entity = UserCatalogEntity.userLocal(
      entityId: 'pe_u_test',
      type: EntityAnchorType.person,
      title: 'Subaru',
    );

    await CollectibleOpener.openRef(
      ref: CollectibleRef(kind: CollectibleKind.person, id: entity.entityId),
      userCatalog: _FakeCatalog([entity]),
      vaultItems: const [],
      onOpenWork: (_) {},
      onOpenEntity: (e) async => openedEntity = e,
    );

    expect(openedEntity?.entityId, 'pe_u_test');
  });
}

class _FakeCatalog implements UserCatalogPort {
  _FakeCatalog(this._entities);

  final List<UserCatalogEntity> _entities;

  @override
  List<UserCatalogEntity> get all => _entities;

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
