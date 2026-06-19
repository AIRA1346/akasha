import '../core/archiving/entity_anchor.dart';

/// Wave 4 — Browse 축 Entity 유형 필터 ([wave4-entity-types-spec §7]).
enum BrowseEntityScope {
  all,
  work,
  person,
  concept,
  event,
}

extension BrowseEntityScopeX on BrowseEntityScope {
  String get label => switch (this) {
        BrowseEntityScope.all => '전체',
        BrowseEntityScope.work => 'Work',
        BrowseEntityScope.person => 'Person',
        BrowseEntityScope.concept => 'Concept',
        BrowseEntityScope.event => 'Event',
      };

  bool get showsWorkGrid =>
      this == BrowseEntityScope.work || this == BrowseEntityScope.all;

  bool get showsCatalogEntities =>
      this != BrowseEntityScope.work;

  EntityAnchorType? get catalogEntityType => switch (this) {
        BrowseEntityScope.person => EntityAnchorType.person,
        BrowseEntityScope.concept => EntityAnchorType.concept,
        BrowseEntityScope.event => EntityAnchorType.event,
        _ => null,
      };

}

BrowseEntityScope browseScopeForEntityType(EntityAnchorType type) =>
    switch (type) {
      EntityAnchorType.person => BrowseEntityScope.person,
      EntityAnchorType.concept => BrowseEntityScope.concept,
      EntityAnchorType.event => BrowseEntityScope.event,
      _ => BrowseEntityScope.all,
    };
