import 'package:flutter/material.dart';

import '../../../theme/akasha_palette.dart';
import '../../../theme/akasha_radius.dart';
import '../../../theme/akasha_spacing.dart';
import '../../../theme/akasha_typography.dart';
import '../../../utils/app_l10n.dart';
import '../app_destination.dart';

/// Compact role statement for global destinations with dedicated content.
///
/// It clarifies the role of each surface without changing navigation or local
/// content state.
class DestinationContextHeader extends StatelessWidget {
  const DestinationContextHeader({super.key, required this.destination});

  static const headerKey = ValueKey<String>('destination-context-header');
  static const titleKey = ValueKey<String>('destination-context-header-title');
  static const descriptionKey = ValueKey<String>(
    'destination-context-header-description',
  );

  final AppDestination destination;

  @override
  Widget build(BuildContext context) {
    final definition = AppDestinationRegistry.definitionFor(destination);
    final l10n = lookupAppL10n(context);
    final description = definition.resolvePurposeDescription(l10n);
    if (!definition.showsContextHeader || description == null) {
      return const SizedBox.shrink();
    }

    final palette = context.akashaPalette;
    final title = definition.resolveLabel(l10n);

    return Semantics(
      container: true,
      header: true,
      label: '$title. $description',
      child: Container(
        key: headerKey,
        padding: const EdgeInsets.fromLTRB(
          AkashaSpacing.lg,
          AkashaSpacing.md,
          AkashaSpacing.lg,
          AkashaSpacing.md,
        ),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.54),
          border: Border(bottom: BorderSide(color: palette.borderSubtle(0.2))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: AkashaRadius.lgBorder,
                border: Border.all(color: palette.borderSubtle(0.22)),
              ),
              alignment: Alignment.center,
              child: Icon(definition.icon, size: 18, color: palette.accent),
            ),
            const SizedBox(width: AkashaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    key: titleKey,
                    style: AkashaTypography.dashboardSectionTitle.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    key: descriptionKey,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AkashaTypography.bodySecondary.copyWith(
                      color: palette.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DestinationContextFrame extends StatelessWidget {
  const DestinationContextFrame({
    super.key,
    required this.destination,
    required this.child,
  });

  final AppDestination destination;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final definition = AppDestinationRegistry.definitionFor(destination);
    if (!definition.showsContextHeader) return child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DestinationContextHeader(destination: destination),
        Expanded(child: child),
      ],
    );
  }
}
