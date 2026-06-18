import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'work_detail_info_form.dart';
import 'work_detail_info_poster.dart';

/// 워크벤치 좌측 작품정보 패널 (E2-6).
class WorkDetailInfoPanel extends StatelessWidget {
  const WorkDetailInfoPanel({
    super.key,
    required this.item,
    required this.preview,
    required this.panelWidth,
    required this.infoPanelLocked,
    required this.vaultLinked,
    required this.titleCtrl,
    required this.posterUrlCtrl,
    required this.draftRating,
    required this.draftWorkStatus,
    required this.draftMyStatus,
    required this.draftHallOfFame,
    required this.draftTags,
    required this.registryTags,
    required this.isSaving,
    required this.isArchived,
    required this.showAddToLibrary,
    required this.onInfoWidthChanged,
    required this.onToggleInfoLock,
    required this.onMarkDirty,
    required this.onDraftRatingChanged,
    required this.onDraftWorkStatusChanged,
    required this.onDraftMyStatusChanged,
    required this.onDraftHallOfFameChanged,
    required this.onDraftTagsChanged,
    required this.onPosterTap,
    required this.onResetToDefaults,
    required this.onSaveArchive,
    required this.onAddToLibrary,
    this.canDeleteMd = false,
    this.onDeleteArchive,
  });

  final AkashaItem item;
  final AkashaItem preview;
  final double panelWidth;
  final bool infoPanelLocked;
  final bool vaultLinked;
  final TextEditingController titleCtrl;
  final TextEditingController posterUrlCtrl;
  final double draftRating;
  final String draftWorkStatus;
  final String draftMyStatus;
  final bool draftHallOfFame;
  final List<String> draftTags;
  final Set<String> registryTags;
  final bool isSaving;
  final bool isArchived;
  final bool showAddToLibrary;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final VoidCallback onMarkDirty;
  final ValueChanged<double> onDraftRatingChanged;
  final ValueChanged<String> onDraftWorkStatusChanged;
  final ValueChanged<String> onDraftMyStatusChanged;
  final ValueChanged<bool> onDraftHallOfFameChanged;
  final ValueChanged<List<String>> onDraftTagsChanged;
  final VoidCallback onPosterTap;
  final VoidCallback onResetToDefaults;
  final VoidCallback onSaveArchive;
  final VoidCallback onAddToLibrary;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;

  @override
  Widget build(BuildContext context) {
    final gradColors = categoryGradient(item.category);
    final metaLine = [
      if (item.creator.isNotEmpty) item.creator,
      if (item.releaseYear != null) '${item.releaseYear}',
    ].join(' · ');

    return WorkbenchResizablePanel(
      width: panelWidth,
      minWidth: 220,
      maxWidth: 400,
      locked: infoPanelLocked,
      onWidthChanged: onInfoWidthChanged,
      onToggleLock: onToggleInfoLock,
      child: ColoredBox(
        color: const Color(0xFF1A1A28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '작품 정보',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2D2D44)),
            if (!vaultLinked)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Row(
                  children: [
                    Icon(Icons.folder_off_outlined,
                        size: 14, color: Colors.amber[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '볼트 미연동 · 임시 저장만',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final posterMaxHeight = constraints.maxHeight * 0.55;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: WorkDetailInfoPoster(
                            preview: preview,
                            posterUrlCtrl: posterUrlCtrl,
                            gradColors: gradColors,
                            maxWidth: constraints.maxWidth,
                            maxHeight: posterMaxHeight,
                            onPosterTap: onPosterTap,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                          child: WorkDetailInfoForm(
                            item: item,
                            metaLine: metaLine,
                            titleCtrl: titleCtrl,
                            draftRating: draftRating,
                            draftWorkStatus: draftWorkStatus,
                            draftMyStatus: draftMyStatus,
                            draftHallOfFame: draftHallOfFame,
                            draftTags: draftTags,
                            registryTags: registryTags,
                            isSaving: isSaving,
                            isArchived: isArchived,
                            showAddToLibrary: showAddToLibrary,
                            onMarkDirty: onMarkDirty,
                            onDraftRatingChanged: onDraftRatingChanged,
                            onDraftWorkStatusChanged: onDraftWorkStatusChanged,
                            onDraftMyStatusChanged: onDraftMyStatusChanged,
                            onDraftHallOfFameChanged: onDraftHallOfFameChanged,
                            onDraftTagsChanged: onDraftTagsChanged,
                            onResetToDefaults: onResetToDefaults,
                            onSaveArchive: onSaveArchive,
                            onAddToLibrary: onAddToLibrary,
                            canDeleteMd: canDeleteMd,
                            onDeleteArchive: onDeleteArchive,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
