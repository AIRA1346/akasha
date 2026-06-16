import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../services/markdown_body_merger.dart';
import '../../../services/markdown_parser.dart';
import '../../../services/works_registry.dart';
import '../../../widgets/sanctum_page_panel.dart';

/// WorkDetailWorkspace draft·markdown 조작 (E2-6).
class WorkDetailDraftOps {
  static bool sameItemSnapshot(AkashaItem a, AkashaItem b) {
    return a.workId == b.workId &&
        a.title == b.title &&
        a.rating == b.rating &&
        a.posterPath == b.posterPath &&
        a.bodyRaw == b.bodyRaw &&
        a.description == b.description &&
        a.review == b.review &&
        a.myStatusLabel == b.myStatusLabel &&
        a.workStatusLabel == b.workStatusLabel &&
        a.isHallOfFame == b.isHallOfFame &&
        listEquals(a.tags, b.tags);
  }

  static String initialBodyMarkdown(AkashaItem item) {
    if (item.bodyRaw.trim().isNotEmpty) return item.bodyRaw;
    return MarkdownBodyMerger.buildDefaultBody(
      synopsis: item.description,
      quotes: item.memorableQuotes,
      memo: item.review,
    );
  }

  static void syncBodyFromEditor(AkashaItem item, TextEditingController bodyCtrl) {
    item.bodyRaw = bodyCtrl.text.trimRight();
    final slots = MarkdownBodyMerger.parseSlots(item.bodyRaw);
    item.description = slots.synopsis;
    item.memorableQuotes = List<String>.from(slots.quotes);
    item.review = slots.memo;
  }

  static AkashaItem applyDraft({
    required AkashaItem item,
    required TextEditingController titleCtrl,
    required TextEditingController posterUrlCtrl,
    required double draftRating,
    required String draftWorkStatus,
    required String draftMyStatus,
    required bool draftHallOfFame,
    required List<String> draftTags,
  }) {
    final poster = posterUrlCtrl.text.trim();
    item.title =
        titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : item.title;
    item.rating = draftRating;
    item.posterPath = poster.isNotEmpty ? poster : null;
    item.setWorkStatus(draftWorkStatus);
    item.setMyStatus(draftMyStatus);
    item.isHallOfFame = draftHallOfFame;
    item.tags = List<String>.from(draftTags);
    return item;
  }

  static AkashaItem buildSaveDraft({
    required AkashaItem item,
    required SanctumPageView pageView,
    required TextEditingController titleCtrl,
    required TextEditingController bodyCtrl,
    required TextEditingController fileCtrl,
    required TextEditingController posterUrlCtrl,
    required double draftRating,
    required String draftWorkStatus,
    required String draftMyStatus,
    required bool draftHallOfFame,
    required List<String> draftTags,
  }) {
    if (pageView == SanctumPageView.file) {
      final preservedPath = item.filePath;
      final titleFallback =
          titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : item.title;
      final parsed =
          MarkdownParser.deserialize(fileCtrl.text, titleFallback);
      parsed.filePath = preservedPath;
      return parsed;
    }
    syncBodyFromEditor(item, bodyCtrl);
    return applyDraft(
      item: item,
      titleCtrl: titleCtrl,
      posterUrlCtrl: posterUrlCtrl,
      draftRating: draftRating,
      draftWorkStatus: draftWorkStatus,
      draftMyStatus: draftMyStatus,
      draftHallOfFame: draftHallOfFame,
      draftTags: draftTags,
    );
  }

  static String previewBodyMarkdown({
    required AkashaItem item,
    required SanctumPageView pageView,
    required TextEditingController bodyCtrl,
    required TextEditingController titleCtrl,
    required TextEditingController posterUrlCtrl,
    required double draftRating,
    required String draftWorkStatus,
    required String draftMyStatus,
    required bool draftHallOfFame,
    required List<String> draftTags,
  }) {
    if (pageView == SanctumPageView.body) {
      syncBodyFromEditor(item, bodyCtrl);
    }
    final draft = applyDraft(
      item: item,
      titleCtrl: titleCtrl,
      posterUrlCtrl: posterUrlCtrl,
      draftRating: draftRating,
      draftWorkStatus: draftWorkStatus,
      draftMyStatus: draftMyStatus,
      draftHallOfFame: draftHallOfFame,
      draftTags: draftTags,
    );
    return MarkdownBodyMerger.mergeBody(
      bodyRaw: draft.bodyRaw,
      synopsis: draft.description,
      quotes: draft.memorableQuotes,
      memo: draft.review,
    );
  }

  static Set<String> loadRegistryTags(String workId) {
    final resolved = WorksRegistry.resolveWorkId(workId);
    if (resolved.isEmpty) return {};
    final work = WorksRegistry.getWorkById(resolved);
    return work?.tags.toSet() ?? {};
  }
}
