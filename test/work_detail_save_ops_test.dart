import 'package:akasha/features/workbench/presentation/work_detail_save_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/sanctum_page_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shouldSkip blocks when suppressPersist or isSaving', () {
    expect(
      WorkDetailSaveOps.shouldSkip(suppressPersist: true, isSaving: false),
      isTrue,
    );
    expect(
      WorkDetailSaveOps.shouldSkip(suppressPersist: false, isSaving: true),
      isTrue,
    );
    expect(
      WorkDetailSaveOps.shouldSkip(suppressPersist: false, isSaving: false),
      isFalse,
    );
  });

  test('bodyMarkdownAfterSave returns null when still dirty', () {
    final item = createItem(
      workId: 'wk_save_ops',
      title: 'T',
      category: MediaCategory.manga,
      bodyRaw: 'body',
    );
    expect(
      WorkDetailSaveOps.bodyMarkdownAfterSave(
        saved: item,
        silent: false,
        stillDirty: true,
      ),
      isNull,
    );
    expect(
      WorkDetailSaveOps.bodyMarkdownAfterSave(
        saved: item,
        silent: false,
        stillDirty: false,
      ),
      isNotEmpty,
    );
  });
}
