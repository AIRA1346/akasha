import 'package:flutter/material.dart';

import '../../../../../theme/akasha_colors.dart';
import '../../../../../theme/akasha_radius.dart';
import '../../../../../theme/akasha_spacing.dart';
import '../../../../../theme/akasha_typography.dart';

/// Sanctum 슬롯 섹션 공통 카드 — 제목 + 멀티라인 TextField.
class SanctumSectionCard extends StatelessWidget {
  const SanctumSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.controller,
    required this.minLines,
  });

  final IconData icon;
  final String title;
  final String hint;
  final TextEditingController controller;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AkashaColors.surface.withValues(alpha: 0.35),
        borderRadius: AkashaRadius.mdBorder,
        border: Border.all(color: AkashaColors.borderSubtle(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AkashaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AkashaColors.accent),
                const SizedBox(width: AkashaSpacing.sm),
                Text(title, style: AkashaTypography.sectionTitle),
              ],
            ),
            const SizedBox(height: AkashaSpacing.sm),
            TextField(
              controller: controller,
              minLines: minLines,
              maxLines: null,
              style: AkashaTypography.body,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AkashaTypography.bodySecondary,
                filled: true,
                fillColor: AkashaColors.workbenchEditor,
                border: OutlineInputBorder(
                  borderRadius: AkashaRadius.smBorder,
                  borderSide: BorderSide(
                    color: AkashaColors.borderSubtle(0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AkashaRadius.smBorder,
                  borderSide: BorderSide(
                    color: AkashaColors.borderSubtle(0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AkashaRadius.smBorder,
                  borderSide: const BorderSide(color: AkashaColors.accent),
                ),
                contentPadding: const EdgeInsets.all(AkashaSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
