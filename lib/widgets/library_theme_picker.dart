import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/library_theme.dart';
import '../models/theme_catalog.dart';
import '../theme/akasha_palette.dart';
import '../utils/app_l10n.dart';

/// 앱 테마 선택 바텀시트.
Future<LibraryTheme?> showLibraryThemePicker(
  BuildContext context, {
  required LibraryTheme current,
}) async {
  return showModalBottomSheet<LibraryTheme>(
    context: context,
    backgroundColor: context.akashaPalette.surfaceElevated,
    builder: (ctx) {
      final l10n = lookupAppL10n(ctx);
      final bundledThemes = LibraryTheme.all.where(
        (theme) => ThemeCatalog.byPresetId(theme.id)?.isBundled ?? false,
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
              ...bundledThemes.map((theme) {
                final selected = current.id == theme.id;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: selected
                      ? theme.accentColor.withValues(alpha: 0.08)
                      : null,
                  leading: _ThemeSwatch(theme: theme),
                  title: Text(_localizedThemeName(l10n, theme)),
                  trailing: selected
                      ? Icon(Icons.check, color: theme.accentColor)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx, theme);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

String _localizedThemeName(AppLocalizations? l10n, LibraryTheme theme) {
  return switch (theme.id) {
    'classicDark' => l10n?.themeClassicDarkName ?? 'Classic Dark',
    'midnightBlue' => l10n?.themeMidnightBlueName ?? 'Midnight Blue',
    'sakura' => l10n?.themeSakuraName ?? 'Sakura',
    'amethyst' => l10n?.themeAmethystName ?? 'Amethyst',
    'nocturne' => l10n?.themeNocturneName ?? 'Nocturne',
    _ => theme.name,
  };
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.theme});

  final LibraryTheme theme;

  @override
  Widget build(BuildContext context) {
    final preview = AkashaPalette.fromLibraryTheme(theme);

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
