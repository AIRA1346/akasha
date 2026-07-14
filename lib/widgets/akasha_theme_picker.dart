import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/akasha_theme_registry.dart';
import '../theme/akasha_palette.dart';
import '../theme/akasha_theme_preset.dart';
import '../utils/app_l10n.dart';

/// App-theme picker. Access filtering comes from the canonical registry; the
/// picker returns a canonical preset ID and never owns persistence or access
/// resolution.
Future<String?> showAkashaThemePicker(
  BuildContext context, {
  required String currentThemeId,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.akashaPalette.surfaceElevated,
    builder: (ctx) {
      final l10n = lookupAppL10n(ctx);
      final bundledThemes = AkashaThemeRegistry.all.where(
        (definition) => definition.catalog.isBundled,
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.appPreferencesThemeTitle ?? '앱 테마',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.appThemePickerFreeNotice ??
                    'Classic Dark와 Midnight Blue는 기본 무료 테마입니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: ctx.akashaPalette.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ...bundledThemes.map((definition) {
                final selected = currentThemeId == definition.id;
                final preset = definition.preset;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: selected
                      ? preset.accentColor.withValues(alpha: 0.08)
                      : null,
                  leading: _ThemeSwatch(preset: preset),
                  title: Text(_localizedThemeName(l10n, definition)),
                  trailing: selected
                      ? Icon(Icons.check, color: preset.accentColor)
                      : null,
                  onTap: () => Navigator.pop(ctx, definition.id),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

String _localizedThemeName(
  AppLocalizations? l10n,
  AkashaThemeDefinition definition,
) {
  final catalog = definition.catalog;
  return switch (catalog.displayNameL10nKey) {
    'themeClassicDarkName' =>
      l10n?.themeClassicDarkName ?? catalog.fallbackDisplayName,
    'themeMidnightBlueName' =>
      l10n?.themeMidnightBlueName ?? catalog.fallbackDisplayName,
    'themeSakuraName' => l10n?.themeSakuraName ?? catalog.fallbackDisplayName,
    'themeAmethystName' =>
      l10n?.themeAmethystName ?? catalog.fallbackDisplayName,
    'themeNocturneName' =>
      l10n?.themeNocturneName ?? catalog.fallbackDisplayName,
    _ => catalog.fallbackDisplayName,
  };
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.preset});

  final AkashaThemePreset preset;

  @override
  Widget build(BuildContext context) {
    final preview = AkashaPalette.fromPreset(preset);

    return Container(
      width: 42,
      height: 30,
      decoration: BoxDecoration(
        color: preview.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: preview.borderSubtle(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: preview.sidebar)),
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: preview.surface),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: preview.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
