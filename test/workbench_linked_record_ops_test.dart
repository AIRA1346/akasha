import 'package:akasha/features/workbench/presentation/workbench_linked_record_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/models/user_catalog_entity.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('openLinkedWork prefers onRecordOpenWork callback', () {
    final work = createItem(
      workId: 'wk_link',
      title: 'Work',
      category: MediaCategory.manga,
    );
    dynamic opened;
    WorkbenchLinkedRecordOps.openLinkedWork(
      work: work,
      onRecordOpenWork: (item) => opened = item,
    );
    expect(opened, work);
  });

  test('openLinkedEntity prefers onRecordOpenEntity callback', () {
    final entity = UserCatalogEntity(
      entityId: 'ent_link',
      title: 'Entity',
      subtype: MediaCategory.manga,
      addedAt: DateTime.utc(2024, 1, 1),
    );
    dynamic opened;
    WorkbenchLinkedRecordOps.openLinkedEntity(
      entity: entity,
      onRecordOpenEntity: (e) => opened = e,
    );
    expect(opened, entity);
  });
}
