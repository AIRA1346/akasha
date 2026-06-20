import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/browse_entity_scope.dart';

void main() {
  test('showsWorkGrid is true for work and all only', () {
    expect(BrowseEntityScope.work.showsWorkGrid, isTrue);
    expect(BrowseEntityScope.all.showsWorkGrid, isTrue);
    expect(BrowseEntityScope.person.showsWorkGrid, isFalse);
    expect(BrowseEntityScope.concept.showsWorkGrid, isFalse);
  });

  test('showsEntityDiscoveryStrip is true for all only', () {
    expect(BrowseEntityScope.all.showsEntityDiscoveryStrip, isTrue);
    expect(BrowseEntityScope.work.showsEntityDiscoveryStrip, isFalse);
    expect(BrowseEntityScope.person.showsEntityDiscoveryStrip, isFalse);
  });

  test('browse surface routing matrix', () {
    String surface(BrowseEntityScope scope) {
      if (!scope.showsWorkGrid) return 'entityGallery';
      if (scope.showsEntityDiscoveryStrip) return 'workGridWithEntityStrip';
      return 'workGrid';
    }

    expect(surface(BrowseEntityScope.work), 'workGrid');
    expect(surface(BrowseEntityScope.all), 'workGridWithEntityStrip');
    expect(surface(BrowseEntityScope.person), 'entityGallery');
    expect(surface(BrowseEntityScope.concept), 'entityGallery');
  });

  test('browseScopeForEntityType maps person concept event place org', () {
    expect(
      browseScopeForEntityType(EntityAnchorType.person),
      BrowseEntityScope.person,
    );
    expect(
      browseScopeForEntityType(EntityAnchorType.concept),
      BrowseEntityScope.concept,
    );
    expect(
      browseScopeForEntityType(EntityAnchorType.event),
      BrowseEntityScope.event,
    );
    expect(
      browseScopeForEntityType(EntityAnchorType.place),
      BrowseEntityScope.place,
    );
    expect(
      browseScopeForEntityType(EntityAnchorType.organization),
      BrowseEntityScope.organization,
    );
  });
}
