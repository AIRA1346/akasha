import 'package:akasha/features/workbench/presentation/work_detail_draft_ops.dart';
import 'package:akasha/models/enums.dart';
import 'package:akasha/utils/helpers.dart';
import 'package:akasha/widgets/sanctum_page_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('previewBodyMarkdown syncs body editor in preview view', () {
    final item = createItem(
      workId: 'wk_test',
      title: '테스트 작품',
      category: MediaCategory.animation,
      review: '이전 메모',
    );
    item.bodyRaw = '# 📝 메모\n이전 메모';
    final bodyCtrl = TextEditingController(text: '# 📝 메모\n새 메모 내용');
    final titleCtrl = TextEditingController(text: item.title);
    final posterCtrl = TextEditingController();

    final preview = WorkDetailDraftOps.previewBodyMarkdown(
      item: item,
      pageView: SanctumPageView.preview,
      bodyCtrl: bodyCtrl,
      titleCtrl: titleCtrl,
      posterUrlCtrl: posterCtrl,
      draftRating: item.rating,
      draftWorkStatus: item.workStatusLabel,
      draftMyStatus: item.myStatusLabel,
      draftHallOfFame: item.isHallOfFame,
      draftTags: item.tags,
    );

    expect(preview, contains('새 메모 내용'));
    expect(item.review, '새 메모 내용');
  });

  test('previewBodyMarkdown skips body sync in file view', () {
    final item = createItem(
      workId: 'wk_test2',
      title: '파일 뷰',
      category: MediaCategory.manga,
      review: '저장된 메모',
    );
    item.bodyRaw = '# 📝 메모\n저장된 메모';
    final bodyCtrl = TextEditingController(text: '# 📝 메모\n에디터만 변경');
    final titleCtrl = TextEditingController(text: item.title);
    final posterCtrl = TextEditingController();

    final preview = WorkDetailDraftOps.previewBodyMarkdown(
      item: item,
      pageView: SanctumPageView.file,
      bodyCtrl: bodyCtrl,
      titleCtrl: titleCtrl,
      posterUrlCtrl: posterCtrl,
      draftRating: item.rating,
      draftWorkStatus: item.workStatusLabel,
      draftMyStatus: item.myStatusLabel,
      draftHallOfFame: item.isHallOfFame,
      draftTags: item.tags,
    );

    expect(preview, contains('저장된 메모'));
    expect(item.review, '저장된 메모');
    expect(preview, isNot(contains('에디터만 변경')));
  });

  test('syncBodyFromEditor preserves trailing whitespace while editing', () {
    final item = createItem(
      workId: 'wk_trim',
      title: '트림',
      category: MediaCategory.manga,
    );
    final bodyCtrl = TextEditingController(text: '본문   ');

    WorkDetailDraftOps.syncBodyFromEditor(item, bodyCtrl);

    expect(item.bodyRaw, '본문   ');
    expect(bodyCtrl.text, '본문   ');
  });

  test('buildSaveDraft trims trailing whitespace only at save', () {
    final item = createItem(
      workId: 'wk_trim_save',
      title: '저장 트림',
      category: MediaCategory.manga,
    );
    final bodyCtrl = TextEditingController(text: '# 📝 메모\n내용   ');
    final titleCtrl = TextEditingController(text: item.title);
    final posterCtrl = TextEditingController();
    final fileCtrl = TextEditingController();

    WorkDetailDraftOps.buildSaveDraft(
      item: item,
      pageView: SanctumPageView.body,
      titleCtrl: titleCtrl,
      bodyCtrl: bodyCtrl,
      fileCtrl: fileCtrl,
      posterUrlCtrl: posterCtrl,
      draftRating: item.rating,
      draftWorkStatus: item.workStatusLabel,
      draftMyStatus: item.myStatusLabel,
      draftHallOfFame: item.isHallOfFame,
      draftTags: item.tags,
    );

    expect(item.bodyRaw, '# 📝 메모\n내용');
    expect(bodyCtrl.text, '# 📝 메모\n내용   ');
  });
}
