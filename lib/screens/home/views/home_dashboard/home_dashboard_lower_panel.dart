import 'package:flutter/material.dart';

import '../../../../theme/akasha_palette.dart';
import '../../../../theme/akasha_radius.dart';
import '../../../../theme/akasha_spacing.dart';
import '../../../../theme/akasha_typography.dart';

class HomeDashboardLowerPanel extends StatelessWidget {
  const HomeDashboardLowerPanel({
    super.key,
    required this.panelKey,
    required this.child,
  });

  final Key panelKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return DecoratedBox(
      key: panelKey,
      decoration: palette.surfaceCard(radius: AkashaRadius.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 268),
        child: Padding(
          padding: const EdgeInsets.all(AkashaSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}

class HomeDashboardPanelLoading extends StatelessWidget {
  const HomeDashboardPanelLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 160,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class HomeDashboardPanelStatus extends StatelessWidget {
  const HomeDashboardPanelStatus({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.akashaPalette;
    return SizedBox(
      height: 190,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AkashaSpacing.md),
                child: Icon(icon, color: palette.accent, size: 24),
              ),
            ),
            const SizedBox(height: AkashaSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AkashaTypography.bodySecondary.copyWith(
                color: palette.textSecondary,
                height: 1.4,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AkashaSpacing.md),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
