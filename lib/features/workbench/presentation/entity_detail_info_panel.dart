import 'package:flutter/material.dart';

import '../../../models/akasha_item.dart';
import '../../../models/enums.dart';
import '../../../models/user_catalog_entity.dart';
import '../../../screens/home/views/preview_record_view_model.dart';
import '../../../screens/home/views/preview_work_panel_content.dart';
import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../widgets/workbench_resizable_panel.dart';
import 'widgets/workbench_panel_styles.dart';
import 'work_detail_info_poster.dart';

/// Entity 워크벤치 좌측 요약 패널 — WorkDetailInfoPanel과 동일 구조.
class EntityDetailInfoPanel extends StatelessWidget {
  const EntityDetailInfoPanel({
    super.key,
    required this.entity,
    required this.preview,
    required this.hasJournal,
    required this.panelWidth,
    required this.infoPanelLocked,
    required this.onInfoWidthChanged,
    required this.onToggleInfoLock,
    required this.onPosterTap,
    required this.posterUrlCtrl,
    this.onClose,
    this.onFocusSanctum,
  });

  final UserCatalogEntity entity;
  final AkashaItem preview;
  final bool hasJournal;
  final double panelWidth;
  final bool infoPanelLocked;
  final ValueChanged<double>? onInfoWidthChanged;
  final VoidCallback? onToggleInfoLock;
  final VoidCallback onPosterTap;
  final TextEditingController posterUrlCtrl;
  final VoidCallback? onClose;
  final VoidCallback? onFocusSanctum;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    final record = PreviewRecordViewModel.fromEntity(entity);
    final gradColors = categoryGradient(entity.subtype);

    return WorkbenchResizablePanel(
      width: panelWidth,
      minWidth: 220,
      maxWidth: 400,
      locked: infoPanelLocked,
      onWidthChanged: onInfoWidthChanged,
      onToggleLock: onToggleInfoLock,
      child: ColoredBox(
        color: palette.workbenchPanel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final posterMaxHeight = constraints.maxHeight * 0.30;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AkashaSpacing.md,
                          AkashaSpacing.sm,
                          AkashaSpacing.md,
                          AkashaSpacing.xs,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: WorkDetailInfoPoster(
                            preview: preview,
                            posterUrlCtrl: posterUrlCtrl,
                            gradColors: gradColors,
                            maxWidth: constraints.maxWidth,
                            maxHeight: posterMaxHeight,
                            onPosterTap: onPosterTap,
                            onClose: onClose,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: WorkbenchPanelStyles.panelPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PreviewRecordTitleBlock(model: record),
                              const SizedBox(height: AkashaSpacing.sm),
                              Row(
                                children: [
                                  Icon(
                                    hasJournal
                                        ? Icons.inventory_2_outlined
                                        : Icons.cloud_outlined,
                                    size: 14,
                                    color: hasJournal
                                        ? AkashaColors.statusSaved
                                        : AkashaColors.textMuted,
                                  ),
                                  const SizedBox(width: AkashaSpacing.sm),
                                  Text(
                                    hasJournal ? '기록 있음' : '기록 없음 (카탈로그만)',
                                    style: AkashaTypography.bodySecondary
                                        .copyWith(
                                          color: hasJournal
                                              ? AkashaColors.statusSaved
                                              : AkashaColors.textMuted,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AkashaSpacing.md),
                              PreviewRecordCoreInfoSection(
                                rows: record.coreInfoRows,
                              ),
                              const SizedBox(height: AkashaSpacing.md),
                              WorkbenchPanelStyles.panelDivider(
                                vertical: AkashaSpacing.sm,
                              ),
                              WorkbenchPanelStyles.sectionLabel('메모'),
                              const SizedBox(height: AkashaSpacing.sm),
                              InkWell(
                                onTap: onFocusSanctum,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: palette.workbenchTile,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: palette.borderSubtle(0.2),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AkashaSpacing.md,
                                    vertical: AkashaSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        size: 18,
                                        color: AkashaColors.textMuted,
                                      ),
                                      const SizedBox(width: AkashaSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          '메모 · 기록 본문에서 편집',
                                          style: AkashaTypography.caption,
                                        ),
                                      ),
                                      if (onFocusSanctum != null)
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: AkashaColors.textCaption,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
