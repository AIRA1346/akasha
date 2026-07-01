import 'package:akasha/models/browse_entity_scope.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/screens/home/coordinators/home_entity_archive_ops.dart';
import 'package:akasha/screens/home/home_browse_filter_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'onEntityArchived highlights entity scope and clears highlight later',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final context = tester.element(find.byType(SizedBox));
      final filterCtrl = HomeBrowseFilterController();
      var rebuilds = 0;
      final entity = UserCatalogEntity(
        entityId: 'ent_ops',
        entityType: UserCatalogEntity.entityTypePerson,
        title: '테스트',
        subtype: MediaCategory.manga,
        addedAt: DateTime.utc(2024, 1, 1),
      );

      HomeEntityArchiveOps.onEntityArchived(
        context: context,
        entity: entity,
        entry: null,
        filterCtrl: filterCtrl,
        rebuild: () => rebuilds++,
        isMounted: () => true,
        showSnack: (_) {},
      );

      expect(
        filterCtrl.entityScope,
        browseScopeForEntityType(entity.anchorType),
      );
      expect(filterCtrl.highlightEntityId, 'ent_ops');
      expect(rebuilds, greaterThanOrEqualTo(1));

      await tester.pump(const Duration(seconds: 4));
      expect(filterCtrl.highlightEntityId, isNull);
    },
  );
}
