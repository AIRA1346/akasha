import 'package:flutter/material.dart';

import '../theme/akasha_palette.dart';
import '../theme/akasha_radius.dart';
import '../theme/akasha_spacing.dart';
import '../theme/akasha_typography.dart';
import '../utils/app_l10n.dart';

class PreviewConnectionAction {
  const PreviewConnectionAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class PreviewConnectionSuggestion {
  const PreviewConnectionSuggestion({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class PreviewConnectionEmptyState extends StatelessWidget {
  const PreviewConnectionEmptyState({
    super.key,
    required this.description,
    this.actions = const [],
    this.suggestions = const [],
  });

  final String description;
  final List<PreviewConnectionAction> actions;
  final List<PreviewConnectionSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n?.workbenchTabConnections ?? '연결',
          style: AkashaTypography.sectionLabel.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: AkashaSpacing.sm + 2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AkashaRadius.lgBorder,
            border: Border.all(color: palette.borderSubtle(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AkashaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 17,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: AkashaSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.previewNoConnectionsTitle ?? '아직 연결이 없습니다',
                            style: AkashaTypography.bodyEmphasis.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AkashaSpacing.xs),
                          Text(
                            description,
                            style: AkashaTypography.micro.copyWith(
                              color: palette.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: AkashaSpacing.md),
                  Text(
                    l10n?.previewSuggestedConnections ?? '추천 연결',
                    style: AkashaTypography.micro.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: AkashaSpacing.sm),
                  Wrap(
                    spacing: AkashaSpacing.sm,
                    runSpacing: AkashaSpacing.sm,
                    children: [
                      for (final suggestion in suggestions)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            suggestion.icon,
                            size: 14,
                            color: palette.accent,
                          ),
                          label: Text(
                            suggestion.label,
                            style: AkashaTypography.micro,
                          ),
                          onPressed: suggestion.onPressed,
                        ),
                    ],
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AkashaSpacing.md),
                  _ConnectionActionMenu(actions: actions),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionActionMenu extends StatelessWidget {
  const _ConnectionActionMenu({required this.actions});

  final List<PreviewConnectionAction> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = lookupAppL10n(context);
    final palette = context.akashaPalette;

    return MenuAnchor(
      menuChildren: [
        for (final action in actions)
          MenuItemButton(
            onPressed: action.onPressed,
            leadingIcon: Icon(action.icon, size: 17),
            child: Text(action.label),
          ),
      ],
      builder: (context, controller, child) => OutlinedButton.icon(
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        icon: const Icon(Icons.add_link_rounded, size: 17),
        label: Text(l10n?.previewAddConnection ?? '연결 추가'),
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.accent,
          side: BorderSide(color: palette.borderSubtle(0.38)),
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: AkashaRadius.mdBorder),
        ),
      ),
    );
  }
}
