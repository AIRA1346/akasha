import 'package:flutter_test/flutter_test.dart';
import 'package:akasha/core/archiving/entity_anchor.dart';
import 'package:akasha/models/browse_entity_scope.dart';

void main() {
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
