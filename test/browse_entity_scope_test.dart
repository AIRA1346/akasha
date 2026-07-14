import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/browse_entity_scope.dart';
import 'package:akasha/screens/home/app_destination.dart';
import 'package:akasha/screens/home/home_shell_browse_content.dart';

void main() {
  test('showsWorkGrid is true for work and all only', () {
    expect(BrowseEntityScope.work.showsWorkGrid, isTrue);
    expect(BrowseEntityScope.all.showsWorkGrid, isTrue);
    expect(BrowseEntityScope.person.showsWorkGrid, isFalse);
    expect(BrowseEntityScope.concept.showsWorkGrid, isFalse);
  });

  test('entity discovery strip belongs to Explore all-scope only', () {
    expect(
      shouldShowEntityDiscoveryStrip(
        destination: AppDestination.explore,
        scope: BrowseEntityScope.all,
      ),
      isTrue,
    );
    for (final destination in const [
      AppDestination.home,
      AppDestination.library,
      AppDestination.collections,
    ]) {
      expect(
        shouldShowEntityDiscoveryStrip(
          destination: destination,
          scope: BrowseEntityScope.all,
        ),
        isFalse,
        reason: destination.name,
      );
    }
    expect(
      shouldShowEntityDiscoveryStrip(
        destination: AppDestination.explore,
        scope: BrowseEntityScope.work,
      ),
      isFalse,
    );
  });

  test(
    'browse surface routing matrix keeps Library free of discovery strip',
    () {
      String surface(AppDestination destination, BrowseEntityScope scope) {
        if (!scope.showsWorkGrid) return 'entityGallery';
        if (shouldShowEntityDiscoveryStrip(
          destination: destination,
          scope: scope,
        )) {
          return 'workGridWithEntityStrip';
        }
        return 'workGrid';
      }

      expect(
        surface(AppDestination.explore, BrowseEntityScope.work),
        'workGrid',
      );
      expect(
        surface(AppDestination.explore, BrowseEntityScope.all),
        'workGridWithEntityStrip',
      );
      expect(
        surface(AppDestination.library, BrowseEntityScope.all),
        'workGrid',
      );
      expect(
        surface(AppDestination.library, BrowseEntityScope.person),
        'entityGallery',
      );
    },
  );

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
