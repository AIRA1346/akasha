import 'package:flutter/material.dart';

import '../../../theme/akasha_colors.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';

/// Autosave vs 명시 저장 차이 안내 (R4-C P2 — 정책 변경 없음).
class WorkbenchSaveStatusHint extends StatelessWidget {
  const WorkbenchSaveStatusHint({
    super.key,
    required this.isDirty,
    required this.isSaving,
    this.lastSavedAt,
    this.explicitSaveLabel = 'md 저장',
  });

  final bool isDirty;
  final bool isSaving;
  final DateTime? lastSavedAt;
  final String explicitSaveLabel;

  @override
  Widget build(BuildContext context) {
    if (isSaving) {
      return _line('저장 중…', AkashaColors.statusSaving);
    }

    if (isDirty) {
      return _line(
        '변경됨 · 자동 저장은 편집 화면에 유지 · 탐험 복귀는 「$explicitSaveLabel」',
        AkashaColors.statusDirty,
      );
    }

    if (lastSavedAt != null) {
      final t = lastSavedAt!.toLocal();
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return _line(
        '저장됨 $hh:$mm · 자동 저장 · 탐험 복귀는 「$explicitSaveLabel」',
        AkashaColors.statusSaved,
      );
    }

    return _line(
      '「$explicitSaveLabel」하면 탐험 화면(Preview)으로 돌아갑니다',
      AkashaColors.textMuted,
    );
  }

  Widget _line(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkashaSpacing.sm),
      child: Text(
        text,
        style: AkashaTypography.caption.copyWith(color: color, height: 1.35),
      ),
    );
  }
}
