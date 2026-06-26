import 'package:flutter/material.dart';

import '../../services/sanctum_archive_completion.dart';
import '../../theme/akasha_colors.dart';
import '../../theme/akasha_typography.dart';

/// Sanctum 기록 완성도 — 진행 바 + 슬롯 칩.
class SanctumArchiveCompletionBar extends StatelessWidget {
  const SanctumArchiveCompletionBar({
    super.key,
    required this.report,
  });

  final SanctumArchiveCompletionReport report;

  @override
  Widget build(BuildContext context) {
    final color = switch (report.percent) {
      >= 80 => AkashaColors.statusSaved,
      >= 40 => AkashaColors.statusDirty,
      _ => AkashaColors.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '기록 완성도',
                style: AkashaTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AkashaColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${report.percent}%',
                style: AkashaTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.percent / 100,
              minHeight: 6,
              backgroundColor: AkashaColors.borderSubtle(0.12),
              color: AkashaColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: report.criteria.map((criterion) {
              return _SlotChip(criterion: criterion);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.criterion});

  final SanctumCompletionCriterion criterion;

  @override
  Widget build(BuildContext context) {
    final filled = criterion.filled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled
            ? AkashaColors.accent.withValues(alpha: 0.15)
            : AkashaColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled
              ? AkashaColors.accent.withValues(alpha: 0.45)
              : AkashaColors.borderSubtle(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filled ? Icons.check_circle : Icons.circle_outlined,
            size: 12,
            color: filled ? AkashaColors.accent : AkashaColors.textCaption,
          ),
          const SizedBox(width: 4),
          Text(
            criterion.label,
            style: TextStyle(
              fontSize: 10,
              color: filled ? AkashaColors.textPrimary : AkashaColors.textCaption,
            ),
          ),
        ],
      ),
    );
  }
}
