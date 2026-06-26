import 'package:flutter/material.dart';

import '../../../../theme/akasha_colors.dart';
import '../../../../theme/akasha_radius.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';
import '../workbench_save_status_hint.dart';

/// Workbench 패널 공통 스타일·위젯 (R14-A).
abstract final class WorkbenchPanelStyles {
  static const panelPadding = AkashaSpacing.workbenchPanel;

  static Widget panelDivider({double vertical = AkashaSpacing.lg}) {
    return Divider(
      color: AkashaColors.border,
      height: vertical,
      thickness: 1,
    );
  }

  static Widget sectionLabel(String title) {
    return Text(title, style: AkashaTypography.sectionLabel);
  }

  static Widget sectionHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(text, style: AkashaTypography.caption),
    );
  }

  static Widget connectionsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionLabel('연결'),
        sectionHint('기록 본문의 [[링크]]로 연결됩니다'),
      ],
    );
  }

  static Widget graphListButton({required VoidCallback onPressed}) {
    return SizedBox(
      height: 30,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.list_alt_outlined,
          size: 14,
          color: AkashaColors.accent,
        ),
        label: Text(
          '연결 목록에서 보기',
          style: AkashaTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AkashaColors.textPrimary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AkashaColors.accent),
          shape: RoundedRectangleBorder(borderRadius: AkashaRadius.smBorder),
        ),
      ),
    );
  }

  static ButtonStyle compactOutlinedStyle() {
    return OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(vertical: AkashaSpacing.sm),
      textStyle: AkashaTypography.caption,
    );
  }

  static ButtonStyle compactFilledStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AkashaColors.accent,
      foregroundColor: AkashaColors.textPrimary,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(vertical: AkashaSpacing.sm),
      textStyle: AkashaTypography.caption.copyWith(fontWeight: FontWeight.bold),
    );
  }

  static ButtonStyle compactDeleteStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.redAccent,
      side: const BorderSide(color: Colors.redAccent),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(vertical: AkashaSpacing.sm),
      textStyle: AkashaTypography.caption,
    );
  }

  /// Sanctum footer — 작은 텍스트 버튼 (본문 영역 확보).
  static ButtonStyle denseToolbarTextStyle({Color? foregroundColor}) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(
        horizontal: AkashaSpacing.sm,
        vertical: AkashaSpacing.xs,
      ),
      minimumSize: const Size(0, 28),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: AkashaTypography.caption.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle denseFilledStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AkashaColors.accent,
      foregroundColor: AkashaColors.textPrimary,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(
        horizontal: AkashaSpacing.md,
        vertical: AkashaSpacing.xs,
      ),
      minimumSize: const Size(0, 30),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: AkashaTypography.caption.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

/// Workbench 공통 저장·서재·삭제 블록 (R14-A).
class WorkbenchSaveActions extends StatelessWidget {
  const WorkbenchSaveActions({
    super.key,
    required this.isSaving,
    required this.isDirty,
    this.lastSavedAt,
    required this.saveLabel,
    required this.onSave,
    this.explicitSaveLabel,
    this.showAddToLibrary = false,
    this.libraryLabel = '서재에 담기',
    this.onAddToLibrary,
    this.showReset = false,
    this.onReset,
    this.canDeleteMd = false,
    this.onDeleteArchive,
    this.dense = false,
  });

  final bool isSaving;
  final bool isDirty;
  final DateTime? lastSavedAt;
  final String saveLabel;
  final VoidCallback onSave;
  final String? explicitSaveLabel;
  final bool showAddToLibrary;
  final String libraryLabel;
  final VoidCallback? onAddToLibrary;
  final bool showReset;
  final VoidCallback? onReset;
  final bool canDeleteMd;
  final VoidCallback? onDeleteArchive;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return _buildDense(context);
    }
    return _buildStacked(context);
  }

  Widget _buildDense(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchSaveStatusHint(
          isDirty: isDirty,
          isSaving: isSaving,
          lastSavedAt: lastSavedAt,
          explicitSaveLabel: explicitSaveLabel ?? saveLabel,
          dense: true,
        ),
        const SizedBox(height: AkashaSpacing.xs),
        Wrap(
          spacing: AkashaSpacing.xs,
          runSpacing: AkashaSpacing.xs,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showAddToLibrary && onAddToLibrary != null)
              TextButton.icon(
                onPressed: onAddToLibrary,
                icon: const Icon(Icons.collections_bookmark_outlined, size: 14),
                label: Text(libraryLabel),
                style: WorkbenchPanelStyles.denseToolbarTextStyle(),
              ),
            if (showReset && onReset != null)
              TextButton(
                onPressed: onReset,
                style: WorkbenchPanelStyles.denseToolbarTextStyle(),
                child: const Text('기본값'),
              ),
            if (canDeleteMd && onDeleteArchive != null)
              TextButton.icon(
                onPressed: isSaving ? null : onDeleteArchive,
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('md 삭제'),
                style: WorkbenchPanelStyles.denseToolbarTextStyle(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 14),
              label: Text(saveLabel),
              style: WorkbenchPanelStyles.denseFilledStyle(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStacked(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAddToLibrary && onAddToLibrary != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddToLibrary,
              icon: const Icon(Icons.collections_bookmark_outlined, size: 14),
              label: Text(libraryLabel),
              style: WorkbenchPanelStyles.compactOutlinedStyle(),
            ),
          ),
          const SizedBox(height: AkashaSpacing.sm),
        ],
        WorkbenchSaveStatusHint(
          isDirty: isDirty,
          isSaving: isSaving,
          lastSavedAt: lastSavedAt,
          explicitSaveLabel: explicitSaveLabel ?? saveLabel,
        ),
        if (showReset && onReset != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: WorkbenchPanelStyles.compactOutlinedStyle(),
                  child: const Text('기본값'),
                ),
              ),
              const SizedBox(width: AkashaSpacing.sm),
              Expanded(
                flex: 2,
                child: _saveButton(),
              ),
            ],
          )
        else
          _saveButton(),
        if (canDeleteMd && onDeleteArchive != null) ...[
          const SizedBox(height: AkashaSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onDeleteArchive,
              icon: const Icon(Icons.delete_outline, size: 14),
              label: const Text('md 삭제'),
              style: WorkbenchPanelStyles.compactDeleteStyle(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _saveButton() {
    return FilledButton.icon(
      onPressed: isSaving ? null : onSave,
      icon: isSaving
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined, size: 14),
      label: Text(saveLabel),
      style: WorkbenchPanelStyles.compactFilledStyle(),
    );
  }
}
