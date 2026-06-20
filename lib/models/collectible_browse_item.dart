import 'browse_card.dart';
import 'collectible_ref.dart';
import 'entity_browse_card.dart';
import 'akasha_item.dart';
import 'user_catalog_entity.dart';

/// Resolved collection member before gallery enrichment (Phase 5).
sealed class CollectibleMember {
  CollectibleRef get ref;
}

final class WorkCollectibleMember extends CollectibleMember {
  WorkCollectibleMember({required this.ref, required this.item});

  @override
  final CollectibleRef ref;
  final AkashaItem item;
}

final class EntityCollectibleMember extends CollectibleMember {
  EntityCollectibleMember({required this.ref, required this.entity});

  @override
  final CollectibleRef ref;
  final UserCatalogEntity entity;
}

/// Mixed collection gallery cell (Work poster + Entity collectible).
sealed class CollectibleBrowseItem {
  CollectibleRef get ref;
}

final class WorkCollectibleBrowseItem extends CollectibleBrowseItem {
  WorkCollectibleBrowseItem({required this.ref, required this.card});

  @override
  final CollectibleRef ref;
  final BrowseCard card;
}

final class EntityCollectibleBrowseItem extends CollectibleBrowseItem {
  EntityCollectibleBrowseItem({required this.ref, required this.card});

  @override
  final CollectibleRef ref;
  final EntityBrowseCard card;
}

String collectibleRefKey(CollectibleRef ref) => '${ref.kind.name}:${ref.id}';
