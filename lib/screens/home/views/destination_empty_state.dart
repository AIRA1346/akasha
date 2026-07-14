import 'package:flutter/material.dart';

import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';

/// Shared empty/unavailable state for destination-level surfaces.
///
/// Geometry is theme-invariant; themes only supply semantic color tokens.
class DestinationEmptyState extends StatelessWidget {
  const DestinationEmptyState({
    super.key,
    required this.stateId,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final String stateId;
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AkashaSpacing.xl),
        child: Semantics(
          container: true,
          child: Container(
            key: ValueKey<String>('destination-empty-state-$stateId'),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(AkashaSpacing.xl),
            decoration: palette.surfaceCard(radius: AkashaRadius.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: AkashaRadius.xlBorder,
                    border: Border.all(color: palette.borderSubtle(0.24)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 24, color: palette.accent),
                ),
                const SizedBox(height: AkashaSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    key: ValueKey<String>('destination-empty-title-$stateId'),
                    textAlign: TextAlign.center,
                    style: AkashaTypography.dashboardSectionTitle.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AkashaSpacing.sm),
                Text(
                  body,
                  key: ValueKey<String>('destination-empty-body-$stateId'),
                  textAlign: TextAlign.center,
                  style: AkashaTypography.bodySecondary.copyWith(
                    color: palette.textMuted,
                    height: 1.45,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: AkashaSpacing.lg),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
