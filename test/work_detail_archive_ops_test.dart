import 'package:akasha/features/workbench/presentation/work_detail_archive_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saveSuccessMessage mentions md when vault path unset', () {
    final item = createItem(
      workId: 'sub_manga_test_2020',
      title: '테스트',
      category: MediaCategory.manga,
      domain: AppDomain.subculture,
    );
    expect(
      WorkDetailArchiveOps.saveSuccessMessage(item),
      contains('임시 저장'),
    );
  });
}
