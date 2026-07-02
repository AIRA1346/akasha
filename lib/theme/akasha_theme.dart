import 'package:flutter/material.dart';

import '../models/library_theme.dart';
import 'akasha_palette.dart';

/// AKASHA 글로벌 Material 3 다크 테마.
abstract final class AkashaTheme {
  static ThemeData dark({LibraryTheme appTheme = LibraryTheme.classic}) {
    final base = ThemeData.dark(useMaterial3: true);
    return withAppTheme(base, appTheme);
  }

  static ThemeData withAppTheme(ThemeData base, LibraryTheme appTheme) {
    final palette = AkashaPalette.fromLibraryTheme(appTheme);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: palette.accent,
          secondary: palette.accent,
          surface: palette.surface,
          surfaceContainerHighest: palette.surfaceElevated,
          onPrimary: Colors.white,
        );

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      colorScheme: colorScheme,
      extensions: [
        ...base.extensions.values.where((ext) => ext is! AkashaPalette),
        palette,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(color: palette.surfaceElevated),
      dividerTheme: DividerThemeData(color: palette.borderSubtle(0.32)),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: palette.accentSoft,
        checkmarkColor: palette.accent,
        side: BorderSide(color: palette.borderSubtle(0.24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
    );
  }
}
