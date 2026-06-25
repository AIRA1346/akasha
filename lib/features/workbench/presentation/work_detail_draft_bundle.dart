import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../widgets/sanctum_page_panel.dart';
import 'work_detail_draft_ops.dart';

/// WorkDetailWorkspace — draft 필드·컨트롤러 묶음.
class WorkDetailDraftBundle {
  const WorkDetailDraftBundle({
    required this.item,
    required this.pageView,
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.fileCtrl,
    required this.posterUrlCtrl,
    required this.draftRating,
    required this.draftWorkStatus,
    required this.draftMyStatus,
    required this.draftHallOfFame,
    required this.draftTags,
  });

  final AkashaItem item;
  final SanctumPageView pageView;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final TextEditingController fileCtrl;
  final TextEditingController posterUrlCtrl;
  final double draftRating;
  final String draftWorkStatus;
  final String draftMyStatus;
  final bool draftHallOfFame;
  final List<String> draftTags;

  AkashaItem buildSaveDraft() => WorkDetailDraftOps.buildSaveDraft(
        item: item,
        pageView: pageView,
        titleCtrl: titleCtrl,
        bodyCtrl: bodyCtrl,
        fileCtrl: fileCtrl,
        posterUrlCtrl: posterUrlCtrl,
        draftRating: draftRating,
        draftWorkStatus: draftWorkStatus,
        draftMyStatus: draftMyStatus,
        draftHallOfFame: draftHallOfFame,
        draftTags: draftTags,
      );

  String previewBodyMarkdown() => WorkDetailDraftOps.previewBodyMarkdown(
        item: item,
        pageView: pageView,
        bodyCtrl: bodyCtrl,
        titleCtrl: titleCtrl,
        posterUrlCtrl: posterUrlCtrl,
        draftRating: draftRating,
        draftWorkStatus: draftWorkStatus,
        draftMyStatus: draftMyStatus,
        draftHallOfFame: draftHallOfFame,
        draftTags: draftTags,
      );

  AkashaItem applyDraft() => WorkDetailDraftOps.applyDraft(
        item: item,
        titleCtrl: titleCtrl,
        posterUrlCtrl: posterUrlCtrl,
        draftRating: draftRating,
        draftWorkStatus: draftWorkStatus,
        draftMyStatus: draftMyStatus,
        draftHallOfFame: draftHallOfFame,
        draftTags: draftTags,
      );

  void refreshFullFileEditor() => WorkDetailDraftOps.refreshFullFileEditor(
        item: item,
        bodyCtrl: bodyCtrl,
        fileCtrl: fileCtrl,
        titleCtrl: titleCtrl,
        posterUrlCtrl: posterUrlCtrl,
        draftRating: draftRating,
        draftWorkStatus: draftWorkStatus,
        draftMyStatus: draftMyStatus,
        draftHallOfFame: draftHallOfFame,
        draftTags: draftTags,
      );

  void handlePageViewChanging({
    required SanctumPageView current,
    required SanctumPageView next,
  }) =>
      WorkDetailDraftOps.handlePageViewChanging(
        current: current,
        next: next,
        item: item,
        bodyCtrl: bodyCtrl,
        titleCtrl: titleCtrl,
        fileCtrl: fileCtrl,
        posterUrlCtrl: posterUrlCtrl,
        draftRating: draftRating,
        draftWorkStatus: draftWorkStatus,
        draftMyStatus: draftMyStatus,
        draftHallOfFame: draftHallOfFame,
        draftTags: draftTags,
      );
}
